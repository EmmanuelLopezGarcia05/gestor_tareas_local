import 'package:flutter/material.dart';

import 'data/base_datos.dart';
import 'data/tareas_repositorio.dart';
import 'screens/tareas_page.dart';

void main() {
  runApp(const GestorTareasApp());
}

/// Punto de entrada de la aplicación.
/// Si no recibe un repositorio, abre la base persistente de la plataforma.
class GestorTareasApp extends StatefulWidget {
  final TareasRepositorio? repositorio;

  const GestorTareasApp({super.key, this.repositorio});

  @override
  State<GestorTareasApp> createState() => _GestorTareasAppState();
}

class _GestorTareasAppState extends State<GestorTareasApp> {
  late final TareasRepositorio _repositorio;
  late final bool _esPropio;

  @override
  void initState() {
    super.initState();
    _esPropio = widget.repositorio == null;
    _repositorio = widget.repositorio ?? TareasRepositorio(BaseDatos());
  }

  @override
  void dispose() {
    // Solo se cierra la base que abrió este widget.
    if (_esPropio) {
      _repositorio.cerrar();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(repositorio: _repositorio),
    );
  }
}
