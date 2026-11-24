# Gestor de tareas local con SQLite

Aplicación Flutter que administra una lista de tareas guardadas en una base de datos SQLite local. No usa servidor, API REST ni MySQL: cada instalación conserva sus propios datos.

## Tecnología de persistencia

Se eligió **Drift** junto con **drift_flutter**:

- **Drift** es una capa sobre SQLite para Dart. Las tablas se declaran en Dart y `build_runner` genera las clases de datos y las consultas con tipos, lo que evita errores al escribir SQL a mano.
- **drift_flutter** abre la base en la ubicación adecuada de cada plataforma con una sola llamada (`driftDatabase`). En Android, iOS, Windows, Linux y macOS usa un archivo SQLite en el directorio de datos de la aplicación; en web usa SQLite compilado a WebAssembly y guarda el archivo en el almacenamiento del navegador (OPFS o IndexedDB).
- Drift permite consultas reactivas (`watch()`), así la interfaz se actualiza sola después de cada escritura sin volver a consultar desde `build()`.

Se descartaron `sqflite` (no soporta web ni escritorio sin paquetes adicionales) y `shared_preferences` (no es una base de datos y la consigna lo prohíbe).

## Diseño de la tabla

Tabla `tareas`:

| Columna      | Tipo SQLite | Restricciones                          |
|--------------|-------------|----------------------------------------|
| `id`         | INTEGER     | PRIMARY KEY AUTOINCREMENT              |
| `titulo`     | TEXT        | NOT NULL, longitud mínima de 1         |
| `completada` | INTEGER     | NOT NULL, DEFAULT 0 (0 = pendiente, 1 = completada) |

- Cada registro se identifica por `id`, que SQLite asigna automáticamente al insertar. Las operaciones de edición, cambio de estado y eliminación usan ese `id`.
- SQLite no tiene un tipo booleano propio; Drift guarda `completada` como 0 o 1 y lo convierte a `bool` en Dart.
- El título se valida antes de insertar o actualizar: se eliminan los espacios de los extremos y se rechaza si queda vacío.

## Organización prevista

```
lib/
  main.dart               arranque de la app
  models/tarea.dart       modelo usado por la interfaz
  data/                   base de datos Drift y repositorio con el CRUD
  screens/tareas_page.dart  pantalla; solo llama al repositorio
```

## Preparación

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
