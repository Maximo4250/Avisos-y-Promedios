import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/delegacion.dart';
import 'package:flutter_application_2/screens/cargar_aviso_screen.dart';
import 'package:flutter_application_2/services/delegados_service.dart';

void main() {
  const uid = 'alumno';
  test(
    'Estudiante por defecto, permiso exige activo, curso y ciclo válidos',
    () {
      expect(Delegacion.desde(uid, null), isNull);
      expect(
        Delegacion.desde(uid, {'activo': false, 'curso': '4b', 'ciclo': 2026}),
        isNull,
      );
      expect(
        Delegacion.desde(uid, {
          'activo': true,
          'curso': '4b',
          'ciclo': 2026,
        })!.etiqueta,
        '4to B',
      );
      expect(
        Delegacion.desde(uid, {
          'activo': true,
          'curso': '../otro',
          'ciclo': 2026,
        }),
        isNull,
      );
    },
  );
  test('Evaluación requiere fecha, tareas pueden quedar sin fecha', () {
    const tarea = AvisoDelegado(
      id: 'x',
      materia: 'Lengua',
      tipo: 'tarea',
      detalle: 'Ejercicios 1 al 5',
      dia: 'Lu',
    );
    expect(tarea.validar(), isNull);
    expect(tarea.datos['fecha'], '');
    const examen = AvisoDelegado(
      id: 'x',
      materia: 'Lengua',
      tipo: 'evaluacion',
      detalle: 'Funciones',
      dia: 'Lu',
    );
    expect(examen.validar(), contains('fecha'));
    expect(
      AvisoDelegado(
        id: 'x',
        materia: 'Lengua',
        tipo: 'evaluacion',
        detalle: 'Funciones',
        dia: 'Ju',
        fecha: DateTime(2026, 11, 12),
      ).validar(),
      isNull,
    );
  });
  test(
    'Los temas se limpian al revocar, cambiar curso o cerrar sesión',
    () async {
      String? guardado;
      final operaciones = <String>[];
      final push = PushDelegados(
        leer: () async => guardado,
        guardar: (v) async {
          guardado = v;
        },
        suscribir: (v) async {
          operaciones.add('+$v');
        },
        quitar: (v) async {
          operaciones.add('-$v');
        },
      );
      await push.sincronizar(const Delegacion(uid, '4b', 2026));
      expect(guardado, contains('ap_delegados_2026_4b'));
      await push.sincronizar(const Delegacion(uid, '5a', 2026));
      expect(operaciones, contains('-ap_delegados_2026_4b'));
      await push.sincronizar(null);
      expect(guardado, '');
      expect(operaciones, contains('-ap_delegados'));
    },
  );
  test('Un fallo no confirma una suscripción y permite reintentar', () async {
    String? valor;
    var falla = true;
    final push = PushDelegados(
      leer: () async => valor,
      guardar: (v) async {
        valor = v;
      },
      suscribir: (v) async {
        if (falla) throw StateError('red');
      },
      quitar: (v) async {},
    );
    await expectLater(
      push.sincronizar(const Delegacion(uid, '4b', 2026)),
      throwsStateError,
    );
    expect(valor, isNull);
    falla = false;
    await push.sincronizar(const Delegacion(uid, '4b', 2026));
    expect(valor, contains('ap_delegados_2026_4b'));
  });
  testWidgets('El día filtra materias y descarta la selección anterior', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: CargarAvisoScreen(delegacion: Delegacion(uid, '4b', 2026)),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Matematica'), findsOneWidget);
    expect(find.text('Lengua'), findsNothing);
    await tester.tap(find.text('Matematica').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Miércoles').last);
    await tester.pumpAndSettle();
    expect(find.text('Matematica'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Lengua'), findsOneWidget);
    expect(find.text('Ingles'), findsNothing);
    await tester.tap(find.text('Lengua').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    expect(find.text('Trabajo práctico'), findsNothing);
    await tester.tap(find.text('Evaluación').last);
    await tester.pumpAndSettle();
    expect(find.text('Fecha de evaluación · obligatoria'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Temas de evaluación');
    await tester.tap(find.text('Publicar para el curso'));
    await tester.pumpAndSettle();
    expect(find.text('Indicá la fecha de la evaluación.'), findsOneWidget);
  });
  testWidgets(
    'Formulario simple publica una tarea y conserva el ID si se reintenta',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final intentos = <AvisoDelegado>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CargarAvisoScreen(
            delegacion: const Delegacion(uid, '4b', 2026),
            materias: const ['Lengua'],
            publicar: (a) async {
              intentos.add(a);
              if (intentos.length == 1) throw StateError('Reintentar');
            },
          ),
        ),
      );
      await tester.tap(find.text('Publicar para el curso'));
      await tester.pumpAndSettle();
      expect(intentos, isEmpty);
      expect(find.text('Elegí una materia.'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lengua').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Resolver ejercicios 1 al 5',
      );
      await tester.tap(find.text('Publicar para el curso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar para el curso'));
      await tester.pumpAndSettle();
      expect(intentos.length, 2);
      expect(intentos[0].id, intentos[1].id);
      expect(find.text('Aviso publicado'), findsOneWidget);
      expect(intentos.last.fecha, isNull);
    },
  );
}
