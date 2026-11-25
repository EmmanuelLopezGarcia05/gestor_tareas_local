// Segunda ejecución: la app se abrió de nuevo después de cerrarse.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utilidades.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P1: siguen las tres tareas; P2-P4: marcar, editar y eliminar', (
    tester,
  ) async {
    final repositorio = await abrirApp(tester);

    // P1: las tres tareas sobrevivieron al cierre de la app.
    for (final titulo in ['Tarea 1', 'Tarea 2', 'Tarea 3']) {
      expect(find.widgetWithText(ListTile, titulo), findsOneWidget);
    }

    // P2: marcar como completada.
    await tester.tap(enTarea('Tarea 1', find.byType(Checkbox)));
    await esperar(
      tester,
      () => enTarea('Tarea 1', find.textContaining('Completada')),
    );

    // P3: cambiar el título.
    await tester.tap(enTarea('Tarea 2', find.byTooltip('Editar')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Tarea 2 editada',
    );
    await tester.tap(find.text('Guardar'));
    await esperar(
      tester,
      () => find.widgetWithText(ListTile, 'Tarea 2 editada'),
    );

    // P4: eliminar.
    await tester.tap(enTarea('Tarea 3', find.byTooltip('Eliminar')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await esperar(
      tester,
      () => find.widgetWithText(ListTile, 'Tarea 3'),
      findsNothing,
    );

    await repositorio.cerrar();
  });
}
