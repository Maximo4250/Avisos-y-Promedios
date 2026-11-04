import 'package:flutter/material.dart';
import '../services/tema_service.dart';

class AppTheme {
  AppTheme._();
  static Color get acento => TemaService.instance.color;
  // El tema negro necesita indicadores claros sobre el fondo oscuro.
  static Color get detalle => switch (TemaService.instance.elegido) {
    'Negro' => Colors.white,
    'Azul' => const Color(0xFF90CAF9),
    'Violeta' => const Color(0xFFB39DDB),
    _ => acento,
  };
  static Color get sobreDetalle =>
      detalle.computeLuminance() > 0.4 ? Colors.black : Colors.white;
  static Color get sobreAcento =>
      acento.computeLuminance() > 0.4 ? Colors.black : Colors.white;
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: detalle,
      onPrimary: sobreDetalle,
      secondary: detalle,
      onSecondary: sobreDetalle,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: acento,
      foregroundColor: sobreAcento,
      elevation: 4,
      toolbarHeight: 76,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: sobreAcento,
        fontSize: 33,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: acento,
        foregroundColor: sobreAcento,
        side: acento == Colors.black
            ? const BorderSide(color: Colors.white54)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
