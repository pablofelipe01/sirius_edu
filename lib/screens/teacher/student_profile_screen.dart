import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/meshtastic_service.dart';

class StudentProfileScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final MeshNode node;

  const StudentProfileScreen({super.key, required this.meshService, required this.node});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _noteController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _addNote() {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    widget.meshService.sendProfileUpdate(
      widget.node.shortId,
      'teacher_notes',
      note,
    );
    _noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota guardada'), backgroundColor: Color(0xFF27AE60)),
    );
  }

  void _saveParentMessage() {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    widget.meshService.sendProfileUpdate(
      widget.node.shortId,
      'message_to_parent',
      msg,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensaje para padre guardado'), backgroundColor: Color(0xFF27AE60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.node.displayName),
        backgroundColor: const Color(0xFF2980B9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info del alumno
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF2980B9).withValues(alpha: 0.15),
                      child: const Icon(Icons.person, size: 32, color: Color(0xFF2980B9)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.node.displayName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Nodo: ${widget.node.shortId}',
                              style: const TextStyle(color: Color(0xFF7F8C8D))),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 8,
                                  color: widget.node.isOnline ? const Color(0xFF27AE60) : Colors.grey),
                              const SizedBox(width: 4),
                              Text(widget.node.isOnline ? 'En linea' : 'Desconectado',
                                  style: TextStyle(fontSize: 13,
                                      color: widget.node.isOnline ? const Color(0xFF27AE60) : Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notas del profesor (privadas)
            const Text('Notas del profesor (privadas)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Ej: Aprende mejor con ejemplos de animales',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2980B9)),
                  onPressed: _addNote,
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // Mensaje para el padre
            const Text('Mensaje para el padre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Ej: Maria participo muy bien esta semana',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saveParentMessage,
                icon: const Icon(Icons.save),
                label: const Text('Guardar mensaje'),
              ),
            ),

            const SizedBox(height: 20),

            // Acciones rápidas
            const Text('Acciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.sync, size: 18),
                  label: const Text('Sincronizar perfil'),
                  onPressed: () => widget.meshService.sendToGateway(
                    'SYNC_REQ|profile|${widget.node.shortId}',
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: const Text('Ver historial IA'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitando historial...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
