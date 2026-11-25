// Tercera ejecución: se comprueba lo que se cambió antes del último cierre.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utilidades.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P2-P4: los cambios se conservan tras reiniciar', (tester) async {
    final repositorio = await abrirApp(tester);

    // P2: el estado completado se conservó.
    expect(
      enTarea('Tarea 1', find.textContaining('Completada')),
      findsOneWidget,
    );
    // P3: aparece el título nuevo y no el anterior.
    expect(find.widgetWithText(ListTile, 'Tarea 2 editada'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Tarea 2'), findsNothing);
    // P4: la tarea eliminada no reaparece.
    expect(find.widgetWithText(ListTile, 'Tarea 3'), findsNothing);

    final tareas = await repositorio.obtenerTareas();
    expect(tareas.map((t) => t.titulo), ['Tarea 1', 'Tarea 2 editada']);
    expect(tareas.map((t) => t.completada), [true, false]);

    await repositorio.cerrar();
  });
}
