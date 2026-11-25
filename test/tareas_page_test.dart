import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/base_datos.dart';
import 'package:gestor_tareas_local/data/tareas_repositorio.dart';
import 'package:gestor_tareas_local/main.dart';

/// Abre la app con una base en memoria para no tocar el almacenamiento real.
Future<TareasRepositorio> abrirApp(WidgetTester tester) async {
  final repositorio = TareasRepositorio(
    BaseDatos(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    ),
  );
  addTearDown(repositorio.cerrar);
  await tester.pumpWidget(GestorTareasApp(repositorio: repositorio));
  await tester.pumpAndSettle();
  return repositorio;
}

void main() {
  testWidgets('agregar desde la pantalla guarda la tarea y limpia el campo', (
    tester,
  ) async {
    await abrirApp(tester);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Estudiar Drift');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    // El campo quedó vacío, así que el único texto es el de la lista.
    expect(find.text('Estudiar Drift'), findsOneWidget);
    expect(find.text('ID: 1 - Pendiente'), findsOneWidget);
  });

  testWidgets('un título con solo espacios muestra el error y no se guarda', (
    tester,
  ) async {
    await abrirApp(tester);

    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(
      find.text('El título no puede estar vacío ni tener solo espacios.'),
      findsOneWidget,
    );
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
  });

  testWidgets('marcar, editar y eliminar actualizan la lista', (tester) async {
    final repositorio = await abrirApp(tester);
    await repositorio.agregar('Configurar web');
    await tester.pumpAndSettle();

    // Cambiar el estado.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('ID: 1 - Completada'), findsOneWidget);

    // Editar el título desde el diálogo.
    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Configurar worker',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Configurar worker'), findsOneWidget);
    expect(find.text('Configurar web'), findsNothing);

    // Eliminar con confirmación.
    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Configurar worker'), findsNothing);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
  });
}
