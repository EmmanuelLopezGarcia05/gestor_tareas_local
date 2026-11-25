import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/base_datos.dart';
import 'package:gestor_tareas_local/data/tareas_repositorio.dart';
import 'package:gestor_tareas_local/data/validacion.dart';

void main() {
  group('CRUD con SQLite en memoria', () {
    late TareasRepositorio repositorio;

    setUp(() {
      repositorio = TareasRepositorio(BaseDatos(NativeDatabase.memory()));
    });

    tearDown(() => repositorio.cerrar());

    test(
      'agregar guarda el título sin espacios extra y como pendiente',
      () async {
        final id = await repositorio.agregar('  Estudiar Drift  ');

        final tareas = await repositorio.obtenerTareas();
        expect(tareas, hasLength(1));
        expect(tareas.single.id, id);
        expect(tareas.single.titulo, 'Estudiar Drift');
        expect(tareas.single.completada, isFalse);
      },
    );

    test('agregar rechaza títulos vacíos o con solo espacios', () async {
      await expectLater(
        repositorio.agregar(''),
        throwsA(isA<TituloInvalidoException>()),
      );
      await expectLater(
        repositorio.agregar('    '),
        throwsA(isA<TituloInvalidoException>()),
      );
      expect(await repositorio.obtenerTareas(), isEmpty);
    });

    test('cada tarea recibe un id distinto y se listan en orden', () async {
      final id1 = await repositorio.agregar('Primera');
      final id2 = await repositorio.agregar('Segunda');
      final id3 = await repositorio.agregar('Tercera');

      expect({id1, id2, id3}, hasLength(3));
      final titulos = (await repositorio.obtenerTareas()).map((t) => t.titulo);
      expect(titulos, ['Primera', 'Segunda', 'Tercera']);
    });

    test('actualizarTitulo cambia solo la tarea indicada', () async {
      final id = await repositorio.agregar('Configurar web');
      await repositorio.agregar('Otra tarea');

      expect(
        await repositorio.actualizarTitulo(id, ' Configurar worker '),
        isTrue,
      );

      final titulos = (await repositorio.obtenerTareas()).map((t) => t.titulo);
      expect(titulos, ['Configurar worker', 'Otra tarea']);
    });

    test(
      'actualizarTitulo rechaza un título vacío y conserva el anterior',
      () async {
        final id = await repositorio.agregar('Título original');

        await expectLater(
          repositorio.actualizarTitulo(id, '   '),
          throwsA(isA<TituloInvalidoException>()),
        );
        expect(
          (await repositorio.obtenerTareas()).single.titulo,
          'Título original',
        );
      },
    );

    test(
      'cambiarEstado marca como completada y de nuevo como pendiente',
      () async {
        final id = await repositorio.agregar('Redactar reporte');

        await repositorio.cambiarEstado(id, true);
        expect((await repositorio.obtenerTareas()).single.completada, isTrue);

        await repositorio.cambiarEstado(id, false);
        expect((await repositorio.obtenerTareas()).single.completada, isFalse);
      },
    );

    test('eliminar borra por id y no afecta a las demás', () async {
      final id1 = await repositorio.agregar('Se queda');
      final id2 = await repositorio.agregar('Se elimina');

      expect(await repositorio.eliminar(id2), isTrue);
      expect(await repositorio.eliminar(id2), isFalse);

      final tareas = await repositorio.obtenerTareas();
      expect(tareas.map((t) => t.id), [id1]);
    });

    test('las operaciones sobre un id inexistente devuelven false', () async {
      expect(await repositorio.actualizarTitulo(99, 'Nada'), isFalse);
      expect(await repositorio.cambiarEstado(99, true), isFalse);
      expect(await repositorio.eliminar(99), isFalse);
    });

    test(
      'observarTareas emite la lista actualizada después de escribir',
      () async {
        final titulos = repositorio.observarTareas().map(
          (tareas) => tareas.map((t) => t.titulo).toList(),
        );
        final espera = expectLater(titulos, emitsThrough(['A', 'B']));

        await repositorio.agregar('A');
        await repositorio.agregar('B');
        await espera;
      },
    );
  });

  test('los datos siguen ahí al cerrar y volver a abrir la base', () async {
    final carpeta = await Directory.systemTemp.createTemp('gestor_tareas_');
    addTearDown(() => carpeta.delete(recursive: true));
    final archivo = File(
      '${carpeta.path}${Platform.pathSeparator}tareas.sqlite',
    );

    // Primera "ejecución": se escribe y se cierra la base.
    var repositorio = TareasRepositorio(BaseDatos(NativeDatabase(archivo)));
    final id1 = await repositorio.agregar('Completada');
    final id2 = await repositorio.agregar('Título viejo');
    final id3 = await repositorio.agregar('Eliminada');
    await repositorio.cambiarEstado(id1, true);
    await repositorio.actualizarTitulo(id2, 'Título nuevo');
    await repositorio.eliminar(id3);
    await repositorio.cerrar();

    // Segunda "ejecución": se abre el mismo archivo desde cero.
    repositorio = TareasRepositorio(BaseDatos(NativeDatabase(archivo)));
    final tareas = await repositorio.obtenerTareas();
    await repositorio.cerrar();

    expect(tareas.map((t) => t.id), [id1, id2]);
    expect(tareas[0].completada, isTrue);
    expect(tareas[1].titulo, 'Título nuevo');
    expect(tareas[1].completada, isFalse);
  });
}
