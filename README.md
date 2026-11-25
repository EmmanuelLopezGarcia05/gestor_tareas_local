# Gestor de tareas local con SQLite

Aplicación Flutter que administra una lista de tareas guardadas en una base de datos SQLite local. Permite agregar, listar, editar el título, marcar como completada o pendiente y eliminar tareas. No usa servidor, API REST, HTTP ni MySQL: cada instalación (o cada navegador, en web) conserva sus propios datos.

## Tecnología de persistencia

Se eligió **Drift** junto con **drift_flutter**:

- **Drift** es una capa sobre SQLite para Dart. La tabla se declara en Dart y `build_runner` genera las clases de datos y las consultas con tipos, lo que evita errores al escribir SQL a mano.
- **drift_flutter** abre la base con una sola llamada (`driftDatabase`) en las seis plataformas. En Android, iOS, Windows, Linux y macOS usa un archivo SQLite; en web usa SQLite compilado a WebAssembly y guarda el archivo en el almacenamiento del navegador (OPFS o IndexedDB).
- Drift permite consultas reactivas (`watch()`): la pantalla se suscribe una vez y recibe la lista actualizada después de cada escritura, sin consultar la base dentro de `build()`.

Se descartaron `sqflite` (oficialmente solo Android, iOS y macOS; no web, Windows ni Linux) y `shared_preferences` (no es una base de datos y la consigna lo prohíbe).

Versiones usadas: Flutter 3.47.5, Dart 3.13.4, drift 2.35.4, drift_flutter 0.3.1, drift_dev 2.35.3, sqlite3 3.5.2. Las versiones exactas quedan fijadas en `pubspec.lock`.

## Diseño de la tabla

Tabla `tareas`:

| Columna      | Tipo SQLite | Restricciones                                        |
|--------------|-------------|------------------------------------------------------|
| `id`         | INTEGER     | PRIMARY KEY AUTOINCREMENT                            |
| `titulo`     | TEXT        | NOT NULL; Drift exige al menos 1 carácter            |
| `completada` | INTEGER     | NOT NULL, DEFAULT 0, CHECK (completada IN (0, 1))    |

- Cada registro se identifica por `id`, que SQLite asigna al insertar y no reutiliza. Editar, cambiar el estado y eliminar se hacen por `id`.
- SQLite no tiene tipo booleano; `completada` se guarda como 0 o 1 y Drift lo convierte a `bool`.
- Antes de insertar o actualizar, el título se valida: se quitan los espacios de los extremos y se rechaza si queda vacío o si pasa de 100 caracteres.

## Organización del código

```
lib/
  main.dart                  abre la base, la entrega a la pantalla y la cierra en dispose
  models/tarea.dart          modelo que usa la interfaz
  data/base_datos.dart       tabla Tareas y apertura de la base (Drift)
  data/base_datos.g.dart     código generado por build_runner
  data/tareas_repositorio.dart  operaciones CRUD; único acceso a la tabla
  data/validacion.dart       validación del título
  screens/tareas_page.dart   pantalla; solo llama al repositorio
web/
  sqlite3.wasm               SQLite compilado a WebAssembly
  drift_worker.js            worker de Drift para web
test/                        pruebas automatizadas (flutter test)
integration_test/            pruebas de persistencia en un dispositivo real
```

Manejo de errores: las operaciones de escritura atrapan los errores de almacenamiento y muestran un mensaje comprensible; si la base no termina de abrirse en 10 segundos, la pantalla lo avisa en lugar de quedarse esperando.

## Dónde se guardan los datos

| Plataforma | Ubicación |
|------------|-----------|
| Windows    | `%APPDATA%\com.example\gestor_tareas_local\gestor_tareas.sqlite` |
| Android    | carpeta `files` privada de la app (`getApplicationSupportDirectory`) |
| iOS        | `Library/Application Support` dentro del contenedor de la app |
| macOS      | `Application Support` dentro del contenedor de la app |
| Linux      | `~/.local/share/<id de la aplicación>/` |
| Web        | almacenamiento del navegador para el origen (OPFS o IndexedDB), en `drift_db/gestor_tareas` |

En nativo se usa el directorio de soporte de la app (`getApplicationSupportDirectory`) y no Documentos, porque Documentos es del usuario y en Windows suele estar sincronizado con OneDrive. Desinstalar la app borra sus datos en Android e iOS. En web, los datos se pierden si se borran los datos del sitio o si se usa una ventana privada.

## Requisitos

- Flutter 3.47 o compatible (`flutter doctor -v`).
- Web: Google Chrome.
- Windows: Visual Studio 2022 (o Build Tools) con la carga "Desarrollo para el escritorio con C++".
- Android, iOS, Linux y macOS: las herramientas de cada plataforma (iOS y macOS solo desde una Mac).

## Ejecución

```bash
flutter pub get
flutter analyze
flutter test
```

El archivo `lib/data/base_datos.g.dart` ya está en el repositorio. Solo hay que regenerarlo si se modifica la tabla:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Escritorio (Windows)

