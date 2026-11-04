import '../services/sesion_service.dart';
import 'package:flutter_application_2/core/app_theme.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';
import 'package:flutter_application_2/widgets/calendario_mensual.dart';
import 'package:flutter_application_2/core/app_bar_cuenta.dart';
import 'package:flutter_application_2/screens/pendientes_semana.dart';
import 'package:flutter_application_2/services/planificacion_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/data/horario_data.dart';
import 'package:flutter_application_2/screens/materias_screen.dart';
import 'package:flutter_application_2/services/firestore_service.dart';
import 'package:flutter_application_2/services/verificador_firebase.dart';

typedef _Avisos = List<Map<String, dynamic>>;

/// `true` si algún aviso del día es una evaluación (y no una tarea).
bool _hayEvaluacion(_Avisos avisos) =>
    avisos.any((aviso) => aviso['tipo'] == 'evaluacion');

/// Aviso que corresponde a esa materia, o `null` si no hay.
Map<String, dynamic>? _buscarAviso(_Avisos avisos, String materia) {
  for (final aviso in avisos) {
    if (aviso['materia'] == materia) return aviso;
  }
  return null;
}

class DiaSemana extends StatefulWidget {
  final bool soloDias;
  final Stream<List<ActividadSemana>>? actividades;
  final bool comprobarActualizacion;
  final DateTime? hoy;
  const DiaSemana({
    super.key,
    this.soloDias = false,
    this.actividades,
    this.comprobarActualizacion = true,
    this.hoy,
  });

  @override
  State<DiaSemana> createState() => _DiaSemanaState();
}

