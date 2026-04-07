import 'package:flutter/material.dart';
import '../../models/assignment.dart';
import '../../services/meshtastic_service.dart';

class ProgressScreen extends StatelessWidget {
  final MeshtasticService meshService;
  final String studentName;

  const ProgressScreen({super.key, required this.meshService, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meshService,
      builder: (context, _) {
        final lessonCount = meshService.lessons.length;
        final assignmentCount = meshService.assignments.length;
        final submittedCount = meshService.assignments
            .where((a) => a.status != AssignmentStatus.pending)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Hola $studentName',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
              const SizedBox(height: 4),
              const Text('Tu progreso de aprendizaje',
                  style: TextStyle(fontSize: 14, color: Color(0xFF95A5A6))),
              const SizedBox(height: 24),

              // Stats cards
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.menu_book, color: const Color(0xFF27AE60),
                    value: '$lessonCount', label: 'Lecciones',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.assignment, color: const Color(0xFFE67E22),
                    value: '$assignmentCount', label: 'Tareas',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.check_circle, color: const Color(0xFF2980B9),
                    value: '$submittedCount', label: 'Entregadas',
                  )),
                ],
              ),

              const SizedBox(height: 24),

              // Connection status
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        meshService.isConnected ? Icons.cell_tower : Icons.signal_cellular_off,
                        color: meshService.isConnected ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meshService.isConnected ? 'Conectado a la mesh' : 'Sin conexion',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                          Text('${meshService.knownNodes.length} nodos en la red',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF95A5A6))),
                        ],
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
  final Color color;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.color, required this.value, required this.label});

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
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
          ],
        ),
      ),
    );
  }
}
