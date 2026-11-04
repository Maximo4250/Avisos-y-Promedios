import 'package:flutter_application_2/core/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';

const _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];
const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
DateTime fechaCivil(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);
bool mismaFecha(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
DateTime inicioSemana(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day - fecha.weekday + 1);
String fechaCalendario(DateTime fecha) =>
    '${_dias[fecha.weekday - 1]} ${fecha.day} de ${_meses[fecha.month - 1].toLowerCase()} de ${fecha.year}';

/// Días civiles, de lunes a domingo, incluyendo las celdas de meses vecinos.
List<DateTime> diasDelMes(DateTime mes) {
  final primero = DateTime(mes.year, mes.month);
  final inicio = inicioSemana(primero);
  final cantidad =
      ((primero.weekday - 1 + DateTime(mes.year, mes.month + 1, 0).day + 6) ~/
          7) *
      7;
  return List.generate(
    cantidad,
    (i) => DateTime(inicio.year, inicio.month, inicio.day + i),
  );
}

class CalendarioMensual extends StatefulWidget {
  const CalendarioMensual({
    super.key,
    required this.actividades,
    required this.seleccionada,
    required this.onSeleccionar,
    this.hoy,
  });
  final List<ActividadSemana> actividades;
  final DateTime seleccionada;
  final ValueChanged<DateTime> onSeleccionar;

  /// Permite verificar semanas y cambios de año sin depender del reloj de las pruebas.
  final DateTime? hoy;
  @override
  State<CalendarioMensual> createState() => _CalendarioMensualState();
}

class _CalendarioMensualState extends State<CalendarioMensual>
    with WidgetsBindingObserver {
  Color get _dorado => AppTheme.detalle;
  late DateTime _mes, _hoy;
  Timer? _reloj;
  bool _expandido = false;
  @override
  void initState() {
    super.initState();
    _mes = DateTime(widget.seleccionada.year, widget.seleccionada.month);
    _hoy = fechaCivil(widget.hoy ?? DateTime.now());
    WidgetsBinding.instance.addObserver(this);
    _reloj = Timer.periodic(Duration(minutes: 1), (_) => _actualizarHoy());
  }

  void _actualizarHoy() {
    final siguiente = fechaCivil(widget.hoy ?? DateTime.now());
    if (mounted && !mismaFecha(siguiente, _hoy)) {
      setState(() => _hoy = siguiente);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _actualizarHoy();
  }

  @override
  void didUpdateWidget(covariant CalendarioMensual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mismaFecha(oldWidget.seleccionada, widget.seleccionada)) {
      _mes = DateTime(widget.seleccionada.year, widget.seleccionada.month);
    }
    _hoy = fechaCivil(widget.hoy ?? DateTime.now());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _mover(int meses) {
    final fecha = DateTime(_mes.year, _mes.month + meses);
    setState(() => _mes = fecha);
    widget.onSeleccionar(fecha);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    final semana = inicioSemana(_hoy);
    final dias = _expandido
        ? diasDelMes(_mes)
        : List.generate(
            7,
            (i) => DateTime(semana.year, semana.month, semana.day + i),
          );
    final mesTitulo = _expandido ? _mes : _hoy;
    final cantidades = <DateTime, int>{};
    for (final a in widget.actividades) {
      if (a.fecha != null) {
        cantidades.update(
          fechaCivil(a.fecha!),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return Container(
      key: ValueKey('calendario-mensual'),
      padding: EdgeInsets.fromLTRB(10, 8, 10, 12),
      decoration: BoxDecoration(
        color: Color(0xFF18191D),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Color(0xFF303137)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_meses[mesTitulo.month - 1]} ${mesTitulo.year}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
              ),
              IconButton(
                tooltip: 'Volver a hoy',
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.onSeleccionar(_hoy),
                icon: Icon(Icons.today_outlined, size: 20, color: _dorado),
              ),
              if (_expandido)
                IconButton(
                  tooltip: 'Mes anterior',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _mover(-1),
                  icon: Icon(Icons.chevron_left, size: 23),
                ),
              if (_expandido)
                IconButton(
                  tooltip: 'Mes siguiente',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _mover(1),
                  icon: Icon(Icons.chevron_right, size: 23),
                ),
              IconButton(
                key: const ValueKey('alternar-calendario'),
                tooltip: _expandido
                    ? 'Mostrar solo esta semana'
                    : 'Mostrar todo el mes',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _expandido = !_expandido),
                icon: Icon(
                  _expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              for (final dia in [
                'Lun',
                'Mar',
                'Mié',
                'Jue',
                'Vie',
                'Sáb',
                'Dom',
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dia,
                        style: TextStyle(
                          fontSize: 12,
                          color: dia == 'Sáb' || dia == 'Dom'
                              ? Colors.redAccent
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var fila = 0; fila < dias.length ~/ 7; fila++)
            Builder(
              builder: (context) {
                final actual = mismaFecha(dias[fila * 7], semana);
                return Container(
                  key: actual ? ValueKey('semana-actual') : null,
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: actual
                        ? _dorado.withValues(alpha: 0.09)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: actual
                          ? _dorado.withValues(alpha: 0.55)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var columna = 0; columna < 7; columna++)
                        Builder(
                          builder: (context) {
                            final fecha = dias[fila * 7 + columna];
                            final hoy = mismaFecha(fecha, _hoy),
                                seleccionada = mismaFecha(
                                  fecha,
                                  widget.seleccionada,
                                );
                            final cantidad = cantidades[fecha] ?? 0;
                            final color = fecha.weekday >= DateTime.saturday
                                ? Colors.redAccent
                                : hoy
                                ? AppTheme.sobreAcento
                                : !_expandido || fecha.month == _mes.month
                                ? Colors.white
                                : Colors.white38;
                            final etiqueta =
                                '${fechaCalendario(fecha)}${hoy ? ', hoy' : ''}${actual ? ', semana actual' : ''}, '
                                '${cantidad == 0 ? 'sin actividades con fecha' : '$cantidad ${cantidad == 1 ? 'actividad' : 'actividades'}'}';
                            return Expanded(
                              child: Semantics(
                                label: etiqueta,
                                selected: seleccionada,
                                button: true,
                                excludeSemantics: true,
                                child: Tooltip(
                                  message: etiqueta,
                                  child: Material(
                                    color: hoy
                                        ? AppTheme.acento
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(17),
                                    child: InkWell(
                                      key: ValueKey(
                                        'fecha-${fecha.year}-${fecha.month}-${fecha.day}',
                                      ),
                                      borderRadius: BorderRadius.circular(17),
                                      onTap: () => widget.onSeleccionar(fecha),
                                      child: Container(
                                        height: _expandido ? 58 : 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            17,
                                          ),
                                          border: seleccionada && !hoy
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                )
                                              : null,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  '${fecha.day}',
                                                  style: TextStyle(
                                                    fontFamily: hoy
                                                        ? 'Verdana'
                                                        : null,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            SizedBox(
                                              height: 7,
                                              width: 7,
                                              child: cantidad == 0
                                                  ? null
                                                  : DecoratedBox(
                                                      key: ValueKey(
                                                        'punto-${fecha.year}-${fecha.month}-${fecha.day}',
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: hoy
                                                            ? AppTheme
                                                                  .sobreAcento
                                                            : _dorado,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          if (_expandido) SizedBox(height: 8),
          if (_expandido)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 5,
              children: [
                Text(
                  '● Actividades',
                  style: TextStyle(color: _dorado, fontSize: 11),
                ),
                Text(
                  'Franja de color · semana actual',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                Text(
                  'Día destacado · hoy',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
