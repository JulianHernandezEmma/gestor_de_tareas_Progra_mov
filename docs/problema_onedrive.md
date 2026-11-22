# Problema real: el proyecto no compilaba dentro de OneDrive

## Síntoma

Con el proyecto en
`...\OneDrive\Escritorio\Trabajos de La Uni\Semestre 7\...` la app no
compilaba ni se podía ejecutar. Los errores eran intermitentes y apuntaban a
archivos de `build/` o `.dart_tool/` "en uso por otro proceso", aunque el
código estaba bien. Tardé bastante en descubrir que el código no tenía la culpa.

## Causa (qué dicen las fuentes)

OneDrive sincroniza en segundo plano toda la carpeta. Una compilación de
Flutter crea, borra y reescribe miles de archivos pequeños (`build/`,
`.dart_tool/`, cachés de Gradle/Kotlin, `ephemeral/`). Mientras OneDrive los
sube o los analiza, mantiene bloqueos temporales sobre ellos. Si Flutter
intenta borrarlos o reemplazarlos justo entonces, Windows responde con
`errno = 32` ("el proceso no puede acceder al archivo porque está siendo
utilizado por otro proceso") y la compilación se cae.

Evidencia consultada:

- Issue de Flutter #145028: `PathAccessException ... errno = 32` al borrar
  archivos de `build\app\intermediates`. Un usuario lo resolvió **copiando el
  proyecto a otro disco**, sospechando de la carpeta sincronizada con OneDrive.
- Issue de Flutter #186959: los mantenedores describen que antivirus,
  motores de sincronización como OneDrive e indexadores del IDE ponen bloqueos
  transitorios sobre archivos de `build/` y `.dart_tool/`, y que la herramienta
  no reintenta.
- Issue de Flutter #187225: ante "Could not close incremental caches" (caché
  incremental de Kotlin), el equipo pide comprobar que el proyecto no esté en
  una carpeta de OneDrive.
- Pregunta de Stack Overflow 79823485: `flutter clean` falla al borrar
  `.dart_tool` y los `ephemeral` sin que ningún proceso aparezca bloqueándolos;
  la respuesta recomienda mover los repositorios fuera de OneDrive.
- Artículo "OneDrive is not for active development projects" y el hilo de
  Microsoft Community Hub: OneDrive **no permite excluir carpetas por nombre**
  (como `build/` o `node_modules/`), así que la recomendación práctica es
  mantener los repositorios en una ruta local sin sincronizar, por ejemplo
  `C:\dev\`.

Factor adicional: mi ruta original contenía espacios (`Trabajos de La Uni`,
`Programacion de Dispositivos Moviles`). Hay reportes de errores de Flutter en
Windows con espacios en la ruta, que pueden sumarse al problema. No aislé cuál
de los dos factores pesó más; moví el proyecto a una ruta sin ambos.

## Solución aplicada

1. Clonar el repositorio fuera de OneDrive: `C:\dev\Dispositivos-Moviles-2026`
   (sin espacios, sin sincronización).
2. Copiar el proyecto Flutter generado, sin `build/` ni `.dart_tool/`.
3. Ejecutar `flutter pub get` y regenerar el código con `build_runner`.

## Verificación

Ya en `C:\dev`: `flutter analyze` sin errores, `flutter test` con todas las
pruebas en verde, `flutter build web` y `flutter build windows --debug`
terminan correctamente. No reproduje de nuevo el fallo dentro de OneDrive:
la conclusión se apoya en que el problema desapareció al cambiar de ubicación
y en las fuentes anteriores.

## Recomendación

Trabajar siempre en una ruta local sin sincronizar y subir el código con
`git push`. Si hay que quedarse en OneDrive, pausar la sincronización durante
la compilación o marcar la carpeta como "Mantener siempre en este dispositivo"
reduce el problema, pero no lo elimina.
