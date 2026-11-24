import 'dart:async';

import 'package:flutter/material.dart';

import '../data/tareas_repositorio.dart';
import '../data/validacion.dart';
import '../models/tarea.dart';

// Pantalla principal. Lee y escribe las tareas solo a través del repositorio.
class TareasPage extends StatefulWidget {
  final TareasRepositorio repositorio;

  const TareasPage({super.key, required this.repositorio});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  List<Tarea> _tareas = [];
  StreamSubscription<List<Tarea>>? _suscripcion;
  String? _errorTitulo;

  @override
  void initState() {
    super.initState();
    // La consulta se hace aquí y no en build(): el stream avisa cada cambio.
    _suscripcion = widget.repositorio.observarTareas().listen(
      (tareas) => setState(() => _tareas = tareas),
      onError: (Object error) =>
          _mostrarMensaje('No se pudieron cargar las tareas guardadas.'),
    );
  }

  Future<void> _agregarTarea() async {
    final error = validarTitulo(_tituloController.text);
    setState(() => _errorTitulo = error);
    if (error != null) {
      return;
    }
    final guardada = await _ejecutar(
      () => widget.repositorio.agregar(_tituloController.text),
      'No se pudo guardar la tarea.',
    );
    if (guardada) {
      _tituloController.clear();
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await _ejecutar(
      () => widget.repositorio.cambiarEstado(tarea.id, completada),
      'No se pudo actualizar el estado de la tarea.',
    );
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (context) => _DialogoEditarTitulo(tituloActual: tarea.titulo),
    );
    if (nuevoTitulo == null || nuevoTitulo.trim() == tarea.titulo) {
      return;
    }
    await _ejecutar(
      () => widget.repositorio.actualizarTitulo(tarea.id, nuevoTitulo),
      'No se pudo cambiar el título.',
    );
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text(
          '¿Eliminar "${tarea.titulo}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) {
      return;
    }
    await _ejecutar(
      () => widget.repositorio.eliminar(tarea.id),
      'No se pudo eliminar la tarea.',
    );
  }

  /// Ejecuta una operación del repositorio y traduce los errores a mensajes
  /// comprensibles. Devuelve true si se completó. La lista se actualiza sola
  /// mediante el stream.
  Future<bool> _ejecutar(
    Future<Object?> Function() operacion,
    String mensajeError,
  ) async {
    try {
      final resultado = await operacion();
      if (resultado == false) {
        _mostrarMensaje('La tarea ya no existe.');
        return false;
      }
      return true;
    } on TituloInvalidoException catch (e) {
      setState(() => _errorTitulo = e.mensaje);
    } catch (error) {
      debugPrint('Error de almacenamiento: $error');
      _mostrarMensaje('$mensajeError Intenta de nuevo.');
    }
    return false;
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              maxLength: maxLongitudTitulo,
              onChanged: (_) {
                if (_errorTitulo != null) {
                  setState(() => _errorTitulo = null);
                }
              },
              onSubmitted: (_) => _agregarTarea(),
              decoration: InputDecoration(
                labelText: 'Nueva tarea',
                border: const OutlineInputBorder(),
                errorText: _errorTitulo,
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _tareas.isEmpty
                  ? const Center(child: Text('Todavía no hay tareas guardadas'))
                  : ListView.builder(
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: tarea.completada,
                              onChanged: (valor) {
                                if (valor != null) {
                                  _alternarCompletada(tarea, valor);
                                }
                              },
                            ),
                            title: Text(
                              tarea.titulo,
                              style: tarea.completada
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                    )
                                  : null,
                            ),
                            subtitle: Text(
                              'ID: ${tarea.id} - '
                              '${tarea.completada ? 'Completada' : 'Pendiente'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editarTarea(tarea),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _eliminarTarea(tarea),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para cambiar el título. Valida antes de cerrar y devuelve el texto.
class _DialogoEditarTitulo extends StatefulWidget {
  final String tituloActual;

  const _DialogoEditarTitulo({required this.tituloActual});

  @override
  State<_DialogoEditarTitulo> createState() => _DialogoEditarTituloState();
}

class _DialogoEditarTituloState extends State<_DialogoEditarTitulo> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.tituloActual,
  );
  String? _error;

  void _guardar() {
    final error = validarTitulo(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar título'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: maxLongitudTitulo,
        onSubmitted: (_) => _guardar(),
        decoration: InputDecoration(
          labelText: 'Título',
          border: const OutlineInputBorder(),
          errorText: _error,
          errorMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
