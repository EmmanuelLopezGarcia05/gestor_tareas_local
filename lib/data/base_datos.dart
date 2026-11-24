import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'base_datos.g.dart';

/// Tabla de tareas. El id lo asigna SQLite al insertar.
@DataClassName('TareaRegistro')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1)();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class BaseDatos extends _$BaseDatos {
  /// Sin argumento abre la base persistente de la plataforma actual.
  /// Las pruebas pueden pasar otra conexión, por ejemplo una en memoria.
  BaseDatos([QueryExecutor? conexion]) : super(conexion ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrirConexion() {
    // En nativo crea gestor_tareas.sqlite en el directorio de documentos de la
    // app. En web usa SQLite en WebAssembly; los dos archivos están en web/.
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
