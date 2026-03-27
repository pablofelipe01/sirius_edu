import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/meshtastic_service.dart';

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
  String? _error;
  StreamSubscription<BluetoothDevice>? _scanSub;

  @override
  void initState() {
    super.initState();
    _tryAutoConnect();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _tryAutoConnect() async {
    // Intentar reconectar al último dispositivo guardado
    setState(() => _connecting = true);
    await widget.meshService.connectToSavedDevice();

    if (!mounted) return;

    if (widget.meshService.isConnected) {
      _navigateToNext();
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
      _navigateToNext();
    } else {
      setState(() {
        _connecting = false;
        _error = widget.meshService.errorMessage ?? 'No se pudo conectar';
      });
    }
  }

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  void _skipConnection() {
    _navigateToNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar nodo LoRa'),
        actions: [
          TextButton(
            onPressed: _skipConnection,
            child: const Text('Omitir', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
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
                // Instrucciones
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                  child: const Column(
                    children: [
                      Icon(Icons.bluetooth_searching, size: 40, color: Color(0xFF27AE60)),
                      SizedBox(height: 8),
                      Text(
                        'Conecta tu nodo Meshtastic',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Asegurate de que el nodo LoRa esta encendido y cerca',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
                      ),
                    ],
                  ),
                ),

                // Error
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13)),
                  ),

                // Lista de dispositivos
                Expanded(
                  child: _devices.isEmpty
                      ? Center(
                          child: _scanning
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Color(0xFF2980B9)),
                                    SizedBox(height: 12),
                                    Text('Buscando dispositivos...',
                                        style: TextStyle(color: Color(0xFF7F8C8D))),
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
                                title: Text(name,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(device.remoteId.str,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF95A5A6))),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _connectToDevice(device),
                              ),
                            );
                          },
                        ),
                ),

                // Botón escanear
                if (_devices.isNotEmpty || !_scanning)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _scanning ? null : _startScan,
                        icon: _scanning
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
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
