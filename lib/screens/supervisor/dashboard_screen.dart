import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';

class DashboardScreen extends StatelessWidget {
  final MeshtasticService meshService;

  const DashboardScreen({super.key, required this.meshService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Supervisor'),
        backgroundColor: const Color(0xFF8E44AD),
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
          final nodes = meshService.knownNodes;
          final assignments = meshService.assignments;
          final lesson = meshService.activeLesson;
          final onlineNodes = nodes.where((n) => n.isOnline).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen general
                Row(
                  children: [
                    Expanded(child: _SummaryCard(
                      icon: Icons.cell_tower,
                      value: '$onlineNodes / ${nodes.length}',
                      label: 'Nodos en linea',
                      color: const Color(0xFF27AE60),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(
                      icon: Icons.assignment,
                      value: '${assignments.length}',
                      label: 'Tareas activas',
                      color: const Color(0xFF2980B9),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _SummaryCard(
                      icon: Icons.menu_book,
                      value: lesson != null ? '1' : '0',
                      label: 'Lecciones activas',
                      color: const Color(0xFFE67E22),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(
                      icon: Icons.wifi,
                      value: meshService.isConnected ? 'OK' : 'OFF',
                      label: 'Gateway',
                      color: meshService.isConnected ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // Leccion activa
                if (lesson != null) ...[
                  const Text('Leccion activa',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.menu_book, color: Color(0xFF8E44AD)),
                      title: Text(lesson.title),
                      subtitle: Text('${lesson.subject} - Grado ${lesson.grade}'),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Nodos conectados
                const Text('Nodos de la red',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                const SizedBox(height: 8),
                ...nodes.map((node) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Icon(Icons.circle, size: 12,
                        color: node.isOnline ? const Color(0xFF27AE60) : Colors.grey.shade400),
                    title: Text(node.displayName),
                    subtitle: Text(node.shortId),
                    trailing: node.batteryLevel != null
                        ? Text('${node.batteryLevel}%', style: const TextStyle(fontSize: 13))
                        : null,
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
          ],
        ),
      ),
    );
  }
}
