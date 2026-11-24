/// Longitud máxima permitida para el título de una tarea.
const int maxLongitudTitulo = 100;

/// Devuelve un mensaje de error si el título no es válido, o null si lo es.
/// Los espacios de los extremos no cuentan.
String? validarTitulo(String titulo) {
  final limpio = titulo.trim();
  if (limpio.isEmpty) {
    return 'El título no puede estar vacío ni tener solo espacios.';
  }
  if (limpio.length > maxLongitudTitulo) {
    return 'El título no puede tener más de $maxLongitudTitulo caracteres.';
  }
  return null;
}

/// Error lanzado por el repositorio cuando se intenta guardar un título no válido.
class TituloInvalidoException implements Exception {
  final String mensaje;

  const TituloInvalidoException(this.mensaje);

  @override
  String toString() => mensaje;
}
