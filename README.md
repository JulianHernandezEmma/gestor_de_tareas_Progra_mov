# Gestor de tareas SQLite multiplataforma

App Flutter que administra tareas con una base **SQLite local** (sin servidor, sin internet).

## Tecnología de persistencia

**Drift + drift_flutter** (sobre `sqlite3`).

- Una sola base de código para Android, iOS, Windows, Linux, macOS y web.
- En nativo usa SQLite vía FFI; en web usa `sqlite3.wasm` + un worker.
- Tablas y consultas en Dart con tipos seguros; `build_runner` genera el código.
- Consultas reactivas con `Stream` (la UI se actualiza sola tras cada escritura).

## Diseño de la tabla `tareas`

| Columna      | Tipo SQLite         | Notas                                   |
|--------------|---------------------|-----------------------------------------|
| `id`         | INTEGER PK AUTOINC  | Identifica cada registro                |
| `titulo`     | TEXT NOT NULL       | 1 a 120 caracteres, sin ser solo espacios |
| `completada` | INTEGER (0/1)       | SQLite no tiene BOOLEAN; Drift lo mapea |
| `creada_en`  | INTEGER (epoch s)   | Orden de la lista                       |

## Preparación

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d chrome
```

> **Importante:** clona/trabaja el proyecto **fuera de carpetas sincronizadas con OneDrive**
> (ver `docs/problema_onedrive.md`).

## Web (SQLite con WebAssembly)

En `web/` van dos archivos que **deben ser de la misma versión que `drift`** en `pubspec.lock` (hoy 2.35.4):

- `sqlite3.wasm`
- `drift_worker.dart.js` (en el release de GitHub se llama `drift_worker.js`; se renombró)

Se descargan del release `drift-2.35.4` de https://github.com/simolus3/drift/releases.
Si cambias la versión de drift, vuelve a descargarlos. El servidor debe servir
el `.wasm` con `Content-Type: application/wasm` (`flutter run` ya lo hace).
En web los datos quedan ligados al origen y perfil del navegador; en modo privado
o al borrar los datos del sitio se pierden.

## Pruebas automatizadas

`flutter test` ejecuta:

- `tareas_repository_test.dart`: validación de títulos (vacío, solo espacios, más de 120) y CRUD sobre SQLite en memoria.
- `persistencia_test.dart`: guarda, marca, edita y borra en un archivo real, cierra la base, la reabre y comprueba los datos (equivale a P1-P4).
- `widget_test.dart`: la pantalla abre sin errores y un título vacío no se registra.
- `editar_dialogo_test.dart`: flujo de edición desde la interfaz (abrir el diálogo, cambiar el título y guardar).

## Dónde se guarda la base

- **Android, iOS, Windows, Linux, macOS:** archivo `gestor_tareas.sqlite` en la carpeta de datos de la aplicación (`getApplicationSupportDirectory`). En Windows queda en `%APPDATA%\com.example\gestor_tareas_local\`. Se evita la carpeta "Documentos" (el valor por defecto de `drift_flutter`) porque en Windows suele estar sincronizada con OneDrive.
- **Web:** dentro del navegador (OPFS o IndexedDB), ligada al origen y al perfil.

## Entornos verificados

Según la aclaración de la práctica, basta con que la app funcione en tres entornos: web, móvil y escritorio. El código es el mismo para todos.

| Entorno | Cómo se probó | P1 | P2 | P3 | P4 | P5 | P6 |
|---------|---------------|----|----|----|----|----|----|
| Web | `flutter run -d web-server` (puerto 8081), Chromium automatizado con Playwright | OK | OK | OK | OK | OK | OK |
| Escritorio (Windows 11) | Compilación `--debug`, ventana cerrada y reabierta a mano | OK | OK | OK | OK | OK | n/a |
| Móvil (Android) | Emulador Pixel 10 Pro XL, APK `--debug`, `force-stop` y reapertura | OK | OK | OK | OK | OK | n/a |

Qué se hizo en cada prueba: P1 agregar 3 tareas y reiniciar; P2 marcar una como completada; P3 cambiar un título; P4 eliminar una tarea; P5 intentar agregar un título vacío. En cada plataforma, tras P1-P4 se cerró la app por completo y se reabrió: las dos tareas restantes, el estado y el título editado se conservaron, y la tarea eliminada no reapareció. P6 aplica solo a web: se recargó la página y luego se cerró la pestaña y se abrió otra en el mismo origen y perfil, con los datos intactos.

**Limitaciones:**
- No se probó en iOS, macOS ni Linux (requieren sus propios sistemas); el código es el mismo.
- Android solo en emulador y en modo debug, no en un teléfono físico.
- Web solo en Chromium. No se probó Firefox ni Safari, ni el modo privado.
- Con `flutter run` el servidor no envía los encabezados COOP/COEP, así que Drift usa `sharedIndexedDb` (más lento) en lugar de OPFS. Los datos persisten igual; para OPFS, ver [la documentación de Drift](https://drift.simonbinder.eu/platforms/web/).

## Problema real documentado

Ver [`docs/problema_onedrive.md`](docs/problema_onedrive.md).
