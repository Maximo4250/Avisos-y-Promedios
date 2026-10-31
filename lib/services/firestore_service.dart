import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';
import 'package:flutter_application_2/data/resumen_horario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Lectura de los avisos (evaluaciones y tareas) publicados en Firestore.
class FirestoreService {
  static const String _coleccion = 'avisos_semana';

  /// Campo del documento. Está escrito así (con "c") en Firebase: no corregir
  /// aquí sin corregirlo también en la consola de Firestore.
  static const String _campoEvaluaciones = 'evalucaciones';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _avisos {
    final c = ContextoAcademico.instance;
    if (c.legado) return _db.collection(_coleccion);
    return _db
        .collection('ciclos')
        .doc('${c.ciclo}')
        .collection('cursos')
        .doc(c.curso)
        .collection(_coleccion);
  }

  Stream<List<Map<String, dynamic>>> obtenerEvaluacionesPorDia(String dia) {
    return _avisos.doc(dia).snapshots().map(_extraerEvaluaciones);
  }

  /// Avisos aún publicados en el horario semanal para esta materia.
  Stream<List<Map<String, dynamic>>> obtenerAvisosPorMateria(String materia) {
    return _avisos.snapshots().map((snapshot) {
      return snapshot.docs
          .expand((documento) => _extraerEvaluaciones(documento))
          .where(
            (aviso) =>
                esMismaMateria(materia, (aviso['materia'] ?? '').toString()),
          )
          .toList();
    });
  }

  /// Lee la colección existente; no crea ni modifica avisos.
  Stream<List<ActividadSemana>> obtenerActividadesSemana() {
    return _avisos.snapshots().map((snapshot) {
      final actividades = <String, ActividadSemana>{};
      for (final documento in snapshot.docs) {
        for (final original in _extraerEvaluaciones(documento)) {
          final aviso = Map<String, dynamic>.from(original);
          // Firestore Timestamp se convierte solo en memoria.
          for (final campo in const [
            'fecha',
            'fechaEntrega',
            'fecha_entrega',
            'fechaEvaluacion',
            'fecha_evaluacion',
            'fechaLimite',
            'fecha_limite',
            'fechaVencimiento',
            'fecha_vencimiento',
          ]) {
            if (aviso[campo] is Timestamp) {
              aviso[campo] = (aviso[campo] as Timestamp).toDate();
            }
          }
          final actividad = ActividadSemana.desdeAviso(documento.id, aviso);
          actividades[actividad.id] = actividad;
        }
      }
      return ordenarActividades(actividades.values);
    });
  }

  List<Map<String, dynamic>> _extraerEvaluaciones(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null || !data.containsKey(_campoEvaluaciones)) return [];

    try {
      final List<dynamic> listaCruda = data[_campoEvaluaciones];
      return listaCruda
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      debugPrint('Error al convertir evaluaciones: $e');
      return [];
    }
  }
}