class _DiaSemanaState extends State<DiaSemana> {
  late Stream<List<ActividadSemana>> _actividades;
  String? _ambitoAvisos;
  final _sesion = SesionService.instance;
  List<DiaEscolar> get _diasDelCurso => _sesion.conCuenta
      ? horarioParaCurso(
          _sesion.cursoAsignado,
          _sesion.ciclo,
          _sesion.catalogoCursoAsignado,
        )
      : diasEscolares;
  late DateTime _fechaSeleccionada;
  List<ActividadSemana> _ultimasActividades = [];
  final PlanificacionLocal _preferencias = PlanificacionLocal();
  bool _modoSemana = false;
  bool _modoCargado = false;
  bool _semanaVisitada = false;
  bool _guardandoModo = false;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
    _sesion.addListener(_cuentaCambio);
    _fechaSeleccionada = fechaCivil(widget.hoy ?? DateTime.now());
    if (widget.soloDias) {
      _modoCargado = true;
    } else {
      _restaurarModo();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.comprobarActualizacion) {
        VerificadorFirebase.comprobarActualizacion(context);
      }
    });
  }

  void _cargarActividades() {
    _ambitoAvisos = '${_sesion.uid}|${_sesion.cursoAsignado}|${_sesion.ciclo}';
    _actividades =
        widget.actividades ??
        FirestoreService().obtenerActividadesSemana(
          curso: _sesion.conCuenta ? _sesion.cursoAsignado : null,
          ciclo: _sesion.conCuenta ? _sesion.ciclo : null,
        );
  }

  void _cuentaCambio() {
    final ambito = '${_sesion.uid}|${_sesion.cursoAsignado}|${_sesion.ciclo}';
    if (!mounted || ambito == _ambitoAvisos) return;
    setState(() {
      _ultimasActividades = [];
      _cargarActividades();
    });
  }

  @override
  void dispose() {
    _sesion.removeListener(_cuentaCambio);
    super.dispose();
  }

  Future<void> _restaurarModo() async {
    try {
      final semana = await _preferencias.leerModoSemana();
      if (!mounted) return;
      setState(() {
        _modoSemana = semana;
        _semanaVisitada = semana;
        _modoCargado = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _modoCargado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo restaurar el último modo de Horarios.'),
        ),
      );
    }
  }

  Future<void> _cambiarModo() async {
    final siguiente = !_modoSemana;
    setState(() => _guardandoModo = true);
    try {
      await _preferencias.guardarModoSemana(siguiente);
      if (!mounted) return;
      setState(() {
        _modoSemana = siguiente;
        _semanaVisitada = _semanaVisitada || siguiente;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el modo. Intentá nuevamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardandoModo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBarCuenta(
        title: Text(
          _modoSemana ? 'Pendientes semana' : 'Días semana',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.sobreAcento),
        ),
        backgroundColor: AppTheme.acento,
        actions: widget.soloDias
            ? null
            : [
                IconButton(
                  tooltip: _modoSemana
                      ? 'Ver Días semana'
                      : 'Ver Pendientes semana',
                  isSelected: _modoSemana,
                  icon: Icon(Icons.checklist_outlined, size: 35),
                  selectedIcon: Icon(
                    Icons.calendar_view_week_outlined,
                    size: 35,
                  ),
                  onPressed: !_modoCargado || _guardandoModo
                      ? null
                      : _cambiarModo,
                ),
                if (anchoPantalla < 600)
                  IconButton(
                    tooltip: 'Notas y Promedios',
                    icon: Icon(Icons.menu_book_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MateriasScreen(),
                        ),
                      );
                    },
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: AppTheme.detalle,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MateriasScreen(),
                        ),
                      );
                    },
                    child: Text('Notas y Promedios'),
                  ),
              ],
      ),
      body: !_modoCargado
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _modoSemana ? 1 : 0,
              children: [
                _vistaDias(),
                if (_semanaVisitada) PendientesSemana() else SizedBox.shrink(),
              ],
            ),
    );
  }

  Widget _vistaDias() => StreamBuilder<List<ActividadSemana>>(
    key: ValueKey(_ambitoAvisos),
    stream: _actividades,
    builder: (context, snapshot) {
      if (snapshot.hasData) _ultimasActividades = snapshot.data!;
      final actividades = snapshot.data ?? _ultimasActividades;
      final codigo = _codigoFecha(_fechaSeleccionada);
      final coincidencias = _diasDelCurso.where((d) => d.codigo == codigo);
      final dia = coincidencias.isEmpty ? null : coincidencias.first;
      final avisos = _avisosFecha(actividades, _fechaSeleccionada);
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          CalendarioMensual(
            actividades: actividades,
            seleccionada: _fechaSeleccionada,
            hoy: widget.hoy,
            onSeleccionar: (fecha) =>
                setState(() => _fechaSeleccionada = fechaCivil(fecha)),
          ),
          SizedBox(height: 18),
          Text(
            fechaCalendario(_fechaSeleccionada),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.detalle,
            ),
          ),
          if (snapshot.connectionState == ConnectionState.waiting)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (snapshot.hasError)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No se pudieron actualizar los avisos. Revisá la conexión.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFF303137)),
          ),
          Text(
            'Horario habitual',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 10,
              children: [
                for (final d in _diasDelCurso)
                  _BotonDia(
                    dia: d,
                    ancho: 115,
                    seleccionado: d.codigo == codigo,
                    fecha: _fechaDeCodigo(d.codigo),
                    hoy: widget.hoy,
                    avisos: _avisosFecha(actividades, _fechaDeCodigo(d.codigo)),
                    onPressed: () => setState(
                      () => _fechaSeleccionada = _fechaDeCodigo(d.codigo),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14),
          if (dia == null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No hay clases en el horario habitual para este día.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 15),
              ),
            )
          else ...[
            _EncabezadoDia(dia: dia, avisos: avisos),
            SizedBox(height: 10),
            for (final clase in dia.clases)
              _TarjetaClase(
                clase: clase,
                aviso: _buscarAviso(avisos, clase.materia),
              ),
          ],
        ],
      );
    },
  );

  String? _codigoFecha(DateTime fecha) =>
      const {1: 'Lu', 2: 'Ma', 3: 'Mi', 4: 'Ju', 5: 'Vi'}[fecha.weekday];
  DateTime _fechaDeCodigo(String codigo) {
    final inicio = inicioSemana(_fechaSeleccionada);
    final indice =
        const {'Lu': 0, 'Ma': 1, 'Mi': 2, 'Ju': 3, 'Vi': 4}[codigo] ?? 0;
    return DateTime(inicio.year, inicio.month, inicio.day + indice);
  }

  _Avisos _avisosFecha(List<ActividadSemana> actividades, DateTime fecha) => [
    for (final a in actividades)
      if (a.fecha != null
          ? mismaFecha(a.fecha!, fecha)
          : a.diaPublicado == _codigoFecha(fecha))
        {'materia': a.materia, 'detalle': a.descripcion, 'tipo': a.tipo},
  ];
}

