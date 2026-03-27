import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/lesson.dart';
import '../../models/assignment.dart';
import '../../services/meshtastic_service.dart';

class CreateLessonScreen extends StatefulWidget {
  final MeshtasticService meshService;

  const CreateLessonScreen({super.key, required this.meshService});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _uuid = const Uuid();

  String _selectedSubject = 'ciencias_naturales';
  String _selectedGrade = '2';
  bool _sending = false;

  final _subjects = {
    'ciencias_naturales': 'Ciencias Naturales',
    'matematicas': 'Matematicas',
    'lenguaje': 'Lenguaje',
    'ciencias_sociales': 'Ciencias Sociales',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _sendLesson() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa titulo y contenido')),
      );
      return;
    }

    setState(() => _sending = true);

    final summary = content.length > 180 ? '${content.substring(0, 177)}...' : content;
    final lesson = Lesson(
      id: _uuid.v4().substring(0, 8),
      subject: _selectedSubject,
      grade: _selectedGrade,
      title: title,
      summary: summary,
      fullContent: content,
      createdAt: DateTime.now(),
    );

    await widget.meshService.sendLesson(lesson);
    await widget.meshService.storage.saveLesson(lesson);

    if (!mounted) return;
    setState(() => _sending = false);
    _titleController.clear();
    _contentController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leccion enviada a la clase'), backgroundColor: Color(0xFF27AE60)),
    );
  }

  void _askAISuggestion() {
    final subject = _subjects[_selectedSubject] ?? _selectedSubject;
    widget.meshService.sendAIQuestion(
      'profesor',
      '0',
      'Sugiere una leccion corta de $subject para grado $_selectedGrade. '
          'Incluye titulo, resumen de 2 oraciones y 3 puntos clave. '
          'Contexto: estudiantes rurales de Colombia.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pidiendo sugerencia a la IA...'), backgroundColor: Color(0xFF2980B9)),
    );
  }

  void _createAssignment() {
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear tarea'),
        content: TextField(
          controller: descController,
          decoration: const InputDecoration(hintText: 'Descripcion de la tarea'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final desc = descController.text.trim();
              if (desc.isNotEmpty) {
                final assignment = Assignment(
                  id: _uuid.v4().substring(0, 8),
                  description: desc,
                );
                widget.meshService.storage.saveAssignment(assignment);
                // Broadcast tarea por mesh
                widget.meshService.sendMessage(
                  'TAREA|${assignment.id}||$desc|',
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tarea creada y enviada'), backgroundColor: Color(0xFF27AE60)),
                );
              }
              descController.dispose();
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Materia
          DropdownButtonFormField<String>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Materia'),
            items: _subjects.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _selectedSubject = v!),
          ),
          const SizedBox(height: 12),

          // Grado
          DropdownButtonFormField<String>(
            initialValue: _selectedGrade,
            decoration: const InputDecoration(labelText: 'Grado'),
            items: List.generate(5, (i) => '${i + 1}')
                .map((g) => DropdownMenuItem(value: g, child: Text('$g° Grado')))
                .toList(),
            onChanged: (v) => setState(() => _selectedGrade = v!),
          ),
          const SizedBox(height: 12),

          // Titulo
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titulo de la leccion'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),

          // Contenido
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Contenido',
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _askAISuggestion,
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Sugerencia IA'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _createAssignment,
                  icon: const Icon(Icons.assignment_add),
                  label: const Text('Crear tarea'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendLesson,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: const Text('Enviar a clase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2980B9),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
