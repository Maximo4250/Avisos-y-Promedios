import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../data/contexto_academico.dart';
import 'db_helper.dart';

class SincronizacionNotas with WidgetsBindingObserver {
  SincronizacionNotas._();
  static final instance = SincronizacionNotas._();
  final estado = ValueNotifier<String>('Notas guardadas en este dispositivo');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _stream;
  Timer? _timer;
  String? _clave;
  int _epoca = 0;
  Future<void> _cola = Future.value();
  bool _iniciada = false;
  bool _servidor = false;
  List<Object>? _scope;

  void iniciar() {
    if (_iniciada) return;
    _iniciada = true;
    WidgetsBinding.instance.addObserver(this);
    ContextoAcademico.instance.revision.addListener(_contexto);
    DatabaseHelper.cambios.addListener(reintentar);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => reintentar());
    _contexto();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _contexto();
      reintentar();
    }
  }

  CollectionReference<Map<String, dynamic>> _ref(List<Object> s) =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(s[0] as String)
          .collection('libretas')
          .doc('${s[2]}_${s[1]}')
          .collection('notas');
  bool _actual(int e, List<Object> s) =>
      e == _epoca && FirebaseAuth.instance.currentUser?.uid == s[0];

  void _contexto() {
    final c = ContextoAcademico.instance;
    if (_clave == c.clave) return;
    _clave = c.clave;
    _epoca++;
    _stream?.cancel();
    _stream = null;
    _scope = null;
    _servidor = false;
    if (c.propietario == 'invitado' ||
        FirebaseAuth.instance.currentUser?.uid != c.propietario) {
      estado.value = 'Invitado · notas solo en este dispositivo';
      return;
    }
    final s = <Object>[c.propietario, c.curso, c.ciclo];
    _scope = s;
    final e = _epoca;
    estado.value = 'Sincronizando notas…';
    _stream = _ref(s)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            // No aplicar ecos de escrituras aún no confirmadas por el servidor.
            if (snapshot.metadata.hasPendingWrites || !_actual(e, s)) return;
            _cola = _cola
                .then((_) async {
                  if (!_actual(e, s)) return;
                  await DatabaseHelper.instance.prepararIdsSync(s);
                  final cambio = await DatabaseHelper.instance.fusionarNotas(
                    s,
                    [
                      for (final d in snapshot.docs) {...d.data(), 'id': d.id},
                    ],
                  );
                  if (!_actual(e, s)) return;
                  _servidor = !snapshot.metadata.isFromCache;
                  if (cambio) DatabaseHelper.avisarCambios();
                })
                .catchError((Object error) {
                  if (_actual(e, s)) _error(error);
                });
            reintentar();
          },
          onError: (Object error) {
            if (_actual(e, s)) _error(error);
          },
        );
    reintentar();
  }

  void _error(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      _stream?.cancel();
      _stream = null;
    }
    estado.value =
        error is FirebaseException && error.code == 'permission-denied'
        ? 'Sin sincronizar · revisar reglas de Firebase. Tocá para reintentar'
        : 'Cambios guardados localmente · tocá para reintentar';
  }

  void detener() {
    _timer?.cancel();
    _stream?.cancel();
    _epoca++;
    _clave = null;
    _scope = null;
    ContextoAcademico.instance.revision.removeListener(_contexto);
    DatabaseHelper.cambios.removeListener(reintentar);
    WidgetsBinding.instance.removeObserver(this);
    _iniciada = false;
  }

  void reintentar() {
    final s = _scope;
    if (s == null) return;
    if (_stream == null) {
      _clave = null;
      _contexto();
      return;
    }
    final e = _epoca;
    _cola = _cola
        .then((_) async {
          if (!_actual(e, s)) return;
          final base = DatabaseHelper.instance;
          final pendientes = await base.notasPendientes(s);
          if (pendientes.isNotEmpty) {
            estado.value = 'Sincronizando ${pendientes.length} notas…';
          }
          for (final n in pendientes) {
            if (!_actual(e, s)) return;
            final id = n['sync_id'] as String;
            final ref = _ref(s).doc(id);
            // La transacción evita que un equipo atrasado resucite una nota borrada.
            final remoto = await FirebaseFirestore.instance
                .runTransaction<Map<String, dynamic>>((t) async {
                  final doc = await t.get(ref);
                  final valor = <String, dynamic>{
                    'materia': n['nombre'],
                    'valor': n['valor'],
                    'doble': n['es_doble'] == 1,
                    'borrada': n['borrada'] == 1,
                    'curso': s[1],
                    'ciclo': s[2],
                  };
                  if (!doc.exists) {
                    t.set(ref, {
                      ...valor,
                      'actualizada_en': FieldValue.serverTimestamp(),
                    });
                    return {...valor, 'id': id};
                  }
                  final data = doc.data()!;
                  if (n['borrada'] == 1 && data['borrada'] != true) {
                    t.update(ref, {
                      'borrada': true,
                      'actualizada_en': FieldValue.serverTimestamp(),
                    });
                    data['borrada'] = true;
                  }
                  return {...data, 'id': id};
                })
                .timeout(const Duration(seconds: 15));
            final cambio = await base.fusionarNotas(s, [remoto]);
            if (cambio && _actual(e, s)) DatabaseHelper.avisarCambios();
            await base.confirmarNota(s, id, n['borrada'] as int);
          }
          if (!_actual(e, s)) return;
          estado.value = (await base.notasPendientes(s)).isNotEmpty
              ? 'Cambios pendientes de sincronizar'
              : _servidor
              ? 'Notas sincronizadas'
              : 'Notas locales · esperando conexión';
        })
        .catchError((Object error) {
          if (_actual(e, s)) _error(error);
        });
  }
}
