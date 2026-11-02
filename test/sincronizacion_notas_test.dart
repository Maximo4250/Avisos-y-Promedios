import 'dart:io';
import 'package:sqflite/sqflite.dart' as movil;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_2/services/db_helper.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';

void main() {
  sqfliteFfiInit();
  const scope = <Object>['alumno', '4b', 2026];
  late Database a, b;
  late DatabaseHelper telefono, pc;
  Future<Database> base() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(
      'CREATE TABLE materias (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT, es_doble INTEGER DEFAULT 0, propietario TEXT, curso TEXT, ciclo INTEGER)',
    );
    await db.execute(
      'CREATE TABLE notas (id INTEGER PRIMARY KEY AUTOINCREMENT, materia_id INTEGER, valor REAL, sync_id TEXT, borrada INTEGER DEFAULT 0, pendiente INTEGER DEFAULT 1)',
    );
    await db.insert('materias', {
      'nombre': 'Matemáticas',
      'propietario': 'alumno',
      'curso': '4b',
      'ciclo': 2026,
    });
    return db;
  }

  Map<String, dynamic> remoto(Map<String, Object?> n) => {
    'id': n['sync_id'],
    'materia': n['nombre'],
    'valor': n['valor'],
    'doble': n['es_doble'] == 1,
    'borrada': n['borrada'] == 1,
  };
  setUp(() async {
    ContextoAcademico.instance.cambiar(
      owner: 'alumno',
      course: '4b',
      year: 2026,
      label: '4to B',
    );
    a = await base();
    b = await base();
    telefono = DatabaseHelper.paraPruebas(a);
    pc = DatabaseHelper.paraPruebas(b);
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });
  test(
    'Computadora vacía conserva las notas del celular y las recibe',
    () async {
      await telefono.insertarNota(1, 9);
      await telefono.fusionarNotas(scope, []);
      expect((await telefono.obtenerMaterias()).single.notas, [9]);
      final pendientes = await telefono.notasPendientes(scope);
      await pc.fusionarNotas(scope, pendientes.map(remoto).toList());
      expect((await pc.obtenerMaterias()).single.notas, [9]);
      expect(await pc.notasPendientes(scope), isEmpty);
    },
  );
  test('Dos dispositivos agregan sin pisarse y reenviar no duplica', () async {
    await telefono.insertarNota(1, 8);
    await pc.insertarNota(1, 10);
    final t = (await telefono.notasPendientes(scope)).map(remoto).toList();
    final c = (await pc.notasPendientes(scope)).map(remoto).toList();
    await telefono.fusionarNotas(scope, c);
    await pc.fusionarNotas(scope, t);
    await pc.fusionarNotas(scope, t);
    expect((await pc.obtenerMaterias()).single.notas, unorderedEquals([8, 10]));
    expect(
      (await telefono.obtenerMaterias()).single.notas,
      unorderedEquals([8, 10]),
    );
  });
  test('Borrado viaja y una copia antigua no resucita la nota', () async {
    await telefono.insertarNota(1, 7);
    final vieja = remoto((await telefono.notasPendientes(scope)).single);
    await pc.fusionarNotas(scope, [vieja]);
    await pc.eliminarNota(1, 7);
    final borrada = remoto((await pc.notasPendientes(scope)).single);
    await telefono.fusionarNotas(scope, [borrada]);
    await telefono.fusionarNotas(scope, [vieja]);
    expect((await telefono.obtenerMaterias()).single.notas, isEmpty);
  });
  test(
    'Migración deduplica importaciones iguales sin perder dos notas iguales',
    () async {
      for (final db in [a, b]) {
        await db.insert('notas', {'materia_id': 1, 'valor': 8});
        await db.insert('notas', {'materia_id': 1, 'valor': 8});
      }
      final t = (await telefono.notasPendientes(scope)).map(remoto).toList();
      await pc.prepararIdsSync(scope);
      await pc.fusionarNotas(scope, t);
      expect((await pc.obtenerMaterias()).single.notas, [8, 8]);
      expect(t.map((r) => r['id']).toSet().length, 2);
    },
  );
  test(
    'Cambios sin conexión sobreviven a recrear el servicio y no se confirman prematuramente',
    () async {
      await telefono.insertarNota(1, 6);
      final otra = DatabaseHelper.paraPruebas(a);
      final n = (await otra.notasPendientes(scope)).single;
      await otra.eliminarNota(1, 6);
      await otra.confirmarNota(scope, n['sync_id'] as String, 0);
      expect((await otra.notasPendientes(scope)).single['borrada'], 1);
    },
  );
  test('Cuenta, curso y año no mezclan datos', () async {
    await telefono.insertarNota(1, 9);
    await pc.fusionarNotas([
      'otra',
      '4b',
      2026,
    ], (await telefono.notasPendientes(scope)).map(remoto).toList());
    expect((await pc.obtenerMaterias()).single.notas, isEmpty);
    expect(await pc.notasPendientes(['alumno', '4b', 2027]), isEmpty);
  });
  test(
    'Dos notas nuevas de igual valor son independientes y borrar elimina solo una',
    () async {
      await telefono.insertarNota(1, 8);
      await telefono.insertarNota(1, 8);
      final ns = await telefono.notasPendientes(scope);
      expect(ns.map((r) => r['sync_id']).toSet().length, 2);
      await telefono.eliminarNota(1, 8);
      expect((await telefono.obtenerMaterias()).single.notas, [8]);
    },
  );
  test(
    'Actualización real desde SQLite v4 conserva IDs, valores y ámbito',
    () async {
      movil.databaseFactory = databaseFactoryFfi;
      final carpeta = await Directory.systemTemp.createTemp(
        'ap_sync_migracion_',
      );
      final archivo = '${carpeta.path}/notas_v4.db';
      final anterior = await databaseFactoryFfi.openDatabase(
        archivo,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (db, v) async {
            await db.execute(
              'CREATE TABLE materias (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT, es_doble INTEGER DEFAULT 0, propietario TEXT, curso TEXT, ciclo INTEGER)',
            );
            await db.execute(
              'CREATE TABLE notas (id INTEGER PRIMARY KEY AUTOINCREMENT, materia_id INTEGER, valor REAL)',
            );
            await db.insert('materias', {
              'id': 17,
              'nombre': 'Lengua',
              'propietario': 'alumno',
              'curso': '4b',
              'ciclo': 2026,
            });
            await db.insert('notas', {
              'id': 45,
              'materia_id': 17,
              'valor': 9.5,
            });
          },
        ),
      );
      await anterior.close();
      final actualizado = await DatabaseHelper.abrirParaPruebas(archivo);
      final db = await actualizado.database;
      final n = (await db.query('notas')).single;
      expect(n['id'], 45);
      expect(n['materia_id'], 17);
      expect(n['valor'], 9.5);
      expect(n['borrada'], 0);
      expect(n['pendiente'], 1);
      expect((await actualizado.obtenerMaterias()).single.notas, [9.5]);
      await db.close();
      await File(archivo).delete();
      await carpeta.delete();
    },
  );
}
