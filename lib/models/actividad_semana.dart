import 'dart:convert';

/// Un aviso compartido, interpretado para planificar sin alterar su contenido.
class ActividadSemana {
  final String id;
  final String materia;
  final String descripcion;
  final String tipo;
  final DateTime? fecha;
  final String diaPublicado;

  const ActividadSemana({
    required this.id,
    required this.materia,
    required this.descripcion,
    required this.tipo,
    required this.fecha,
    required this.diaPublicado,
  });

  factory ActividadSemana.desdeAviso(
    String documento,
    Map<String, dynamic> aviso,
  ) {
    final materia = (aviso['materia'] ?? '').toString().trim();
    final descripcion = (aviso['detalle'] ?? aviso['descripcion'] ?? '')
        .toString()
        .trim();
    final tipoOriginal = (aviso['tipo'] ?? 'evaluacion')
        .toString()
        .toLowerCase()
        .trim();
    final tipo = const ['evaluación', 'examen', 'exámen'].contains(tipoOriginal)
        ? 'evaluacion'
        : const [
            'trabajo práctico',
            'trabajo practico',
            'tp',
            'trabajos',
          ].contains(tipoOriginal)
        ? 'trabajo'
        : tipoOriginal;
    DateTime? fecha;
    for (final campo in const [
      'fecha',
      'fechaEntrega',
      'fecha_entrega',
      'fechaEvaluacion',
      'fecha_evaluacion',
      'fechaLimite',
      'fecha_limite',
      'fechaVencimiento',
      'fecha_vencimiento',
    ]) {
      fecha = interpretarFecha(aviso[campo]);
      if (fecha != null) break;
    }
    // La posición en el array no identifica al aviso: reordenarlo no borra el progreso.
    // Cuando existe un id propio se respeta; sin id se usa su contenido estable.
    final idPropio = aviso['id'] ?? aviso['aviso_id'];
    final identidad = idPropio != null && idPropio.toString().isNotEmpty
        ? [documento, 'id', idPropio.toString(), fecha?.toIso8601String()]
        : [documento, tipo, materia, descripcion, fecha?.toIso8601String()];
    return ActividadSemana(
      id: jsonEncode(identidad),
      materia: materia.isEmpty ? 'Materia sin indicar' : materia,
      descripcion: descripcion.isEmpty ? 'Sin descripción' : descripcion,
      tipo: tipo,
      fecha: fecha,
      diaPublicado: documento,
    );
  }

  bool get esTrabajo => tipo == 'trabajo';
  bool get esTarea => tipo == 'tarea' || esTrabajo;
  bool get esEvaluacion => tipo == 'evaluacion';
  String get tipoTexto => esTrabajo
      ? 'Trabajo'
      : esTarea
      ? 'Tarea'
      : (esEvaluacion ? 'Evaluación' : 'Aviso');

  int? diasRestantes(DateTime ahora) {
    final f = fecha;
    if (f == null) return null;
    // UTC de fechas civiles evita errores de 23/25 horas por horario de verano.
    return DateTime.utc(
      f.year,
      f.month,
      f.day,
    ).difference(DateTime.utc(ahora.year, ahora.month, ahora.day)).inDays;
  }

  bool vencida(DateTime ahora) => (diasRestantes(ahora) ?? 0) < 0;
  String fechaTexto(DateTime ahora) {
    final f = fecha;
    if (f == null) return 'Sin fecha';
    final dias = diasRestantes(ahora)!;
    final fechaCorta =
        '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
    final plazo = dias < 0
        ? 'Vencida hace ${-dias} ${dias == -1 ? 'día' : 'días'}'
        : dias == 0
        ? 'Hoy'
        : dias == 1
        ? 'Mañana · falta 1 día'
        : 'Faltan $dias días';
    return '$fechaCorta · $plazo';
  }
}

/// Acepta fechas completas; no asigna año ni fecha a un día de la semana.
DateTime? interpretarFecha(Object? valor) {
  if (valor is DateTime) {
    final local = valor.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
  if (valor is! String) return null;
  final texto = valor.trim();
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|T|\s)').firstMatch(texto);
  final latina = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
  ).firstMatch(texto);
  if (iso == null && latina == null) return null;
  final year = int.parse(iso != null ? iso[1]! : latina![3]!);
  final month = int.parse(iso != null ? iso[2]! : latina![2]!);
  final day = int.parse(iso != null ? iso[3]! : latina![1]!);
  final fecha = DateTime(year, month, day);
  if (fecha.year != year || fecha.month != month || fecha.day != day) {
    return null;
  }
  if (iso != null && texto.length > 10) {
    final completa = DateTime.tryParse(texto);
    if (completa == null) return null;
    return interpretarFecha(completa);
  }
  return fecha;
}

List<ActividadSemana> ordenarActividades(
  Iterable<ActividadSemana> actividades,
) {
  final lista = actividades.toList();
  lista.sort((a, b) {
    if (a.fecha == null && b.fecha != null) return 1;
    if (a.fecha != null && b.fecha == null) return -1;
    final porFecha = a.fecha?.compareTo(b.fecha!) ?? 0;
    if (porFecha != 0) return porFecha;
    final porMateria = a.materia.compareTo(b.materia);
    return porMateria != 0 ? porMateria : a.id.compareTo(b.id);
  });
  return lista;
}
