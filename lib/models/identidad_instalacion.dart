import 'dart:convert';
import 'dart:math';

/// Identidad aleatoria de la instalación; no usa IMEI ni información personal.
class IdentidadInstalacion {
  final String id;
  final DateTime creada;
  const IdentidadInstalacion(this.id, this.creada);

  factory IdentidadInstalacion.nueva() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    return IdentidadInstalacion(id, DateTime.now().toUtc());
  }

  factory IdentidadInstalacion.desdeTexto(String texto) {
    final data = jsonDecode(texto) as Map<String, dynamic>;
    final id = data['id'] as String;
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ).hasMatch(id)) {
      throw const FormatException('Identificador local inválido');
    }
    return IdentidadInstalacion(id, DateTime.parse(data['creada'] as String));
  }

  String aTexto() => jsonEncode({'id': id, 'creada': creada.toIso8601String()});
}
