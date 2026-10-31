import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/app_bar_cuenta.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:flutter_application_2/services/sesion_service.dart';

class CursoScreen extends StatefulWidget {
  const CursoScreen({super.key});
  @override
  State<CursoScreen> createState() => _CursoScreenState();
}

class _CursoScreenState extends State<CursoScreen> {
  bool _cargando = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      await SesionService.instance.cargarCursos();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Mostrando los cursos guardados. No se pudo actualizar el catálogo.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = SesionService.instance;
    final c = ContextoAcademico.instance;
    return Scaffold(
      appBar: AppBarCuenta(
        title: const Text('Cursos', style: TextStyle(color: Colors.black))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Ciclo lectivo ${c.ciclo}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            sesion.conCuenta
                ? 'Podés explorar otros cursos. Tus notificaciones siguen siendo de tu curso asignado; cambialo desde Cuenta.'
                : 'El curso que elijas queda guardado y determina los avisos que recibís.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          if (_cargando) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.amber)),
          for (final course in sesion.cursos)
            Card(
              child: ListTile(
                leading: const Icon(Icons.school_outlined, color: Colors.amber),
                title: Text(course['nombre'] as String),
                subtitle: Text(
                  sesion.conCuenta && course['id'] == sesion.cursoAsignado
                      ? 'Mi curso asignado'
                      : 'Disponible',
                ),
                trailing: course['id'] == c.curso
                    ? const Icon(Icons.check, color: Colors.amber)
                    : null,
                onTap: () => sesion.verCurso(course['id'] as String).catchError(
                  (Object e) {
                    if (mounted) {
                      setState(
                        () => _error =
                            'No se pudo abrir ese curso. Intentá nuevamente.',
                      );
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Actualmente solo está habilitado 4to B.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
