import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/actividad_semana.dart';
import 'package:flutter_application_2/services/firestore_service.dart';
import 'package:flutter_application_2/services/planificacion_local.dart';

enum _Filtro {
  prioridades,
  tareas,
  evaluaciones,
  vencidas,
  completadas,
  sinFecha,
}

/// Segunda vista de Horarios. Las escrituras se limitan al dispositivo.
class PendientesSemana extends StatefulWidget {
  final Stream<List<ActividadSemana>>? actividades;
  final PlanificacionLocal almacenamiento;
  const PendientesSemana({
    super.key,
    this.actividades,
    this.almacenamiento = const PlanificacionLocal(),
  });

  @override
  State<PendientesSemana> createState() => _PendientesSemanaState();
}

class _PendientesSemanaState extends State<PendientesSemana> {
  late Stream<List<ActividadSemana>> _actividades;
  Set<String> _completadas = {};
  final Set<String> _guardando = {};
  bool _cargando = true;
  bool _errorLocal = false;
  _Filtro _filtro = _Filtro.prioridades;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _actividades =
        widget.actividades ?? FirestoreService().obtenerActividadesSemana();
    _leerProgreso();
    // Actualiza los días restantes si se deja abierta la pantalla al cambiar de día.
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _leerProgreso() async {
    setState(() {
      _cargando = true;
      _errorLocal = false;
    });
    try {
      final completadas = await widget.almacenamiento.leerCompletadas();
      if (!mounted) return;
      setState(() {
        _completadas = completadas;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorLocal = true;
        _cargando = false;
      });
    }
  }

  Future<void> _completar(ActividadSemana actividad, bool valor) async {
    setState(() => _guardando.add(actividad.id));
    try {
      await widget.almacenamiento.guardarCompletada(actividad.id, valor);
      if (!mounted) return;
      setState(() {
        if (valor) {
          _completadas.add(actividad.id);
        } else {
          _completadas.remove(actividad.id);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el progreso. Intentá nuevamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando.remove(actividad.id));
    }
  }

  bool _completada(ActividadSemana actividad) =>
      actividad.esTarea && _completadas.contains(actividad.id);

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_errorLocal) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No se pudo leer tu progreso local.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _leerProgreso,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return StreamBuilder<List<ActividadSemana>>(
      stream: _actividades,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se pudieron cargar los avisos. Revisá tu conexión.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _actividades =
                          widget.actividades ??
                          FirestoreService().obtenerActividadesSemana();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final actividades = snapshot.data!;
        final ahora = DateTime.now();
        final pendientes = actividades
            .where((a) => a.esTarea && !_completada(a))
            .length;
        final proximas = actividades.where((a) {
          final dias = a.diasRestantes(ahora);
          return a.esEvaluacion && dias != null && dias >= 0 && dias < 7;
        }).length;
        final completadas = actividades.where(_completada).length;
        final vencidas = actividades
            .where((a) => a.vencida(ahora) && !_completada(a))
            .length;
        final visibles = ordenarActividades(
          actividades.where((a) {
            return switch (_filtro) {
              _Filtro.prioridades => !_completada(a),
              _Filtro.tareas => a.esTarea && !_completada(a),
              _Filtro.evaluaciones => a.esEvaluacion && !a.vencida(ahora),
              _Filtro.vencidas => a.vencida(ahora) && !_completada(a),
              _Filtro.completadas => _completada(a),
              _Filtro.sinFecha => a.esEvaluacion && a.fecha == null,
            };
          }),
        );
        final titulo = switch (_filtro) {
          _Filtro.prioridades => 'Tus prioridades',
          _Filtro.tareas => 'Tareas pendientes',
          _Filtro.evaluaciones => 'Próximas evaluaciones',
          _Filtro.vencidas => 'Actividades vencidas',
          _Filtro.completadas => 'Tareas completadas',
          _Filtro.sinFecha => 'Evaluaciones sin fecha',
        };
        return ListView.builder(
          key: const PageStorageKey('pendientes-semana'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: visibles.length + 1,
          itemBuilder: (context, index) {
            if (index > 0) return _tarjeta(visibles[index - 1], ahora);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi semana',
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Los mismos avisos, organizados para vos.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen semanal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _indicador(
                              '$pendientes',
                              'Tareas pendientes',
                              Colors.amber,
                            ),
                            _indicador(
                              '$proximas',
                              'Evaluaciones · 7 días',
                              Colors.redAccent,
                            ),
                            _indicador(
                              '$completadas',
                              'Completadas',
                              Colors.white70,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu progreso se guarda solo en este dispositivo.',
                  style: TextStyle(fontSize: 17, color: Colors.white60),
                ),
                if (snapshot.hasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No se pudo actualizar. Se muestran los últimos avisos disponibles.',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip(_Filtro.prioridades, 'Prioridades'),
                    _chip(_Filtro.tareas, 'Tareas'),
                    _chip(_Filtro.evaluaciones, 'Evaluaciones'),
                    _chip(_Filtro.vencidas, 'Vencidas ($vencidas)'),
                    _chip(_Filtro.completadas, 'Completadas'),
                    _chip(_Filtro.sinFecha, 'Sin fecha'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Exámenes ordenados por fecha. Las tareas se mantienen hasta que las completes.',
                  style: TextStyle(fontSize: 18, color: Colors.white60),
                ),
                const SizedBox(height: 12),
                if (visibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      actividades.isEmpty
                          ? 'No hay actividades para mostrar.'
                          : 'No hay actividades en esta sección.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _indicador(String valor, String etiqueta, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        valor,
        style: TextStyle(
          color: color,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        etiqueta,
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    ],
  );

  Widget _chip(_Filtro filtro, String texto) => ChoiceChip(
    label: Text(texto),
    selected: _filtro == filtro,
    selectedColor: Colors.amber.withValues(alpha: 0.22),
    onSelected: (_) => setState(() => _filtro = filtro),
  );

  Widget _tarjeta(ActividadSemana actividad, DateTime ahora) {
    final completada = _completada(actividad);
    final color = completada
        ? Colors.white54
        : actividad.vencida(ahora) || actividad.esEvaluacion
        ? Colors.redAccent
        : Colors.amber;
    return Card(
      key: ValueKey(actividad.id),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (actividad.esTarea)
              Checkbox(
                value: completada,
                semanticLabel:
                    'Completar tarea de ${actividad.materia}: ${actividad.descripcion}',
                activeColor: Colors.amber,
                onChanged: _guardando.contains(actividad.id)
                    ? null
                    : (valor) => _completar(actividad, valor ?? false),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 12),
                child: Icon(
                  actividad.esEvaluacion
                      ? Icons.event_note
                      : Icons.notifications_outlined,
                  color: color,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completada ? 'Tarea completada' : actividad.tipoTexto,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    actividad.materia,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      decoration: completada
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actividad.descripcion,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (actividad.esEvaluacion) ...[
                    const SizedBox(height: 10),
                    Text(
                      actividad.fechaTexto(ahora),
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
