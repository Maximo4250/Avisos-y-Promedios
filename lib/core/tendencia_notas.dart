/// Resume la dirección de hasta las cinco últimas notas, en orden de carga.
/// Usa una recta de tendencia para considerar todos los puntos recientes.
String tendenciaNotas(List<double> notas) {
  if (notas.length < 2) return 'Faltan notas para ver la tendencia';

  final recientes = notas.length > 5 ? notas.sublist(notas.length - 5) : notas;
  final n = recientes.length;
  final mediaX = (n - 1) / 2;
  final mediaY = recientes.reduce((a, b) => a + b) / n;
  double numerador = 0;
  double denominador = 0;
  for (var i = 0; i < n; i++) {
    final distanciaX = i - mediaX;
    numerador += distanciaX * (recientes[i] - mediaY);
    denominador += distanciaX * distanciaX;
  }
  final cambioEstimado = (numerador / denominador) * (n - 1);
  // Cambios menores a un cuarto de punto se consideran estables.
  if (cambioEstimado >= 0.25) return 'Notas en alza';
  if (cambioEstimado <= -0.25) return 'Notas en baja';
  return 'Notas estables';
}
