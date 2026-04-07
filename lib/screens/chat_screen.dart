import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/meshtastic_service.dart';

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
  StreamSubscription? _messageSub;
  int? _selectedDM;
  String? _selectedDMName;

  @override
  void initState() {
    super.initState();
    _messageSub = widget.meshService.messageStream.listen((_) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.meshService.sendChatMessage(text, destinationId: _selectedDM);
    _controller.clear();
    _scrollToBottom();
  }

  List<ChatMessage> get _filteredMessages {
    return widget.meshService.messageHistory.where((m) {
      // Filtrar mensajes de protocolo
      if (m.messageText.startsWith('ROSTER_') ||
          m.messageText.startsWith('SYNC_') ||
          m.messageText.startsWith('LECCION') ||
          m.messageText.startsWith('TAREA|') ||
          m.messageText.startsWith('EVAL_IA|') ||
          m.messageText.startsWith('RESPUESTA_IA|') ||
          m.messageText.startsWith('PREGUNTA_') ||
          m.messageText.startsWith('RESP_PROF') ||
          m.messageText.startsWith('ENTREGA') ||
          m.messageText.startsWith('LECCION_PASO|')) {
        return false;
      }
      if (_selectedDM != null) {
        return (m.fromNodeId == _selectedDM && m.isDirectMessage) ||
            (m.isMine && m.toNodeId == _selectedDM);
      }
      return !m.isDirectMessage || m.isMine;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    widget.meshService.markChatAsRead();
    final messages = _filteredMessages;
    final myNodeNum = widget.meshService.client.myNodeInfo?.myNodeNum;
    final otherNodes = widget.meshService.knownNodes
        .where((n) => n.nodeId != myNodeNum && n.nodeId != widget.meshService.gatewayNodeId)
        .toList();

    return Column(
      children: [
        // Channel/DM selector
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: ChoiceChip(
                  label: const Text('Grupo'),
                  selected: _selectedDM == null,
                  onSelected: (_) => setState(() {
                    _selectedDM = null;
                    _selectedDMName = null;
                  }),
                  selectedColor: const Color(0xFF27AE60).withValues(alpha: 0.2),
                ),
              ),
              ...otherNodes.map((node) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: ChoiceChip(
                  label: Text(node.displayName),
                  selected: _selectedDM == node.nodeId,
                  onSelected: (_) => setState(() {
                    _selectedDM = node.nodeId;
                    _selectedDMName = node.displayName;
                  }),
                  selectedColor: const Color(0xFF2980B9).withValues(alpha: 0.2),
                  avatar: Icon(Icons.circle, size: 8,
                      color: node.isOnline ? const Color(0xFF27AE60) : Colors.grey.shade400),
                ),
              )),
            ],
          ),
        ),

        const Divider(height: 1),

        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    _selectedDM != null
                        ? 'No hay mensajes con $_selectedDMName'
                        : 'No hay mensajes en el grupo',
                    style: const TextStyle(color: Color(0xFF95A5A6)),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final showDate = index == 0 ||
                        !msg.isSameDay(messages[index - 1]);

                    return Column(
                      children: [
                        if (showDate)
                          _DateSeparator(date: msg.formattedDate),
                        _MessageBubble(message: msg),
                      ],
                    );
                  },
                ),
        ),

        // Input bar
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
                      hintText: _selectedDM != null
                          ? 'Mensaje a $_selectedDMName...'
                          : 'Mensaje al grupo...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
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

class _DateSeparator extends StatelessWidget {
  final String date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECF0F1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D))),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final bgColor = isMine ? const Color(0xFFDCF8C6) : Colors.white;
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isMine ? 12 : 2),
                bottomRight: Radius.circular(isMine ? 2 : 12),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(message.fromNodeName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2980B9))),
                  ),
                Text(message.messageText,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50))),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message.formattedTime,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF95A5A6))),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.deliveryStatus == DeliveryStatus.sending
                            ? Icons.access_time
                            : Icons.check,
                        size: 13,
                        color: message.deliveryStatus == DeliveryStatus.sending
                            ? const Color(0xFF95A5A6)
                            : const Color(0xFF27AE60),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
