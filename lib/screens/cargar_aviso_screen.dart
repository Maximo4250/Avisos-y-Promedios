import 'package:flutter/material.dart';
import '../core/app_bar_cuenta.dart';
import '../data/contexto_academico.dart';
import '../data/horario_data.dart';
import '../models/delegacion.dart';
import '../models/identidad_instalacion.dart';
import '../services/delegados_service.dart';

class CargarAvisoScreen extends StatefulWidget {
  const CargarAvisoScreen({
    super.key,
    required this.delegacion,
    this.publicar,
    this.materias,
  });
  final Delegacion delegacion;
  final Future<void> Function(AvisoDelegado)? publicar;
  final List<String>? materias;
  @override
  State<CargarAvisoScreen> createState() => _CargarAvisoScreenState();
}

class _CargarAvisoScreenState extends State<CargarAvisoScreen> {
  final _detalle = TextEditingController();
  String _id = IdentidadInstalacion.nueva().id;
  String? _materia, _error;
  String _tipo = 'tarea', _dia = 'Lu';
  DateTime? _fecha;
  bool _enviando = false, _listo = false;
  late final List<DiaEscolar> _horario;
  List<String> get _materias {
    final materias =
        widget.materias?.toList() ??
        _horario
            .where((d) => d.codigo == _dia)
            .expand((d) => d.clases)
            .map((c) => c.materia)
            .toSet()
            .toList();
    materias.sort();
    return materias;
  }

  @override
  void initState() {
    super.initState();
    final d = widget.delegacion, c = ContextoAcademico.instance;
    _horario = d.curso == '4b' && d.ciclo == 2026
        ? horarioCuartoB
        : (c.curso == d.curso && c.ciclo == d.ciclo ? diasEscolares : []);
  }

  void _cambiarDia(String dia) {
    setState(() {
      _dia = dia;
      if (!_materias.contains(_materia)) _materia = null;
      _fecha = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final inicio = ahora.year == widget.delegacion.ciclo
        ? ahora
        : DateTime(widget.delegacion.ciclo);
    final weekday = AvisoDelegado.dias.keys.toList().indexOf(_dia) + 1;
    var inicial = DateTime(inicio.year, inicio.month, inicio.day);
    while (inicial.weekday != weekday) {
      inicial = inicial.add(const Duration(days: 1));
    }
    if (inicial.year != widget.delegacion.ciclo) {
      inicial = DateTime(widget.delegacion.ciclo, 12, 31);
      while (inicial.weekday != weekday) {
        inicial = inicial.subtract(const Duration(days: 1));
      }
    }
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? inicial,
      selectableDayPredicate: (date) => date.weekday == weekday,
      helpText: 'Elegí una fecha para ${AvisoDelegado.dias[_dia]}',
      firstDate: DateTime(widget.delegacion.ciclo),
      lastDate: DateTime(widget.delegacion.ciclo, 12, 31),
    );
    if (f != null && mounted) {
      setState(() {
        _fecha = f;
      });
    }
  }

  Future<void> _publicar() async {
    final aviso = AvisoDelegado(
      id: _id,
      materia: _materia ?? '',
      tipo: _tipo,
      detalle: _detalle.text,
      dia: _dia,
      fecha: _fecha,
    );
    final error = aviso.validar();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      if (widget.publicar != null) {
        await widget.publicar!(aviso);
      } else {
        await DelegadosService.instance.publicar(widget.delegacion, aviso);
      }
      if (mounted) setState(() => _listo = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is StateError
              ? e.message
              : 'No se confirmó la publicación. Revisá conexión y permiso; podés reintentar sin duplicar el aviso.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBarCuenta(title: const Text('Cargar aviso')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Delegado · ${widget.delegacion.etiqueta} · ${widget.delegacion.ciclo}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_listo) ...[
          const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: Colors.greenAccent,
          ),
          const Text(
            'Aviso publicado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
          const Text(
            'Ya aparece en el horario, el calendario y los pendientes del curso.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {
              _listo = false;
              _id = IdentidadInstalacion.nueva().id;
              _detalle.clear();
            }),
            child: const Text('Cargar otro aviso'),
          ),
        ] else ...[
          DropdownButtonFormField<String>(
            initialValue: _dia,
            decoration: const InputDecoration(labelText: 'Día en el horario'),
            items: AvisoDelegado.dias.entries
                .take(5)
                .map(
                  (d) => DropdownMenuItem(value: d.key, child: Text(d.value)),
                )
                .toList(),
            onChanged: _enviando ? null : (v) => _cambiarDia(v!),
          ),
          const SizedBox(height: 16),
          if (_materias.isEmpty)
            const Text(
              'No hay materias en el horario de este día. Elegí otro día; si falta el horario, consultá al administrador.',
            ),
          DropdownButtonFormField<String>(
            key: ValueKey('materia_$_dia'),
            initialValue: _materia,
            decoration: const InputDecoration(labelText: 'Materia'),
            items: _materias
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: _enviando ? null : (v) => setState(() => _materia = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo de aviso'),
            items: const [
              DropdownMenuItem(value: 'tarea', child: Text('Tarea')),
              DropdownMenuItem(value: 'evaluacion', child: Text('Evaluación')),
            ],
            onChanged: _enviando ? null : (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detalle,
            enabled: !_enviando,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: '¿Qué hay que hacer o estudiar?',
              hintText: 'Por ejemplo: resolver ejercicios 1 al 5',
            ),
          ),
          OutlinedButton.icon(
            onPressed: _enviando ? null : _elegirFecha,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _fecha == null
                  ? (_tipo == 'evaluacion'
                        ? 'Fecha de evaluación · obligatoria'
                        : 'Fecha de entrega · opcional')
                  : '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}',
            ),
          ),
          if (_fecha != null && _tipo != 'evaluacion')
            TextButton(
              onPressed: _enviando ? null : () => setState(() => _fecha = null),
              child: const Text('Dejar sin fecha'),
            ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ElevatedButton.icon(
            onPressed: _enviando || _materias.isEmpty ? null : _publicar,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish),
            label: Text(_enviando ? 'Publicando…' : 'Publicar para el curso'),
          ),
          const SizedBox(height: 12),
          const Text(
            'El aviso será visible para todo el curso. Necesitás conexión para confirmar la publicación.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ],
    ),
  );
}
