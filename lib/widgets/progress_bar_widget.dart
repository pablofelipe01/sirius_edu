import 'package:flutter/material.dart';

/// Barra de progreso visual para el alumno.
class ProgressBarWidget extends StatelessWidget {
  final int completed;
  final int total;
  final String label;
  final Color color;

  const ProgressBarWidget({
    super.key,
    required this.completed,
    required this.total,
    this.label = '',
    this.color = const Color(0xFF27AE60),
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 16,
            backgroundColor: const Color(0xFFECF0F1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$completed de $total completados',
          style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
        ),
      ],
    );
  }
}
