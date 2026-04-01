import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/meshtastic_service.dart';

/// Pantalla de chat mesh — DM y grupo.
/// Funciona entre alumnos, profesor, y cualquier nodo de la red.
class ChatScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String userName;

  const ChatScreen({super.key, required this.meshService, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int? _selectedDM; // null = grupo, int = DM a ese nodeId
  StreamSubscription<ChatMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.meshService.messageStream.listen((_) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ChatMessage> get _filteredMessages {
    final all = widget.meshService.messageHistory;
    if (_selectedDM == null) {
      return all.where((m) => !m.isDirectMessage).toList();
    }
    return all.where((m) =>
      m.isDirectMessage &&
      (m.fromNodeId == _selectedDM || m.toNodeId == _selectedDM)
    ).toList();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.meshService.sendChatMessage(
      text,
      destinationId: _selectedDM,
      channel: _selectedDM == null ? 0 : 0,
    );
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.meshService.knownNodes
        .where((n) => n.nodeId != (widget.meshService.client.myNodeInfo?.myNodeNum ?? 0))
        .toList();
    final messages = _filteredMessages;

    return Column(
      children: [
        // Selector: Grupo / DM
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ChannelChip(
                  label: 'Grupo',
                  icon: Icons.group,
                  selected: _selectedDM == null,
                  onTap: () => setState(() => _selectedDM = null),
                ),
                ...nodes.map((node) => _ChannelChip(
                  label: node.displayName,
                  icon: Icons.person,
                  selected: _selectedDM == node.nodeId,
                  onTap: () => setState(() => _selectedDM = node.nodeId),
                )),
              ],
            ),
          ),
        ),

        // Mensajes
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    _selectedDM == null ? 'No hay mensajes en el grupo' : 'No hay mensajes',
                    style: const TextStyle(color: Color(0xFF95A5A6)),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _ChatBubble(message: msg);
                  },
                ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _selectedDM == null ? 'Mensaje al grupo...' : 'Mensaje directo...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _send,
                  backgroundColor: const Color(0xFF27AE60),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : const Color(0xFF7F8C8D)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : const Color(0xFF2C3E50))),
          ],
        ),
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF27AE60),
        backgroundColor: Colors.grey.shade100,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: message.isMine ? const Color(0xFFE8F8E8) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(message.isMine ? 14 : 4),
            bottomRight: Radius.circular(message.isMine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMine)
              Text(message.fromNodeName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2980B9))),
            Text(message.messageText, style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50))),
            Text(message.formattedTime,
                style: const TextStyle(fontSize: 10, color: Color(0xFF95A5A6))),
          ],
        ),
      ),
    );
  }
}
