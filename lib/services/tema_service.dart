import 'package:flutter/material.dart';
import 'db_helper.dart';

class TemaService extends ChangeNotifier {
  TemaService({
    Future<String?> Function()? leer,
    Future<void> Function(String)? guardar,
  }) : _leer =
           leer ??
           (() => DatabaseHelper.instance.leerPreferencia('tema_color_v1')),
       _guardar =
           guardar ??
           ((v) =>
               DatabaseHelper.instance.guardarPreferencia('tema_color_v1', v));
  static final instance = TemaService();
  static const colores = <String, Color>{
    'Celeste': Color(0xFF81D4FA),
    'Verde': Color(0xFF81C784),
    'Salmón': Color(0xFFFFAB91),
    'Azul': Color(0xFF1565C0),
    'Violeta': Color(0xFF7E57C2),
    'Dorado / ámbar': Colors.amber,
    'Negro': Colors.black,
  };
  final Future<String?> Function() _leer;
  final Future<void> Function(String) _guardar;
  String elegido = 'Dorado / ámbar';
  Color get color => colores[elegido]!;
  Future<void> _cola = Future.value();
  Future<void> cargar() async {
    try {
      final value = await _leer();
      if (colores.containsKey(value)) {
        elegido = value!;
        notifyListeners();
      }
    } catch (_) {
      /* Mantener el tema predeterminado si no se puede leer. */
    }
  }

  Future<void> elegir(String nombre) {
    if (!colores.containsKey(nombre)) {
      return Future.error(ArgumentError('Color inválido'));
    }
    final next = _cola.then((_) async {
      // Guardar antes de confirmar para no mostrar una preferencia que se perderá.
      await _guardar(nombre);
      elegido = nombre;
      notifyListeners();
    });
    _cola = next.catchError((Object _) {});
    return next;
  }
}
