import 'package:flutter_application_2/data/contexto_academico.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_application_2/models/identidad_instalacion.dart';
import 'db_helper.dart';

/// Un documento por ID local. Un fallo de red nunca bloquea el arranque.
class RegistroInstalacion with WidgetsBindingObserver {
  RegistroInstalacion._();
  static final instance = RegistroInstalacion._();
  Future<IdentidadInstalacion>? _identidad;
  bool _observando = false;
  bool _sincronizando = false;
  DateTime? _ultimoIntento;
  static const _clave = 'identidad_instalacion_v1';
  static const _claveRegistro = 'registro_instalacion_dia_v1';

  Future<IdentidadInstalacion> obtenerIdentidad() async {
    try {
      return await (_identidad ??= _leerOCrear());
    } catch (_) {
      _identidad = null;
      rethrow;
    }
  }

  Future<IdentidadInstalacion> _leerOCrear() async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async {
      final filas = await txn.query(
        'preferencias_locales',
        where: 'clave = ?',
        whereArgs: [_clave],
        limit: 1,
      );
      if (filas.isNotEmpty) {
        // No regenerar ante errores de lectura: evitar duplicar instalaciones.
        return IdentidadInstalacion.desdeTexto(filas.first['valor'] as String);
      }
      final identidad = IdentidadInstalacion.nueva();
      await txn.insert('preferencias_locales', {
        'clave': _clave,
        'valor': identidad.aTexto(),
      });
      return identidad;
    });
  }

  void iniciar() {
    if (!_observando) {
      WidgetsBinding.instance.addObserver(this);
      _observando = true;
    }
    unawaited(sincronizar());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(sincronizar());
  }

  Future<void> sincronizar() async {
    final ahora = DateTime.now();
    if (_sincronizando ||
        (_ultimoIntento != null &&
            ahora.difference(_ultimoIntento!) < const Duration(seconds: 30))) {
      return;
    }
    _sincronizando = true;
    _ultimoIntento = ahora;
    try {
      final identidad = await obtenerIdentidad();
      final info = await PackageInfo.fromPlatform();
      final dia = ahora.toUtc().toIso8601String().substring(0, 10);
      final marca = '$dia|${info.version}|${info.buildNumber}';
      final db = await DatabaseHelper.instance.database;
      final registro = await db.query(
        'preferencias_locales',
        where: 'clave = ?',
        whereArgs: [_claveRegistro],
        limit: 1,
      );
      if (registro.isNotEmpty && registro.first['valor'] == marca) return;
      await FirebaseFirestore.instance
          .collection('instalaciones_app')
          .doc(identidad.id)
          .set({
            'instalada_en': Timestamp.fromDate(identidad.creada),
            'ultima_actividad': FieldValue.serverTimestamp(),
            'curso': ContextoAcademico.instance.nombreCurso,
            'version': info.version,
            'compilacion': info.buildNumber,
            'plataforma': 'android',
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 12));
      // Solo marcar sincronizado tras la confirmación de Firebase.
      await db.rawInsert(
        'INSERT OR REPLACE INTO preferencias_locales (clave, valor) VALUES (?, ?)',
        [_claveRegistro, marca],
      );
    } catch (error) {
      debugPrint('No se pudo registrar la instalación: $error');
    } finally {
      _sincronizando = false;
    }
  }
}
