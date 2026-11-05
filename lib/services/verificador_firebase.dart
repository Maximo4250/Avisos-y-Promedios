import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compara la versión instalada con la publicada en Remote Config y, si hay
/// una más nueva, ofrece descargarla.
class VerificadorFirebase {
  static Future<void> comprobarActualizacion(BuildContext context) async {
    // La versión web se actualiza al abrirla; nunca ofrecer un APK en computadora.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await remoteConfig.fetchAndActivate();

      final versionRemota = remoteConfig.getString('latest_version');
      final downloadUrl = remoteConfig.getString('download_url');
      final versionActual = (await PackageInfo.fromPlatform()).version;

      if (versionRemota.isNotEmpty &&
          versionRemota != versionActual &&
          context.mounted) {
        _mostrarModalActualizacion(context, versionRemota, downloadUrl);
      }
    } catch (e) {
      debugPrint('Error al verificar Remote Config: $e');
    }
  }

  static void _mostrarModalActualizacion(
    BuildContext context,
    String nuevaVersion,
    String url,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¡Nueva versión disponible!'),
        content: Text(
          'Hay una versión más reciente ($nuevaVersion) disponible. '
          '¿Deseas descargarla ahora?',
        ),
        actions: [
          TextButton(
            // Cierra el diálogo y permite seguir usando la app normalmente
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Luego'),
          ),
          // El color ámbar/negro ya viene del elevatedButtonTheme global.
          ElevatedButton(
            onPressed: () async {
              if (url.isNotEmpty) {
                final lanzado = await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );

                if (!lanzado && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir el enlace de descarga'),
                    ),
                  );
                }
              }
              if (context.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Actualizar ahora'),
          ),
        ],
      ),
    );
  }
}
