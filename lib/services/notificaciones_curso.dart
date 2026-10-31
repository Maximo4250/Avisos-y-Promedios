import 'package:firebase_messaging/firebase_messaging.dart';
import 'db_helper.dart';

abstract interface class SuscripcionesCurso {
  Stream<void> get cambiosToken;
  Future<void> sincronizar(String curso, int ciclo);
}

/// Temas públicos para avisos escolares: no son permisos de acceso ni grupos privados.
class SuscripcionesFirebaseCurso implements SuscripcionesCurso {
  SuscripcionesFirebaseCurso({
    DatabaseHelper? base,
    Future<void> Function(String)? suscribir,
    Future<void> Function(String)? desuscribir,
  }) : _base = base ?? DatabaseHelper.instance,
       _suscribir =
           suscribir ??
           ((topic) => FirebaseMessaging.instance.subscribeToTopic(topic)),
       _desuscribir =
           desuscribir ??
           ((topic) => FirebaseMessaging.instance.unsubscribeFromTopic(topic));
  final DatabaseHelper _base;
  final Future<void> Function(String) _suscribir, _desuscribir;
  @override
  Stream<void> get cambiosToken =>
      FirebaseMessaging.instance.onTokenRefresh.map((_) {});
  Future<void> _cola = Future<void>.value();
  @override
  Future<void> sincronizar(String curso, int ciclo) {
    final next = _cola.then((_) async {
      if (!RegExp(r'^[a-z0-9_-]{1,40}$').hasMatch(curso)) {
        throw StateError('Curso inválido para notificaciones.');
      }
      final topic = 'ap_${ciclo}_$curso';
      final db = _base;
      final anterior = await db.leerPreferencia('topic_curso_v1');
      if (anterior != null && anterior.isNotEmpty && anterior != topic) {
        await _desuscribir(anterior).timeout(const Duration(seconds: 10));
        await db.guardarPreferencia('topic_curso_v1', '');
      }
      await _suscribir(topic).timeout(const Duration(seconds: 10));
      await db.guardarPreferencia('topic_curso_v1', topic);
    });
    _cola = next.catchError((Object _) {});
    return next;
  }
}

/// FCM web no permite suscripciones a temas desde el cliente.
/// Los avisos se consultan en la app; el push por curso continúa en Android.
class SuscripcionesSinPush implements SuscripcionesCurso {
  const SuscripcionesSinPush();
  @override
  Stream<void> get cambiosToken => const Stream<void>.empty();
  @override
  Future<void> sincronizar(String curso, int ciclo) async {}
}
