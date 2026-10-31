import 'package:flutter_application_2/data/contexto_academico.dart';
import 'db_helper.dart';

/// Solo preferencias y progreso personal; no guarda copias de avisos compartidos.
class PlanificacionLocal {
  const PlanificacionLocal();

  Future<bool> leerModoSemana() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'preferencias_locales',
      where: 'clave = ?',
      whereArgs: ['modo_semana'],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['valor'] == '1';
  }

  Future<void> guardarModoSemana(bool activo) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO preferencias_locales (clave, valor) VALUES (?, ?)',
      ['modo_semana', activo ? '1' : '0'],
    );
  }

  Future<Set<String>> leerCompletadas() async {
    final contexto = ContextoAcademico.instance.clave;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'progreso_avisos',
      where: 'completada = 1 AND contexto = ?',
      whereArgs: [contexto],
    );
    return rows.map((row) => row['aviso_id'] as String).toSet();
  }

  Future<void> guardarCompletada(String id, bool completada) async {
    final contexto = ContextoAcademico.instance.clave;
    final db = await DatabaseHelper.instance.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO progreso_avisos (aviso_id, completada, contexto) VALUES (?, ?, ?)',
      [id, completada ? 1 : 0, contexto],
    );
  }
}
