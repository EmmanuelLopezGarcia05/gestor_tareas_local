import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
  BaseDatos([QueryExecutor? conexion]) : super(conexion ?? abrirConexion());

  @override
  int get schemaVersion => 1;

  /// Abre la base persistente llamada [nombre].
  ///
  /// En nativo crea el archivo [nombre].sqlite en el directorio de soporte de
  /// la app y no en Documentos, que el usuario puede borrar o sincronizar con
  /// la nube. En web usa SQLite compilado a WebAssembly; sqlite3.wasm y
  /// drift_worker.js están en web/.
  static QueryExecutor abrirConexion({String nombre = 'gestor_tareas'}) {
    return driftDatabase(
      name: nombre,
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
