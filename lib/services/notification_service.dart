import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Permisos, canal de Android y notificaciones push en primer plano.
class NotificationService {
  static const String _icono = 'ic_stat_aviso';

  /// Debe coincidir con el id configurado en el AndroidManifest.
  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificaciones Importantes',
    description: 'Este canal se usa para avisos y tareas importantes.',
    importance: Importance.max,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _inicializarNotificacionesLocales();
    await _crearCanalAndroid();
    _escucharMensajesEnPrimerPlano();
    await _pedirPermisos();
    // Obtener el token no es un requisito para mostrar la interfaz.
    unawaited(_mostrarTokenFcm());
  }

  Future<void> _pedirPermisos() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      'Estado de permisos de notificación: ${settings.authorizationStatus}',
    );
  }

  Future<void> _inicializarNotificacionesLocales() {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_icono),
    );
    return _local.initialize(settings);
  }

  Future<void> _crearCanalAndroid() async {
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_canal);
  }

  Future<void> _mostrarTokenFcm() async {
    try {
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 10),
      );
      debugPrint('Registro de notificaciones disponible: ${token != null}');
    } catch (error) {
      debugPrint('No se pudo obtener el registro FCM: $error');
    }
  }

  /// Muestra como notificación local los mensajes recibidos con la app abierta.
  void _escucharMensajesEnPrimerPlano() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = notification?.android;
      if (notification == null || android == null) return;

      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _canal.id,
            _canal.name,
            channelDescription: _canal.description,
            icon: _icono,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
}
