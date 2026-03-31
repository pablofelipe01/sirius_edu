import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:meshtastic_flutter/meshtastic_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/chat_message.dart';
import '../models/lesson.dart';
import '../models/assignment.dart';
import '../models/submission.dart';
import 'fragment_service.dart';
import 'local_storage_service.dart';

/// Estado de conexión BLE de la app
enum AppConnectionStatus { disconnected, scanning, connecting, connected, error }

/// Rol del usuario en la app
enum UserRole { student, teacher, parent, supervisor }

/// Servicio central Meshtastic — extiende ChangeNotifier para reactividad.
class MeshtasticService extends ChangeNotifier with WidgetsBindingObserver {
  final MeshtasticClient _client = MeshtasticClient();
  final FragmentService _fragmentService = FragmentService();
  final LocalStorageService _storage = LocalStorageService();
  final Uuid _uuid = const Uuid();

  // --- Estado reactivo ---
  AppConnectionStatus _status = AppConnectionStatus.disconnected;
  final List<MeshNode> _knownNodes = [];
  final List<ChatMessage> _messageHistory = [];
  int _unreadChatCount = 0;
  String? _errorMessage;
  final bool _autoReconnectEnabled = true;

  Lesson? _activeLesson;
  List<Assignment> _assignments = [];
  final List<Submission> _submissions = [];

  Set<int> _processedPacketIds = {};

  // Reensamblaje de fragmentos [N/M] del gateway
  // Clave: fromNodeId, Valor: {fragmentos ordenados}
  final Map<int, List<String?>> _pendingBracketFragments = {};
  final Map<int, DateTime> _bracketFragmentTimestamps = {};

  final List<MeshNode> _preloadedNodes = [
    MeshNode(nodeId: 0x49b54674, nodeName: 'Gateway Jetson'),
  ];

  // --- Streams ---
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _lessonController = StreamController<Lesson>.broadcast();
  final _assignmentController = StreamController<Assignment>.broadcast();
  final _evaluationController = StreamController<Map<String, dynamic>>.broadcast();
  final _aiResponseController = StreamController<Map<String, String>>.broadcast();

  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  String? _savedDeviceId;
  String? _savedDeviceName;

  // --- Getters ---
  AppConnectionStatus get status => _status;
  List<MeshNode> get knownNodes => _knownNodes;
  List<ChatMessage> get messageHistory => _messageHistory;
  int get unreadChatCount => _unreadChatCount;
  String? get errorMessage => _errorMessage;
  Lesson? get activeLesson => _activeLesson;
  List<Assignment> get assignments => _assignments;
  List<Submission> get submissions => _submissions;
  MeshtasticClient get client => _client;
  LocalStorageService get storage => _storage;
  bool get isConnected => _status == AppConnectionStatus.connected;

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<Lesson> get lessonStream => _lessonController.stream;
  Stream<Assignment> get assignmentStream => _assignmentController.stream;
  Stream<Map<String, dynamic>> get evaluationStream => _evaluationController.stream;
  Stream<Map<String, String>> get aiResponseStream => _aiResponseController.stream;

  // --- Info del dispositivo conectado ---
  String? get connectedDeviceName => _savedDeviceName;
  String? get connectedDeviceMac => _savedDeviceId;
  int? get connectedNodeBatteryLevel {
    if (_client.myNodeInfo == null) return null;
    final myNum = _client.myNodeInfo!.myNodeNum;
    final node = _knownNodes.where((n) => n.nodeId == myNum).firstOrNull;
    return node?.batteryLevel;
  }

  int _gatewayNodeId = 0x49b54674;
  static const int defaultGatewayNodeId = 0x49b54674;
  int get gatewayNodeId => _gatewayNodeId;

  MeshtasticService() {
    WidgetsBinding.instance.addObserver(this);
    _knownNodes.addAll(_preloadedNodes);
    _loadSavedGateway();
    _initializeClient();
  }

