import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'db_helper.dart';
import 'repositorio_cuentas.dart';
import 'notificaciones_curso.dart';

class SesionService extends ChangeNotifier with WidgetsBindingObserver {
  SesionService({
    RepositorioCuentas? cuentas,
    DatabaseHelper? base,
    SuscripcionesCurso? notificaciones,
  }) : _cuentas = cuentas ?? RepositorioFirebaseCuentas(),
       _base = base ?? DatabaseHelper.instance,
       _notificaciones =
           notificaciones ??
           (kIsWeb
               ? const SuscripcionesSinPush()
               : SuscripcionesFirebaseCurso());
  static final instance = SesionService();
  final RepositorioCuentas _cuentas;
  final DatabaseHelper _base;
  final SuscripcionesCurso _notificaciones;
  Map<String, dynamic>? perfil;
  String? uid;
  bool trabajando = false, lista = false;
  bool _disposed = false;
  String? errorInicial;
  StreamSubscription<IdentidadCuenta?>? _auth;
  StreamSubscription<Map<String, dynamic>?>? _perfilStream;
  StreamSubscription<void>? _tokenStream;
  int _restauracion = 0;
  String get cursoAsignado =>
      (perfil?['curso_predeterminado'] ?? '4b') as String;
  int get ciclo => (perfil?['ciclo'] as num?)?.toInt() ?? 2026;
  bool get conCuenta => uid != null;
  final Map<String, Map<String, dynamic>> _cursos = {
    '4b': {'nombre': '4to B', 'disponible': true},
  };
  List<Map<String, dynamic>> get cursos =>
      _cursos.entries.map((e) => {...e.value, 'id': e.key}).toList();
  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  Map<String, dynamic> _fallback(IdentidadCuenta user) => {
    'usuario': user.nombre,
    'correo': user.correo,
    'curso_predeterminado': '4b',
    'ciclo': 2026,
  };
  Future<Map<String, dynamic>> _leerCache(IdentidadCuenta user) async {
    final value = await _base.leerPreferencia('perfil:${user.uid}');
    try {
      return {
        ..._fallback(user),
        if (value != null)
          ...Map<String, dynamic>.from(jsonDecode(value) as Map),
        'correo': user.correo,
      };
    } on FormatException {
      return _fallback(user);
    } on TypeError {
      return _fallback(user);
    }
  }

  Future<void> _guardarCache() async {
    final id = uid, value = perfil;
    if (id == null || value == null) return;
    await _base.guardarPreferencia(
      'perfil:$id',
      jsonEncode({
        for (final key in [
          'usuario',
          'correo',
          'curso_predeterminado',
          'ciclo',
        ])
          key: value[key],
      }),
    );
  }

  /// Elegir la identidad local antes de mostrar las notas, incluso sin conexión.
  Future<void> prepararLocal() async {
    final user = _cuentas.actual;
    uid = user?.uid;
    perfil = user == null ? null : await _leerCache(user);
    final curso = user == null
        ? await _base.leerPreferencia('curso_invitado') ?? '4b'
        : cursoAsignado;
    await _aplicarCurso(curso, owner: uid ?? 'invitado', year: ciclo);
  }

