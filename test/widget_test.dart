import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';
import 'package:gestor_tareas_local/main.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async {
    // Cierra los streams de Drift para que no queden temporizadores pendientes.
    await db.close();
  });

  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    await tester.pumpWidget(GestorTareasApp(repositorio: TareasRepository(db)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // Desmonta la app antes de cerrar la base.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('Un título vacío no se registra y muestra un aviso',
      (tester) async {
    await tester.pumpWidget(GestorTareasApp(repositorio: TareasRepository(db)));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('El título no puede estar vacío.'), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
