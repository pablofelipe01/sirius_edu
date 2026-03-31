import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/chat_message.dart';
import '../services/meshtastic_service.dart';
import '../widgets/battery_indicator.dart';
import 'student/student_main_screen.dart';
import 'teacher/teacher_main_screen.dart';
import 'parent/parent_main_screen.dart';
import 'supervisor/dashboard_screen.dart';

/// Flujo: Escanear → Conectar → Settings (info nodo) → Continuar →
///   ROSTER_REQ al gateway → Identifica rol por node_id → PIN si aplica → Pantalla del rol
class DeviceSelectionScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final Widget nextScreen; // Fallback si no hay roster

  const DeviceSelectionScreen({
    super.key,
    required this.meshService,
    required this.nextScreen,
  });

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

enum _ScreenPhase { scanning, connecting, settings, identifyingUser, askingPin, unknownNode }

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  final List<BluetoothDevice> _devices = [];
  _ScreenPhase _phase = _ScreenPhase.scanning;
  String? _error;
  StreamSubscription<BluetoothDevice>? _scanSub;
  StreamSubscription<ChatMessage>? _msgSub;
  int? _selectedGatewayNodeId;

  // Roster data del usuario identificado
  String? _userId;
  String? _userName;
  String? _userRole;
  String? _userGrade;
  String? _childId;
  bool _needsPin = false;
  final _pinController = TextEditingController();
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _selectedGatewayNodeId = widget.meshService.gatewayNodeId;
    widget.meshService.addListener(_onServiceChange);
    _tryAutoConnect();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _msgSub?.cancel();
    _pinController.dispose();
    widget.meshService.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() => setState(() {});

  // ============================================================
  // FASE 1: ESCANEO Y CONEXIÓN BLE
  // ============================================================

  Future<void> _tryAutoConnect() async {
    setState(() => _phase = _ScreenPhase.connecting);
    await widget.meshService.connectToSavedDevice();

    if (!mounted) return;

    if (widget.meshService.isConnected) {
      setState(() => _phase = _ScreenPhase.settings);
    } else {
      setState(() => _phase = _ScreenPhase.scanning);
      _startScan();
    }
  }

  void _startScan() {
    setState(() {
      _devices.clear();
      _error = null;
    });

    _scanSub?.cancel();
    _scanSub = widget.meshService.scanDevices().listen(
      (device) {
        if (!_devices.any((d) => d.remoteId == device.remoteId)) {
          setState(() => _devices.add(device));
        }
      },
      onDone: () => setState(() {}),
      onError: (e) => setState(() => _error = e.toString()),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _scanSub?.cancel();
    setState(() {
      _phase = _ScreenPhase.connecting;
      _error = null;
    });

    await widget.meshService.connectToDevice(device);
    if (!mounted) return;

    if (widget.meshService.isConnected) {
      setState(() => _phase = _ScreenPhase.settings);
    } else {
      setState(() {
        _phase = _ScreenPhase.scanning;
        _error = widget.meshService.errorMessage ?? 'No se pudo conectar';
      });
    }
  }

  Future<void> _disconnect() async {
    await widget.meshService.disconnectAndClear();
    setState(() {
      _phase = _ScreenPhase.scanning;
      _devices.clear();
    });
    _startScan();
  }

  // ============================================================
  // FASE 2: IDENTIFICACIÓN POR ROSTER
  // ============================================================

  void _requestRoster() {
    setState(() => _phase = _ScreenPhase.identifyingUser);

    // Escuchar respuesta del gateway
    // El gateway responde a mensajes mesh normales, que llegan por _handleChatMessage
    // Necesitamos escuchar mensajes que empiecen con ROSTER_RES
    _listenForRosterResponse();

    // Enviar solicitud
    widget.meshService.sendToGateway('ROSTER_REQ|${widget.meshService.client.myNodeInfo?.myNodeNum ?? 0}');
  }

  void _listenForRosterResponse() {
    _msgSub?.cancel();
    _msgSub = widget.meshService.messageStream.listen((msg) {
      final text = msg.messageText;
      if (text.startsWith('ROSTER_RES|')) {
        _msgSub?.cancel();
        _handleRosterResponse(text);
      } else if (text.startsWith('ROSTER_PIN_OK|')) {
        _msgSub?.cancel();
        _handlePinOk(text);
      } else if (text.startsWith('ROSTER_PIN_FAIL|')) {
        _handlePinFail();
      }
    });

    // Timeout: si no responde en 15s, ir al fallback
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _phase == _ScreenPhase.identifyingUser) {
        _scanSub?.cancel();
        // No hay respuesta del gateway — usar nextScreen como fallback
        _navigateToFallback();
      }
    });
  }

  void _handleRosterResponse(String text) {
    // ROSTER_RES|id|name|role|grade|child_id|has_pin
    // ROSTER_RES|UNKNOWN
    final parts = text.split('|');

    if (parts.length < 2 || parts[1] == 'UNKNOWN') {
      setState(() => _phase = _ScreenPhase.unknownNode);
      return;
    }

    _userId = parts[1];
    _userName = parts.length > 2 ? parts[2] : '';
    _userRole = parts.length > 3 ? parts[3] : '';
    _userGrade = parts.length > 4 ? parts[4] : '';
    _childId = parts.length > 5 ? parts[5] : '';
    _needsPin = parts.length > 6 && parts[6] == '1';

    if (_needsPin) {
      setState(() => _phase = _ScreenPhase.askingPin);
    } else {
      _navigateToRole();
    }
  }

  void _submitPin() {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() => _pinError = null);
    _listenForRosterResponse(); // Re-escuchar para PIN_OK/PIN_FAIL
    widget.meshService.sendToGateway('ROSTER_PIN|$_userId|$pin');
  }

  void _handlePinOk(String text) {
    _navigateToRole();
  }

  void _handlePinFail() {
    setState(() {
      _pinError = 'PIN incorrecto. Intenta de nuevo.';
      _pinController.clear();
    });
  }

  void _navigateToRole() {
    Widget screen;
    switch (_userRole) {
      case 'student':
        screen = StudentMainScreen(meshService: widget.meshService, studentName: _userName ?? '');
      case 'teacher':
        screen = TeacherMainScreen(meshService: widget.meshService, teacherName: _userName ?? '');
      case 'parent':
        screen = ParentMainScreen(meshService: widget.meshService, parentName: _userName ?? '');
      case 'supervisor':
        screen = DashboardScreen(meshService: widget.meshService);
      default:
        screen = widget.nextScreen;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _navigateToFallback() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _ScreenPhase.scanning:
        return _buildScanView();
      case _ScreenPhase.connecting:
        return _buildConnectingView();
      case _ScreenPhase.settings:
        return _buildSettingsView();
      case _ScreenPhase.identifyingUser:
        return _buildIdentifyingView();
      case _ScreenPhase.askingPin:
        return _buildPinView();
      case _ScreenPhase.unknownNode:
        return _buildUnknownView();
    }
  }

  Widget _buildConnectingView() {
    return const Scaffold(
      appBar: null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF27AE60)),
            SizedBox(height: 16),
            Text('Conectando...', style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifyingView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Identificando usuario')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2980B9)),
            SizedBox(height: 16),
            Text('Consultando al gateway...', style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
            SizedBox(height: 8),
            Text('Identificando tu nodo en el sistema', style: TextStyle(fontSize: 13, color: Color(0xFF95A5A6))),
          ],
        ),
      ),
    );
  }

  Widget _buildPinView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificacion')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Color(0xFF2980B9)),
              const SizedBox(height: 16),
              Text('Hola, $_userName',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 8),
              Text('Rol: ${_userRole == 'teacher' ? 'Profesor' : 'Supervisor'}',
                  style: const TextStyle(fontSize: 15, color: Color(0xFF7F8C8D))),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'Ingresa tu PIN',
                  errorText: _pinError,
                  prefixIcon: const Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
                onSubmitted: (_) => _submitPin(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitPin,
                  child: const Text('Verificar PIN', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnknownView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Nodo no registrado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber, size: 64, color: Color(0xFFE67E22)),
              const SizedBox(height: 16),
              const Text('Nodo no registrado',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 8),
              const Text(
                'Este nodo no esta en el sistema.\nContacta al profesor o supervisor para registrarte.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF7F8C8D)),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Conectar otro nodo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS VIEW (después de conectar, antes de identificar)
  // ============================================================

  Widget _buildSettingsView() {
    final service = widget.meshService;
    final nodes = service.knownNodes;

    return Scaffold(
      appBar: AppBar(title: const Text('Nodo Conectado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dispositivo BLE
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bluetooth_connected, color: Color(0xFF27AE60)),
                        const SizedBox(width: 8),
                        const Text('Dispositivo BLE',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Conectado',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF27AE60))),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow('Nombre', service.connectedDeviceName ?? 'Desconocido'),
                    const SizedBox(height: 6),
                    _InfoRow('MAC', service.connectedDeviceMac ?? '-'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Bateria: ', style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
                        BatteryIndicator(batteryLevel: service.connectedNodeBatteryLevel),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disconnect,
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Desconectar y buscar otro'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE74C3C),
                          side: const BorderSide(color: Color(0xFFE74C3C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Gateway
            Card(
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
                    const Text('Nodo gateway (donde esta la IA):',
                        style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D))),
                    const SizedBox(height: 8),
                    if (nodes.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: nodes.any((n) => n.nodeId == _selectedGatewayNodeId)
                            ? _selectedGatewayNodeId
                            : null,
                        hint: const Text('Selecciona el gateway'),
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
                              Expanded(child: Text('${node.displayName} (${node.shortId})',
                                  overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedGatewayNodeId = value);
                            service.saveGatewayNodeId(value);
                          }
                        },
                      )
                    else
                      const Text('Esperando nodos...',
                          style: TextStyle(color: Color(0xFF95A5A6), fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nodos en la red
            Card(
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E44AD).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${nodes.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8E44AD))),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (nodes.isEmpty)
                      const Text('Descubriendo nodos...',
                          style: TextStyle(color: Color(0xFF95A5A6), fontStyle: FontStyle.italic))
                    else
                      ...nodes.map((node) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10,
                                color: node.isOnline ? const Color(0xFF27AE60) : Colors.grey.shade400),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(node.displayName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                  Text(node.shortId, style: const TextStyle(fontSize: 11, color: Color(0xFF95A5A6))),
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

            const SizedBox(height: 24),

            // Botón Continuar → identifica usuario por roster
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _requestRoster,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCAN VIEW
  // ============================================================

  Widget _buildScanView() {
    final scanning = widget.meshService.status == AppConnectionStatus.scanning;

    return Scaffold(
      appBar: AppBar(title: const Text('Conectar nodo LoRa')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF27AE60).withValues(alpha: 0.1),
            child: const Column(
              children: [
                Icon(Icons.bluetooth_searching, size: 40, color: Color(0xFF27AE60)),
                SizedBox(height: 8),
                Text('Conecta tu nodo Meshtastic',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                SizedBox(height: 4),
                Text('Asegurate de que el nodo LoRa esta encendido y cerca',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D))),
              ],
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13)),
            ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: scanning
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF2980B9)),
                              SizedBox(height: 12),
                              Text('Buscando dispositivos...', style: TextStyle(color: Color(0xFF7F8C8D))),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No se encontraron dispositivos', style: TextStyle(color: Color(0xFF7F8C8D))),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _startScan,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Buscar de nuevo'),
                              ),
                            ],
                          ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final name = device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Dispositivo ${device.remoteId.str.substring(device.remoteId.str.length - 5)}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2980B9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bluetooth, color: Color(0xFF2980B9)),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(device.remoteId.str,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF95A5A6))),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _connectToDevice(device),
                        ),
                      );
                    },
                  ),
          ),
          if (_devices.isNotEmpty || !scanning)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: scanning ? null : _startScan,
                  icon: scanning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(scanning ? 'Buscando...' : 'Buscar dispositivos'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
      ],
    );
  }
}
