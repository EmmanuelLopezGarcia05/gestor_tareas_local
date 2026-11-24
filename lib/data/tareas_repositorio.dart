import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'base_datos.dart';
import 'validacion.dart';

/// Punto único de acceso a la tabla de tareas. La pantalla no usa Drift
/// directamente, solo estos métodos.
class TareasRepositorio {
  final BaseDatos _db;

  TareasRepositorio(this._db);

  /// Lista reactiva: emite de nuevo cada vez que cambia la tabla.
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  /// Consulta única de todas las tareas, ordenadas por id.
  Future<List<Tarea>> obtenerTareas() async {
    final consulta = _db.select(_db.tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    final filas = await consulta.get();
    return filas.map(_aModelo).toList();
  }

  /// Inserta una tarea pendiente y devuelve su id.
  /// Lanza [TituloInvalidoException] si el título no es válido.
  Future<int> agregar(String titulo) {
    final limpio = _validar(titulo);
    return _db.into(_db.tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  /// Cambia el título de la tarea con ese id. Devuelve false si no existe.
  Future<bool> actualizarTitulo(int id, String titulo) async {
    final limpio = _validar(titulo);
    final filas = await (_db.update(_db.tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(limpio)));
    return filas > 0;
  }

  /// Marca la tarea como completada o pendiente. Devuelve false si no existe.
  Future<bool> cambiarEstado(int id, bool completada) async {
    final filas = await (_db.update(_db.tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    return filas > 0;
  }

  /// Elimina la tarea con ese id. Devuelve false si no existía.
  Future<bool> eliminar(int id) async {
    final filas = await (_db.delete(
      _db.tareas,
    )..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }

  /// Libera la conexión con la base de datos.
  Future<void> cerrar() => _db.close();

  String _validar(String titulo) {
    final error = validarTitulo(titulo);
    if (error != null) {
      throw TituloInvalidoException(error);
    }
    return titulo.trim();
  }

  Tarea _aModelo(TareaRegistro fila) {
    return Tarea(id: fila.id, titulo: fila.titulo, completada: fila.completada);
  }
}
