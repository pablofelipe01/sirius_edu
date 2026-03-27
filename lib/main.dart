import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/meshtastic_service.dart';
import 'screens/role_selection_screen.dart';
import 'screens/device_selection_screen.dart';
import 'screens/student/student_main_screen.dart';
import 'screens/teacher/teacher_main_screen.dart';
import 'screens/parent/parent_main_screen.dart';
import 'screens/supervisor/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SiriusEduApp());
}

class SiriusEduApp extends StatefulWidget {
  const SiriusEduApp({super.key});

  @override
  State<SiriusEduApp> createState() => _SiriusEduAppState();
}

class _SiriusEduAppState extends State<SiriusEduApp> {
  final MeshtasticService _meshService = MeshtasticService();

  @override
  void dispose() {
    _meshService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sirius Edu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF27AE60),
          primary: const Color(0xFF27AE60),
          secondary: const Color(0xFF2980B9),
          surface: Colors.white,
          onSurface: const Color(0xFF2C3E50),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF27AE60),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF27AE60),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF27AE60), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        useMaterial3: true,
      ),
      home: StartupScreen(meshService: _meshService),
    );
  }
}

/// Pantalla de inicio que decide si ir a selección de rol o directo al rol guardado.
class StartupScreen extends StatefulWidget {
  final MeshtasticService meshService;

  const StartupScreen({super.key, required this.meshService});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedRole();
  }

  Future<void> _checkSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');
    final studentName = prefs.getString('user_name') ?? 'Estudiante';

    if (!mounted) return;

    if (savedRole != null) {
      _navigateToRole(savedRole, studentName);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RoleSelectionScreen(meshService: widget.meshService),
        ),
      );
    }
  }

  Widget _buildRoleScreen(String role, String userName) {
    switch (role) {
      case 'student':
        return StudentMainScreen(meshService: widget.meshService, studentName: userName);
      case 'teacher':
        return TeacherMainScreen(meshService: widget.meshService, teacherName: userName);
      case 'parent':
        return ParentMainScreen(meshService: widget.meshService, parentName: userName);
      case 'supervisor':
        return DashboardScreen(meshService: widget.meshService);
      default:
        return RoleSelectionScreen(meshService: widget.meshService);
    }
  }

  void _navigateToRole(String role, String userName) {
    final roleScreen = _buildRoleScreen(role, userName);
    // Pasar por selección de dispositivo BLE (se puede omitir para modo offline)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceSelectionScreen(
          meshService: widget.meshService,
          nextScreen: roleScreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Color(0xFF27AE60)),
            SizedBox(height: 16),
            Text(
              'Sirius Edu',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Conectando educacion',
              style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Color(0xFF27AE60)),
          ],
        ),
      ),
    );
  }
}
