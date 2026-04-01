import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../settings_screen.dart';
import '../device_selection_screen.dart';
import '../chat_screen.dart';
import 'lesson_screen.dart';
import 'tutor_screen.dart';
import 'assignments_screen.dart';
import 'progress_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final String studentName;

  const StudentMainScreen({super.key, required this.meshService, required this.studentName});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      LessonScreen(meshService: widget.meshService),
      TutorScreen(meshService: widget.meshService, studentName: widget.studentName),
      AssignmentsScreen(meshService: widget.meshService, studentName: widget.studentName),
      ChatScreen(meshService: widget.meshService, userName: widget.studentName),
      ProgressScreen(meshService: widget.meshService, studentName: widget.studentName),
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
          nextScreen: StudentMainScreen(meshService: widget.meshService, studentName: widget.studentName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${widget.studentName}'),
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
            const NavigationDestination(icon: Icon(Icons.smart_toy), label: 'Tutor IA'),
            const NavigationDestination(icon: Icon(Icons.assignment), label: 'Tareas'),
            NavigationDestination(
              icon: Badge(
                label: Text('${widget.meshService.unreadChatCount}'),
                isLabelVisible: widget.meshService.unreadChatCount > 0,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              label: 'Chat',
            ),
            const NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Progreso'),
            const NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
          ],
        ),
      ),
    );
  }
}