/// Conserva el selector habitual y reutiliza los datos del calendario.
class _BotonDia extends StatelessWidget {
  const _BotonDia({
    required this.dia,
    required this.ancho,
    required this.seleccionado,
    required this.fecha,
    required this.avisos,
    required this.onPressed,
    this.hoy,
  });
  final DiaEscolar dia;
  final double ancho;
  final bool seleccionado;
  final DateTime fecha;
  final _Avisos avisos;
  final VoidCallback onPressed;
  final DateTime? hoy;
  @override
  Widget build(BuildContext context) {
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    final esHoy = mismaFecha(fecha, hoy ?? DateTime.now());
    final hayEvaluacion = _hayEvaluacion(avisos);
    final hayTarea = avisos.any(
      (a) => a['tipo'] == 'tarea' || a['tipo'] == 'trabajo',
    );
    return SizedBox(
      width: ancho,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 22,
            child: hayTarea || hayEvaluacion
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hayTarea && hayEvaluacion
                          ? '● Tarea · Evaluación'
                          : hayEvaluacion
                          ? '● Evaluación'
                          : '● Tarea / trabajo',
                      style: TextStyle(
                        color: hayEvaluacion
                            ? Colors.redAccent
                            : AppTheme.detalle,
                        fontSize: 10,
                        fontFamily: 'Verdana',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: seleccionado
                    ? AppTheme.acento
                    : Colors.grey.shade800,
                foregroundColor: seleccionado
                    ? AppTheme.sobreAcento
                    : Colors.white,
                side: seleccionado
                    ? BorderSide(color: Colors.white, width: 1.5)
                    : BorderSide.none,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
              child: Text(
                dia.etiqueta,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: esHoy ? 'Verdana' : null,
                  fontWeight: FontWeight.bold,
                  color: seleccionado ? AppTheme.sobreAcento : Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 18,
            child: esHoy
                ? Text(
                    'Hoy',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Verdana',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Título del día: nombre y salida, con color según los avisos activos.
class _EncabezadoDia extends StatelessWidget {
  const _EncabezadoDia({required this.dia, required this.avisos});

  final DiaEscolar dia;
  final _Avisos avisos;

  Color get _color {
    if (avisos.isEmpty) return Colors.white;
    return _hayEvaluacion(avisos) ? Colors.redAccent : Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    return Text(
      '${dia.nombre} || Salida: ${dia.salida}',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _color,
      ),
    );
  }
}

/// Tarjeta de una clase; si tiene aviso muestra detalle y chip EXAMEN/TAREA.
class _TarjetaClase extends StatelessWidget {
  const _TarjetaClase({required this.clase, required this.aviso});

  final ClaseHorario clase;
  final Map<String, dynamic>? aviso;

  @override
  Widget build(BuildContext context) {
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    final aviso = this.aviso;
    final esEvaluacion = (aviso?['tipo'] ?? 'evaluacion') == 'evaluacion';
    final esTrabajo = aviso?['tipo'] == 'trabajo';
    final detalle = (aviso?['detalle'] ?? '').toString();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      color: aviso != null ? Colors.black : Colors.grey.shade900,
      child: ListTile(
        leading: Text(
          clase.hora,
          style: TextStyle(
            color: AppTheme.detalle,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        title: Text(
          clase.materia,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: detalle.isNotEmpty
            ? Text(
                detalle,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              )
            : null,
        trailing: aviso != null
            ? Chip(
                backgroundColor: esEvaluacion ? Colors.red : Colors.green,
                label: Text(
                  esEvaluacion
                      ? '¡EXAMEN!'
                      : esTrabajo
                      ? 'TRABAJO'
                      : 'TAREA',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
