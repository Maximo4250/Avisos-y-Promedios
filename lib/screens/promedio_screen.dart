import 'package:flutter_application_2/core/app_bar_cuenta.dart';
import 'package:flutter_application_2/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/constants.dart';
import 'package:flutter_application_2/core/nota_utils.dart';
import 'package:flutter_application_2/core/tendencia_notas.dart';
import 'package:flutter_application_2/data/resumen_horario.dart';
import 'package:flutter_application_2/models/materia.dart';

class ResultadoScreen extends StatelessWidget {
  final Materia materia;
  const ResultadoScreen({super.key, required this.materia});

  @override
  Widget build(BuildContext context) {
    final cursadas = cursadasDeMateria(materia.nombre);
    return Scaffold(
      appBar: AppBarCuenta(
        title: Text(
          'Datos e historia - ${materia.nombre}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final historia = _historia();
            final datos = _datos(cursadas);
            if (constraints.maxWidth < 650) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [historia, const SizedBox(height: 16), datos],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: historia),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: datos),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _datos(List<CursadaMateria> cursadas) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cursada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (cursadas.isEmpty)
              const Text('Esta materia no tiene un horario registrado.')
            else ...[
              const Text(
                'Carga semanal estimada',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                duracionSemanal(cursadas),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Días y horarios',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final cursada in cursadas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${cursada.dia}: ${cursada.inicio} – ${cursada.fin}',
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Calculado hasta la siguiente clase o la salida. Puede incluir recreos.',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 12),
              _PendientesMateria(
                key: ValueKey(materia.nombre),
                materia: materia.nombre,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historia() {
    final notas = materia.notas;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Historia de notas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (notas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Agregá notas para ver el gráfico de evolución.',
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Text(
                'Promedio: ${materia.promedio.toStringAsFixed(2)} '
                '(${estaAprobada(materia.promedio) ? 'Aprobado' : 'Desaprobado'})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorSegunNota(materia.promedio),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 10,
                    minX: 1,
                    maxX: notas.length > 1 ? notas.length.toDouble() : 2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < notas.length; i++)
                            FlSpot((i + 1).toDouble(), notas[i]),
                        ],
                        color: Colors.amber,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: spot.y < kUmbralPuntoGrafico
                                  ? Colors.red
                                  : Colors.green,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text('Calificación'),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 2,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text('Nota'),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Tooltip(
                message:
                    'Tendencia de hasta las últimas 5 notas, en orden de carga. '
                    'Los cambios menores a 0,25 puntos se consideran estables.',
                child: Text(
                  tendenciaNotas(notas),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendientesMateria extends StatefulWidget {
  final String materia;
  const _PendientesMateria({super.key, required this.materia});
  @override
  State<_PendientesMateria> createState() => _PendientesMateriaState();
}

class _PendientesMateriaState extends State<_PendientesMateria> {
  late final Stream<List<Map<String, dynamic>>> _avisos;
  @override
  void initState() {
    super.initState();
    _avisos = FirestoreService().obtenerAvisosPorMateria(widget.materia);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _avisos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'No se pudieron consultar los pendientes.',
            style: TextStyle(fontSize: 13, color: Colors.amber),
          );
        }
        if (!snapshot.hasData) {
          return const Text(
            'Consultando pendientes…',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          );
        }
        final avisos = snapshot.data!;
        final tareas = avisos.where((a) => a['tipo'] == 'tarea').length;
        final examenes = avisos
            .where((a) => (a['tipo'] ?? 'evaluacion') == 'evaluacion')
            .length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tareas == 0
                  ? 'Sin tareas pendientes'
                  : '$tareas ${tareas == 1 ? 'tarea pendiente' : 'tareas pendientes'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tareas == 0 ? Colors.greenAccent : Colors.amber,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              examenes == 0
                  ? 'Sin exámenes pendientes'
                  : '$examenes ${examenes == 1 ? 'examen pendiente' : 'exámenes pendientes'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: examenes == 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        );
      },
    );
  }
}
