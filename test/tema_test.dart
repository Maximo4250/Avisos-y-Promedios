// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/services/tema_service.dart';
import 'package:flutter_application_2/core/app_theme.dart';

void main() {
  test(
    'Siete colores, predeterminado y restauración de la preferencia',
    () async {
      String? guardado;
      final s = TemaService(
        leer: () async => guardado,
        guardar: (v) async {
          guardado = v;
        },
      );
      expect(s.elegido, 'Dorado / ámbar');
      expect(TemaService.colores.length, 7);
      await s.elegir('Azul');
      expect(guardado, 'Azul');
      final reabierto = TemaService(
        leer: () async => guardado,
        guardar: (v) async {},
      );
      await reabierto.cargar();
      expect(reabierto.color, TemaService.colores['Azul']);
    },
  );
  test(
    'Un fallo al guardar no confirma el cambio y permite reintentar',
    () async {
      var falla = true;
      final s = TemaService(
        guardar: (v) async {
          if (falla) throw StateError('sin almacenamiento');
        },
      );
      await expectLater(s.elegir('Negro'), throwsStateError);
      expect(s.elegido, 'Dorado / ámbar');
      falla = false;
      await s.elegir('Celeste');
      expect(s.elegido, 'Celeste');
    },
  );
  test('El orden de selecciones rápidas se conserva', () async {
    final s = TemaService(guardar: (v) async {});
    await Future.wait([s.elegir('Azul'), s.elegir('Verde'), s.elegir('Negro')]);
    expect(s.elegido, 'Negro');
  });
  testWidgets(
    'Cambiar tema conserva la navegación y actualiza una pantalla abierta',
    (tester) async {
      final s = TemaService.instance;
      // No usar SQLite en esta prueba: el estado visible se actualiza por notificación.
      final anterior = s.elegido;
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: s,
          builder: (context, _) => MaterialApp(
            navigatorKey: nav,
            theme: AppTheme.dark,
            home: const _PantallaTema(),
          ),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const _PantallaTema()),
      );
      await tester.pumpAndSettle();
      for (final nombre in TemaService.colores.keys) {
        s.elegido = nombre;
        s.notifyListeners();
        await tester.pumpAndSettle();
        final bar = tester.widget<AppBar>(find.byType(AppBar).last);
        expect(bar.backgroundColor, TemaService.colores[nombre]);
        if (nombre == 'Negro') {
          expect(AppTheme.dark.colorScheme.onPrimary, Colors.black);
        }
        final contraste =
            (AppTheme.acento.computeLuminance() + 0.05) /
            (AppTheme.sobreAcento.computeLuminance() + 0.05);
        expect(
          contraste >= 4.5 || 1 / contraste >= 4.5,
          isTrue,
          reason: nombre,
        );
        final detalleContraste =
            (AppTheme.detalle.computeLuminance() + 0.05) /
            (const Color(0xFF212121).computeLuminance() + 0.05);
        expect(detalleContraste, greaterThanOrEqualTo(4.5), reason: nombre);
        expect(nav.currentState!.canPop(), isTrue);
      }
      s.elegido = anterior;
      s.notifyListeners();
      await tester.pumpAndSettle();
    },
  );
}

class _PantallaTema extends StatelessWidget {
  const _PantallaTema();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      title: const Text('Tema'),
    ),
  );
}
