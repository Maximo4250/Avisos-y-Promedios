import 'package:flutter_application_2/core/app_bar_cuenta.dart';
import 'package:flutter_application_2/data/contexto_academico.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});
  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final _texto = TextEditingController();
  bool _enviando = false;
  String? _error;
  DocumentReference<Map<String, dynamic>>? _envio;
  Map<String, dynamic>? _contenidoEnvio;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final idea = _texto.text.trim();
    if (idea.length < 10) {
      setState(() => _error = 'Contanos tu idea con al menos 10 caracteres.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
    });
    // Reintentar el mismo mensaje usa el mismo documento y evita duplicados.
    if (_contenidoEnvio?['idea'] != idea) {
      _envio = FirebaseFirestore.instance.collection('ideas_app').doc();
      _contenidoEnvio = {
        'idea': idea,
        'curso': ContextoAcademico.instance.nombreCurso,
        'creada_en': Timestamp.now(),
        'estado': 'nueva',
      };
    }
    try {
      await _envio!.set(_contenidoEnvio!).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _texto.clear();
      _envio = null;
      _contenidoEnvio = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias! Tu idea fue enviada.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.code == 'permission-denied'
            ? 'El buzón todavía no está habilitado. Tu texto se conserva acá.'
            : 'No pudimos confirmar el envío. Revisá tu conexión y reintentá.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'No pudimos confirmar el envío. Tu texto se conserva para reintentar.',
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBarCuenta(
      title: const Text(
        'Ideas para A&P',
        style: TextStyle(color: Colors.black),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lightbulb_outline, size: 48, color: Colors.amber),
          const SizedBox(height: 18),
          const Text(
            '¿Qué te gustaría mejorar?',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Una función nueva, algo que te cuesta usar o una idea para organizarte mejor.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _texto,
            enabled: !_enviando,
            minLines: 5,
            maxLines: 9,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Tu idea',
              alignLabelWithHint: true,
              hintText: 'Me gustaría que la app…',
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: 4,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_enviando ? 'Enviando…' : 'Enviar idea'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Se enviará el texto y tu curso al creador de A&P. No hace falta incluir tu nombre ni datos personales.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}
