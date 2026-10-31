import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class IdentidadCuenta {
  const IdentidadCuenta(this.uid, this.correo, this.nombre);
  final String uid, correo, nombre;
}

abstract interface class RepositorioCuentas {
  IdentidadCuenta? get actual;
  Stream<IdentidadCuenta?> get cambios;
  Future<IdentidadCuenta> registrar(String correo, String clave, String nombre);
  Future<IdentidadCuenta> ingresar(String correo, String clave);
  Future<void> salir();
  Future<void> recuperar(String correo);
  Future<void> verificar();
  Future<Map<String, dynamic>> cargarPerfil(
    IdentidadCuenta identidad, {
    String? nombre,
    String curso = '4b',
  });
  Stream<Map<String, dynamic>?> observarPerfil(String uid);
  Future<void> guardarCurso(String uid, String curso);
  Future<List<Map<String, dynamic>>> cursos(int ciclo);
  Future<Map<String, dynamic>?> curso(String curso, int ciclo);
}

/// Firebase Auth administra las claves y los correos de recuperación.
/// Firestore guarda únicamente el nombre visible y la preferencia de curso.
class RepositorioFirebaseCuentas implements RepositorioCuentas {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  IdentidadCuenta? _identidad(User? user) => user == null || user.isAnonymous
      ? null
      : IdentidadCuenta(
          user.uid,
          user.email ?? '',
          user.displayName ?? 'Estudiante',
        );
  @override
  IdentidadCuenta? get actual => _identidad(_auth.currentUser);
  @override
  Stream<IdentidadCuenta?> get cambios =>
      _auth.authStateChanges().map(_identidad);
  @override
  Future<IdentidadCuenta> registrar(
    String correo,
    String clave,
    String nombre,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: clave,
    );
    // Si este paso falla, la cuenta ya existe: el perfil puede repararse al entrar.
    try {
      await result.user!.updateDisplayName(nombre);
    } on FirebaseAuthException {
      debugPrint('Nombre visible pendiente de actualizar.');
    }
    return IdentidadCuenta(result.user!.uid, result.user!.email!, nombre);
  }

  @override
  Future<IdentidadCuenta> ingresar(String correo, String clave) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: clave,
    );
    return _identidad(result.user)!;
  }

  @override
  Future<void> salir() => _auth.signOut();
  @override
  Future<void> recuperar(String correo) async {
    try {
      await _auth.setLanguageCode('es');
      await _auth.sendPasswordResetEmail(email: correo);
    } on FirebaseAuthException catch (error) {
      // Mantener respuesta uniforme incluso en proyectos sin protección de enumeración.
      if (error.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> verificar() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Primero iniciá sesión.');
    }
    await _auth.setLanguageCode('es');
    await user.sendEmailVerification();
  }

  @override
  Future<Map<String, dynamic>> cargarPerfil(
    IdentidadCuenta identidad, {
    String? nombre,
    String curso = '4b',
  }) async {
    final ref = _db.collection('usuarios').doc(identidad.uid);
    final snap = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 12));
    if (snap.exists) return snap.data()!;
    // Una interrupción entre crear Auth y crear perfil no obliga a registrarse otra vez.
    return _db
        .runTransaction<Map<String, dynamic>>((tx) async {
          final existing = await tx.get(ref);
          if (existing.exists) return existing.data()!;
          final label = (nombre ?? identidad.nombre).trim();
          final value = <String, dynamic>{
            'usuario': label.length >= 3 && label.length <= 30
                ? label
                : 'Estudiante',
            'curso_predeterminado': curso,
            'ciclo': 2026,
            'creada_en': FieldValue.serverTimestamp(),
            'actualizada_en': FieldValue.serverTimestamp(),
          };
          tx.set(ref, value);
          return value;
        })
        .timeout(const Duration(seconds: 12));
  }

  @override
  Stream<Map<String, dynamic>?> observarPerfil(String uid) =>
      _db.collection('usuarios').doc(uid).snapshots().map((doc) => doc.data());
  @override
  Future<void> guardarCurso(String uid, String curso) => _db
      .collection('usuarios')
      .doc(uid)
      .update({
        'curso_predeterminado': curso,
        'actualizada_en': FieldValue.serverTimestamp(),
      })
      .timeout(const Duration(seconds: 12));
  @override
  Future<List<Map<String, dynamic>>> cursos(int ciclo) async {
    final result = await _db
        .collection('ciclos')
        .doc('$ciclo')
        .collection('cursos')
        .where('disponible', isEqualTo: true)
        .get()
        .timeout(const Duration(seconds: 12));
    return result.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  @override
  Future<Map<String, dynamic>?> curso(String curso, int ciclo) async =>
      (await _db
              .collection('ciclos')
              .doc('$ciclo')
              .collection('cursos')
              .doc(curso)
              .get()
              .timeout(const Duration(seconds: 8)))
          .data();
}
