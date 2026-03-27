import 'package:flutter/material.dart';
import '../../services/meshtastic_service.dart';
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
      ProgressScreen(meshService: widget.meshService, studentName: widget.studentName),
    ];
    widget.meshService.loadLocalData();
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Lecciones'),
          NavigationDestination(icon: Icon(Icons.smart_toy), label: 'Tutor IA'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Tareas'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Progreso'),
        ],
      ),
    );
  }
}
