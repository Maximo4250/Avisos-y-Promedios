import '../models/registro_aviso.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';
import 'package:flutter_application_2/data/resumen_horario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Lectura de los avisos (evaluaciones y tareas) publicados en Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> coleccionAvisos(
    FirebaseFirestore db,
    String curso,
    int ciclo,
  ) => db
      .collection('ciclos')
      .doc('$ciclo')
      .collection('cursos')
      .doc(curso)
      .collection('avisos');

  /// Cada curso lee exclusivamente su colección de avisos individuales.
  Stream<List<RegistroAviso>> registros({String? curso, int? ciclo}) {
    final c = ContextoAcademico.instance;
    return coleccionAvisos(
      _db,
      curso ?? c.curso,
      ciclo ?? c.ciclo,
    ).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((d) => RegistroAviso(d.id, d.data())).toList(),
    );
  }

  Stream<List<Map<String, dynamic>>> obtenerEvaluacionesPorDia(String dia) {
    return registros().map(
      (rows) => rows
          .where((r) => !r.archivado && r.dia == dia)
          .map((r) => r.contenido)
          .toList(),
    );
  }

  /// Avisos aún publicados en el horario semanal para esta materia.
  Stream<List<Map<String, dynamic>>> obtenerAvisosPorMateria(String materia) {
    return registros().map(
      (rows) => rows
          .where((r) => !r.archivado)
          .map((r) => r.contenido)
          .where(
            (a) => esMismaMateria(materia, (a['materia'] ?? '').toString()),
          )
          .toList(),
    );
  }

  /// Lee la colección existente; no crea ni modifica avisos.
  Stream<List<ActividadSemana>> obtenerActividadesSemana({
    String? curso,
    int? ciclo,
  }) {
    return registros(curso: curso, ciclo: ciclo).map((rows) {
      final actividades = <String, ActividadSemana>{};
      for (final registro in rows.where((r) => !r.archivado)) {
        for (final original in [registro.contenido]) {
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
          final actividad = ActividadSemana.desdeAviso(registro.dia, aviso);
          actividades[actividad.id] = actividad;
        }
      }
      return ordenarActividades(actividades.values);
    });
  }
}
