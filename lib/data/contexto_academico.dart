import 'package:flutter/foundation.dart';

/// Contexto académico explícito: nunca avanza de año por el reloj del teléfono.
class ContextoAcademico {
  ContextoAcademico._();
  static final instance = ContextoAcademico._();
  String propietario = 'invitado';
  String curso = '4b';
  int ciclo = 2026;
  String nombreCurso = '4to B';
  Map<String, dynamic>? catalogo;
  final revision = ValueNotifier<int>(0);
  String get clave => '$propietario|$ciclo|$curso';
  bool get legado => curso == '4b' && ciclo == 2026;
  void cambiar({
    required String owner,
    required String course,
    required int year,
    required String label,
    Map<String, dynamic>? datos,
  }) {
    propietario = owner;
    curso = course;
    ciclo = year;
    nombreCurso = label;
    catalogo = datos;
  }
}
