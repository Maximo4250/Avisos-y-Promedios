import '../models/registro_aviso.dart';
import 'firestore_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/delegacion.dart';
import 'db_helper.dart';

class PushDelegados {
  PushDelegados({
    Future<void> Function(String)? suscribir,
    Future<void> Function(String)? quitar,
    Future<String?> Function()? leer,
    Future<void> Function(String)? guardar,
  }) : _suscribir =
           suscribir ?? ((v) => FirebaseMessaging.instance.subscribeToTopic(v)),
       _quitar =
           quitar ??
           ((v) => FirebaseMessaging.instance.unsubscribeFromTopic(v)),
       _leer =
           leer ??
           (() => DatabaseHelper.instance.leerPreferencia('temas_delegado_v1')),
       _guardar =
           guardar ??
           ((v) => DatabaseHelper.instance.guardarPreferencia(
             'temas_delegado_v1',
             v,
           ));
  final Future<void> Function(String) _suscribir, _quitar, _guardar;
  final Future<String?> Function() _leer;
  Future<void> _cola = Future.value();
  Future<void> sincronizar(Delegacion? d) {
    final trabajo = _cola.then((_) async {
      final anteriores = (await _leer() ?? '')
          .split(',')
          .where((v) => v.isNotEmpty)
          .toSet();
      final nuevos = d == null
          ? <String>{}
          : {'ap_delegados', 'ap_delegados_${d.ciclo}_${d.curso}'};
      for (final topic in anteriores.difference(nuevos)) {
        await _quitar(topic).timeout(const Duration(seconds: 10));
        anteriores.remove(topic);
        await _guardar(anteriores.join(','));
      }
      for (final topic in nuevos) {
        await _suscribir(topic).timeout(const Duration(seconds: 10));
        anteriores.add(topic);
        await _guardar(anteriores.join(','));
      }
    });
    _cola = trabajo.catchError((Object _) {});
    return trabajo;
  }
}

class DelegadosService {
  DelegadosService._();
  static final instance = DelegadosService._();
  final permiso = ValueNotifier<Delegacion?>(null);
  final _push = PushDelegados();
  StreamSubscription<User?>? _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _doc;
  StreamSubscription<String>? _token;
  Timer? _reintento;
  int _version = 0;
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  void iniciar() {
    if (_auth != null) return;
    _auth = FirebaseAuth.instance.authStateChanges().listen((u) {
      final version = ++_version;
      _doc?.cancel();
      permiso.value = null;
      unawaited(_sincronizar());
      if (u == null || u.isAnonymous) return;
      _doc = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(u.uid)
          .collection('permisos')
          .doc('delegado')
          .snapshots()
          .listen(
            (s) {
              if (version != _version) return;
              permiso.value = Delegacion.desde(u.uid, s.data());
              unawaited(_sincronizar());
            },
            onError: (Object _) {
              if (version == _version) {
                permiso.value = null;
                unawaited(_sincronizar());
              }
            },
          );
    });
    if (_android) {
      _token = FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => unawaited(_sincronizar()),
      );
    }
    _reintento = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_sincronizar()),
    );
  }

  Future<void> _sincronizar() async {
    if (!_android) return;
    try {
      await _push.sincronizar(permiso.value);
    } catch (_) {
      /* Reintento al renovar token o periódicamente. */
    }
  }

  void detener() {
    _version++;
    _doc?.cancel();
    _auth?.cancel();
    _token?.cancel();
    _reintento?.cancel();
    _auth = null;
    permiso.value = null;
  }

  Future<void> publicar(Delegacion d, AvisoDelegado aviso) async {
    final error = aviso.validar();
    if (error != null) throw StateError(error);
    if (FirebaseAuth.instance.currentUser?.uid != d.uid ||
        permiso.value?.uid != d.uid ||
        permiso.value?.curso != d.curso ||
        permiso.value?.ciclo != d.ciclo) {
      throw StateError('Tu permiso cambió. Volvé a Mi cuenta.');
    }
    final db = FirebaseFirestore.instance;
    final coleccion = FirestoreService.coleccionAvisos(db, d.curso, d.ciclo);
    final ref = coleccion.doc('aviso_${aviso.id}');
    await db
        .runTransaction((t) async {
          final anterior = await t.get(ref);
          if (anterior.exists) {
            final a = anterior.data()!;
            if (a['autor_uid'] == d.uid &&
                a['dia'] == aviso.dia &&
                mapEquals(
                  Map<String, dynamic>.from(a['datos'] as Map),
                  aviso.datos,
                )) {
              return;
            }
            throw StateError(
              'Este intento ya publicó otro contenido. Volvé a abrir el formulario.',
            );
          }
          t.set(ref, {
            'autor_uid': d.uid,
            'curso': d.curso,
            'ciclo': d.ciclo,
            'dia': aviso.dia,
            'creada_en': FieldValue.serverTimestamp(),
            'datos': aviso.datos,
            'archivado': false,
          });
        })
        .timeout(const Duration(seconds: 20));
  }

  void _verificar(Delegacion d) {
    if (FirebaseAuth.instance.currentUser?.uid != d.uid ||
        permiso.value?.uid != d.uid ||
        permiso.value?.curso != d.curso ||
        permiso.value?.ciclo != d.ciclo) {
      throw StateError('Tu permiso cambió. Volvé a Mi cuenta.');
    }
  }

  Future<void> archivar(Delegacion d, RegistroAviso registro) async {
    _verificar(d);
    final db = FirebaseFirestore.instance;
    final ref = FirestoreService.coleccionAvisos(
      db,
      d.curso,
      d.ciclo,
    ).doc(registro.id);
    await db
        .runTransaction((t) async {
          final actual = await t.get(ref);
          if (!actual.exists) {
            throw StateError('Primero trasladá los avisos anteriores.');
          }
          if (actual.data()?['archivado'] == true) return;
          t.update(ref, {
            'archivado': true,
            'archivado_por': d.uid,
            'archivado_en': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 20));
  }
}
