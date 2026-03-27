import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../../widgets/ai_message_bubble.dart';

class TeacherAIScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String teacherName;

  const TeacherAIScreen({super.key, required this.meshService, required this.teacherName});

  @override
  State<TeacherAIScreen> createState() => _TeacherAIScreenState();
}

class _TeacherAIScreenState extends State<TeacherAIScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];
  bool _waiting = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _messages.add(_Msg(
      text: 'Hola profesor ${widget.teacherName}. Puedo ayudarte con sugerencias de lecciones, '
          'como explicar temas, estrategias de evaluacion y mas.',
      isAI: true,
    ));

    _sub = widget.meshService.aiResponseStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _waiting = false;
        _messages.add(_Msg(text: data['response'] ?? '', isAI: true));
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Msg(text: text, isAI: false));
      _waiting = true;
    });
    _controller.clear();

    widget.meshService.sendAIQuestion('profesor', '0', text);
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
    return Column(
      children: [
        // Sugerencias rápidas
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _SuggestionChip('Sugerir leccion de ciencias', onTap: () {
                _controller.text = 'Sugiere una leccion de ciencias naturales para grado 2';
                _send();
              }),
              _SuggestionChip('Como explicar fracciones', onTap: () {
                _controller.text = 'Como puedo explicar fracciones a ninos de 8 anos de forma sencilla?';
                _send();
              }),
              _SuggestionChip('Actividad para lenguaje', onTap: () {
                _controller.text = 'Sugiere una actividad practica de lenguaje para grado 3';
                _send();
              }),
            ],
          ),
        ),

        // Mensajes
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length + (_waiting ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _waiting) {
                return const AIMessageBubble(text: '', isFromAI: true, isLoading: true);
              }
              final msg = _messages[index];
              return AIMessageBubble(text: msg.text, isFromAI: msg.isAI, time: msg.time);
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
                      hintText: 'Pregunta al asistente...',
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
                  onPressed: _waiting ? null : _send,
                  backgroundColor: const Color(0xFF2980B9),
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

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        backgroundColor: const Color(0xFF2980B9).withValues(alpha: 0.1),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isAI;
  final String time;

  _Msg({required this.text, required this.isAI})
      : time = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
}
