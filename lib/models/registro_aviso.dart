import 'actividad_semana.dart';

/// Documento independiente de un aviso. Conserva el contenido original al migrar.
class RegistroAviso {
  const RegistroAviso(this.id, this.datos);
  final String id;
  final Map<String, dynamic> datos;
  bool get archivado => datos['archivado'] == true;
  String get dia => datos['dia'].toString();
  Map<String, dynamic> get contenido =>
      Map<String, dynamic>.from(datos['datos'] as Map);
  String? get origen => datos['origen_documento'] == null
      ? null
      : '${datos['origen_documento']}|${datos['origen_indice']}';
  ActividadSemana get actividad => ActividadSemana.desdeAviso(dia, contenido);
}

List<RegistroAviso> registrosLegados(
  String documento,
  Map<String, dynamic> data,
) {
  final lista = data['evalucaciones'];
  if (lista is! List) return [];
  return [
    for (var i = 0; i < lista.length; i++)
      if (lista[i] is Map)
        RegistroAviso('legado_${documento}_$i', {
          'datos': Map<String, dynamic>.from(lista[i] as Map),
          'dia': data['dia'] ?? documento,
          'archivado': false,
          'origen_documento': documento,
          'origen_indice': i,
        }),
  ];
}

/// Incluye archivados para ocultar su original antiguo durante la transición.
List<RegistroAviso> combinarRegistros(
  List<RegistroAviso> antiguos,
  List<RegistroAviso> nuevos,
) {
  final trasladados = nuevos.map((r) => r.origen).whereType<String>().toSet();
  return [...antiguos.where((r) => !trasladados.contains(r.origen)), ...nuevos];
}
