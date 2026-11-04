import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/registro_aviso.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';

void main() {
  final datos = {'materia': 'Lengua', 'tipo': 'tarea', 'detalle': 'Leer texto'};
  test('Traslado conserva identidad del progreso y no inventa fecha', () {
    final r = registrosLegados('Lu', {
      'evalucaciones': [datos],
    }).single;
    expect(r.actividad.id, ActividadSemana.desdeAviso('Lu', datos).id);
    expect(r.actividad.fecha, isNull);
    expect(r.id, 'legado_Lu_0');
  });
  test('Copia archivada oculta el original antiguo sin duplicarlo', () {
    final viejo = registrosLegados('Lu', {
      'evalucaciones': [datos],
    }).single;
    final nuevo = RegistroAviso(viejo.id, {...viejo.datos, 'archivado': true});
    final combinados = combinarRegistros([viejo], [nuevo]);
    expect(combinados.length, 1);
    expect(combinados.where((r) => !r.archivado), isEmpty);
  });
  test(
    'Traslado parcial conserva pendientes y mantiene avisos idénticos distintos',
    () {
      final viejos = registrosLegados('Lu', {
        'evalucaciones': [datos, datos],
      });
      expect(viejos[0].id, isNot(viejos[1].id));
      final copia = RegistroAviso(viejos.first.id, {
        ...viejos.first.datos,
        'curso': '4b',
      });
      expect(combinarRegistros(viejos, [copia]).length, 2);
      expect(
        combinarRegistros([], [copia]).single.actividad.id,
        viejos.first.actividad.id,
      );
    },
  );
}
