import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_2/models/identidad_instalacion.dart';
import 'package:flutter_application_2/services/db_helper.dart';
import 'package:flutter_application_2/services/registro_instalacion.dart';
import 'package:flutter_application_2/services/sesion_service.dart';

String mensajeCuenta(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'El correo no es válido.',
      'email-already-in-use' =>
        'Ese correo ya tiene una cuenta. Iniciá sesión o recuperá la contraseña.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Correo o contraseña incorrectos.',
      'weak-password' || 'password-does-not-meet-requirements' =>
        'Usá una contraseña más segura, con al menos 10 caracteres.',
      'network-request-failed' =>
        'No hay conexión. Revisá Internet e intentá nuevamente.',
      'too-many-requests' =>
        'Hubo demasiados intentos. Esperá un momento antes de volver a probar.',
      'operation-not-allowed' || 'configuration-not-found' =>
        'Falta habilitar Correo/Contraseña en Firebase Authentication.',
      'user-disabled' => 'Esta cuenta está deshabilitada.',
      _ => 'No se pudo completar la operación. Intentá nuevamente.',
    };
  }
  if (error is FirebaseException) {
    return error.code == 'permission-denied'
        ? 'No se pudo guardar el perfil. Falta revisar las reglas de Firebase.'
        : 'No se pudo sincronizar el perfil. Revisá la conexión.';
  }
  if (error is StateError) return error.message;
  return 'No se pudo completar la operación. Intentá nuevamente.';
}

class CuentaScreen extends StatefulWidget {
  const CuentaScreen({super.key});
  @override
  State<CuentaScreen> createState() => _CuentaScreenState();
}

class _CuentaScreenState extends State<CuentaScreen> {
  final _sesion = SesionService.instance;
  String? _error;
  @override
  void initState() {
    super.initState();
    _sesion.addListener(_cambio);
  }

