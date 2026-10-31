"""Ejecuta el SQL de migración extraído del código Dart en SQLite real."""
from pathlib import Path
import ast
import re
import sqlite3
import unittest

P=Path(__file__).resolve().parents[1]
SOURCE=(P/'lib/services/db_helper.dart').read_text(encoding='utf-8')

def execute_strings(text):
    for expr in re.findall(r'await db.execute\((.*?)\);',text,re.S):
        fragments=re.findall(r'''("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')''',expr)
        if fragments: yield ''.join(ast.literal_eval(f) for f in fragments)

class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.db=sqlite3.connect(':memory:')
        self.addCleanup(self.db.close)

    def migrate(self,version):
        db=self.db
        db.execute('CREATE TABLE materias(id INTEGER PRIMARY KEY,nombre TEXT,es_doble INTEGER NOT NULL DEFAULT 0)')
        db.execute('CREATE TABLE notas(id INTEGER PRIMARY KEY,materia_id INTEGER,valor REAL)')
        db.execute('CREATE TABLE preferencias_locales(clave TEXT PRIMARY KEY,valor TEXT)')
        db.execute('CREATE TABLE progreso_avisos(aviso_id TEXT PRIMARY KEY,completada INTEGER NOT NULL DEFAULT 0)')
        db.execute("INSERT INTO materias VALUES(1,'Lengua',0)")
        db.execute('INSERT INTO notas VALUES(1,1,8.5)')
        db.execute("INSERT INTO preferencias_locales VALUES('identidad_instalacion_v1','id-original')")
        db.execute("INSERT INTO progreso_avisos VALUES('tarea-original',1)")
        upgrade=SOURCE.split('if (oldVersion < 4) {',1)[1].split('Future<void> _createDB',1)[0]
        schema=SOURCE.split('Future<void> _crearProgreso',1)[1].split('Future<String?> leerPreferencia',1)[0]
        sqls=list(execute_strings(upgrade))
        for sql in sqls:
            if sql.startswith('INSERT INTO progreso_avisos'):
                for ddl in execute_strings(schema):db.execute(ddl)
            db.execute(sql)
        db.commit()

    def test_preserves_existing_data_and_id(self):
        self.migrate(3)
        self.assertEqual(self.db.execute('SELECT valor FROM notas').fetchall(),[(8.5,)])
        self.assertEqual(self.db.execute('SELECT propietario,curso,ciclo FROM materias').fetchall(),[('invitado','4b',2026)])
        self.assertEqual(self.db.execute('SELECT contexto,completada FROM progreso_avisos').fetchall(),[('invitado|2026|4b',1)])
        self.assertEqual(self.db.execute('SELECT valor FROM preferencias_locales').fetchone(),('id-original',))

    def test_account_course_and_year_are_isolated(self):
        self.migrate(3)
        for i,scope in enumerate([('usuario1','4b',2026),('usuario2','4b',2026),('usuario1','5b',2027)],start=2):
            self.db.execute('INSERT INTO materias VALUES(?,?,?,?,?,?)',(i,'Lengua',0,*scope))
            self.db.execute('INSERT INTO notas VALUES(?,?,?)',(i,i,5+i))
        for scope,expected in [(('invitado','4b',2026),8.5),(('usuario1','4b',2026),7),(('usuario2','4b',2026),8),(('usuario1','5b',2027),9)]:
            rows=self.db.execute('SELECT n.valor FROM notas n JOIN materias m ON m.id=n.materia_id WHERE m.propietario=? AND m.curso=? AND m.ciclo=?',scope).fetchall()
            self.assertEqual(rows,[(expected,)])
        for scope in ['usuario1|2026|4b','usuario2|2026|4b']:
            self.db.execute('INSERT INTO progreso_avisos VALUES(?,?,?)',('misma-tarea',0,scope))
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM progreso_avisos').fetchone(),(3,))

if __name__=='__main__':unittest.main()
