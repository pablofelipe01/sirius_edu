import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/assignment.dart';
import '../../services/meshtastic_service.dart';

class AssignmentsScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String studentName;

  const AssignmentsScreen({super.key, required this.meshService, required this.studentName});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _responseController = TextEditingController();
  StreamSubscription? _evalSub;
  final Map<String, Map<String, dynamic>> _evaluations = {};

  @override
  void initState() {
    super.initState();
    _evalSub = widget.meshService.evaluationStream.listen((eval) {
      if (!mounted) return;
      setState(() {
        _evaluations[eval['assignment_id'] ?? ''] = eval;
      });
    });
  }

  @override
  void dispose() {
    _evalSub?.cancel();
    _responseController.dispose();
    super.dispose();
  }

  void _submitResponse(Assignment assignment) {
    final response = _responseController.text.trim();
    if (response.isEmpty) return;

    widget.meshService.sendSubmission(assignment.id, widget.studentName, response);
    _responseController.clear();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Respuesta enviada'), backgroundColor: Color(0xFF27AE60)),
    );
  }

  void _openAssignment(Assignment assignment) {
    _responseController.clear();
    final eval = _evaluations[assignment.id];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.description,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
            if (assignment.deadline != null) ...[
              const SizedBox(height: 8),
              Text('Fecha limite: ${assignment.deadline!.day}/${assignment.deadline!.month}',
                  style: const TextStyle(color: Color(0xFFE67E22))),
            ],
            const SizedBox(height: 16),
            if (eval != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFE67E22), size: 20),
                        const SizedBox(width: 4),
                        Text('Puntaje: ${eval['score']}/10',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(eval['feedback'] ?? '', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ] else if (assignment.status == AssignmentStatus.pending) ...[
              TextField(
                controller: _responseController,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu respuesta aqui...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _submitResponse(assignment),
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar respuesta'),
                ),
              ),
            ] else ...[
              const Text('Respuesta enviada. Esperando evaluacion...',
                  style: TextStyle(color: Color(0xFF7F8C8D), fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.meshService,
      builder: (context, _) {
        final assignments = widget.meshService.assignments;

        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No tienes tareas pendientes',
                    style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D))),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => widget.meshService.sendToGateway('SYNC_REQ|assignments|${widget.studentName}'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Buscar tareas'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            final eval = _evaluations[a.id];
            final hasEval = eval != null;

            IconData statusIcon;
            Color statusColor;
            String statusText;

            if (hasEval) {
              statusIcon = Icons.star;
              statusColor = const Color(0xFF27AE60);
              statusText = 'Evaluada';
            } else if (a.status == AssignmentStatus.submitted) {
              statusIcon = Icons.check_circle;
              statusColor = const Color(0xFF2980B9);
              statusText = 'Entregada';
            } else {
              statusIcon = Icons.access_time;
              statusColor = const Color(0xFFE67E22);
              statusText = 'Pendiente';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                title: Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openAssignment(a),
              ),
            );
          },
        );
      },
    );
  }
}
