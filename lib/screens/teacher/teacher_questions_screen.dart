import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';

/// Profesor ve preguntas pendientes de alumnos y responde vía mesh → gateway → Supabase.
class TeacherQuestionsScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String teacherName;

  const TeacherQuestionsScreen({super.key, required this.meshService, required this.teacherName});

  @override
  State<TeacherQuestionsScreen> createState() => _TeacherQuestionsScreenState();
}

class _TeacherQuestionsScreenState extends State<TeacherQuestionsScreen> {
  final _responseControllers = <String, TextEditingController>{};
  bool _syncing = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.meshService.pendingQuestionStream.listen((_) {
      if (mounted) setState(() {});
    });
    _requestQuestions();
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final c in _responseControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _requestQuestions() {
    if (!widget.meshService.isConnected) return;
    setState(() => _syncing = true);
    widget.meshService.requestSync('questions');
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _syncing = false);
    });
  }

  void _respond(String questionId) {
    final controller = _responseControllers[questionId];
    if (controller == null || controller.text.trim().isEmpty) return;

    widget.meshService.respondToQuestion(questionId, controller.text.trim());
    controller.clear();

    // Remover de la lista local
    widget.meshService.pendingQuestions.removeWhere((q) => q['id'] == questionId);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Respuesta enviada'), backgroundColor: Color(0xFF27AE60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.meshService.pendingQuestions;

    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No hay preguntas pendientes',
                style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D))),
            const SizedBox(height: 16),
            _syncing
                ? const CircularProgressIndicator(color: Color(0xFF2980B9))
                : OutlinedButton.icon(
                    onPressed: _requestQuestions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Buscar preguntas'),
                  ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        final qId = q['id'] ?? '';
        _responseControllers.putIfAbsent(qId, () => TextEditingController());

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Color(0xFF2980B9)),
                    const SizedBox(width: 6),
                    Text(q['student_name'] ?? 'Alumno',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2980B9))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(q['question'] ?? '',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _responseControllers[qId],
                        decoration: InputDecoration(
                          hintText: 'Tu respuesta...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _respond(qId),
                      icon: const Icon(Icons.send),
                      color: const Color(0xFF27AE60),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
