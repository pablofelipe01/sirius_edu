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
  StreamSubscription? _syncSub;
  final Map<String, Map<String, dynamic>> _evaluations = {};
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _evalSub = widget.meshService.evaluationStream.listen((eval) {
      if (!mounted) return;
      setState(() {
        _evaluations[eval['assignment_id'] ?? ''] = eval;
      });
    });
    _syncSub = widget.meshService.syncStatusStream.listen((status) {
      if (status == 'SYNC_END|assignments' && mounted) {
        setState(() => _syncing = false);
      }
    });
  }

  @override
  void dispose() {
    _evalSub?.cancel();
    _syncSub?.cancel();
    _responseController.dispose();
    super.dispose();
  }

  void _requestAssignments() {
    if (!widget.meshService.isConnected || _syncing) return;
    setState(() => _syncing = true);
    widget.meshService.requestSync('assignments');
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _syncing) setState(() => _syncing = false);
    });
  }

  void _openAssignment(Assignment assignment) {
    _responseController.clear();
    final eval = _evaluations[assignment.id];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AssignmentDetailView(
          assignment: assignment,
          evaluation: eval,
          meshService: widget.meshService,
          studentName: widget.studentName,
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text('Tareas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                  const Spacer(),
                  if (_syncing)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE67E22)))
                  else
                    IconButton(
                      onPressed: _requestAssignments,
                      icon: const Icon(Icons.refresh, color: Color(0xFFE67E22)),
                      tooltip: 'Buscar tareas',
                    ),
                ],
              ),
            ),
            Expanded(
              child: assignments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No tienes tareas',
                              style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D))),
                          const SizedBox(height: 24),
                          if (!_syncing)
                            OutlinedButton.icon(
                              onPressed: _requestAssignments,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Buscar tareas'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
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
                          statusText = 'Nota: ${eval['score']}/10';
                        } else if (a.status == AssignmentStatus.submitted) {
                          statusIcon = Icons.check_circle;
                          statusColor = const Color(0xFF2980B9);
                          statusText = 'Entregada';
                        } else {
                          statusIcon = Icons.edit_note;
                          statusColor = const Color(0xFFE67E22);
                          statusText = 'Pendiente';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openAssignment(a),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(statusIcon, color: statusColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50))),
                                        const SizedBox(height: 4),
                                        Text(statusText, style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Color(0xFFBDC3C7)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Vista detallada de una tarea
class _AssignmentDetailView extends StatefulWidget {
  final Assignment assignment;
  final Map<String, dynamic>? evaluation;
  final MeshtasticService meshService;
  final String studentName;

  const _AssignmentDetailView({
    required this.assignment,
    this.evaluation,
    required this.meshService,
    required this.studentName,
  });

  @override
  State<_AssignmentDetailView> createState() => _AssignmentDetailViewState();
}

class _AssignmentDetailViewState extends State<_AssignmentDetailView> {
  final _responseController = TextEditingController();
  Map<String, dynamic>? _evaluation;
  StreamSubscription? _evalSub;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _evaluation = widget.evaluation;
    _evalSub = widget.meshService.evaluationStream.listen((eval) {
      if (eval['assignment_id'] == widget.assignment.id && mounted) {
        setState(() => _evaluation = eval);
      }
    });
  }

  @override
  void dispose() {
    _evalSub?.cancel();
    _responseController.dispose();
    super.dispose();
  }

  void _submit() {
    final response = _responseController.text.trim();
    if (response.isEmpty) return;
    setState(() => _sending = true);
    widget.meshService.sendSubmission(widget.assignment.id, widget.studentName, response);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Respuesta enviada. Esperando evaluacion...'), backgroundColor: Color(0xFF27AE60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarea', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFFE67E22),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instrucciones
            const Text('Instrucciones:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D))),
            const SizedBox(height: 8),
            Text(widget.assignment.description,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF2C3E50))),

            if (widget.assignment.deadline != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFFE67E22)),
                  const SizedBox(width: 6),
                  Text('Fecha limite: ${widget.assignment.deadline!.day}/${widget.assignment.deadline!.month}/${widget.assignment.deadline!.year}',
                      style: const TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.w500)),
                ],
              ),
            ],

            // Evaluación IA
            if (_evaluation != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF27AE60), size: 20),
                        const SizedBox(width: 8),
                        Text('Puntaje: ${_evaluation!['score']}/10',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_evaluation!['feedback'] ?? '',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50), height: 1.5)),
                  ],
                ),
              ),
            ],

            // Campo de respuesta
            if (_evaluation == null && !_sending) ...[
              const SizedBox(height: 24),
              const Text('Tu respuesta:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D))),
              const SizedBox(height: 8),
              TextField(
                controller: _responseController,
                decoration: InputDecoration(
                  hintText: 'Escribe tu respuesta aqui...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                ),
                maxLines: 6,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar respuesta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            if (_sending && _evaluation == null) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFE67E22)),
                    SizedBox(height: 12),
                    Text('Esperando evaluacion de la IA...',
                        style: TextStyle(color: Color(0xFF95A5A6))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
