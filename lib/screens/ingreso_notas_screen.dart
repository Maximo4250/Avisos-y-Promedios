import '../core/app_theme.dart';
import 'package:flutter_application_2/core/app_bar_cuenta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/nota_utils.dart';
import 'package:flutter_application_2/models/materia.dart';
import 'package:flutter_application_2/screens/promedio_screen.dart';
import 'package:flutter_application_2/services/db_helper.dart';

class IngresoNotasScreen extends StatefulWidget {
  final Materia materia;

  const IngresoNotasScreen({super.key, required this.materia});

  @override
  State<IngresoNotasScreen> createState() => _IngresoNotasScreenState();
}

class _IngresoNotasScreenState extends State<IngresoNotasScreen> {
  final TextEditingController _notaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    DatabaseHelper.cambios.addListener(_recargar);
  }

  Future<void> _recargar() async {
    final materias = await DatabaseHelper.instance.obtenerMaterias();
    final actual = materias.where((m) => m.id == widget.materia.id);
    if (!mounted || actual.isEmpty) return;
    setState(() {
      widget.materia.notas
        ..clear()
        ..addAll(actual.first.notas);
    });
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregarNota() async {
    final nota = double.tryParse(_notaController.text);

    // Se escribe en positivo a propósito: así también se rechaza NaN.
    if (nota == null || !(nota >= 0 && nota <= 10)) {
      _mostrarMensaje('Ingresa una nota válida (0 a 10)');
      return;
    }

    final id = widget.materia.id;
    if (id != null) await DatabaseHelper.instance.insertarNota(id, nota);
    if (!mounted) return;

    setState(() {
      // La lista se vuelve a leer desde la base local.
      _notaController.clear();
    });
  }

  Future<void> _borrarNota(int index, double nota) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final id = widget.materia.id;
    if (id != null) await DatabaseHelper.instance.eliminarNota(id, nota);
    if (!mounted) return;

    await _recargar();
  }

  void _mostrarOpcionesNota(int index, double nota) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Expanded(
              child: Text(
                'Nota ${index + 1} de ${widget.materia.nombre} ($nota)',
              ),
            ),
            TextButton(
              onPressed: () => _borrarNota(index, nota),
              child: const Text('BORRAR', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _irAResultado() {
    ScaffoldMessenger.of(context).clearSnackBars();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadoScreen(materia: widget.materia),
      ),
    );
  }

  @override
  void dispose() {
    DatabaseHelper.cambios.removeListener(_recargar);
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notas = widget.materia.notas;

    return Scaffold(
      appBar: AppBarCuenta(
        title: Text(
          'Notas: ${widget.materia.nombre}',
          style: TextStyle(color: AppTheme.sobreAcento),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _notaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ingrese una nota',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _agregarNota,
                  child: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: notas.isEmpty
                  ? const Center(child: Text('No hay notas ingresadas'))
                  : ListView.builder(
                      itemCount: notas.length,
                      itemBuilder: (context, index) {
                        final nota = notas[index];

                        return ListTile(
                          key: ValueKey('nota-$index-$nota'),
                          leading: CircleAvatar(
                            backgroundColor: colorSegunNota(nota),
                            foregroundColor: Colors.black,
                            child: Text('${index + 1}'),
                          ),
                          title: Text('Nota: $nota'),
                          onTap: () => _mostrarOpcionesNota(index, nota),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _irAResultado,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Datos e historia'),
            ),
          ),
        ),
      ),
    );
  }
}
