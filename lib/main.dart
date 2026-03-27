import 'package:flutter/material.dart';
import 'services/meshtastic_service.dart';
import 'screens/device_selection_screen.dart';
import 'screens/role_selection_screen.dart';

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

/// Flujo: Startup → DeviceSelection (conectar nodo) → RoleSelection → Pantalla del rol
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
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // SIEMPRE ir a DeviceSelection primero.
    // Después de conectar, consulta el roster al gateway para saber quién eres.
    // Fallback: si no hay roster, va a selección manual de rol.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceSelectionScreen(
          meshService: widget.meshService,
          nextScreen: RoleSelectionScreen(meshService: widget.meshService),
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
            Text('Sirius Edu',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            SizedBox(height: 8),
            Text('Conectando educacion',
                style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Color(0xFF27AE60)),
          ],
        ),
      ),
    );
  }
}
