import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import 'student_profile_screen.dart';

class StudentsScreen extends StatelessWidget {
  final MeshtasticService meshService;

  const StudentsScreen({super.key, required this.meshService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meshService,
      builder: (context, _) {
        final nodes = meshService.knownNodes
            .where((n) => n.nodeId != MeshtasticService.gatewayNodeId)
            .toList();

        if (nodes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Sin alumnos conectados',
                    style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D))),
                const SizedBox(height: 8),
                const Text('Los alumnos apareceran cuando se conecten a la red',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF95A5A6))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            final node = nodes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: node.isOnline
                      ? const Color(0xFF27AE60).withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  child: Icon(Icons.person,
                      color: node.isOnline ? const Color(0xFF27AE60) : Colors.grey),
                ),
                title: Text(node.displayName),
                subtitle: Text(node.shortId, style: const TextStyle(fontSize: 12)),
                trailing: Icon(Icons.circle, size: 10,
                    color: node.isOnline ? const Color(0xFF27AE60) : Colors.grey.shade400),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentProfileScreen(
                        meshService: meshService,
                        node: node,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
