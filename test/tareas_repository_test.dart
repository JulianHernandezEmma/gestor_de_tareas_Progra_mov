import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';

void main() {
  group('validarTitulo (F1)', () {
    test('rechaza vacío y solo espacios', () {
      expect(() => TareasRepository.validarTitulo(''),
          throwsA(isA<TituloInvalidoException>()));
      expect(() => TareasRepository.validarTitulo('   \t '),
          throwsA(isA<TituloInvalidoException>()));
      expect(() => TareasRepository.validarTitulo(null),
          throwsA(isA<TituloInvalidoException>()));
    });

    test('recorta espacios y acepta un título normal', () {
      expect(TareasRepository.validarTitulo('  Estudiar SQLite  '),
          'Estudiar SQLite');
    });

    test('rechaza títulos de más de 120 caracteres', () {
      final largo = 'a' * (TareasRepository.largoMaximo + 1);
      expect(() => TareasRepository.validarTitulo(largo),
          throwsA(isA<TituloInvalidoException>()));
    });
  });

  group('CRUD sobre SQLite en memoria', () {
    late AppDatabase db;
    late TareasRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TareasRepository(db);
    });
    tearDown(() => db.close());

    test('agregar y consultar guarda título y estado pendiente', () async {
      await repo.agregar('  Comprar leche ');
      final tareas = await repo.observar().first;
      expect(tareas, hasLength(1));
      expect(tareas.single.titulo, 'Comprar leche');
      expect(tareas.single.completada, isFalse);
    });

    test('un título vacío no inserta ninguna fila', () async {
      await expectLater(
          repo.agregar('   '), throwsA(isA<TituloInvalidoException>()));
      expect(await repo.observar().first, isEmpty);
    });

    test('editar y marcar completada modifican solo esa tarea', () async {
      await repo.agregar('Uno');
      await repo.agregar('Dos');
      final antes = await repo.observar().first;
      final uno = antes.firstWhere((t) => t.titulo == 'Uno');

      await repo.editarTitulo(uno.id, 'Uno editado');
      await repo.marcarCompletada(uno.id, true);

      final despues = await repo.observar().first;
      final editada = despues.firstWhere((t) => t.id == uno.id);
      final otra = despues.firstWhere((t) => t.id != uno.id);
      expect(editada.titulo, 'Uno editado');
      expect(editada.completada, isTrue);
      expect(otra.titulo, 'Dos');
      expect(otra.completada, isFalse);
    });

    test('eliminar borra por id y restaurar la devuelve', () async {
      await repo.agregar('Borrar');
      final tarea = (await repo.observar().first).single;

      await repo.eliminar(tarea.id);
      expect(await repo.observar().first, isEmpty);

      await repo.restaurar(tarea);
      final vuelta = (await repo.observar().first).single;
      expect(vuelta.id, tarea.id);
      expect(vuelta.titulo, 'Borrar');
    });
  });
}
