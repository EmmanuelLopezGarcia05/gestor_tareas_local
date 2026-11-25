import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/validacion.dart';

void main() {
  group('validarTitulo', () {
    test('rechaza un título vacío', () {
      expect(validarTitulo(''), isNotNull);
    });

    test(
      'rechaza títulos con solo espacios, tabuladores o saltos de línea',
      () {
        expect(validarTitulo('   '), isNotNull);
        expect(validarTitulo('\t \n '), isNotNull);
      },
    );

    test(
      'acepta un título con texto aunque tenga espacios en los extremos',
      () {
        expect(validarTitulo('  Estudiar Drift  '), isNull);
      },
    );

    test(
      'respeta la longitud máxima sin contar los espacios de los extremos',
      () {
        expect(validarTitulo('a' * maxLongitudTitulo), isNull);
        expect(validarTitulo('  ${'a' * maxLongitudTitulo}  '), isNull);
        expect(validarTitulo('a' * (maxLongitudTitulo + 1)), isNotNull);
      },
    );
  });
}