  Future<void> iniciar() async {
    if (_auth != null || _disposed) return;
    _auth = _cuentas.cambios.listen((user) {
      if (!trabajando && user?.uid != uid) unawaited(_restaurar(user));
    });
    WidgetsBinding.instance.addObserver(this);
    // No es necesario iniciar una sesión anónima para suscribirse a temas FCM.
    _tokenStream = _notificaciones.cambiosToken.listen(
      (_) => unawaited(sincronizarPush()),
    );
    await _restaurar(_cuentas.actual);
    lista = true;
    _avisar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !trabajando) {
      unawaited(_restaurar(_cuentas.actual, preservarCurso: true));
    }
  }

  Future<void> actualizarPerfil() =>
      _restaurar(_cuentas.actual, preservarCurso: true);
  Future<void> _restaurar(
    IdentidadCuenta? user, {
    String? nombre,
    String? curso,
    bool preservarCurso = false,
  }) async {
    final revision = ++_restauracion;
    await _perfilStream?.cancel();
    _perfilStream = null;
    errorInicial = null;
    if (user == null) {
      uid = null;
      perfil = null;
      final selected = await _base.leerPreferencia('curso_invitado') ?? '4b';
      if (_disposed || revision != _restauracion) return;
      await _aplicarCurso(selected, owner: 'invitado', year: 2026);
    } else {
      uid = user.uid;
      perfil = await _leerCache(user);
      try {
        final value = await _cuentas.cargarPerfil(
          user,
          nombre: nombre ?? perfil?['usuario'] as String?,
          curso: curso ?? cursoAsignado,
        );
        if (_disposed ||
            revision != _restauracion ||
            _cuentas.actual?.uid != user.uid) {
          return;
        }
        perfil = {...value, 'correo': user.correo};
        await _guardarCache();
      } catch (_) {
        if (_disposed || revision != _restauracion) return;
        errorInicial =
            'Tu sesión está abierta. No pudimos sincronizar el perfil; revisá la conexión y tocá Reintentar.';
      }
      if (_disposed || revision != _restauracion) return;
      final contexto = ContextoAcademico.instance;
      final visto =
          preservarCurso &&
              contexto.propietario == user.uid &&
              contexto.ciclo == ciclo
          ? contexto.curso
          : cursoAsignado;
      await _aplicarCurso(visto, owner: user.uid, year: ciclo);
      _escucharPerfil(user);
    }
    _avisar();
    unawaited(sincronizarPush());
  }

  void _escucharPerfil(IdentidadCuenta user) {
    _perfilStream = _cuentas
        .observarPerfil(user.uid)
        .listen(
          (value) async {
            if (_disposed || uid != user.uid || trabajando || value == null) {
              return;
            }
            final anterior = cursoAsignado;
            perfil = {...value, 'correo': user.correo};
            errorInicial = null;
            try {
              await _guardarCache();
            } catch (_) {
              /* Reintentar al abrir. */
            }
            if (anterior != cursoAsignado) unawaited(sincronizarPush());
            _avisar();
          },
          onError: (_) {
            if (_disposed || uid != user.uid) return;
            errorInicial =
                'No se pudo sincronizar el perfil. Revisá la conexión y la configuración de Firebase.';
            _avisar();
          },
        );
  }

  Future<void> cargarCursos() async {
    for (final value in await _cuentas.cursos(ciclo)) {
      _cursos[value['id'] as String] = value;
    }
    _avisar();
  }

  Future<void> _aplicarCurso(
    String course, {
    required String owner,
    required int year,
  }) async {
    if (!_cursos.containsKey(course)) {
      try {
        final value = await _cuentas.curso(course, year);
        if (value != null) _cursos[course] = value;
      } catch (_) {
        /* Conservar el ámbito local aunque no haya red. */
      }
    }
    ContextoAcademico.instance.cambiar(
      owner: owner,
      course: course,
      year: year,
      label: (_cursos[course]?['nombre'] ?? course).toString(),
      datos: _cursos[course],
    );
    await _base.prepararContexto();
    ContextoAcademico.instance.revision.value++;
  }

  Future<void> verCurso(String course) async {
    if (trabajando) {
      throw StateError('Esperá a que termine la operación de cuenta.');
    }
    if (!_cursos.containsKey(course)) throw StateError('Curso no disponible.');
    await _aplicarCurso(course, owner: uid ?? 'invitado', year: ciclo);
    if (!conCuenta) {
      await _base.guardarPreferencia('curso_invitado', course);
      unawaited(sincronizarPush());
    }
    _avisar();
  }

  Future<void> acceder({
    required bool registro,
    required String correo,
    required String password,
    String usuario = '',
    String curso = '4b',
  }) async {
    if (trabajando) throw StateError('Ya hay una operación en curso.');
    trabajando = true;
    errorInicial = null;
    _avisar();
    try {
      if (!_cursos.containsKey(curso)) throw StateError('Curso no disponible.');
      final user = registro
          ? await _cuentas.registrar(correo.trim(), password, usuario.trim())
          : await _cuentas.ingresar(correo.trim(), password);
      // Guardar un perfil local inmediatamente: un fallo de red posterior no
      // convierte una cuenta creada en un error que invite a registrarse otra vez.
      uid = user.uid;
      perfil = registro
          ? {
              ..._fallback(user),
              'usuario': usuario.trim(),
              'curso_predeterminado': curso,
            }
          : await _leerCache(user);
      await _guardarCache();
      await _restaurar(
        user,
        nombre: registro ? usuario.trim() : null,
        curso: registro ? curso : null,
      );
    } finally {
      trabajando = false;
      _avisar();
      unawaited(sincronizarPush());
    }
  }

  Future<void> guardarCuenta(String curso) async {
    final id = uid;
    if (id == null) throw StateError('Primero iniciá sesión.');
    if (trabajando) throw StateError('Ya hay una operación en curso.');
    if (!_cursos.containsKey(curso)) throw StateError('Curso no disponible.');
    trabajando = true;
    _avisar();
    try {
      await _cuentas.guardarCurso(id, curso);
      perfil = {...perfil!, 'curso_predeterminado': curso};
      await _guardarCache();
    } finally {
      trabajando = false;
      _avisar();
      unawaited(sincronizarPush());
    }
  }

  Future<void> recuperar(String correo) => _cuentas.recuperar(correo.trim());
  Future<void> verificarCorreo() => _cuentas.verificar();
  Future<void> salir() async {
    if (trabajando) throw StateError('Ya hay una operación en curso.');
    trabajando = true;
    _avisar();
    try {
      await _perfilStream?.cancel();
      _perfilStream = null;
      await _cuentas.salir();
      await _restaurar(null);
    } finally {
      trabajando = false;
      _avisar();
      unawaited(sincronizarPush());
    }
  }

  Future<void> sincronizarPush() async {
    if (_disposed || trabajando) return;
    final c = ContextoAcademico.instance;
    try {
      await _notificaciones.sincronizar(
        conCuenta ? cursoAsignado : c.curso,
        ciclo,
      );
    } catch (_) {
      debugPrint(
        'Suscripción de curso pendiente: se reintentará al abrir la app.',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _restauracion++;
    WidgetsBinding.instance.removeObserver(this);
    _auth?.cancel();
    _perfilStream?.cancel();
    _tokenStream?.cancel();
    super.dispose();
  }
}
