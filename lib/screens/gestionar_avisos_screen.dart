import 'package:flutter/material.dart';
import '../core/app_bar_cuenta.dart';
import '../models/delegacion.dart';
import '../models/registro_aviso.dart';
import '../services/delegados_service.dart';
import '../services/firestore_service.dart';
import 'cargar_aviso_screen.dart';

class GestionarAvisosScreen extends StatefulWidget {
  const GestionarAvisosScreen({
    super.key,
    required this.delegacion,
    this.avisos,
    this.archivar,
  });
  final Delegacion delegacion;
  final Stream<List<RegistroAviso>>? avisos;
  final Future<void> Function(RegistroAviso)? archivar;
  @override
  State<GestionarAvisosScreen> createState() => _GestionarAvisosScreenState();
}

class _GestionarAvisosScreenState extends State<GestionarAvisosScreen> {
  late final Stream<List<RegistroAviso>> _avisos;
  bool _ocupado = false;
  String? _mensaje;
  @override
  void initState() {
    super.initState();
    _avisos =
        widget.avisos ??
        FirestoreService().registros(
          curso: widget.delegacion.curso,
          ciclo: widget.delegacion.ciclo,
        );
  }

  Future<void> _accion(Future<String> Function() accion) async {
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    try {
      final mensaje = await accion();
      if (mounted) setState(() => _mensaje = mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _mensaje =
              'No se confirmó el cambio. Revisá la conexión y tu permiso y volvé a intentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _archivar(RegistroAviso r) async {
    final aceptar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Archivar este aviso?'),
        content: Text(
          '${r.actividad.materia}: ${r.actividad.descripcion}\n\n'
          'Dejará de aparecer para todo el curso. El administrador podrá recuperarlo desde Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (aceptar == true) {
      await _accion(() async {
        if (widget.archivar != null) {
          await widget.archivar!(r);
          return 'Aviso archivado para todo el curso.';
        }
        await DelegadosService.instance.archivar(widget.delegacion, r);
        return 'Aviso archivado para todo el curso.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBarCuenta(title: const Text('Avisos del curso')),
    body: StreamBuilder<List<RegistroAviso>>(
      stream: _avisos,
      builder: (context, snapshot) {
        final registros = snapshot.data ?? [];
        final activos = registros.where((r) => !r.archivado).toList()
          ..sort(
            (a, b) => (a.contenido['fecha'] ?? '').toString().compareTo(
              (b.contenido['fecha'] ?? '').toString(),
            ),
          );
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${widget.delegacion.etiqueta} · ${widget.delegacion.ciclo}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Cargar tarea o evaluación'),
              onPressed: _ocupado
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CargarAvisoScreen(delegacion: widget.delegacion),
                      ),
                    ),
            ),
            if (_ocupado) const LinearProgressIndicator(),
            if (_mensaje != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_mensaje!),
              ),
            if (snapshot.hasError)
              const Text(
                'No se pudieron actualizar los avisos. Revisá la conexión.',
              ),
            if (!snapshot.hasData && !snapshot.hasError)
              const Center(child: CircularProgressIndicator()),
            if (snapshot.hasData && activos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No hay avisos activos para este curso.'),
              ),
            for (final r in activos)
              Card(
                child: ListTile(
                  title: Text(
                    '${r.actividad.materia} · ${r.actividad.tipoTexto}',
                  ),
                  subtitle: Text(
                    '${r.actividad.descripcion}\n${AvisoDelegado.dias[r.dia] ?? r.dia} · '
                    '${r.actividad.fechaTexto(DateTime.now())}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Archivar aviso',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: _ocupado ? null : () => _archivar(r),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Podés archivar cualquier aviso de tu curso, aunque lo haya cargado otro delegado. '
              'Los archivados se conservan para el administrador.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    ),
  );
}
