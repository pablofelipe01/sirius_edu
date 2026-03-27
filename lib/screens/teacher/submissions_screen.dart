import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';

class SubmissionsScreen extends StatefulWidget {
  final MeshtasticService meshService;

  const SubmissionsScreen({super.key, required this.meshService});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final _criteriaController = TextEditingController();
  final _gradeController = TextEditingController();

  @override
  void dispose() {
    _criteriaController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.meshService,
      builder: (context, _) {
        final submissions = widget.meshService.submissions;

        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grading, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Sin entregas pendientes',
                    style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D))),
                const SizedBox(height: 8),
                const Text('Las entregas apareceran cuando los alumnos respondan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF95A5A6))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final s = submissions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: s.aiScore != null
                      ? const Color(0xFF27AE60).withValues(alpha: 0.15)
                      : const Color(0xFFE67E22).withValues(alpha: 0.15),
                  child: Text(
                    s.aiScore != null ? s.aiScore!.toStringAsFixed(0) : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: s.aiScore != null ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                    ),
                  ),
                ),
                title: Text('Alumno: ${s.studentId}'),
                subtitle: Text(
                  'Tarea: ${s.assignmentId} - ${s.submittedAt.day}/${s.submittedAt.month}',
                  style: const TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Respuesta del alumno:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(s.response),

                        if (s.aiFeedback != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Evaluacion IA:',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2980B9))),
                                Text(s.aiFeedback!),
                                if (s.aiScore != null)
                                  Text('Puntaje: ${s.aiScore}/10',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        TextField(
                          controller: _criteriaController,
                          decoration: const InputDecoration(
                            labelText: 'Tu criterio como profesor',
                            hintText: 'Escribe tu evaluacion...',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _gradeController,
                          decoration: const InputDecoration(
                            labelText: 'Nota final',
                            hintText: 'Ej: Excelente, Bien, Por mejorar',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final criteria = _criteriaController.text.trim();
                              final grade = _gradeController.text.trim();
                              if (criteria.isEmpty || grade.isEmpty) return;

                              widget.meshService.sendTeacherEvaluation(
                                s.assignmentId,
                                s.studentId,
                                criteria,
                                grade,
                              );
                              _criteriaController.clear();
                              _gradeController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Evaluacion enviada'),
                                    backgroundColor: Color(0xFF27AE60)),
                              );
                            },
                            icon: const Icon(Icons.send),
                            label: const Text('Enviar evaluacion final'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2980B9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
