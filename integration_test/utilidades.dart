import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/base_datos.dart';
import 'package:gestor_tareas_local/data/tareas_repositorio.dart';
import 'package:gestor_tareas_local/main.dart';

/// Base persistente exclusiva de estas pruebas, para no tocar la de la app.
const nombreBasePrueba = 'gestor_tareas_prueba';

/// Abre la app real con la base persistente de prueba y espera a que cargue.
Future<TareasRepositorio> abrirApp(WidgetTester tester) async {
  final repositorio = TareasRepositorio(
    BaseDatos(BaseDatos.abrirConexion(nombre: nombreBasePrueba)),
  );
  await tester.pumpWidget(GestorTareasApp(repositorio: repositorio));
  await esperar(
    tester,
    () => find.byType(CircularProgressIndicator),
    findsNothing,
  );
  return repositorio;
}

/// Las escrituras ocurren en segundo plano, así que se espera a que la
/// pantalla refleje el cambio en lugar de suponer un tiempo fijo. Recibe una
/// función porque cada intento necesita un buscador nuevo: un Finder guarda el
/// resultado de su primera búsqueda.
Future<void> esperar(
  WidgetTester tester,
  Finder Function() buscar, [
  Matcher matcher = findsOneWidget,
]) async {
  for (var intento = 0; intento < 100; intento++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (matcher.matches(buscar(), {})) {
      return;
    }
  }
  expect(buscar(), matcher);
}

/// Busca un elemento dentro de la fila de la tarea con ese título.
Finder enTarea(String titulo, Finder elemento) {
  return find.descendant(
    of: find.widgetWithText(ListTile, titulo),
    matching: elemento,
  );
}
