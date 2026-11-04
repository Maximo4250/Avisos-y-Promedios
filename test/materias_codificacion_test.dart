import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as movil;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter_application_2/services/db_helper.dart';

void main() {
  sqfliteFfiInit();
  const scope = <Object>['alumno', '4b', 2026];
  const pares = {
    'MatemÃ¡ticas': 'Matemáticas',
    'BiologÃ­a': 'Biología',
    'InglÃ©s': 'Inglés',
    'ED FÃ­sica': 'ED Física',
    'EI TecnologÃ­a': 'EI Tecnología',
  };
  setUp(() {
    movil.databaseFactory = databaseFactoryFfi;
    ContextoAcademico.instance.cambiar(
      owner: 'alumno',
      course: '4b',
      year: 2026,
      label: '4to B',
    );
  });
  test(
    'Migración v5 reúne materias sin perder notas, IDs, borrados ni ámbitos',
    () async {
      final carpeta = await Directory.systemTemp.createTemp('ap_materias_v6_');
      addTearDown(() => carpeta.delete(recursive: true));
      final path = '${carpeta.path}/notas.db';
      final anterior = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE materias (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT, es_doble INTEGER DEFAULT 0, propietario TEXT, curso TEXT, ciclo INTEGER)',
            );
            await db.execute(
              'CREATE TABLE notas (id INTEGER PRIMARY KEY AUTOINCREMENT, materia_id INTEGER, valor REAL, sync_id TEXT, borrada INTEGER DEFAULT 0, pendiente INTEGER DEFAULT 1)',
            );
          },
        ),
      );
      var numero = 0;
      for (final par in pares.entries) {
        for (final nombre in [par.key, par.value]) {
          final id = await anterior.insert('materias', {
            'nombre': nombre,
            'es_doble': nombre == par.value ? 1 : 0,
            'propietario': 'alumno',
            'curso': '4b',
            'ciclo': 2026,
          });
          numero++;
          await anterior.insert('notas', {
            'materia_id': id,
            'valor': 8.0,
            'sync_id': 'nota-$numero',
            'borrada': numero == 2 ? 1 : 0,
            'pendiente': numero.isEven ? 0 : 1,
          });
        }
      }
      for (final otro in [
        <Object>['otro', '4b', 2026],
        <Object>['alumno', '5a', 2026],
        <Object>['alumno', '4b', 2027],
      ]) {
        await anterior.insert('materias', {
          'nombre': 'BiologÃ­a',
          'es_doble': 0,
          'propietario': otro[0],
          'curso': otro[1],
          'ciclo': otro[2],
        });
      }
      final originales = await anterior.query(
        'notas',
        columns: ['id', 'valor', 'sync_id', 'borrada', 'pendiente'],
        orderBy: 'id',
      );
      await anterior.close();
      final helper = await DatabaseHelper.abrirParaPruebas(path);
      final db = await helper.database;
      final reparadas = await helper.obtenerMaterias();
      expect(reparadas.length, 5);
      expect(reparadas.map((m) => m.nombre).toSet(), pares.values.toSet());
      expect(
        await db.query(
          'notas',
          columns: ['id', 'valor', 'sync_id', 'borrada', 'pendiente'],
          orderBy: 'id',
        ),
        originales,
      );
      expect((await db.query('materias')).length, 8);
      expect((await db.query('materias_antes_v6')).length, 13);
      expect((await db.query('notas_antes_v6')).length, 10);
      expect(reparadas.every((m) => m.esDoble), isTrue);
      expect(reparadas.fold<int>(0, (total, m) => total + m.notas.length), 9);
      // Un cliente antiguo puede seguir enviando el nombre dañado: no crea otra materia.
      await helper.fusionarNotas(scope, [
        {
          'id': 'nueva',
          'materia': 'BiologÃ­a',
          'valor': 9.0,
          'doble': true,
          'borrada': false,
        },
      ]);
      expect((await helper.obtenerMaterias()).length, 5);
      await helper.fusionarNotas(scope, [
        {
          'id': 'nueva',
          'materia': 'Biología',
          'valor': 9.0,
          'doble': true,
          'borrada': false,
        },
      ]);
      expect((await db.query('notas')).length, 11);
      await db.close();
      final reabierto = await DatabaseHelper.abrirParaPruebas(path);
      expect((await reabierto.obtenerMaterias()).length, 5);
      expect((await (await reabierto.database).query('notas')).length, 11);
      await (await reabierto.database).close();
    },
  );
  test(
    'Una instalación nueva crea las diez materias con tildes correctas',
    () async {
      final carpeta = await Directory.systemTemp.createTemp('ap_catalogo_v6_');
      addTearDown(() => carpeta.delete(recursive: true));
      final helper = await DatabaseHelper.abrirParaPruebas(
        '${carpeta.path}/nueva.db',
      );
      final db = await helper.database;
      final nombres = (await db.query(
        'materias',
      )).map((m) => m['nombre']).toList();
      expect(nombres.length, 10);
      expect(nombres, containsAll(pares.values));
      expect(nombres.any((n) => n.toString().contains('Ã')), isFalse);
      await helper.prepararContexto();
      expect((await helper.obtenerMaterias()).length, 10);
      await helper.fusionarNotas(scope, [
        {
          'id': 'cloud-1',
          'materia': 'Biología',
          'valor': 8.0,
          'doble': false,
          'borrada': false,
        },
      ]);
      expect((await helper.obtenerMaterias()).length, 10);
      await db.close();
    },
  );
}
