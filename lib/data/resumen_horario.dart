import 'horario_data.dart';

String _claveMateria(String nombre) {
  var clave = nombre.toLowerCase();
  const acentos = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};
  acentos.forEach(
    (original, simple) => clave = clave.replaceAll(original, simple),
  );
  clave = clave.replaceAll(RegExp(r'[^a-z0-9]'), '');
  const alias = {
    'matematicas': 'matematica',
    'artesvisuales': 'artesv',
    'eitecnologia': 'eitecno',
    'formcristiana': 'formacioncristiana',
  };
  return alias[clave] ?? clave;
}

class CursadaMateria {
  final String dia;
  final String inicio;
  final String fin;
  final int minutos;
  const CursadaMateria(this.dia, this.inicio, this.fin, this.minutos);
}

/// Intervalos del horario; pueden incluir recreos entre clases.
List<CursadaMateria> cursadasDeMateria(String nombre) {
  final clave = _claveMateria(nombre);
  final resultado = <CursadaMateria>[];
  int enMinutos(String hora) {
    final partes = hora.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  for (final dia in diasEscolares) {
    for (var i = 0; i < dia.clases.length; i++) {
      final clase = dia.clases[i];
      if (_claveMateria(clase.materia) != clave) continue;
      final fin = i + 1 < dia.clases.length
          ? dia.clases[i + 1].hora
          : dia.salida;
      resultado.add(
        CursadaMateria(
          dia.nombre,
          clase.hora,
          fin,
          enMinutos(fin) - enMinutos(clase.hora),
        ),
      );
    }
  }
  return resultado;
}

String duracionSemanal(List<CursadaMateria> cursadas) {
  final minutos = cursadas.fold<int>(
    0,
    (total, clase) => total + clase.minutos,
  );
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '$resto min';
  return resto == 0 ? '$horas h' : '$horas h $resto min';
}

/// Usa las mismas equivalencias para horarios y avisos de la materia.
bool esMismaMateria(String nombre, String otroNombre) =>
    _claveMateria(nombre) == _claveMateria(otroNombre);
