import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'base_datos.dart';

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

  /// Inserta una tarea pendiente y devuelve su id.
  Future<int> agregar(String titulo) {
    return _db
        .into(_db.tareas)
        .insert(TareasCompanion.insert(titulo: titulo.trim()));
  }

  /// Libera la conexión con la base de datos.
  Future<void> cerrar() => _db.close();

  Tarea _aModelo(TareaRegistro fila) {
    return Tarea(id: fila.id, titulo: fila.titulo, completada: fila.completada);
  }
}
