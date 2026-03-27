import 'package:flutter/material.dart';
import 'package:sirius_edu/models/lesson.dart';

/// Tarjeta visual para mostrar una lección activa.
class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;
  final VoidCallback? onAskTutor;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.onAskTutor,
  });

  IconData _subjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'ciencias_naturales':
      case 'ciencias naturales':
        return Icons.science;
      case 'matematicas':
      case 'matemáticas':
        return Icons.calculate;
      case 'lenguaje':
        return Icons.menu_book;
      case 'ciencias_sociales':
      case 'ciencias sociales':
        return Icons.public;
      default:
        return Icons.school;
    }
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'ciencias_naturales':
      case 'ciencias naturales':
        return const Color(0xFF27AE60);
      case 'matematicas':
      case 'matemáticas':
        return const Color(0xFF2980B9);
      case 'lenguaje':
        return const Color(0xFFE67E22);
      case 'ciencias_sociales':
      case 'ciencias sociales':
        return const Color(0xFF8E44AD);
      default:
        return const Color(0xFF2980B9);
    }
  }

  String _subjectLabel(String subject) {
    switch (subject.toLowerCase()) {
      case 'ciencias_naturales':
        return 'Ciencias Naturales';
      case 'matematicas':
        return 'Matemáticas';
      case 'lenguaje':
        return 'Lenguaje';
      case 'ciencias_sociales':
        return 'Ciencias Sociales';
      default:
        return subject;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(lesson.subject);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con color de materia
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_subjectIcon(lesson.subject), color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _subjectLabel(lesson.subject),
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Resumen
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                lesson.summary,
                style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.4),
              ),
            ),
            // Botones
            if (onAskTutor != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAskTutor,
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('Preguntarle al Tutor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
