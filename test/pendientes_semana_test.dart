import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';
import 'package:flutter_application_2/screens/pendientes_semana.dart';
import 'package:flutter_application_2/services/planificacion_local.dart';

class MemoriaLocal extends PlanificacionLocal {
  final Set<String> completadas = {};
  bool modo = false;
  bool fallar = false;
  @override
  Future<Set<String>> leerCompletadas() async => Set.of(completadas);
  @override
  Future<void> guardarCompletada(String id, bool valor) async {
    if (fallar) throw StateError('Fallo de escritura');
    if (valor) {
      completadas.add(id);
    } else {
      completadas.remove(id);
    }
  }

  @override
  Future<bool> leerModoSemana() async => modo;
  @override
  Future<void> guardarModoSemana(bool valor) async {
    modo = valor;
  }
}

void main() {
  final tarea = ActividadSemana.desdeAviso('Lu', {
    'materia': 'Lengua',
    'detalle': 'Leer el capítulo',
    'tipo': 'tarea',
  });
  testWidgets('muestra estado vacío sin errores en pantalla estrecha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PendientesSemana(
            actividades: Stream.value([]),
            almacenamiento: MemoriaLocal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay actividades para mostrar.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('completar, reabrir y desmarcar conserva el progreso local', (
    tester,
  ) async {
    final memoria = MemoriaLocal();
    Future<void> abrir() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: PendientesSemana(
              actividades: Stream.value([tarea]),
              almacenamiento: memoria,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await abrir();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(memoria.completadas, contains(tarea.id));
    expect(find.byType(Checkbox), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await abrir();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Completadas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(memoria.completadas, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('una escritura fallida no marca la tarea completada', (
    tester,
  ) async {
    final memoria = MemoriaLocal()..fallar = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PendientesSemana(
            actividades: Stream.value([tarea]),
            almacenamiento: memoria,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(memoria.completadas, isEmpty);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      find.text('No se pudo guardar el progreso. Intentá nuevamente.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'no oculta vencidas ni inventa fecha y muestra error de conexión',
    (tester) async {
      final vencida = ActividadSemana.desdeAviso('Ma', {
        'materia': 'Historia',
        'detalle': 'Prueba antigua',
        'fecha': DateTime.now().subtract(const Duration(days: 2)),
        'tipo': 'evaluacion',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendientesSemana(
              actividades: Stream.value([
                tarea,
                vencida,
                ActividadSemana.desdeAviso('Ju', {
                  'tipo': 'evaluacion',
                  'materia': 'Biología',
                }),
              ]),
              almacenamiento: MemoriaLocal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Vencida hace'), findsOneWidget);
      await tester.ensureVisible(find.text('Sin fecha').last);
      expect(find.text('Sin fecha'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendientesSemana(
              actividades: Stream.error(StateError('Sin conexión')),
              almacenamiento: MemoriaLocal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudieron cargar los avisos. Revisá tu conexión.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
