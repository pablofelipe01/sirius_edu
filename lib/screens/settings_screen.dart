import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/meshtastic_service.dart';
import '../widgets/battery_indicator.dart';

class SettingsScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final VoidCallback onDeviceChange;
  final VoidCallback onDisconnect;

  const SettingsScreen({
    super.key,
    required this.meshService,
    required this.onDeviceChange,
    required this.onDisconnect,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  MeshtasticService get _service => widget.meshService;
  int? _selectedGatewayNodeId;
  String _userRole = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChange);
    _selectedGatewayNodeId = _service.gatewayNodeId;
    _loadUserInfo();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() => setState(() {});

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? '';
      _userName = prefs.getString('user_name') ?? '';
    });
  }

  Future<void> _disconnectDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar nodo'),
        content: const Text('Se desconectara del nodo LoRa actual. Puedes reconectar despues.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE74C3C)),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.disconnectAndClear();
      widget.onDisconnect();
    }
  }

  Future<void> _changeRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'student': return 'Estudiante';
      case 'teacher': return 'Profesor';
      case 'parent': return 'Padre';
      case 'supervisor': return 'Supervisor';
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _service.isConnected;
    final nodes = _service.knownNodes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === NODO CONECTADO ===
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: isConnected ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                      ),
                      const SizedBox(width: 8),
                      const Text('Nodo Conectado',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? const Color(0xFF27AE60).withValues(alpha: 0.15)
                              : const Color(0xFFE74C3C).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isConnected ? 'Conectado' : 'Desconectado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isConnected ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (isConnected) ...[
                    _InfoRow(label: 'Nombre', value: _service.connectedDeviceName ?? 'Desconocido'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'MAC', value: _service.connectedDeviceMac ?? '-'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Bateria: ', style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
                        BatteryIndicator(batteryLevel: _service.connectedNodeBatteryLevel),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disconnectDevice,
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Desconectar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE74C3C),
                          side: const BorderSide(color: Color(0xFFE74C3C)),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text('No hay nodo conectado',
                        style: TextStyle(color: Color(0xFF95A5A6), fontSize: 14)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onDeviceChange,
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('Buscar y conectar nodo'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // === GATEWAY ===
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cell_tower, color: Color(0xFF2980B9)),
                      SizedBox(width: 8),
                      Text('Gateway',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Selecciona el nodo gateway de la red:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedGatewayNodeId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: nodes.map((node) => DropdownMenuItem(
                      value: node.nodeId,
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8,
                              color: node.isOnline ? const Color(0xFF27AE60) : Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${node.displayName} (${node.shortId})',
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGatewayNodeId = value);
                        _service.saveGatewayNodeId(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gateway actualizado'),
                              backgroundColor: Color(0xFF27AE60)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // === NODOS EN LA RED ===
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.device_hub, color: Color(0xFF8E44AD)),
                      const SizedBox(width: 8),
                      const Text('Nodos en la Red',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      const Spacer(),
                      Text('${nodes.length}', style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8E44AD))),
                    ],
                  ),
                  const Divider(height: 24),
                  if (nodes.isEmpty)
                    const Text('No se han detectado nodos',
                        style: TextStyle(color: Color(0xFF95A5A6), fontSize: 14))
                  else
                    ...nodes.map((node) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10,
                              color: node.isOnline ? const Color(0xFF27AE60) : Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(node.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text(node.shortId,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF95A5A6))),
                              ],
                            ),
                          ),
                          if (node.batteryLevel != null)
                            BatteryIndicator(batteryLevel: node.batteryLevel, size: 16),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // === USUARIO ===
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person, color: Color(0xFFE67E22)),
                      SizedBox(width: 8),
                      Text('Usuario',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: 'Nombre', value: _userName),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Rol', value: _roleLabel(_userRole)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _changeRole,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Cambiar rol'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // === ACCIONES ===
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFF7F8C8D)),
                      SizedBox(width: 8),
                      Text('Acciones',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    ],
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onDeviceChange,
                      icon: const Icon(Icons.bluetooth_searching, size: 18),
                      label: const Text('Cambiar nodo'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Version
          Center(
            child: Text(
              'Sirius Edu v1.0.0\nInverse Neural Lab',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ),
      ],
    );
  }
}
