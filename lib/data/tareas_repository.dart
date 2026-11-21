import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'app_database.dart';

/// Error de validación con un mensaje apto para mostrar al usuario.
class TituloInvalidoException implements Exception {
  const TituloInvalidoException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Único punto de acceso a SQLite para la interfaz.
class TareasRepository {
  TareasRepository(this._db);

  final AppDatabase _db;

  static const int largoMaximo = 120;

  /// Devuelve el título sin espacios sobrantes, o lanza [TituloInvalidoException].
  static String validarTitulo(String? titulo) {
    final limpio = (titulo ?? '').trim();
    if (limpio.isEmpty) {
      throw const TituloInvalidoException('El título no puede estar vacío.');
    }
    if (limpio.length > largoMaximo) {
      throw const TituloInvalidoException(
          'El título no puede pasar de $largoMaximo caracteres.');
    }
    return limpio;
  }

  /// Consulta reactiva: emite la lista completa cada vez que la tabla cambia.
  Stream<List<Tarea>> observar() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([
        (t) => OrderingTerm.desc(t.creadaEn),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  Future<void> agregar(String titulo) async {
    final limpio = validarTitulo(titulo);
    await _db.into(_db.tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  Tarea _aModelo(TareaFila fila) => Tarea(
        id: fila.id,
        titulo: fila.titulo,
        completada: fila.completada,
      );
}
