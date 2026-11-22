import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Tabla `tareas`. Drift convierte los nombres a snake_case en SQL
/// (creadaEn -> creada_en) y el booleano se guarda como INTEGER 0/1.
@DataClassName('TareaFila')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1, max: 120)();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
  DateTimeColumn get creadaEn => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Recibe el ejecutor para poder usar una base en memoria en las pruebas.
  AppDatabase(super.e);

  /// Abre la base persistente (archivo en nativo, OPFS/IndexedDB en web).
  ///
  /// En nativo el archivo va en la carpeta de datos de la aplicación y no en
  /// "Documentos" (el valor por defecto de drift_flutter): en Windows,
  /// Documentos suele estar sincronizada con OneDrive, que puede bloquear el
  /// archivo SQLite y sus -wal/-shm mientras la app lo usa.
  factory AppDatabase.persistente() => AppDatabase(
        driftDatabase(
          name: 'gestor_tareas',
          native: DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
}
