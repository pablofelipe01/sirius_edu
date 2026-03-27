import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/meshtastic_service.dart';
import '../widgets/battery_indicator.dart';

class DeviceSelectionScreen extends StatefulWidget {
  final MeshtasticService meshService;
  final Widget nextScreen;

  const DeviceSelectionScreen({
    super.key,
    required this.meshService,
    required this.nextScreen,
  });

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  final List<BluetoothDevice> _devices = [];
  bool _scanning = false;
  bool _connecting = false;
  bool _connected = false; // Muestra Settings después de conectar
  String? _error;
  StreamSubscription<BluetoothDevice>? _scanSub;
  int? _selectedGatewayNodeId;

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
    widget.meshService.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() => setState(() {});

  Future<void> _tryAutoConnect() async {
    setState(() => _connecting = true);
    await widget.meshService.connectToSavedDevice();

    if (!mounted) return;

    if (widget.meshService.isConnected) {
      setState(() {
        _connecting = false;
        _connected = true;
      });
    } else {
      setState(() => _connecting = false);
      _startScan();
    }
  }

  void _startScan() {
    setState(() {
      _scanning = true;
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
      onDone: () => setState(() => _scanning = false),
      onError: (e) => setState(() {
        _scanning = false;
        _error = e.toString();
      }),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _scanSub?.cancel();
    setState(() {
      _connecting = true;
      _scanning = false;
      _error = null;
    });

    await widget.meshService.connectToDevice(device);

    if (!mounted) return;

    if (widget.meshService.isConnected) {
      setState(() {
        _connecting = false;
        _connected = true;
      });
    } else {
      setState(() {
        _connecting = false;
        _error = widget.meshService.errorMessage ?? 'No se pudo conectar';
      });
    }
  }

  Future<void> _disconnect() async {
    await widget.meshService.disconnectAndClear();
    setState(() {
      _connected = false;
      _devices.clear();
    });
    _startScan();
  }

  void _continueToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // === PANTALLA DE SETTINGS (después de conectar) ===
    if (_connected) {
      return _buildSettingsView();
    }

    // === PANTALLA DE ESCANEO/CONEXIÓN ===
    return _buildScanView();
  }

  Widget _buildSettingsView() {
    final service = widget.meshService;
    final nodes = service.knownNodes;

    return Scaffold(
      appBar: AppBar(title: const Text('Nodo Conectado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === ESTADO DE CONEXIÓN ===
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

            // === GATEWAY ===
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
                    const Text('Nodo gateway de la red (donde esta la IA):',
                        style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D))),
                    const SizedBox(height: 8),
                    if (nodes.isNotEmpty)
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
                            service.saveGatewayNodeId(value);
                          }
                        },
                      )
                    else
                      const Text('Esperando descubrimiento de nodos...',
                          style: TextStyle(color: Color(0xFF95A5A6), fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === NODOS EN LA RED ===
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
                                  Text(node.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
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

            const SizedBox(height: 24),

            // === BOTÓN CONTINUAR ===
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _continueToApp,
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

  Widget _buildScanView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar nodo LoRa')),
      body: _connecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF27AE60)),
                  SizedBox(height: 16),
                  Text('Conectando...', style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
                ],
              ),
            )
          : Column(
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
                          child: _scanning
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
                                    const Text('No se encontraron dispositivos',
                                        style: TextStyle(color: Color(0xFF7F8C8D))),
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
                if (_devices.isNotEmpty || !_scanning)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _scanning ? null : _startScan,
                        icon: _scanning
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.bluetooth_searching),
                        label: Text(_scanning ? 'Buscando...' : 'Buscar dispositivos'),
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
