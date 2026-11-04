import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/app_theme.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';
import 'package:flutter_application_2/screens/horario_screen.dart';
import 'package:flutter_application_2/widgets/calendario_mensual.dart';

ActividadSemana actividad(String tipo, String? fecha, String detalle) =>
    ActividadSemana.desdeAviso('Lu', {
      'tipo': tipo,
      'fecha': fecha,
      'materia': 'Lengua',
      'detalle': detalle,
    });
final ejemplos = [
  actividad('tarea', '2026-10-28', 'Resolver los ejercicios'),
  actividad('evaluacion', '2026-10-29', 'Temas de la unidad'),
  actividad('trabajo', '2026-10-30', 'Entregar el trabajo práctico'),
  actividad('tarea', null, 'Leer el capítulo, sin fecha confirmada'),
];
Widget calendarioPrueba({
  DateTime? fecha,
  DateTime? hoy,
  List<ActividadSemana>? avisos,
}) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: SingleChildScrollView(
      child: StatefulBuilder(
        builder: (context, setLocal) {
          // La selección controlada se prueba en los tests de navegación con su propio estado.
          return CalendarioMensual(
            actividades: avisos ?? ejemplos,
            seleccionada: fecha ?? DateTime(2026, 10, 28),
            hoy: hoy ?? DateTime(2026, 10, 30),
            onSeleccionar: (_) {},
          );
        },
      ),
    ),
  ),
);