  void _cambio() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sesion.removeListener(_cambio);
    super.dispose();
  }

  Future<void> _accion(Future<void> Function() action) async {
    setState(() => _error = null);
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = mensajeCuenta(e));
    }
  }

  Future<void> _configurar() async {
    var course = _sesion.cursoAsignado;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de cuenta'),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: course,
                decoration: const InputDecoration(labelText: 'Mi curso'),
                items: _sesion.cursos
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['nombre'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => course = v ?? course),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cambiar mi curso modifica los avisos que recibo. Explorar otro curso no lo cambia.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _accion(() => _sesion.guardarCuenta(course));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi cuenta', style: TextStyle(color: Colors.black)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.account_circle_outlined,
          size: 64,
          color: Colors.amber,
        ),
        const SizedBox(height: 16),
        Text(
          _sesion.conCuenta
              ? _sesion.perfil!['usuario'] as String
              : 'Modo invitado',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_error != null || _sesion.errorInicial != null) ...[
          Text(
            _error ?? _sesion.errorInicial!,
            style: const TextStyle(color: Colors.redAccent),
          ),
          TextButton(
            onPressed: _sesion.trabajando
                ? null
                : () => _accion(_sesion.actualizarPerfil),
            child: const Text('Reintentar'),
          ),
        ],
        if (!_sesion.conCuenta) ...[
          const Text(
            'Podés seguir usando A&P sin registrarte. Una cuenta te permite '
            'mantener tu identidad y elegir tu curso predeterminado.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _sesion.trabajando
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccesoCuentaScreen(),
                    ),
                  ),
            child: const Text('Iniciar sesión'),
          ),
          TextButton(
            onPressed: _sesion.trabajando
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccesoCuentaScreen(registro: true),
                    ),
                  ),
            child: const Text('Crear cuenta'),
          ),
        ] else ...[
          ListTile(
            title: const Text('Mi curso'),
            subtitle: Text(
              '${_sesion.cursoAsignado.toUpperCase()} · ${_sesion.ciclo}',
            ),
            trailing: const Icon(Icons.settings_outlined),
            onTap: _sesion.trabajando ? null : _configurar,
          ),
          ListTile(
            title: const Text('Correo'),
            subtitle: Text(
              (_sesion.perfil?['correo'] as String?)?.isNotEmpty == true
                  ? _sesion.perfil!['correo'] as String
                  : 'No agregado',
            ),
          ),
          TextButton(
            onPressed: _sesion.trabajando
                ? null
                : () => _accion(() async {
                    await _sesion.verificarCorreo();
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Revisá tu correo para verificarlo.'),
                        ),
                      );
                    }
                  }),
            child: const Text('Verificar mi correo'),
          ),
          const Divider(),
          const Text(
            kIsWeb ? 'Notas de este navegador' : 'Notas de este dispositivo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Las notas están separadas por cuenta, curso y año. El respaldo y la sincronización '
            'de notas entre celulares aún no forman parte de esta entrega.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          TextButton(
            onPressed: _sesion.trabajando
                ? null
                : () => _accion(() async {
                    final accept = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Importar notas del invitado'),
                        content: const Text(
                          'Se copiarán las notas de invitado del curso que estás viendo a esta cuenta. '
                          'El original se conserva. Solo se permite si la cuenta no tiene notas en ese curso y año.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Importar'),
                          ),
                        ],
                      ),
                    );
                    if (accept == true) {
                      await DatabaseHelper.instance.importarNotasInvitado();
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Notas importadas.')),
                        );
                      }
                    }
                  }),
            child: const Text('Importar mis notas de invitado'),
          ),
          TextButton(
            onPressed: _sesion.trabajando ? null : () => _accion(_sesion.salir),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
        if (_sesion.trabajando) const LinearProgressIndicator(),
        const SizedBox(height: 32),
        ExpansionTile(
          title: const Text(
            'Información técnica',
            style: TextStyle(fontSize: 13),
          ),
          children: [
            FutureBuilder<IdentidadInstalacion>(
              future: RegistroInstalacion.instance.obtenerIdentidad(),
              builder: (context, snap) => Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  snap.data?.id ?? 'ID no disponible',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const Text(
              'Este ID identifica la instalación, no es una contraseña.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      ],
    ),
  );
}

class AccesoCuentaScreen extends StatefulWidget {
  final bool registro;
  final SesionService? sesion;
  const AccesoCuentaScreen({super.key, this.registro = false, this.sesion});
  @override
  State<AccesoCuentaScreen> createState() => _AccesoCuentaScreenState();
}

class _AccesoCuentaScreenState extends State<AccesoCuentaScreen> {
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  SesionService get _sesion => widget.sesion ?? SesionService.instance;
  bool _recuperar = false, _visible = false, _ocupado = false;
  String _curso = '4b';
  String? _error, _mensaje;
  @override
  void dispose() {
    for (final c in [_nombre, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    final correo = _email.text.trim();
    String? error;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)) {
      error = 'Ingresá un correo válido.';
    } else if (!_recuperar &&
        widget.registro &&
        (_nombre.text.trim().length < 3 || _nombre.text.trim().length > 30)) {
      error = 'El nombre debe tener entre 3 y 30 caracteres.';
    } else if (!_recuperar &&
        widget.registro &&
        (_pass.text.length < 10 || _pass.text != _confirm.text)) {
      error = 'Usá al menos 10 caracteres y repetí la misma contraseña.';
    } else if (!_recuperar && _pass.text.isEmpty) {
      error = 'Ingresá tu contraseña.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
      _mensaje = null;
    });
    try {
      if (_recuperar) {
        await _sesion.recuperar(correo);
        if (!mounted) return;
        setState(
          () => _mensaje =
              'Si existe una cuenta con ese correo, recibirás un enlace para cambiar la contraseña. Revisá también Spam.',
        );
      } else {
        await _sesion.acceder(
          registro: widget.registro,
          correo: correo,
          usuario: _nombre.text.trim(),
          password: _pass.text,
          curso: _curso,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeCuenta(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _recuperar
            ? 'Recuperar cuenta'
            : widget.registro
            ? 'Crear cuenta'
            : 'Iniciar sesión',
      ),
    ),
    body: AutofillGroup(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.registro && !_recuperar) ...[
            TextField(
              controller: _nombre,
              enabled: !_ocupado,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                helperText: 'Nombre visible; ingresás con tu correo.',
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _email,
            enabled: !_ocupado,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
          ),
          if (!_recuperar) ...[
            TextField(
              controller: _pass,
              enabled: !_ocupado,
              obscureText: !_visible,
              maxLength: 128,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: [
                widget.registro
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _visible = !_visible),
                  tooltip: _visible
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña',
                  icon: Icon(
                    _visible ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            if (widget.registro) ...[
              TextField(
                controller: _confirm,
                enabled: !_ocupado,
                obscureText: !_visible,
                maxLength: 128,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Repetir contraseña',
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _curso,
                decoration: const InputDecoration(
                  labelText: 'Curso predeterminado',
                ),
                items: _sesion.cursos
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['nombre'] as String),
                      ),
                    )
                    .toList(),
                onChanged: _ocupado ? null : (v) => _curso = v ?? '4b',
              ),
              const SizedBox(height: 12),
              const Text(
                'Usá un correo al que tengas acceso. Te servirá para recuperar la cuenta si olvidás la contraseña.',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ],
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (_mensaje != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _mensaje!,
                style: const TextStyle(color: Colors.amber),
              ),
            ),
          ElevatedButton(
            onPressed: _ocupado ? null : _enviar,
            child: Text(
              _ocupado
                  ? 'Esperá…'
                  : _recuperar
                  ? 'Enviar enlace de recuperación'
                  : widget.registro
                  ? 'Crear cuenta'
                  : 'Ingresar',
            ),
          ),
          if (!widget.registro)
            TextButton(
              onPressed: _ocupado
                  ? null
                  : () => setState(() {
                      _recuperar = !_recuperar;
                      _error = null;
                      _mensaje = null;
                      _pass.clear();
                    }),
              child: Text(
                _recuperar ? 'Volver a iniciar sesión' : 'Olvidé mi contraseña',
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'La cuenta es opcional. Firebase administra tu contraseña; A&P no la guarda en sus archivos ni en el perfil.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}
