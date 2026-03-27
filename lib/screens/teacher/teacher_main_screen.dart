import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
import '../settings_screen.dart';
import '../device_selection_screen.dart';
import 'create_lesson_screen.dart';
import 'students_screen.dart';
import 'submissions_screen.dart';
import 'teacher_ai_screen.dart';

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
      CreateLessonScreen(meshService: widget.meshService),
      StudentsScreen(meshService: widget.meshService),
      SubmissionsScreen(meshService: widget.meshService),
      TeacherAIScreen(meshService: widget.meshService, teacherName: widget.teacherName),
      SettingsScreen(
        meshService: widget.meshService,
        onDeviceChange: _goToDeviceSelection,
        onDisconnect: _goToDeviceSelection,
      ),
    ];
  }

  void _goToDeviceSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceSelectionScreen(
          meshService: widget.meshService,
          nextScreen: TeacherMainScreen(
            meshService: widget.meshService,
            teacherName: widget.teacherName,
          ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Lecciones'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Alumnos'),
          NavigationDestination(icon: Icon(Icons.grading), label: 'Entregas'),
          NavigationDestination(icon: Icon(Icons.smart_toy), label: 'Asistente IA'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