void main() {
  test('Mes completo de lunes a domingo: años bisiestos y cambios de año', () {
    final febrero = diasDelMes(DateTime(2024, 2));
    expect(febrero.where((d) => d.month == 2).length, 29);
    expect(febrero.first.weekday, DateTime.monday);
    expect(febrero.last.weekday, DateTime.sunday);
    expect(diasDelMes(DateTime(2021, 2)).length, 28);
    final diciembre = diasDelMes(DateTime(2026, 12));
    expect(diciembre.last, DateTime(2027, 1, 3));
    expect(inicioSemana(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
  });
  test(
    'Los trabajos prácticos conservan fechas explícitas y se consideran pendientes',
    () {
      for (final tipo in [
        'trabajo',
        'trabajo práctico',
        'trabajo practico',
        'TP',
      ]) {
        final a = actividad(tipo, '2026-11-12', 'Preparar exposición');
        expect(a.esTrabajo, true);
        expect(a.esTarea, true);
        expect(a.tipoTexto, 'Trabajo');
        expect(a.fecha, DateTime(2026, 11, 12));
      }
      expect(actividad('trabajo', null, 'Sin fecha').fecha, isNull);
    },
  );
  test('Una fecha de tarea conserva el ID que ya usaba el progreso local', () {
    final a = actividad('tarea', '2026-10-28', 'Resolver los ejercicios');
    expect(
      a.id,
      '["Lu","tarea","Lengua","Resolver los ejercicios","2026-10-28T00:00:00.000"]',
    );
  });
  testWidgets(
    'Empieza compacto y permite desplegar y contraer sin cambiar la selección',
    (tester) async {
      await tester.pumpWidget(calendarioPrueba());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fecha-2026-10-26')), findsOneWidget);
      expect(find.byKey(const ValueKey('fecha-2026-11-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('fecha-2026-10-12')), findsNothing);
      final compacto = tester
          .getSize(find.byKey(const ValueKey('calendario-mensual')))
          .height;
      await tester.tap(find.byTooltip('Mostrar todo el mes'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fecha-2026-10-12')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('calendario-mensual'))).height,
        greaterThan(compacto),
      );
      await tester.tap(find.byTooltip('Mostrar solo esta semana'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fecha-2026-10-12')), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('calendario-mensual'))).height,
        compacto,
      );
      expect(find.byKey(const ValueKey('punto-2026-10-28')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Marca evaluaciones, tareas y trabajos sin inventar fechas', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(calendarioPrueba());
    await tester.pumpAndSettle();
    for (final dia in [28, 29, 30]) {
      expect(find.byKey(ValueKey('punto-2026-10-$dia')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('punto-2026-10-26')), findsNothing);
    expect(find.byKey(const ValueKey('semana-actual')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(
          'Viernes 30 de octubre de 2026, hoy, semana actual, 1 actividad',
        ),
      ),
      findsOneWidget,
    );
    final seleccion = find.bySemanticsLabel(
      RegExp('Miércoles 28 de octubre de 2026'),
    );
    expect(
      tester
          .getSemantics(seleccion)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    semantics.dispose();
  });
  testWidgets('Se puede cambiar de mes/año y regresar a hoy', (tester) async {
    var seleccionada = DateTime(2026, 12, 15);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setLocal) => CalendarioMensual(
                actividades: ejemplos,
                seleccionada: seleccionada,
                hoy: DateTime(2026, 10, 30),
                onSeleccionar: (fecha) => setLocal(() => seleccionada = fecha),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Mostrar todo el mes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Enero 2027'), findsOneWidget);
    expect(seleccionada, DateTime(2027, 1, 1));
    expect(find.byKey(const ValueKey('semana-actual')), findsNothing);
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Diciembre 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver a hoy'));
    await tester.pumpAndSettle();
    expect(find.text('Octubre 2026'), findsOneWidget);
    expect(seleccionada, DateTime(2026, 10, 30));
  });
  testWidgets(
    'La semana actual se distingue aunque empiece en el año anterior',
    (tester) async {
      await tester.pumpWidget(
        calendarioPrueba(
          fecha: DateTime(2027, 1, 1),
          hoy: DateTime(2027, 1, 1),
          avisos: [],
        ),
      );
      expect(find.byKey(const ValueKey('semana-actual')), findsOneWidget);
      expect(find.byKey(const ValueKey('fecha-2026-12-28')), findsOneWidget);
    },
  );
  testWidgets(
    'Días Semana usa una sola suscripción y conserva el horario original',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var escuchas = 0;
      final stream = StreamController<List<ActividadSemana>>.broadcast(
        onListen: () => escuchas++,
      );
      addTearDown(stream.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: DiaSemana(
            soloDias: true,
            actividades: stream.stream,
            hoy: DateTime(2026, 10, 30),
            comprobarActualizacion: false,
          ),
        ),
      );
      stream.add(ejemplos);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendario-mensual')), findsOneWidget);
      expect(escuchas, 1);
      expect(find.text('Entregar el trabajo práctico'), findsNothing);
      expect(find.text('Sin fecha (1)'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('fecha-2026-10-28')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(find.text('Resolver los ejercicios'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 700));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('fecha-2026-10-31')));
      await tester.pumpAndSettle();
      expect(find.text('Sábado 31 de octubre de 2026'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(
        find.text('No hay clases en el horario habitual para este día.'),
        findsOneWidget,
      );
      expect(escuchas, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Un error de red se informa sin afirmar que no existen actividades',
    (tester) async {
      final stream = StreamController<List<ActividadSemana>>();
      addTearDown(stream.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: DiaSemana(
            soloDias: true,
            actividades: stream.stream,
            hoy: DateTime(2026, 10, 30),
            comprobarActualizacion: false,
          ),
        ),
      );
      stream.add(ejemplos);
      await tester.pumpAndSettle();
      stream.addError(StateError('Sin red'));
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudieron actualizar los avisos. Revisá la conexión.'),
        findsOneWidget,
      );
      expect(
        find.text('No hay actividades con fecha para este día.'),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('punto-2026-10-30')), findsOneWidget);
    },
  );
  testWidgets('El calendario y el horario no desbordan en pantallas pequeñas', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: DiaSemana(
            soloDias: true,
            actividades: Stream.value(ejemplos),
            hoy: DateTime(2026, 10, 30),
            comprobarActualizacion: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Vista previa de la pantalla con actividades de ejemplo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (Platform.environment['CAPTURA_CALENDARIO'] != null) {
      await tester.runAsync(() async {
        for (final font in ['Roboto', 'Verdana', 'Ahem']) {
          final bytes = await File(
            r'C:\Windows\Fonts\segoeui.ttf',
          ).readAsBytes();
          final loader = FontLoader(font)
            ..addFont(Future.value(bytes.buffer.asByteData()));
          await loader.load();
        }
        final iconos = await File(
          'C:/Users/Max/flutter/3.41.7/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(iconos.buffer.asByteData()))).load();
      });
    }
    final captura = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captura,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark.copyWith(
            appBarTheme: AppTheme.dark.appBarTheme.copyWith(
              titleTextStyle: AppTheme.dark.appBarTheme.titleTextStyle!
                  .copyWith(fontFamily: 'Roboto'),
            ),
          ),
          builder: (context, child) => Column(
            children: [
              const Material(
                color: Color(0xFF18191D),
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: Text(
                      'Vista previa · actividades de ejemplo',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ),
                ),
              ),
              Expanded(child: child!),
            ],
          ),
          home: DiaSemana(
            soloDias: true,
            actividades: Stream.value(ejemplos),
            hoy: DateTime(2026, 10, 30),
            comprobarActualizacion: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final destino = Platform.environment['CAPTURA_CALENDARIO'] ?? '';
    if (destino.isNotEmpty) {
      final boundary =
          captura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final imagen = await boundary.toImage();
        final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
        await File(destino).writeAsBytes(bytes!.buffer.asUint8List());
        imagen.dispose();
      });
    }
  });
}
