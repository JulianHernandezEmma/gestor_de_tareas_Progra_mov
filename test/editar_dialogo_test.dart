import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';
import 'package:gestor_tareas_local/main.dart';

/// Flujo de edición desde la interfaz (F3): abrir el diálogo, cambiar el
/// título y guardar.
///
/// Nota: el error "TextEditingController was used after being disposed" que
/// tenía el diálogo solo aparecía en el navegador, al reconstruirse el
/// diálogo durante su animación de salida. Esta prueba no lo reproduce (se
/// comprobó que también pasaba con el código anterior); ese arreglo se
/// verificó a mano en web. Aquí se cubre que el flujo completo funcione.
void main() {
  testWidgets('Editar el título desde el diálogo guarda el cambio',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = TareasRepository(db);
    addTearDown(db.close);

    await tester.runAsync(() => repo.agregar('Tarea original'));
    await tester.pumpWidget(GestorTareasApp(repositorio: repo));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Tarea original'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Editar título'), findsOneWidget);

    // El campo del diálogo es el último TextField (queda encima de la página).
    await tester.enterText(find.byType(TextField).last, 'Tarea editada');
    await tester.tap(find.text('Guardar'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Editar título'), findsNothing);
    expect(find.text('Tarea editada'), findsOneWidget);
    expect(find.text('Tarea original'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
