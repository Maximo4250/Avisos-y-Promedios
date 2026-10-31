import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter_application_2/screens/navegacion_principal.dart';
import 'package:flutter_application_2/services/planificacion_local.dart';

class PreferenciasPrueba extends PlanificacionLocal {
  bool semana = false;
  @override
  Future<bool> leerModoSemana() async => semana;
  @override
  Future<void> guardarModoSemana(bool value) async {
    semana = value;
  }
}

void main() {
  testWidgets(
    'La barra mantiene visibles los cinco destinos y restaura el modo',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ContextoAcademico.instance.cambiar(
        owner: 'invitado',
        course: '4b',
        year: 2026,
        label: '4to B',
      );
      final prefs = PreferenciasPrueba()..semana = true;
      await tester.pumpWidget(
        MaterialApp(
          home: NavegacionPrincipal(
            preferencias: prefs,
            secciones: List.generate(
              5,
              (i) => Scaffold(body: Center(child: Text('Contenido $i'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Contenido 1'), findsOneWidget);
      for (final label in [
        'Días',
        'Pendientes',
        '4to B',
        'Materias',
        'Ideas',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.getTopLeft(find.text('Días')).dy, greaterThan(650));
      for (final entry in [
        (0, 'Días'),
        (3, 'Materias'),
        (4, 'Ideas'),
        (2, '4to B'),
      ]) {
        await tester.tap(find.text(entry.$2));
        await tester.pumpAndSettle();
        expect(find.text('Contenido ${entry.$1}'), findsOneWidget);
      }
      expect(prefs.semana, false);
      expect(tester.takeException(), isNull);
    },
  );
}
