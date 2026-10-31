import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter_application_2/services/db_helper.dart';
import 'package:flutter_application_2/services/repositorio_cuentas.dart';
import 'package:flutter_application_2/services/notificaciones_curso.dart';
import 'package:flutter_application_2/services/sesion_service.dart';
import 'package:flutter_application_2/screens/cuenta_screen.dart';

class BaseMemoria extends Fake implements DatabaseHelper {
  final valores = <String, String>{};
  final ambitos = <String>[];
  @override
  Future<String?> leerPreferencia(String clave) async => valores[clave];
  @override
  Future<void> guardarPreferencia(String clave, String valor) async {
    valores[clave] = valor;
  }

  @override
  Future<void> prepararContexto() async {
    ambitos.add(ContextoAcademico.instance.clave);
  }
}

class TemasMemoria implements SuscripcionesCurso {
  final destinos = <(String, int)>[];
  @override
  Stream<void> get cambiosToken => const Stream.empty();
  @override
  Future<void> sincronizar(String curso, int ciclo) async {
    destinos.add((curso, ciclo));
  }
}

class CuentasMemoria implements RepositorioCuentas {
  @override
  IdentidadCuenta? actual;
  bool sinRed = false, accesoDenegado = false;
  int registros = 0, ingresos = 0, recuperaciones = 0;
  String? correoRecuperacion;
  final perfiles = <String, Map<String, dynamic>>{};
  final eventos = StreamController<IdentidadCuenta?>.broadcast();
  final cambiosPerfil = <String, StreamController<Map<String, dynamic>?>>{};
  @override
  Stream<IdentidadCuenta?> get cambios => eventos.stream;
  IdentidadCuenta identidad(String correo, String nombre) =>
      IdentidadCuenta(correo.split('@').first, correo, nombre);
  @override
  Future<IdentidadCuenta> registrar(
    String correo,
    String clave,
    String nombre,
  ) async {
    registros++;
    actual = identidad(correo, nombre);
    return actual!;
  }

  @override
  Future<IdentidadCuenta> ingresar(String correo, String clave) async {
    ingresos++;
    if (accesoDenegado) throw StateError('Acceso rechazado');
    actual = identidad(correo, 'Estudiante');
    return actual!;
  }

  @override
  Future<void> salir() async {
    actual = null;
  }

  @override
  Future<void> recuperar(String correo) async {
    recuperaciones++;
    correoRecuperacion = correo;
  }

  @override
  Future<void> verificar() async {}
  @override
  Future<Map<String, dynamic>> cargarPerfil(
    IdentidadCuenta identidad, {
    String? nombre,
    String curso = '4b',
  }) async {
    if (sinRed) throw StateError('Sin red');
    return {
      ...perfiles.putIfAbsent(
        identidad.uid,
        () => {
          'usuario': nombre ?? identidad.nombre,
          'curso_predeterminado': curso,
          'ciclo': 2026,
        },
      ),
    };
  }

  @override
  Stream<Map<String, dynamic>?> observarPerfil(String uid) => cambiosPerfil
      .putIfAbsent(
        uid,
        () => StreamController<Map<String, dynamic>?>.broadcast(),
      )
      .stream;
  @override
  Future<void> guardarCurso(String uid, String curso) async {
    if (sinRed) throw StateError('Sin red');
    perfiles[uid]!['curso_predeterminado'] = curso;
  }

