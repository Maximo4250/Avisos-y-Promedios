import 'package:flutter_application_2/core/app_theme.dart';
import 'package:flutter_application_2/core/app_bar_cuenta.dart';
import 'package:flutter_application_2/core/tendencia_notas.dart';
import 'package:flutter/material.dart';
import '../services/sincronizacion_notas.dart';
import 'package:flutter_application_2/core/nota_utils.dart';
import 'package:flutter_application_2/models/materia.dart';
import 'package:flutter_application_2/screens/horario_screen.dart';
import 'package:flutter_application_2/screens/ingreso_notas_screen.dart';
import 'package:flutter_application_2/services/db_helper.dart';
import 'package:flutter_application_2/services/verificador_firebase.dart';

class MateriasScreen extends StatefulWidget {
  final bool enBarra;
  const MateriasScreen({super.key, this.enBarra = false});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  List<Materia> _materias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
    DatabaseHelper.cambios.addListener(_cargarMaterias);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VerificadorFirebase.comprobarActualizacion(context);
    });
  }

  /// Carga las materias (con sus notas) desde SQLite.
  Future<void> _cargarMaterias() async {
    final materiasDB = await DatabaseHelper.instance.obtenerMaterias();
    if (!mounted) return;
    setState(() {
      _materias = materiasDB;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    DatabaseHelper.cambios.removeListener(_cargarMaterias);
    super.dispose();
  }

  void _ordenarPorPromedio() {
    setState(() => _materias.sort((a, b) => b.promedio.compareTo(a.promedio)));
  }

  void _abrirHorario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiaSemana()),
    );
  }

  void _abrirNotas(Materia materia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngresoNotasScreen(materia: materia),
      ),
    ).then((_) => _cargarMaterias()); // Recarga los datos al regresar
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    final promedioGeneral = calcularPromedioGeneral(_materias);

    return Scaffold(
      appBar: AppBarCuenta(
        title: Text(
          'Mis Materias',
          style: TextStyle(color: AppTheme.sobreAcento),
        ),
        backgroundColor: AppTheme.acento,
        automaticallyImplyLeading: false,
        leadingWidth: widget.enBarra ? 100 : 300,
        leading: widget.enBarra
            ? IconButton(
                icon: Icon(Icons.bar_chart),
                tooltip: 'Ordenar por mayor promedio',
                onPressed: _ordenarPorPromedio,
              )
            : Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: AppTheme.detalle,
                    ),
                    onPressed: _abrirHorario,
                    child: Text('Dias Semana'),
                  ),
                  IconButton(
                    icon: Icon(Icons.bar_chart, size: 38),
                    tooltip: 'Ordenar por mayor promedio',
                    onPressed: _ordenarPorPromedio,
                  ),
                ],
              ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(42),
          child: Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Center(
              child: Container(
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Promedio Final: ${promedioGeneral.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colorSegunNota(promedioGeneral),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<String>(
        valueListenable: SincronizacionNotas.instance.estado,
        builder: (context, texto, _) => TextButton.icon(
          onPressed: SincronizacionNotas.instance.reintentar,
          icon: Icon(Icons.cloud_sync_outlined, size: 16),
          label: Text(texto, style: TextStyle(fontSize: 12)),
        ),
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _materias.length,
              itemBuilder: (context, index) {
                final materia = _materias[index];
                final totalNotas = materia.notas.length;
                final aprobadas = materia.notas.where(estaAprobada).length;
                final aRecuperar = totalNotas - aprobadas;
                final color = totalNotas == 0
                    ? Colors.white70
                    : colorSegunNota(materia.promedio);

                return Card(
                  margin: EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: Icon(Icons.book, color: color),
                    title: Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          materia.nombre,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$totalNotas ${totalNotas == 1 ? 'nota' : 'notas'}',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        if (materia.esDoble)
                          Text(
                            'Peso doble',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.detalle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: totalNotas == 0
                          ? Text('Sin notas cargadas')
                          : Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Aprobadas: $aprobadas',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'A recuperar: $aRecuperar',
                                  style: TextStyle(
                                    color: aRecuperar > 0
                                        ? AppTheme.detalle
                                        : Colors.white70,
                                    fontWeight: aRecuperar > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  tendenciaNotas(materia.notas),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Promedio',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                        Text(
                          totalNotas == 0
                              ? '—'
                              : materia.promedio.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _abrirNotas(materia),
                  ),
                );
              },
            ),
    );
  }
}