  Future<void> _loadSavedGateway() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('gateway_node_id');
    if (saved != null) _gatewayNodeId = saved;
    _savedDeviceName = prefs.getString('saved_device_name');
  }

  Future<void> saveGatewayNodeId(int nodeId) async {
    _gatewayNodeId = nodeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gateway_node_id', nodeId);
    notifyListeners();
  }

  Future<void> disconnectAndClear() async {
    _keepAliveTimer?.cancel();
    try {
      await _client.disconnect();
    } catch (_) {}
    _status = AppConnectionStatus.disconnected;
    _savedDeviceId = null;
    _savedDeviceName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_device_id');
    await prefs.remove('saved_device_name');
    notifyListeners();
  }

  Future<void> _initializeClient() async {
    try {
      await _client.initialize();
      _client.packetStream.listen(_handlePacket);
      _client.nodeStream.listen(_handleNodeInfo);
      _client.connectionStream.listen(_handleConnectionStatus);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // =====================================================
  // CONEXIÓN BLE
  // =====================================================

  Stream<BluetoothDevice> scanDevices() {
    _status = AppConnectionStatus.scanning;
    notifyListeners();
    return _client.scanForDevices();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _status = AppConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.connectToDevice(device);
      _savedDeviceId = device.remoteId.str;
      _savedDeviceName = device.platformName.isNotEmpty ? device.platformName : device.remoteId.str;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_device_id', _savedDeviceId!);
      await prefs.setString('saved_device_name', _savedDeviceName!);

      _status = AppConnectionStatus.connected;
      _startKeepAlive();
      notifyListeners();
    } catch (e) {
      _status = AppConnectionStatus.error;
      _errorMessage = 'Error de conexion: $e';
      notifyListeners();
    }
  }

  Future<void> connectToSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    _savedDeviceId = prefs.getString('saved_device_id');
    if (_savedDeviceId == null) return;

    _status = AppConnectionStatus.scanning;
    notifyListeners();

    try {
      await for (final device in _client.scanForDevices(timeout: const Duration(seconds: 15))) {
        if (device.remoteId.str == _savedDeviceId) {
          await connectToDevice(device);
          return;
        }
      }
      _status = AppConnectionStatus.disconnected;
      _errorMessage = 'Dispositivo no encontrado';
      notifyListeners();
    } catch (e) {
      _status = AppConnectionStatus.error;
      _errorMessage = 'Error buscando dispositivo: $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _keepAliveTimer?.cancel();
    try {
      await _client.disconnect();
    } catch (_) {}
    _status = AppConnectionStatus.disconnected;
    notifyListeners();
  }

  // =====================================================
  // KEEPALIVE
  // =====================================================

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_status == AppConnectionStatus.connected) {
        _client.isConnected;
      }
    });
  }

  // =====================================================
  // AUTO-RECONEXIÓN
  // =====================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _autoReconnectEnabled) {
      if (_status != AppConnectionStatus.connected && _savedDeviceId != null) {
        connectToSavedDevice();
      }
    }
  }

  // =====================================================
  // MANEJO DE PAQUETES ENTRANTES
  // =====================================================

  void _handlePacket(MeshPacketWrapper packet) {
    if (_processedPacketIds.contains(packet.id)) return;
    _processedPacketIds.add(packet.id);
    if (_processedPacketIds.length > 100) {
      _processedPacketIds = _processedPacketIds.skip(50).toSet();
    }

    final payload = packet.decoded?.payload;
    if (payload == null || payload.isEmpty) return;
    final text = utf8.decode(payload, allowMalformed: true);

    // Reensamblaje de fragmentos [N/M] del gateway
    final bracketMatch = RegExp(r'^\[(\d+)/(\d+)\] (.*)').firstMatch(text);
    if (bracketMatch != null) {
      _handleBracketFragment(
        int.parse(bracketMatch.group(1)!),
        int.parse(bracketMatch.group(2)!),
        bracketMatch.group(3)!,
        packet.from,
      );
      return;
    }

    if (text.startsWith('FRAG|')) {
      _handleFragment(text, packet.from);
    } else if (text.startsWith('LECCION|')) {
      _handleLessonMessage(text);
    } else if (text.startsWith('TAREA|')) {
      _handleAssignmentMessage(text);
    } else if (text.startsWith('EVAL_IA|')) {
      _handleAIEvaluation(text);
    } else if (text.startsWith('EVAL_PROF|')) {
      _handleTeacherEvaluation(text);
    } else if (text.startsWith('RESPUESTA_IA|')) {
      _handleAIResponse(text);
    } else if (text.startsWith('SYNC_RES|')) {
      _handleSyncResponse(text);
    } else {
      _handleChatMessage(text, packet);
    }
  }

  /// Maneja fragmentos con formato [N/M] del gateway (send_private_message)
  void _handleBracketFragment(int fragNum, int total, String data, int fromNode) {
    // Limpiar fragmentos viejos (>60s)
    final now = DateTime.now();
    _bracketFragmentTimestamps.removeWhere(
      (key, ts) => now.difference(ts).inSeconds > 60,
    );
    _pendingBracketFragments.removeWhere(
      (key, _) => !_bracketFragmentTimestamps.containsKey(key),
    );

    // Inicializar lista si es nuevo
    if (!_pendingBracketFragments.containsKey(fromNode)) {
      _pendingBracketFragments[fromNode] = List<String?>.filled(total, null);
    }
    _bracketFragmentTimestamps[fromNode] = now;

    final fragments = _pendingBracketFragments[fromNode]!;
    // Expandir si total cambió
    if (fragments.length < total) {
      _pendingBracketFragments[fromNode] = [
        ...fragments,
        ...List<String?>.filled(total - fragments.length, null),
      ];
    }
    _pendingBracketFragments[fromNode]![fragNum - 1] = data; // 1-based → 0-based

    // Verificar si tenemos todos
    final frags = _pendingBracketFragments[fromNode]!;
    if (frags.every((f) => f != null)) {
      final reassembled = frags.join('');
      _pendingBracketFragments.remove(fromNode);
      _bracketFragmentTimestamps.remove(fromNode);
      // Procesar mensaje completo
      _processRouting(reassembled, fromNode);
    }
  }

  /// Rutea un mensaje completo (ya reensamblado o no fragmentado)
  void _processRouting(String text, int fromNode) {
    if (text.startsWith('RESPUESTA_IA|')) {
      _handleAIResponse(text);
    } else if (text.startsWith('LECCION|')) {
      _handleLessonMessage(text);
    } else if (text.startsWith('TAREA|')) {
      _handleAssignmentMessage(text);
    } else if (text.startsWith('EVAL_IA|')) {
      _handleAIEvaluation(text);
    } else if (text.startsWith('EVAL_PROF|')) {
      _handleTeacherEvaluation(text);
    } else if (text.startsWith('SYNC_RES|')) {
      _handleSyncResponse(text);
    } else if (text.startsWith('ROSTER_RES|') || text.startsWith('ROSTER_PIN_OK|') || text.startsWith('ROSTER_PIN_FAIL|')) {
      // Estos se manejan como chat messages para que el DeviceSelectionScreen los reciba via messageStream
      final message = ChatMessage(
        messageText: text, fromNodeId: fromNode,
        fromNodeName: _getNodeName(fromNode), timestamp: DateTime.now(),
        channel: 0, isDirectMessage: true, isMine: false,
      );
      _messageHistory.add(message);
      _messageController.add(message);
      notifyListeners();
    } else {
      // Chat normal genérico — crear ChatMessage
      final message = ChatMessage(
        messageText: text, fromNodeId: fromNode,
        fromNodeName: _getNodeName(fromNode), timestamp: DateTime.now(),
        channel: 0, isDirectMessage: true, isMine: false,
      );
      _messageHistory.add(message);
      _unreadChatCount++;
      _messageController.add(message);
      notifyListeners();
    }
  }

  void _handleFragment(String text, int fromNode) {
    final reassembled = _fragmentService.receiveFragment(text);
    if (reassembled != null) {
      _processReassembledMessage(reassembled, fromNode);
    }
  }

  void _processReassembledMessage(String text, int fromNode) {
    _processRouting(text, fromNode);
  }

  void _handleLessonMessage(String text) {
    final parts = text.split('|');
    if (parts.length < 6) return;
    final lesson = Lesson(
      id: parts[1], subject: parts[2], grade: parts[3],
      title: parts[4], summary: parts[5],
      fullContent: parts.length > 6 ? parts.sublist(6).join('|') : parts[5],
      createdAt: DateTime.now(), isActive: true,
    );
    _activeLesson = lesson;
    _storage.saveLesson(lesson);
    _lessonController.add(lesson);
    notifyListeners();
  }

  void _handleAssignmentMessage(String text) {
    final parts = text.split('|');
    if (parts.length < 4) return;
    final assignment = Assignment(
      id: parts[1], studentId: parts[2], description: parts[3],
      deadline: parts.length > 4 && parts[4].isNotEmpty ? DateTime.tryParse(parts[4]) : null,
    );
    _assignments.add(assignment);
    _storage.saveAssignment(assignment);
    _assignmentController.add(assignment);
    notifyListeners();
  }

  void _handleAIEvaluation(String text) {
    final parts = text.split('|');
    if (parts.length < 4) return;
    _evaluationController.add({
      'assignment_id': parts[1], 'score': parts[2],
      'feedback': parts.sublist(3).join('|'),
    });
    notifyListeners();
  }

  void _handleTeacherEvaluation(String text) {
    final parts = text.split('|');
    if (parts.length < 5) return;
    _evaluationController.add({
      'assignment_id': parts[1], 'student_id': parts[2],
      'criteria': parts[3], 'grade': parts[4],
    });
    notifyListeners();
  }

  void _handleAIResponse(String text) {
    final parts = text.split('|');
    if (parts.length < 3) return;
    _aiResponseController.add({
      'student_id': parts[1],
      'response': parts.sublist(2).join('|'),
    });
    notifyListeners();
  }

  void _handleSyncResponse(String text) {
    // SYNC_RES — handled as needed
  }

  void _handleChatMessage(String text, MeshPacketWrapper packet) {
    final nodeName = _getNodeName(packet.from);
    final message = ChatMessage(
      messageText: text, fromNodeId: packet.from, fromNodeName: nodeName,
      timestamp: DateTime.now(), channel: packet.channel,
      toNodeId: packet.to == 0xFFFFFFFF ? null : packet.to,
      isDirectMessage: packet.to != 0xFFFFFFFF, isMine: false,
    );
    _messageHistory.add(message);
    _unreadChatCount++;
    _messageController.add(message);
    notifyListeners();
  }

  void _handleNodeInfo(NodeInfoWrapper nodeInfo) {
    final existingIndex = _knownNodes.indexWhere((n) => n.nodeId == nodeInfo.num);
    final node = MeshNode(
      nodeId: nodeInfo.num,
      nodeName: nodeInfo.user?.longName ?? 'Nodo !${nodeInfo.num.toRadixString(16)}',
      isOnline: true, lastSeen: DateTime.now(),
      batteryLevel: nodeInfo.batteryLevel, voltage: nodeInfo.voltage,
    );
    if (existingIndex >= 0) {
      _knownNodes[existingIndex] = node;
    } else {
      _knownNodes.add(node);
    }
    notifyListeners();
  }

  void _handleConnectionStatus(ConnectionStatus sdkStatus) {
    switch (sdkStatus.state) {
      case MeshtasticConnectionState.connected:
        _status = AppConnectionStatus.connected;
      case MeshtasticConnectionState.disconnected:
        _status = AppConnectionStatus.disconnected;
      case MeshtasticConnectionState.connecting:
      case MeshtasticConnectionState.configuring:
        _status = AppConnectionStatus.connecting;
      case MeshtasticConnectionState.error:
        _status = AppConnectionStatus.error;
        _errorMessage = sdkStatus.errorMessage;
    }
    notifyListeners();
  }

  String _getNodeName(int nodeId) {
    final node = _knownNodes.where((n) => n.nodeId == nodeId).firstOrNull;
    return node?.displayName ?? '!${nodeId.toRadixString(16)}';
  }

  // =====================================================
  // ENVÍO DE MENSAJES
  // =====================================================

  Future<void> sendMessage(String text, {int? destinationId, int channel = 0}) async {
    if (!isConnected) return;
    if (FragmentService.fitsInSinglePacket(text)) {
      await _client.sendTextMessage(text, destinationId: destinationId, channel: channel);
    } else {
      final msgId = _uuid.v4().substring(0, 8);
      final fragments = _fragmentService.fragmentMessage(msgId, text);
      for (final frag in fragments) {
        await _client.sendTextMessage(frag, destinationId: destinationId, channel: channel);
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> sendToGateway(String text) async {
    await sendMessage(text, destinationId: gatewayNodeId);
  }

  Future<void> sendAIQuestion(String studentId, String contextId, String question) async {
    await sendToGateway('PREGUNTA_IA|$studentId|$contextId|$question');
  }

  Future<void> sendSubmission(String assignmentId, String studentId, String response) async {
    await sendToGateway('ENTREGA|$assignmentId|$studentId|$response');
  }

  Future<void> sendLesson(Lesson lesson) async {
    await sendMessage('LECCION|${lesson.id}|${lesson.subject}|${lesson.grade}|${lesson.title}|${lesson.summary}');
  }

  Future<void> sendAssignment(Assignment assignment, int studentNodeId) async {
    final deadline = assignment.deadline?.toIso8601String() ?? '';
    await sendMessage('TAREA|${assignment.id}|${assignment.studentId ?? ''}|${assignment.description}|$deadline',
        destinationId: studentNodeId);
  }

  Future<void> sendTeacherEvaluation(String assignmentId, String studentId, String criteria, String grade) async {
    await sendToGateway('EVAL_PROF|$assignmentId|$studentId|$criteria|$grade');
  }

  Future<void> sendProfileUpdate(String studentId, String field, String value) async {
    await sendToGateway('PERFIL_UPDATE|$studentId|$field|$value');
  }

  Future<void> sendChatMessage(String text, {int? destinationId, int channel = 0}) async {
    await sendMessage(text, destinationId: destinationId, channel: channel);
    final message = ChatMessage(
      messageText: text,
      fromNodeId: _client.myNodeInfo?.myNodeNum ?? 0,
      fromNodeName: _client.localUser?.longName ?? 'Yo',
      timestamp: DateTime.now(), channel: channel,
      toNodeId: destinationId, isDirectMessage: destinationId != null,
      isMine: true, deliveryStatus: DeliveryStatus.sending,
    );
    _messageHistory.add(message);
    _messageController.add(message);
    notifyListeners();
  }

  void markChatAsRead() {
    _unreadChatCount = 0;
    notifyListeners();
  }

  Future<void> loadLocalData() async {
    _activeLesson = await _storage.getActiveLesson();
    _assignments = await _storage.getAssignments();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _messageController.close();
    _lessonController.close();
    _assignmentController.close();
    _evaluationController.close();
    _aiResponseController.close();
    _client.disconnect();
    _storage.close();
    super.dispose();
  }
}
