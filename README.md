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
