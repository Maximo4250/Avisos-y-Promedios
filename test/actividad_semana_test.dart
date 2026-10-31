import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';

ActividadSemana aviso(
  String descripcion, {
  Object? fecha,
  String tipo = 'evaluacion',
}) => ActividadSemana.desdeAviso('Lu', {
  'materia': 'Matemática',
  'detalle': descripcion,
  'tipo': tipo,
  'fecha': fecha,
});

void main() {
  test('las tareas conservan su fecha explícita para el calendario', () {
    final tarea = aviso('Ejercicios', fecha: '2026-10-25', tipo: 'tarea');
    expect(tarea.fecha, DateTime(2026, 10, 25));
    expect(tarea.vencida(DateTime(2026, 10, 26)), isTrue);
  });

  test('no inventa fecha a partir del día del documento', () {
    expect(aviso('Ejercicio').fecha, isNull);
    expect(aviso('Ejercicio').fechaTexto(DateTime(2026, 10, 22)), 'Sin fecha');
    expect(interpretarFecha('Lunes'), isNull);
    expect(interpretarFecha('22/10'), isNull);
  });
  test('acepta fechas completas y rechaza fechas imposibles', () {
    expect(interpretarFecha('2026-10-25'), DateTime(2026, 10, 25));
    expect(interpretarFecha('25/10/2026'), DateTime(2026, 10, 25));
    expect(interpretarFecha('25-10-2026'), DateTime(2026, 10, 25));
    expect(interpretarFecha('31/02/2026'), isNull);
    expect(interpretarFecha('2026-02-31'), isNull);
    expect(interpretarFecha('2026-10-25Tbasura'), isNull);
  });
  test('usa el siguiente campo válido cuando fecha está vacío', () {
    final a = ActividadSemana.desdeAviso('Ma', {
      'fecha': '',
      'fecha_entrega': '25/10/2026',
      'descripcion': 'Leer',
    });
    expect(a.fecha, DateTime(2026, 10, 25));
    expect(a.descripcion, 'Leer');
  });
  test('hoy, mañana, días restantes y vencidos usan fechas civiles', () {
    final ahora = DateTime(2026, 10, 22, 23, 59);
    expect(aviso('Hoy', fecha: '2026-10-22').diasRestantes(ahora), 0);
    expect(aviso('Mañana', fecha: '2026-10-23').diasRestantes(ahora), 1);
    expect(aviso('Ayer', fecha: '2026-10-21').vencida(ahora), isTrue);
    expect(
      aviso('Ayer', fecha: '2026-10-21').fechaTexto(ahora),
      contains('Vencida hace 1 día'),
    );
  });
  test('prioriza fechas incluyendo vencidas y deja sin fecha al final', () {
    final lista = ordenarActividades([
      aviso('Sin fecha'),
      aviso('Nueva', fecha: '2026-10-25'),
      aviso('Vencida', fecha: '2026-10-20'),
      aviso('Hoy', fecha: '2026-10-22'),
      aviso('Otra sin fecha'),
    ]);
    expect(lista.map((a) => a.descripcion).take(3), [
      'Vencida',
      'Hoy',
      'Nueva',
    ]);
    expect(lista.skip(3).every((a) => a.fecha == null), isTrue);
  });
  test('el id es estable ante reordenamiento de campos y distingue avisos', () {
    final a = aviso('Resolver guía', fecha: '22/10/2026');
    final b = ActividadSemana.desdeAviso('Lu', {
      'fecha': '2026-10-22',
      'tipo': 'evaluacion',
      'detalle': 'Resolver guía',
      'materia': 'Matemática',
    });
    expect(a.id, b.id);
    expect(a.id, isNot(aviso('Otra guía', fecha: '22/10/2026').id));
    expect(a.id, isNot(aviso('Resolver guía', fecha: '23/10/2026').id));
  });
  test('respeta id propio al editar una descripción', () {
    final a = ActividadSemana.desdeAviso('Lu', {
      'id': 'a1',
      'detalle': 'Original',
    });
    final b = ActividadSemana.desdeAviso('Lu', {
      'id': 'a1',
      'detalle': 'Corregida',
    });
    expect(a.id, b.id);
  });
  test('identifica evaluaciones sin cambiar el aviso original', () {
    final original = <String, dynamic>{
      'tipo': 'evaluación',
      'detalle': 'Prueba',
    };
    final a = ActividadSemana.desdeAviso('Mi', original);
    expect(a.esEvaluacion, isTrue);
    expect(original['tipo'], 'evaluación');
  });
}
