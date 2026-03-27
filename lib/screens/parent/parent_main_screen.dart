import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../../widgets/progress_bar_widget.dart';

class ParentMainScreen extends StatelessWidget {
  final MeshtasticService meshService;
  final String parentName;

  const ParentMainScreen({super.key, required this.meshService, required this.parentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso de tu hijo'),
        backgroundColor: const Color(0xFFE67E22),
        actions: [
          ListenableBuilder(
            listenable: meshService,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                meshService.isConnected ? Icons.cell_tower : Icons.signal_cellular_off,
                color: meshService.isConnected ? Colors.white : Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: meshService,
        builder: (context, _) {
          final lesson = meshService.activeLesson;
          final total = meshService.assignments.length;
          final completed = meshService.assignments.where((a) => a.status.index >= 2).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del hijo
                Card(
                  color: const Color(0xFFE67E22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.school, size: 40, color: Colors.white),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(parentName,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text('Estudiante',
                                style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Progreso semanal
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Esta semana',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 12),
                        ProgressBarWidget(
                          completed: completed,
                          total: total > 0 ? total : 1,
                          label: 'Ejercicios completados',
                          color: const Color(0xFFE67E22),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                      title: const Text('Aprendiendo'),
                      subtitle: Text(lesson.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                    ),
                  ),

                const SizedBox(height: 16),

                // Preguntas al tutor
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chat, color: Color(0xFF27AE60)),
                    ),
                    title: const Text('Preguntas al tutor'),
                    subtitle: Text('${meshService.messageHistory.length} preguntas esta semana',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 24),

                // Sugerencia para el hogar
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: const Color(0xFFFFF9E6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Color(0xFFE67E22)),
                            SizedBox(width: 8),
                            Text('Para ayudar en casa',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson != null
                              ? 'Pida a su hijo que le explique que es "${lesson.title}". '
                                'Cuando un nino explica lo que aprendio, lo recuerda mejor.'
                              : 'Pregunte a su hijo que aprendio hoy en la escuela y escuchelo con atencion.',
                          style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
