import 'package:flutter_application_2/core/app_theme.dart';
import 'package:flutter_application_2/core/app_bar_cuenta.dart';
import 'package:flutter_application_2/screens/curso_screen.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/horario_screen.dart';
import 'package:flutter_application_2/screens/pendientes_semana.dart';
import 'package:flutter_application_2/screens/materias_screen.dart';
import 'package:flutter_application_2/screens/ideas_screen.dart';
import 'package:flutter_application_2/services/planificacion_local.dart';

class NavegacionPrincipal extends StatefulWidget {
  final List<Widget>? secciones;
  final PlanificacionLocal preferencias;
  const NavegacionPrincipal({
    super.key,
    this.secciones,
    this.preferencias = const PlanificacionLocal(),
  }) : assert(secciones == null || secciones.length == 5);
  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  Color get dorado => AppTheme.detalle;
  var _navegadores = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _visitadas = <int>{3};
  int _indice = 3;
  bool _eligio = false;

  @override
  void initState() {
    super.initState();
    _restaurarHorario();
    ContextoAcademico.instance.revision.addListener(_contextoCambio);
  }

  void _contextoCambio() {
    if (!mounted) return;
    setState(() {
      _navegadores = List.generate(5, (_) => GlobalKey<NavigatorState>());
      _visitadas.clear();
      _visitadas.add(_indice);
    });
  }

  @override
  void dispose() {
    ContextoAcademico.instance.revision.removeListener(_contextoCambio);
    super.dispose();
  }

  Future<void> _restaurarHorario() async {
    try {
      final semana = await widget.preferencias.leerModoSemana();
      if (!mounted || _eligio || !semana) return;
      setState(() {
        _indice = 1;
        _visitadas.add(1);
      });
    } catch (_) {
      /* La navegación funciona aunque falle la preferencia. */
    }
  }

  void _seleccionar(int indice) {
    _eligio = true;
    if (_indice == indice) {
      _navegadores[indice].currentState?.popUntil((route) => route.isFirst);
    }
    setState(() {
      _indice = indice;
      _visitadas.add(indice);
    });
    if (indice == 0 || indice == 1) _guardarModo(indice == 1);
  }

  Future<void> _guardarModo(bool semana) async {
    try {
      await widget.preferencias.guardarModoSemana(semana);
    } catch (_) {
      /* No bloquear el cambio de sección. */
    }
  }

  Widget _pantalla(int indice) =>
      widget.secciones?[indice] ??
      switch (indice) {
        0 => DiaSemana(soloDias: true),
        1 => Scaffold(
          appBar: AppBarCuenta(
            title: Text(
              'Pendientes semana',
              style: TextStyle(color: AppTheme.sobreAcento),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: PendientesSemana(),
        ),
        2 => CursoScreen(),
        3 => MateriasScreen(enBarra: true),
        _ => IdeasScreen(),
      };

  @override
  Widget build(BuildContext context) {
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          for (var i = 0; i < 5; i++)
            if (_visitadas.contains(i))
              NavigatorPopHandler(
                enabled: _indice == i,
                onPopWithResult: (_) => _navegadores[i].currentState!.pop(),
                child: Navigator(
                  key: _navegadores[i],
                  onGenerateRoute: (_) =>
                      MaterialPageRoute(builder: (_) => _pantalla(i)),
                ),
              )
            else
              SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF0D0E10),
          border: Border(top: BorderSide(color: Color(0xFF292A2E))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _boton(0, Icons.calendar_view_week_outlined, 'Días'),
                _boton(1, Icons.checklist_rounded, 'Pendientes'),
                Expanded(
                  child: Center(
                    heightFactor: 1,
                    child: Semantics(
                      selected: _indice == 2,
                      button: true,
                      label: 'Curso: ${ContextoAcademico.instance.nombreCurso}',
                      child: Tooltip(
                        message: 'Explorar cursos',
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Material(
                            color: AppTheme.acento,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: _indice == 2
                                    ? Colors.white
                                    : AppTheme.detalle,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              customBorder: CircleBorder(),
                              onTap: () => _seleccionar(2),
                              child: Center(
                                child: Text(
                                  ContextoAcademico.instance.nombreCurso,
                                  style: TextStyle(
                                    color: AppTheme.sobreAcento,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _boton(3, Icons.menu_book_outlined, 'Materias'),
                _boton(4, Icons.lightbulb_outline, 'Ideas'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _boton(int indice, IconData icono, String etiqueta) {
    final activo = _indice == indice;
    final color = activo ? dorado : Color(0xFFA4A5AC);
    return Expanded(
      child: Semantics(
        selected: activo,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _seleccionar(indice),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, color: color, size: 25),
                SizedBox(height: 5),
                Text(
                  etiqueta,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activo ? dorado : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
