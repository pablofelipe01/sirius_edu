import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/meshtastic_service.dart';
import 'student/student_main_screen.dart';
import 'teacher/teacher_main_screen.dart';
import 'parent/parent_main_screen.dart';
import 'supervisor/dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final MeshtasticService meshService;
  const RoleSelectionScreen({super.key, required this.meshService});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectRole(String role) async {
    _nameController.clear();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Escribe tu nombre'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final n = _nameController.text.trim();
              if (n.isNotEmpty) Navigator.pop(ctx, n);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    if (role == 'teacher') {
      final ok = await _askPin();
      if (!ok) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    await prefs.setString('user_name', name);

    if (!mounted) return;
    _navigateTo(role, name);
  }

  void _navigateTo(String role, String name) {
    Widget roleScreen;
    switch (role) {
      case 'student':
        roleScreen = StudentMainScreen(meshService: widget.meshService, studentName: name);
      case 'teacher':
        roleScreen = TeacherMainScreen(meshService: widget.meshService, teacherName: name);
      case 'parent':
        roleScreen = ParentMainScreen(meshService: widget.meshService, parentName: name);
      case 'supervisor':
        roleScreen = DashboardScreen(meshService: widget.meshService);
      default:
        return;
    }
    // Nodo ya está conectado — ir directo a la pantalla del rol
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => roleScreen),
    );
  }

  Future<bool> _askPin() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN de Profesor'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'Ingresa el PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim() == '1234'),
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
    c.dispose();
    if (ok != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorrecto'), backgroundColor: Color(0xFFE74C3C)),
      );
    }
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.school, size: 72, color: Color(0xFF27AE60)),
              const SizedBox(height: 16),
              const Text('Sirius Edu',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 8),
              const Text('Selecciona tu rol', style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _RoleCard(icon: Icons.person, title: 'Estudiante',
                        desc: 'Aprende con lecciones y tutor IA', color: const Color(0xFF27AE60),
                        onTap: () => _selectRole('student')),
                    _RoleCard(icon: Icons.school, title: 'Profesor',
                        desc: 'Crea lecciones y evalua alumnos', color: const Color(0xFF2980B9),
                        onTap: () => _selectRole('teacher')),
                    _RoleCard(icon: Icons.family_restroom, title: 'Padre',
                        desc: 'Ve el progreso de tu hijo', color: const Color(0xFFE67E22),
                        onTap: () => _selectRole('parent')),
                    _RoleCard(icon: Icons.dashboard, title: 'Supervisor',
                        desc: 'Monitorea todos los salones', color: const Color(0xFF8E44AD),
                        onTap: () => _selectRole('supervisor')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({required this.icon, required this.title, required this.desc,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(desc, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
            ],
          ),
        ),
      ),
    );
  }
}
