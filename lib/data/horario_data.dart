import 'contexto_academico.dart';

/// Una clase del horario: hora de inicio y nombre de la materia.
///
/// OJO: `materia` se compara por texto exacto con el campo `materia` de los
/// avisos de Firestore, así que la ortografía debe coincidir con la nube.
class ClaseHorario {
  final String hora;
  final String materia;

  const ClaseHorario(this.hora, this.materia);
}

/// Un día de clase con su hora de salida y sus clases.
class DiaEscolar {
  /// Código corto; también es el id del documento en `avisos_semana/<codigo>`.
  final String codigo;
  final String nombre;
  final String salida;
  final List<ClaseHorario> clases;

  const DiaEscolar({
    required this.codigo,
    required this.nombre,
    required this.salida,
    required this.clases,
  });

  String get etiqueta => nombre.toUpperCase();
}

const List<DiaEscolar> _dias4b = [
  DiaEscolar(
    codigo: 'Lu',
    nombre: 'Lunes',
    salida: '12:15',
    clases: [
      ClaseHorario('07:05', 'Ingles'),
      ClaseHorario('08:35', 'Matematica'),
      ClaseHorario('10:05', 'Cs Sociales'),
      ClaseHorario('10:45', 'EI Tecno.'),
    ],
  ),
  DiaEscolar(
    codigo: 'Ma',
    nombre: 'Martes',
    salida: '12:55',
    clases: [
      ClaseHorario('07:05', 'Ingles'),
      ClaseHorario('07:45', 'Artes V.'),
      ClaseHorario('08:35', 'Lengua'),
      ClaseHorario('10:05', 'Cs Sociales'),
      ClaseHorario('11:25', 'Formacion Cristiana'),
    ],
  ),
  DiaEscolar(
    codigo: 'Mi',
    nombre: 'Miércoles',
    salida: '11:25',
    clases: [
      ClaseHorario('07:05', 'Lengua'),
      ClaseHorario('08:35', 'Biología'),
      ClaseHorario('10:05', 'Artes V.'),
    ],
  ),
  DiaEscolar(
    codigo: 'Ju',
    nombre: 'Jueves',
    salida: '11:25',
    clases: [
      ClaseHorario('07:05', 'FVT'),
      ClaseHorario('08:35', 'Matemática'),
      ClaseHorario('10:05', 'EI Tecno.'),
    ],
  ),
  DiaEscolar(
    codigo: 'Vi',
    nombre: 'Viernes',
    salida: '12:15',
    clases: [
      ClaseHorario('07:05', 'EI Tecno.'),
      ClaseHorario('08:35', 'Biologia'),
      ClaseHorario('10:05', 'ED. Fisica.'),
    ],
  ),
];

List<DiaEscolar> get horarioCuartoB => List.unmodifiable(_dias4b);

List<DiaEscolar> get diasEscolares {
  final c = ContextoAcademico.instance;
  return horarioParaCurso(c.curso, c.ciclo, c.catalogo);
}

List<DiaEscolar> horarioParaCurso(
  String curso,
  int ciclo,
  Map<String, dynamic>? catalogo,
) {
  if (curso == '4b' && ciclo == 2026) return _dias4b;
  final raw = catalogo?['horario'] as List? ?? [];
  return [
    for (final dynamic d in raw)
      DiaEscolar(
        codigo: d['codigo'] as String,
        nombre: d['nombre'] as String,
        salida: d['salida'] as String,
        clases: [
          for (final dynamic clase in d['clases'] as List)
            ClaseHorario(clase['hora'] as String, clase['materia'] as String),
        ],
      ),
  ];
}
