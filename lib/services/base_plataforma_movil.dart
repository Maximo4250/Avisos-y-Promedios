import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Windows guarda las notas fuera de la instalación y del navegador.
Future<void> prepararBasePlataforma() async {
  if (!Platform.isWindows) return;
  final local = Platform.environment['LOCALAPPDATA'];
  if (local == null || local.isEmpty) {
    throw StateError('No se encontró la carpeta de datos de Windows.');
  }
  final carpeta = Directory(p.join(local, 'Avisos y Promedios', 'datos'));
  await carpeta.create(recursive: true);
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await databaseFactory.setDatabasesPath(carpeta.path);
}
