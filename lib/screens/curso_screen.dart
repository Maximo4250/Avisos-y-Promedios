import 'package:flutter_application_2/core/app_theme.dart';
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
    Theme.of(
      context,
    ); // Actualizar también los acentos de las pantallas abiertas.
    final sesion = SesionService.instance;
    final c = ContextoAcademico.instance;
    return Scaffold(
      appBar: AppBarCuenta(
        title: Text('Cursos', style: TextStyle(color: AppTheme.sobreAcento)),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'Ciclo lectivo ${c.ciclo}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            sesion.conCuenta
                ? 'Podés explorar otros cursos. Tus notificaciones siguen siendo de tu curso asignado; cambialo desde Cuenta.'
                : 'El curso que elijas queda guardado y determina los avisos que recibís.',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 20),
          if (_cargando) LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: TextStyle(color: AppTheme.detalle)),
          for (final course in sesion.cursos)
            Card(
              child: ListTile(
                leading: Icon(Icons.school_outlined, color: AppTheme.detalle),
                title: Text(course['nombre'] as String),
                subtitle: Text(
                  sesion.conCuenta && course['id'] == sesion.cursoAsignado
                      ? 'Mi curso asignado'
                      : 'Disponible',
                ),
                trailing: course['id'] == c.curso
                    ? Icon(Icons.check, color: AppTheme.detalle)
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
          SizedBox(height: 16),
          Text(
            'Actualmente solo está habilitado 4to B.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