  @override
  Future<List<Map<String, dynamic>>> cursos(int ciclo) async => [
    {'id': '4b', 'nombre': '4to B', 'disponible': true},
    {'id': '5a', 'nombre': 'Curso de prueba', 'disponible': true},
  ];
  @override
  Future<Map<String, dynamic>?> curso(String id, int ciclo) async => {
    'nombre': 'Curso de prueba',
    'disponible': true,
  };
  Future<void> cerrar() async {
    await eventos.close();
    for (final c in cambiosPerfil.values) {
      await c.close();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BaseMemoria base;
  late TemasMemoria temas;
  late CuentasMemoria cuentas;
  late SesionService sesion;
  setUp(() {
    base = BaseMemoria();
    temas = TemasMemoria();
    cuentas = CuentasMemoria();
    ContextoAcademico.instance.cambiar(
      owner: 'invitado',
      course: '4b',
      year: 2026,
      label: '4to B',
    );
    sesion = SesionService(cuentas: cuentas, base: base, notificaciones: temas);
  });
  tearDown(() async {
    sesion.dispose();
    await cuentas.cerrar();
  });
  Future<void> ingresar() => sesion.acceder(
    registro: false,
    correo: 'alumna@example.com',
    password: 'una clave de prueba',
  );
  Future<void> turno() => Future<void>.delayed(Duration.zero);

  test('El invitado conserva el último curso al abrir', () async {
    base.valores['curso_invitado'] = '5a';
    await sesion.prepararLocal();
    expect(sesion.conCuenta, false);
    expect(ContextoAcademico.instance.clave, 'invitado|2026|5a');
  });
  test('Explorar otro curso con cuenta no cambia el destinatario', () async {
    await ingresar();
    await sesion.cargarCursos();
    await sesion.verCurso('5a');
    await sesion.sincronizarPush();
    expect(ContextoAcademico.instance.curso, '5a');
    expect(sesion.cursoAsignado, '4b');
    expect(temas.destinos.last, ('4b', 2026));
  });
  test(
    'El invitado cambia preferencias y notificaciones al elegir curso',
    () async {
      await sesion.prepararLocal();
      await sesion.cargarCursos();
      await sesion.verCurso('5a');
      await turno();
      expect(base.valores['curso_invitado'], '5a');
      expect(temas.destinos.last, ('5a', 2026));
    },
  );
  test(
    'Configuración guarda el curso propio sin cambiar el que se explora',
    () async {
      await ingresar();
      await sesion.cargarCursos();
      await sesion.guardarCuenta('5a');
      await turno();
      expect(cuentas.perfiles['alumna']!['curso_predeterminado'], '5a');
      expect(ContextoAcademico.instance.curso, '4b');
      expect(temas.destinos.last, ('5a', 2026));
      expect(
        jsonDecode(base.valores['perfil:alumna']!)['curso_predeterminado'],
        '5a',
      );
    },
  );
  test(
    'Cuenta creada con perfil pendiente sigue siendo una cuenta y puede reintentarse',
    () async {
      cuentas.sinRed = true;
      await sesion.cargarCursos();
      await sesion.acceder(
        registro: true,
        correo: 'alumna@example.com',
        usuario: 'Lucía',
        password: 'clave muy larga',
        curso: '5a',
      );
      expect(sesion.conCuenta, true);
      expect(sesion.errorInicial, isNotNull);
      expect(ContextoAcademico.instance.clave, 'alumna|2026|5a');
      cuentas.sinRed = false;
      await sesion.actualizarPerfil();
      expect(cuentas.registros, 1);
      expect(sesion.errorInicial, isNull);
      expect(sesion.perfil!['usuario'], 'Lucía');
      expect(sesion.cursoAsignado, '5a');
    },
  );
  test(
    'Abrir sin red restaura el ámbito de la cuenta y no muestra datos de invitado',
    () async {
      cuentas.actual = const IdentidadCuenta(
        'alumna',
        'alumna@example.com',
        'Lucía',
      );
      base.valores['perfil:alumna'] = jsonEncode({
        'usuario': 'Lucía',
        'curso_predeterminado': '5a',
        'ciclo': 2026,
      });
      cuentas.sinRed = true;
      await sesion.prepararLocal();
      expect(ContextoAcademico.instance.clave, 'alumna|2026|5a');
      await sesion.actualizarPerfil();
      expect(ContextoAcademico.instance.clave, 'alumna|2026|5a');
    },
  );
  test('Una caché dañada no bloquea el inicio ni mezcla identidades', () async {
    cuentas.actual = const IdentidadCuenta(
      'alumna',
      'alumna@example.com',
      'Lucía',
    );
    base.valores['perfil:alumna'] = 'archivo dañado';
    await sesion.prepararLocal();
    expect(ContextoAcademico.instance.propietario, 'alumna');
    expect(sesion.perfil!['correo'], 'alumna@example.com');
  });
  test(
    'Cerrar sesión funciona sin red y devuelve los datos del invitado',
    () async {
      await ingresar();
      base.valores['curso_invitado'] = '5a';
      cuentas.sinRed = true;
      await sesion.salir();
      expect(sesion.conCuenta, false);
      expect(ContextoAcademico.instance.clave, 'invitado|2026|5a');
      expect(base.valores.containsKey('perfil:alumna'), true);
    },
  );
  test('Acceso rechazado conserva el ámbito invitado', () async {
    await sesion.prepararLocal();
    cuentas.accesoDenegado = true;
    await expectLater(ingresar(), throwsStateError);
    expect(sesion.trabajando, false);
    expect(sesion.conCuenta, false);
    expect(ContextoAcademico.instance.propietario, 'invitado');
  });
  test('Cambiar de cuenta nunca conserva el propietario anterior', () async {
    await ingresar();
    await sesion.salir();
    await sesion.acceder(
      registro: false,
      correo: 'otro@example.com',
      password: 'otra contraseña',
    );
    expect(ContextoAcademico.instance.propietario, 'otro');
    expect(
      base.ambitos,
      containsAllInOrder([
        'alumna|2026|4b',
        'invitado|2026|4b',
        'otro|2026|4b',
      ]),
    );
  });
  test('Las claves no se guardan en preferencias ni en el perfil', () async {
    const clave = 'secreto NO guardar';
    await sesion.acceder(
      registro: true,
      correo: 'alumna@example.com',
      usuario: 'Lucía',
      password: clave,
    );
    expect(jsonEncode(base.valores), isNot(contains(clave)));
    expect(jsonEncode(cuentas.perfiles), isNot(contains(clave)));
  });
  test(
    'Cambiar el perfil en otro dispositivo actualiza la suscripción al recibirlo',
    () async {
      await ingresar();
      await sesion.cargarCursos();
      cuentas.cambiosPerfil['alumna']!.add({
        'usuario': 'Lucía',
        'curso_predeterminado': '5a',
        'ciclo': 2026,
      });
      await turno();
      await turno();
      expect(sesion.cursoAsignado, '5a');
      expect(temas.destinos.last, ('5a', 2026));
      expect(ContextoAcademico.instance.curso, '4b');
    },
  );

  testWidgets('Registro pide correo y valida antes de crear una cuenta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AccesoCuentaScreen(registro: true, sesion: sesion)),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.pump();
    expect(find.text('Ingresá un correo válido.'), findsOneWidget);
    expect(cuentas.registros, 0);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Lucía');
    await tester.enterText(fields.at(1), 'lucia@example.com');
    await tester.enterText(fields.at(2), 'contraseña larga');
    await tester.enterText(fields.at(3), 'otra contraseña');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.pump();
    expect(
      find.text('Usá al menos 10 caracteres y repetí la misma contraseña.'),
      findsOneWidget,
    );
    expect(cuentas.registros, 0);
  });
  testWidgets(
    'Recuperar cuenta pide solo correo y envía una respuesta uniforme',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AccesoCuentaScreen(sesion: sesion)),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        true,
      );
      await tester.tap(find.text('Olvidé mi contraseña'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  lucia@example.com  ');
      await tester.tap(find.text('Enviar enlace de recuperación'));
      await tester.pumpAndSettle();
      expect(cuentas.correoRecuperacion, 'lucia@example.com');
      expect(cuentas.recuperaciones, 1);
      expect(find.textContaining('Si existe una cuenta'), findsOneWidget);
    },
  );
  test(
    'Al volver a la app se conserva el curso que se estaba explorando',
    () async {
      await ingresar();
      await sesion.cargarCursos();
      await sesion.verCurso('5a');
      await sesion.actualizarPerfil();
      expect(ContextoAcademico.instance.curso, '5a');
      expect(sesion.cursoAsignado, '4b');
    },
  );
  test(
    'Una suscripción cambia de tema y conserva solo el tema confirmado',
    () async {
      final llamadas = <String>[];
      final push = SuscripcionesFirebaseCurso(
        base: base,
        suscribir: (topic) async {
          llamadas.add('alta:$topic');
        },
        desuscribir: (topic) async {
          llamadas.add('baja:$topic');
        },
      );
      await push.sincronizar('4b', 2026);
      await push.sincronizar('5a', 2026);
      expect(llamadas, [
        'alta:ap_2026_4b',
        'baja:ap_2026_4b',
        'alta:ap_2026_5a',
      ]);
      expect(base.valores['topic_curso_v1'], 'ap_2026_5a');
    },
  );
  test(
    'Si falla retirar el tema anterior no se agregan dos cursos y se puede reintentar',
    () async {
      var fallar = true;
      final altas = <String>[];
      base.valores['topic_curso_v1'] = 'ap_2026_4b';
      final push = SuscripcionesFirebaseCurso(
        base: base,
        suscribir: (topic) async {
          altas.add(topic);
        },
        desuscribir: (topic) async {
          if (fallar) throw StateError('Sin red');
        },
      );
      await expectLater(push.sincronizar('5a', 2026), throwsStateError);
      expect(altas, isEmpty);
      expect(base.valores['topic_curso_v1'], 'ap_2026_4b');
      fallar = false;
      await push.sincronizar('5a', 2026);
      expect(altas, ['ap_2026_5a']);
    },
  );
}
