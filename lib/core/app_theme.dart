import 'package:flutter/material.dart';

/// Tema global de la app (oscuro con acento ámbar).
class AppTheme {
  AppTheme._();

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.amber,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.amber,
      foregroundColor: Colors.black,
      elevation: 4,
      toolbarHeight: 76,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
    ),
    // Configuración base de todos los ElevatedButton.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
