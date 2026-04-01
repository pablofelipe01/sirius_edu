import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../../widgets/lesson_card.dart';

class LessonScreen extends StatefulWidget {
  final MeshtasticService meshService;
  const LessonScreen({super.key, required this.meshService});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _requestLessons();
  }

  void _requestLessons() {
    if (!widget.meshService.isConnected) return;
    setState(() => _syncing = true);
    widget.meshService.requestSync('lessons');
    // El gateway responde con LECCION| que se maneja en MeshtasticService
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _syncing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.meshService,
      builder: (context, _) {
        final lesson = widget.meshService.activeLesson;

        if (lesson == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No hay leccion activa',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D))),
                  const SizedBox(height: 8),
                  Text(
                    _syncing ? 'Buscando lecciones...' : 'Pide tus lecciones al gateway',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6)),
                  ),
                  const SizedBox(height: 24),
                  _syncing
                      ? const CircularProgressIndicator(color: Color(0xFF27AE60))
                      : OutlinedButton.icon(
                          onPressed: _requestLessons,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Buscar lecciones'),
                        ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LessonCard(lesson: lesson),
              if (lesson.fullContent.isNotEmpty && lesson.fullContent != lesson.summary) ...[
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.article, color: Color(0xFF2980B9)),
                            SizedBox(width: 8),
                            Text('Contenido',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(lesson.fullContent,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _requestLessons,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar lecciones'),
              ),
            ],
          ),
        );
      },
    );
  }
}
