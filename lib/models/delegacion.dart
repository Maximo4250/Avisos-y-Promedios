class Delegacion {
  const Delegacion(this.uid, this.curso, this.ciclo);
  final String uid, curso;
  final int ciclo;
  static Delegacion? desde(String uid, Map<String, dynamic>? d) {
    if (d == null ||
        d['activo'] != true ||
        d['curso'] is! String ||
        d['ciclo'] is! int) {
      return null;
    }
    final curso = d['curso'] as String, ciclo = d['ciclo'] as int;
    if (!RegExp(r'^[a-z0-9_-]{1,40}$').hasMatch(curso) ||
        ciclo < 2026 ||
        ciclo > 2100) {
      return null;
    }
    return Delegacion(uid, curso, ciclo);
  }

  String get etiqueta => curso == '4b' ? '4to B' : curso.toUpperCase();
}

class AvisoDelegado {
  const AvisoDelegado({
    required this.id,
    required this.materia,
    required this.tipo,
    required this.detalle,
    required this.dia,
    this.fecha,
  });
  final String id, materia, tipo, detalle, dia;
  final DateTime? fecha;
  static const dias = <String, String>{
    'Lu': 'Lunes',
    'Ma': 'Martes',
    'Mi': 'Miércoles',
    'Ju': 'Jueves',
    'Vi': 'Viernes',
    'Sa': 'Sábado',
    'Do': 'Domingo',
  };
  String? validar() {
    if (materia.trim().isEmpty || materia.length > 100) {
      return 'Elegí una materia.';
    }
    if (!['tarea', 'evaluacion'].contains(tipo)) {
      return 'Elegí el tipo de aviso.';
    }
    if (detalle.trim().length < 3 || detalle.trim().length > 1000) {
      return 'Escribí una descripción de 3 a 1000 caracteres.';
    }
    if (!dias.containsKey(dia)) return 'Elegí el día del aviso.';
    if (tipo == 'evaluacion' && fecha == null) {
      return 'Indicá la fecha de la evaluación.';
    }
    if (fecha != null && dias.keys.elementAt(fecha!.weekday - 1) != dia) {
      return 'El día debe coincidir con la fecha elegida.';
    }
    return null;
  }

  Map<String, dynamic> get datos => {
    'id': id,
    'materia': materia.trim(),
    'tipo': tipo,
    'detalle': detalle.trim(),
    'fecha': fecha == null
        ? ''
        : '${fecha!.year.toString().padLeft(4, '0')}-${fecha!.month.toString().padLeft(2, '0')}-${fecha!.day.toString().padLeft(2, '0')}',
  };
}