```bash
flutter run -d windows
```

### Web

Los archivos `web/sqlite3.wasm` y `web/drift_worker.js` se tomaron del release [drift-2.35.4](https://github.com/simolus3/drift/releases/tag/drift-2.35.4), la misma versión de `drift` del proyecto. Si se actualiza `drift`, hay que descargar los dos archivos del release correspondiente.

Para comprobar la persistencia conviene usar siempre el mismo puerto, porque el navegador guarda los datos por origen (protocolo, host y puerto):

```bash
flutter run -d web-server --web-port 8080 --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
```

y abrir `http://localhost:8080` en Chrome. Con esos dos encabezados el navegador permite que Drift use OPFS, que es la opción más rápida. Sin ellos (por ejemplo con `flutter run -d chrome`) Drift usa IndexedDB, que también es persistente. `flutter run -d chrome` abre Chrome con un perfil temporal y un puerto distinto en cada ejecución, así que los datos no se conservan entre una ejecución y otra.

## Pruebas automatizadas

`flutter test` ejecuta:

- `test/widget_test.dart`: la prueba base; la pantalla inicial se muestra sin errores.
- `test/validacion_test.dart`: títulos vacíos, con solo espacios o tabuladores, con espacios en los extremos y la longitud máxima.
- `test/tareas_repositorio_test.dart`: alta, consulta, edición, cambio de estado y eliminación contra SQLite en memoria (`NativeDatabase.memory()`); rechazo de títulos vacíos; operaciones sobre un id inexistente; el stream de `watch()`; y persistencia real con un archivo que se cierra y se vuelve a abrir.
- `test/tareas_page_test.dart`: la pantalla completa con una base en memoria: agregar, mensaje de error con título vacío, marcar, editar y eliminar.

`integration_test/` repite P1 a P5 sobre la app real y una base persistente separada (`gestor_tareas_prueba`). Son tres archivos que se ejecutan por separado y en orden; cada ejecución abre la app desde cero, así que entre una y otra la app se cierra por completo:

```bash
flutter test integration_test/persistencia_1_agregar_test.dart -d windows
flutter test integration_test/persistencia_2_modificar_test.dart -d windows
flutter test integration_test/persistencia_3_verificar_test.dart -d windows
```

## Pruebas de funcionamiento

Resultados de las pruebas P1 a P6 de la consigna:

| ID | Acción | Web (Chrome 157) | Windows 11 (escritorio) |
|----|--------|------------------|-------------------------|
| P1 | Agregar tres tareas, cerrar por completo y abrir | Siguen las tres | Siguen las tres |
| P2 | Marcar una como completada y reiniciar | Se conserva el estado | Se conserva el estado |
| P3 | Cambiar el título y reiniciar | Aparece el título nuevo | Aparece el título nuevo |
| P4 | Eliminar una tarea y reiniciar | No reaparece | No reaparece |
| P5 | Intentar agregar un título vacío o con solo espacios | No se registra y se muestra el error | No se registra y se muestra el error |
| P6 | Recargar y cerrar/abrir la pestaña (mismo origen y perfil) | Los datos permanecen | No aplica |

- **Web:** compilación release servida en `localhost` con los encabezados COOP/COEP y abierta en Chrome 157. En web, "reiniciar" significa recargar la página o cerrar la pestaña y abrir otra en el mismo origen. Drift usó OPFS (`opfsLocks`), y el archivo `drift_db/gestor_tareas/database` aparece en el almacenamiento del sitio.
- **Windows:** se ejecutaron las tres pruebas de `integration_test/` en orden, cada una en un proceso nuevo de la app. Después se leyó el archivo `gestor_tareas_prueba.sqlite` por fuera de la app: contenía "Tarea 1" completada y "Tarea 2 editada" pendiente, sin la tarea eliminada. También se abrió el ejecutable release (`build\windows\x64\runner\Release\gestor_tareas_local.exe`), que creó `gestor_tareas.sqlite` en `%APPDATA%\com.example\gestor_tareas_local\`.

## Plataformas

| Plataforma | Estado |
|------------|--------|
| Web (Chrome) | Verificada |
| Windows 11 | Verificada |
| Android | Prevista, no verificada: no hay Android SDK en el equipo de desarrollo |
| iOS y macOS | Previstas, no verificadas: se compilan solo desde una Mac con Xcode |
| Linux | Prevista, no verificada: se compila desde Linux |

El código no tiene partes específicas de una plataforma: `drift_flutter` y `path_provider` dan soporte a las seis, y las carpetas de plataforma son las que genera `flutter create`.

### Limitaciones

- No hay sincronización entre dispositivos: cada instalación y cada navegador tienen su propia base.
- En web, los datos dependen del navegador: se pierden al borrar los datos del sitio, y en una ventana privada se descartan al cerrarla. Además, cambiar de puerto o de dominio equivale a otro origen y a otra base.
- Algunos navegadores embebidos en otras aplicaciones bloquean los workers que necesita Drift. En ese caso la base no se abre y la app muestra un aviso en lugar de quedarse esperando.
