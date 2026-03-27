import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../../widgets/lesson_card.dart';

class LessonScreen extends StatelessWidget {
  final MeshtasticService meshService;

  const LessonScreen({super.key, required this.meshService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meshService,
      builder: (context, _) {
        final lesson = meshService.activeLesson;

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
                  const Text('Tu profesor enviara una leccion pronto',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF95A5A6))),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => meshService.sendToGateway('SYNC_REQ|lesson_active|0'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Buscar leccion'),
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
              LessonCard(
                lesson: lesson,
                onAskTutor: () {
                  // Navegar al tab de tutor (index 1 en StudentMainScreen)
                  // Se maneja via el parent NavigationBar
                },
              ),
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
                            Text('Contenido de la leccion',
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
              if (meshService.assignments.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assignment),
                  label: Text('Tienes ${meshService.assignments.length} tarea(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
