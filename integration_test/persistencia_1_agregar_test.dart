// Primera de tres ejecuciones separadas (ver README): cada una abre la app
// desde cero, así que entre ellas la app se cierra por completo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utilidades.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P1 y P5: agrega tres tareas y rechaza un título vacío', (
    tester,
  ) async {
    final repositorio = await abrirApp(tester);

    // Se parte de una base vacía por si quedaron datos de otra corrida.
    for (final tarea in await repositorio.obtenerTareas()) {
      await repositorio.eliminar(tarea.id);
    }
    await esperar(tester, () => find.text('Todavía no hay tareas guardadas'));

    for (final titulo in ['Tarea 1', 'Tarea 2', 'Tarea 3']) {
      // En escritorio el campo pierde el foco al pulsar el botón; se toca
      // de nuevo antes de escribir, como lo haría una persona.
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), titulo);
      await tester.tap(find.text('Agregar tarea'));
      await esperar(tester, () => find.widgetWithText(ListTile, titulo));
      // Como una persona, se espera a que el campo se limpie antes de seguir.
      await esperar(
        tester,
        () => find.widgetWithText(TextField, titulo),
        findsNothing,
      );
    }

    // P5: un título con solo espacios no se registra.
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pump();
    expect(
      find.text('El título no puede estar vacío ni tener solo espacios.'),
      findsOneWidget,
    );
    expect(await repositorio.obtenerTareas(), hasLength(3));

    await repositorio.cerrar();
  });
}
