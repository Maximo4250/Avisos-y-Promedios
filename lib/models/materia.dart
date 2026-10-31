/// Materia con sus notas. Se guarda en SQLite (tablas `materias` y `notas`).
class Materia {
  int? id; // null hasta que se inserta en la base de datos
  String nombre;
  List<double> notas;
  bool esDoble;

  Materia({
    this.id,
    required this.nombre,
    this.esDoble = false,
    List<double>? notas,
  }) : notas = notas ?? [];

  double get promedio {
    if (notas.isEmpty) return 0.0;
    return notas.reduce((a, b) => a + b) / notas.length;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'es_doble': esDoble ? 1 : 0,
  };

  factory Materia.fromMap(Map<String, dynamic> map, {List<double>? notas}) {
    return Materia(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      esDoble: map['es_doble'] == 1,
      notas: notas,
    );
  }
}

/// Promedio general ponderado: las materias dobles pesan 2, el resto 1.
double calcularPromedioGeneral(List<Materia> materias) {
  double suma = 0.0;
  int pesoTotal = 0;

  for (final materia in materias) {
    final peso = materia.esDoble ? 2 : 1;
    suma += materia.promedio * peso;
    pesoTotal += peso;
  }

  return pesoTotal == 0 ? 0.0 : suma / pesoTotal;
}
