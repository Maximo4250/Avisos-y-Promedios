import 'services/tema_service.dart';
import 'services/delegados_service.dart';
import 'package:flutter_application_2/services/sesion_service.dart';
import 'package:flutter_application_2/services/registro_instalacion.dart';
import 'dart:async';
import 'services/sincronizacion_notas.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options_web.dart';
import 'services/base_plataforma.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/app_theme.dart';
import 'package:flutter_application_2/screens/navegacion_principal.dart';
import 'package:flutter_application_2/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await prepararBasePlataforma();
    await TemaService.instance.cargar().timeout(const Duration(seconds: 20));
    await Firebase.initializeApp(
      options: kIsWeb || defaultTargetPlatform == TargetPlatform.windows
          ? opcionesFirebaseWeb
          : null,
    ).timeout(const Duration(seconds: 15));
    await SesionService.instance.prepararLocal();
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'inicio de Firebase',
      ),
    );
    runApp(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se pudo iniciar la aplicación. Intentá nuevamente.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: main,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const MyAppNotas());
  // Mostrar la primera pantalla antes de pedir permisos o contactar a FCM.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_iniciarNotificaciones());
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      RegistroInstalacion.instance.iniciar();
    }
    unawaited(_iniciarCuentas());
  });
}

Future<void> _iniciarCuentas() async {
  try {
    await SesionService.instance.iniciar();
    SincronizacionNotas.instance.iniciar();
    DelegadosService.instance.iniciar();
  } catch (error) {
    debugPrint(
      'Cuentas disponibles cuando se complete la configuración de Firebase: $error',
    );
  }
}

Future<void> _iniciarNotificaciones() async {
  try {
    await NotificationService().initNotifications();
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'inicio de notificaciones',
      ),
    );
  }
}

class MyAppNotas extends StatelessWidget {
  const MyAppNotas({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemaService.instance,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Avisos y Promedios',
        theme: AppTheme.dark,
        home: const NavegacionPrincipal(),
      ),
    );
  }
}
