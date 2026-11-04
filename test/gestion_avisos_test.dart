import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/delegacion.dart';
import 'package:flutter_application_2/models/registro_aviso.dart';
import 'package:flutter_application_2/screens/gestionar_avisos_screen.dart';

void main() {
  testWidgets(
    'Archivar pide confirmación, cancelar conserva y aceptar actualiza la lista',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final stream = StreamController<List<RegistroAviso>>();
      addTearDown(stream.close);
      final r = RegistroAviso('aviso_1', {
        'dia': 'Lu',
        'archivado': false,
        'datos': {
          'materia': 'Lengua',
          'detalle': 'Leer texto',
          'tipo': 'tarea',
        },
      });
      var llamadas = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: GestionarAvisosScreen(
            delegacion: const Delegacion('alumno', '4b', 2026),
            avisos: stream.stream,
            archivar: (aviso) async {
              llamadas++;
              stream.add([
                RegistroAviso(r.id, {...r.datos, 'archivado': true}),
              ]);
            },
          ),
        ),
      );
      stream.add([r]);
      await tester.pumpAndSettle();
      expect(find.text('Organizar avisos anteriores'), findsNothing);
      await tester.tap(find.byTooltip('Archivar aviso'));
      await tester.pumpAndSettle();
      expect(llamadas, 0);
      expect(find.text('¿Archivar este aviso?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(llamadas, 0);
      expect(find.byTooltip('Archivar aviso'), findsOneWidget);
      await tester.tap(find.byTooltip('Archivar aviso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archivar'));
      await tester.pumpAndSettle();
      expect(llamadas, 1);
      expect(find.byTooltip('Archivar aviso'), findsNothing);
      expect(
        find.text('No hay avisos activos para este curso.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
