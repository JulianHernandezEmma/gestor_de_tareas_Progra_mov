import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';

/// Simula "cerrar y volver a abrir la app": se cierra la conexión y se abre
/// otra sobre el mismo archivo SQLite (cubre P1 a P4 de la práctica).
void main() {
  late Directory dir;
  late File archivo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('gestor_tareas_test_');
    archivo = File('${dir.path}/tareas.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<TareasRepository> abrir(List<AppDatabase> abiertas) async {
    final db = AppDatabase(NativeDatabase(archivo));
    abiertas.add(db);
    return TareasRepository(db);
  }

  test('los datos sobreviven a cerrar y reabrir la base', () async {
    final abiertas = <AppDatabase>[];

    var repo = await abrir(abiertas);
    await repo.agregar('Tarea 1');
    await repo.agregar('Tarea 2');
    await repo.agregar('Tarea 3');
    final tareas = await repo.observar().first;
    final t1 = tareas.firstWhere((t) => t.titulo == 'Tarea 1');
    final t2 = tareas.firstWhere((t) => t.titulo == 'Tarea 2');
    final t3 = tareas.firstWhere((t) => t.titulo == 'Tarea 3');
    await repo.marcarCompletada(t1.id, true); // P2
    await repo.editarTitulo(t2.id, 'Tarea 2 editada'); // P3
    await repo.eliminar(t3.id); // P4
    await abiertas.last.close();

    repo = await abrir(abiertas); // "reinicio"
    final despues = await repo.observar().first;
    expect(despues, hasLength(2));
    expect(despues.firstWhere((t) => t.id == t1.id).completada, isTrue);
    expect(despues.firstWhere((t) => t.id == t2.id).titulo, 'Tarea 2 editada');
    expect(despues.any((t) => t.id == t3.id), isFalse);
    await abiertas.last.close();
  });
}
