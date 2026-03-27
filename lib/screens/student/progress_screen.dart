import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../../widgets/progress_bar_widget.dart';

class ProgressScreen extends StatelessWidget {
  final MeshtasticService meshService;
  final String studentName;

  const ProgressScreen({super.key, required this.meshService, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meshService,
      builder: (context, _) {
        final totalAssignments = meshService.assignments.length;
        final completed = meshService.assignments
            .where((a) => a.status.index >= 2) // aiEvaluated o fullyEvaluated
            .length;
        final lesson = meshService.activeLesson;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Card(
                color: const Color(0xFF27AE60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 48, color: Colors.white),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sigue asi, $studentName!',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            const Text('Tu progreso esta semana',
                                style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Progreso de tareas
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProgressBarWidget(
                    completed: completed,
                    total: totalAssignments > 0 ? totalAssignments : 1,
                    label: 'Tareas completadas',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Estadísticas simples
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assignment_turned_in,
                      value: '$completed',
                      label: 'Tareas\nhechas',
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.smart_toy,
                      value: '${meshService.messageHistory.length}',
                      label: 'Preguntas\nal tutor',
                      color: const Color(0xFF2980B9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star,
                      value: completed > 0 ? '$completed' : '0',
                      label: 'Estrellas\nganadas',
                      color: const Color(0xFFE67E22),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Materia actual
              if (lesson != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2980B9).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.science, color: Color(0xFF2980B9)),
                    ),
                    title: const Text('Aprendiendo ahora'),
                    subtitle: Text(lesson.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                  ),
                ),

              const SizedBox(height: 16),

              // Estrellas visuales
              if (completed > 0)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tus estrellas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: List.generate(
                            completed,
                            (_) => const Icon(Icons.star, color: Color(0xFFF39C12), size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D))),
          ],
        ),
      ),
    );
  }
}
