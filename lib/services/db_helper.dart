import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter_application_2/models/materia.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/identidad_instalacion.dart';
import 'package:sqflite/sqflite.dart';

/// Acceso a la base de datos local (SQLite): materias y notas.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _apertura;

  static const String _dbName = 'notas_app.db';
  static const int _dbVersion = 5;
  static final cambios = ValueNotifier<int>(0);
  static void avisarCambios() => cambios.value++;
  // Constructor aislado para probar dos dispositivos con bases independientes.
  DatabaseHelper.paraPruebas(Database db) : _basePrueba = db;
  Database? _basePrueba;

  /// Datos precargados la primera vez que se crea la base.
  static const List<({String nombre, List<double> notas, bool esDoble})>
  _materiasIniciales = [
    (nombre: 'MatemÃ¡ticas', notas: [8.0, 9.5], esDoble: false),
    (nombre: 'Lengua', notas: [6.0, 8.0], esDoble: false),
    (nombre: 'BiologÃ­a', notas: [1.0], esDoble: false),
    (nombre: 'Cs Sociales', notas: [5.0], esDoble: true),
    (nombre: 'InglÃ©s', notas: [6.51], esDoble: false),
    (nombre: 'Artes Visuales', notas: [7.0], esDoble: false),
    (nombre: 'ED FÃ­sica', notas: [4.5], esDoble: false),
    (nombre: 'FVT', notas: [8.0], esDoble: false),
    (nombre: 'EI TecnologÃ­a', notas: [0.0], esDoble: true),
    (nombre: 'Form Cristiana', notas: [10.0], esDoble: false),
  ];

  DatabaseHelper._init();

  static Future<DatabaseHelper> abrirParaPruebas(String path) async {
    final helper = DatabaseHelper._init();
    helper._basePrueba = await helper._initDB(path);
    return helper;
  }

  Future<Database> get database async {
    if (_basePrueba != null) return _basePrueba!;
    if (_database != null) return _database!;
    try {
      _database = await (_apertura ??= _initDB(_dbName));
    } catch (_) {
      _apertura = null;
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final path = join(await getDatabasesPath(), fileName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE notas ADD COLUMN sync_id TEXT');
      await db.execute(
        'ALTER TABLE notas ADD COLUMN borrada INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE notas ADD COLUMN pendiente INTEGER NOT NULL DEFAULT 1',
      );
    }
    // TelÃ©fonos con la versiÃ³n 1 reciben la columna nueva automÃ¡ticamente.
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE materias ADD COLUMN es_doble INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) await _crearPlanificacionLocal(db);
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE materias ADD COLUMN propietario TEXT NOT NULL DEFAULT 'invitado'",
      );
      await db.execute(
        "ALTER TABLE materias ADD COLUMN curso TEXT NOT NULL DEFAULT '4b'",
      );
      await db.execute(
        'ALTER TABLE materias ADD COLUMN ciclo INTEGER NOT NULL DEFAULT 2026',
      );
      await db.execute(
        'ALTER TABLE progreso_avisos RENAME TO progreso_avisos_v3',
      );
      await _crearProgreso(db);
      await db.execute(
        "INSERT INTO progreso_avisos (aviso_id, completada, contexto) SELECT aviso_id, completada, 'invitado|2026|4b' FROM progreso_avisos_v3",
      );
      await db.execute('DROP TABLE progreso_avisos_v3');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await _crearPlanificacionLocal(db, nueva: true);
    await db.execute('''
      CREATE TABLE materias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        es_doble INTEGER NOT NULL DEFAULT 0,
        propietario TEXT NOT NULL DEFAULT 'invitado',
        curso TEXT NOT NULL DEFAULT '4b',
        ciclo INTEGER NOT NULL DEFAULT 2026
      )
    ''');

    await db.execute('''
      CREATE TABLE notas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia_id INTEGER NOT NULL,
        valor REAL NOT NULL,
        sync_id TEXT,
        borrada INTEGER NOT NULL DEFAULT 0,
        pendiente INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (materia_id) REFERENCES materias (id) ON DELETE CASCADE
      )
    ''');

    for (final m in _materiasIniciales) {
      final id = await db.insert('materias', {
        'nombre': m.nombre,
        'es_doble': m.esDoble ? 1 : 0,
      });
      for (final nota in m.notas) {
        await db.insert('notas', {'materia_id': id, 'valor': nota});
      }
    }
  }

  Future<void> _crearPlanificacionLocal(
    Database db, {
    bool nueva = false,
  }) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS preferencias_locales ('
      'clave TEXT PRIMARY KEY, valor TEXT NOT NULL)',
    );
    if (nueva) {
      await _crearProgreso(db);
    } else {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS progreso_avisos ('
        'aviso_id TEXT PRIMARY KEY, completada INTEGER NOT NULL DEFAULT 0)',
      );
    }
  }

  Future<void> _crearProgreso(Database db) async {
    await db.execute(
      "CREATE TABLE IF NOT EXISTS progreso_avisos ("
      "aviso_id TEXT NOT NULL, completada INTEGER NOT NULL DEFAULT 0, "
      "contexto TEXT NOT NULL, PRIMARY KEY (aviso_id, contexto))",
    );
  }

  Future<String?> leerPreferencia(String clave) async {
    final db = await database;
    final rows = await db.query(
      'preferencias_locales',
      where: 'clave = ?',
      whereArgs: [clave],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['valor'] as String;
  }

  Future<void> guardarPreferencia(String clave, String valor) async {
    final db = await database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO preferencias_locales (clave, valor) VALUES (?, ?)',
      [clave, valor],
    );
  }

  List<Object> get _scope {
    final c = ContextoAcademico.instance;
    return [c.propietario, c.curso, c.ciclo];
  }

  static const _whereScope = 'propietario = ? AND curso = ? AND ciclo = ?';

  Future<void> prepararContexto() async {
    final scope = _scope;
    final catalogo = ContextoAcademico.instance.catalogo;
    final esLegado = ContextoAcademico.instance.legado;
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'materias',
        where: _whereScope,
        whereArgs: scope,
        limit: 1,
      );
      if (rows.isNotEmpty) return;
      final materias = catalogo?['materias'] as List?;
      final defaults =
          materias ??
          (esLegado
              ? [
                  for (final m in _materiasIniciales)
                    {'nombre': m.nombre, 'es_doble': m.esDoble},
                ]
              : []);
      for (final dynamic m in defaults) {
        await txn.insert('materias', {
          'nombre': m['nombre'],
          'es_doble': m['es_doble'] == true ? 1 : 0,
          'propietario': scope[0],
          'curso': scope[1],
          'ciclo': scope[2],
        });
      }
    });
  }

  /// ImportaciÃ³n explÃ­cita, Ãºnica y solo hacia una cuenta sin notas en ese curso/aÃ±o.
  Future<void> importarNotasInvitado() async {
    final scope = _scope;
    if (scope[0] == 'invitado') throw StateError('Primero iniciÃ¡ sesiÃ³n.');
    final marker = 'importado|${scope.join('|')}';
    final db = await database;
    await db.transaction((txn) async {
      if ((await txn.query(
        'preferencias_locales',
        where: 'clave = ?',
        whereArgs: [marker],
      )).isNotEmpty) {
        throw StateError('Estas notas ya fueron importadas a esta cuenta.');
      }
      final destinos = await txn.query(
        'materias',
        where: _whereScope,
        whereArgs: scope,
      );
      final yaTiene = await txn.rawQuery(
        'SELECT n.id FROM notas n JOIN materias m ON m.id = n.materia_id WHERE m.propietario = ? AND m.curso = ? AND m.ciclo = ? LIMIT 1',
        scope,
      );
      if (yaTiene.isNotEmpty) {
        throw StateError(
          'La cuenta ya tiene notas en este curso. No se mezclaron datos.',
        );
      }
      final fuentes = await txn.query(
        'materias',
        where: _whereScope,
        whereArgs: ['invitado', scope[1], scope[2]],
      );
      for (final m in fuentes) {
        final matches = destinos.where((d) => d['nombre'] == m['nombre']);
        final id = matches.isEmpty
            ? await txn.insert('materias', {
                'nombre': m['nombre'],
                'es_doble': m['es_doble'],
                'propietario': scope[0],
                'curso': scope[1],
                'ciclo': scope[2],
              })
            : matches.first['id'] as int;
        final notas = await txn.query(
          'notas',
          where: 'materia_id = ? AND borrada = 0',
          whereArgs: [m['id']],
        );
        for (final nota in notas) {
          await txn.insert('notas', {'materia_id': id, 'valor': nota['valor']});
        }
      }
      await txn.insert('preferencias_locales', {'clave': marker, 'valor': '1'});
    });
    avisarCambios();
    ContextoAcademico.instance.revision.value++;
  }

  // --- MATERIAS ---

  /// Devuelve todas las materias con sus notas (2 consultas en total).
  Future<List<Materia>> obtenerMaterias() async {
    final scope = _scope;
    final db = await database;
    final materiasRows = await db.query(
      'materias',
      where: _whereScope,
      whereArgs: scope,
    );
    final notasRows = await db.rawQuery(
      'SELECT n.* FROM notas n JOIN materias m ON m.id = n.materia_id WHERE m.propietario = ? AND m.curso = ? AND m.ciclo = ? AND n.borrada = 0 ORDER BY n.id',
      scope,
    );

    final notasPorMateria = <int, List<double>>{};
    for (final row in notasRows) {
      notasPorMateria
          .putIfAbsent(row['materia_id'] as int, () => [])
          .add((row['valor'] as num).toDouble());
    }

    return [
      for (final row in materiasRows)
        Materia.fromMap(row, notas: notasPorMateria[row['id'] as int]),
    ];
  }

  Future<int> insertarMateria(Materia materia) async {
    final scope = _scope;
    final db = await database;
    return db.insert('materias', {
      ...materia.toMap(),
      'propietario': scope[0],
      'curso': scope[1],
      'ciclo': scope[2],
    });
  }

  // --- NOTAS ---

  Future<int> insertarNota(int materiaId, double valor) async {
    if (!valor.isFinite || valor < 0 || valor > 10) {
      throw ArgumentError('Nota inválida');
    }
    final scope = _scope;
    final db = await database;
    final id = await db.rawInsert(
      'INSERT INTO notas (materia_id, valor, sync_id) SELECT id, ?, ? FROM materias WHERE id = ? AND $_whereScope',
      [valor, IdentidadInstalacion.nueva().id, materiaId, ...scope],
    );
    avisarCambios();
    return id;
  }

  Future<int> eliminarNota(int materiaId, double valor) async {
    final scope = _scope;
    final db = await database;
    // Asignar IDs antes de ocultar una nota antigua; así el borrado también viaja.
    await prepararIdsSync(scope);
    final count = await db.rawUpdate(
      'UPDATE notas SET borrada = 1, pendiente = 1 WHERE id = ('
      'SELECT n.id FROM notas n JOIN materias m ON m.id = n.materia_id '
      'WHERE n.borrada = 0 AND n.materia_id = ? AND n.valor = ? '
      'AND m.propietario = ? AND m.curso = ? AND m.ciclo = ? ORDER BY n.id LIMIT 1)',
      [materiaId, valor, ...scope],
    );
    avisarCambios();
    return count;
  }

  Future<void> prepararIdsSync(List<Object> scope) async {
    final db = await database;
    await db.transaction((t) async {
      final rows = await t.rawQuery(
        'SELECT n.*, m.nombre FROM notas n JOIN materias m ON m.id=n.materia_id '
        'WHERE m.propietario=? AND m.curso=? AND m.ciclo=? ORDER BY n.id',
        scope,
      );
      final ocurrencias = <String, int>{};
      for (final row in rows) {
        if (row['sync_id'] != null &&
            !(row['sync_id'] as String).startsWith('legado_')) {
          continue;
        }
        final clave = jsonEncode([
          row['nombre'],
          (row['valor'] as num).toDouble(),
        ]);
        final numero = ocurrencias.update(
          clave,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
        if (row['sync_id'] != null) continue;
        final id =
            'legado_${base64Url.encode(utf8.encode('$clave|$numero')).replaceAll('=', '')}';
        await t.update(
          'notas',
          {'sync_id': id},
          where: 'id=?',
          whereArgs: [row['id']],
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> notasPendientes(List<Object> scope) async {
    await prepararIdsSync(scope);
    final db = await database;
    return db.rawQuery(
      'SELECT n.*, m.nombre, m.es_doble FROM notas n JOIN materias m ON m.id=n.materia_id '
      'WHERE m.propietario=? AND m.curso=? AND m.ciclo=? AND n.pendiente=1 ORDER BY n.id',
      scope,
    );
  }

  Future<void> confirmarNota(List<Object> scope, String id, int borrada) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE notas SET pendiente=0 WHERE sync_id=? AND borrada=? '
      'AND materia_id IN (SELECT id FROM materias WHERE $_whereScope)',
      [id, borrada, ...scope],
    );
  }

  /// Fusión por ID: una lista remota vacía nunca elimina las notas locales.
  /// Una marca de borrado gana siempre; reenviar una nota antigua no la revive.
  Future<bool> fusionarNotas(
    List<Object> scope,
    List<Map<String, dynamic>> remotas,
  ) async {
    final db = await database;
    var cambio = false;
    await db.transaction((t) async {
      for (final r in remotas) {
        final rows = await t.rawQuery(
          'SELECT n.* FROM notas n JOIN materias m ON m.id=n.materia_id '
          'WHERE m.propietario=? AND m.curso=? AND m.ciclo=? AND n.sync_id=?',
          [...scope, r['id']],
        );
        if (rows.isNotEmpty) {
          final local = rows.first;
          if (r['borrada'] == true && local['borrada'] != 1) {
            await t.update(
              'notas',
              {'borrada': 1, 'pendiente': 0},
              where: 'id=?',
              whereArgs: [local['id']],
            );
            cambio = true;
          }
          continue;
        }
        final materias = await t.query(
          'materias',
          where: '$_whereScope AND nombre=?',
          whereArgs: [...scope, r['materia']],
        );
        final mid = materias.isNotEmpty
            ? materias.first['id'] as int
            : await t.insert('materias', {
                'nombre': r['materia'],
                'es_doble': r['doble'] == true ? 1 : 0,
                'propietario': scope[0],
                'curso': scope[1],
                'ciclo': scope[2],
              });
        await t.insert('notas', {
          'materia_id': mid,
          'valor': r['valor'],
          'sync_id': r['id'],
          'borrada': r['borrada'] == true ? 1 : 0,
          'pendiente': 0,
        });
        cambio = true;
      }
    });
    return cambio;
  }
}
