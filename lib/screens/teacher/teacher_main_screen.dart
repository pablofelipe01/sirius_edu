import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../settings_screen.dart';
import '../device_selection_screen.dart';
import '../chat_screen.dart';
import '../student/lesson_screen.dart';
import 'teacher_questions_screen.dart';

class TeacherMainScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String teacherName;

  const TeacherMainScreen({super.key, required this.meshService, required this.teacherName});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // El profesor ve las mismas lecciones que los alumnos (las que el creo en la web)
      LessonScreen(meshService: widget.meshService, studentName: widget.teacherName),
      TeacherQuestionsScreen(meshService: widget.meshService, teacherName: widget.teacherName),
      ChatScreen(meshService: widget.meshService, userName: widget.teacherName),
      SettingsScreen(
        meshService: widget.meshService,
        onDeviceChange: _goToDeviceSelection,
        onDisconnect: _goToDeviceSelection,
      ),
    ];
    widget.meshService.loadLocalData();
  }

  void _goToDeviceSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceSelectionScreen(
          meshService: widget.meshService,
          nextScreen: TeacherMainScreen(meshService: widget.meshService, teacherName: widget.teacherName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prof. ${widget.teacherName}'),
        backgroundColor: const Color(0xFF2980B9),
        actions: [
          ListenableBuilder(
            listenable: widget.meshService,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                widget.meshService.isConnected ? Icons.cell_tower : Icons.signal_cellular_off,
                color: widget.meshService.isConnected ? Colors.white : Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.meshService,
        builder: (context, _) => NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.menu_book), label: 'Lecciones'),
            NavigationDestination(
              icon: Badge(
                label: Text('${widget.meshService.pendingQuestions.length}'),
                isLabelVisible: widget.meshService.pendingQuestions.isNotEmpty,
                child: const Icon(Icons.help_outline),
              ),
              label: 'Preguntas',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('${widget.meshService.unreadChatCount}'),
                isLabelVisible: widget.meshService.unreadChatCount > 0,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              label: 'Chat',
            ),
            const NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
          ],
        ),
      ),
    );
  }
}
