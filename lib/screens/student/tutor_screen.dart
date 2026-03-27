import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../../widgets/ai_message_bubble.dart';

class TutorScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String studentName;

  const TutorScreen({super.key, required this.meshService, required this.studentName});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_TutorMessage> _messages = [];
  bool _waitingForResponse = false;
  StreamSubscription? _aiSub;

  @override
  void initState() {
    super.initState();
    final subject = widget.meshService.activeLesson?.subject ?? 'tus materias';
    _messages.add(_TutorMessage(
      text: 'Hola ${widget.studentName}, estoy aqui para ayudarte con $subject. Preguntame lo que quieras.',
      isFromAI: true,
    ));

    _aiSub = widget.meshService.aiResponseStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _waitingForResponse = false;
        _messages.add(_TutorMessage(text: data['response'] ?? '', isFromAI: true));
      });
      // Guardar conversación local
      widget.meshService.storage.saveConversation(
        widget.studentName, _messages.last.text, data['response'] ?? '',
      );
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _aiSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuestion() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Validar tamaño
    final bytes = utf8.encode('PREGUNTA_IA|${widget.studentName}|0|$text');
    if (bytes.length > 237) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje muy largo, acortalo un poco')),
      );
      return;
    }

    setState(() {
      _messages.add(_TutorMessage(text: text, isFromAI: false));
      _waitingForResponse = true;
    });
    _controller.clear();

    widget.meshService.sendAIQuestion(
      widget.studentName,
      widget.meshService.activeLesson?.id ?? '0',
      text,
    );

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

  int get _remainingBytes {
    final prefix = 'PREGUNTA_IA|${widget.studentName}|0|';
    final used = utf8.encode(prefix + _controller.text).length;
    return 237 - used;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mensajes
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length + (_waitingForResponse ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _waitingForResponse) {
                return const AIMessageBubble(text: '', isFromAI: true, isLoading: true);
              }
              final msg = _messages[index];
              return AIMessageBubble(text: msg.text, isFromAI: msg.isFromAI, time: msg.time);
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
                      hintText: 'Escribe tu pregunta...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      suffixText: '${_remainingBytes}b',
                      suffixStyle: TextStyle(
                        fontSize: 11,
                        color: _remainingBytes < 20 ? const Color(0xFFE74C3C) : const Color(0xFF95A5A6),
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendQuestion(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _waitingForResponse ? null : _sendQuestion,
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

class _TutorMessage {
  final String text;
  final bool isFromAI;
  final String time;

  _TutorMessage({required this.text, required this.isFromAI})
      : time = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
}
