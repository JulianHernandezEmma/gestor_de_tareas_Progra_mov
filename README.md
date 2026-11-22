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

## Entornos

Según la aclaración de la práctica, basta con que la app funcione en tres entornos: web, móvil y escritorio. El código es el mismo para todos.

| Entorno | Estado |
|---------|--------|
| Escritorio (Windows) | Compila (`flutter build windows`) y el ejecutable arranca; pruebas P1-P6 manuales: ver abajo |
| Web | Compila (`flutter build web`); pruebas manuales: ver abajo |
| Móvil (Android) | Previsto con el mismo código, **no probado** |

Resultados de P1-P6 manuales: _pendiente de registrar tras ejecutar la app._

## Problema real documentado

Ver [`docs/problema_onedrive.md`](docs/problema_onedrive.md).
