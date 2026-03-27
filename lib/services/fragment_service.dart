import 'dart:convert';

/// Servicio de fragmentación de mensajes largos para mesh LoRa.
/// Máximo 237 bytes por mensaje mesh. Fragmentos usan header FRAG|id|num|total|
/// dejando ~180 bytes útiles por fragmento.
class FragmentService {
  static const int maxMeshBytes = 237;
  static const int maxPayloadBytes = 180;

  // Fragmentos pendientes de reensamblaje: msgId -> {fragNum: data}
  final Map<String, Map<int, String>> _pendingFragments = {};
  final Map<String, int> _expectedTotals = {};
  final Map<String, DateTime> _fragmentTimestamps = {};

  // Timeout para fragmentos incompletos
  static const Duration fragmentTimeout = Duration(seconds: 60);

  /// Verifica si un mensaje cabe en un solo paquete mesh
  static bool fitsInSinglePacket(String text) {
    return utf8.encode(text).length <= maxMeshBytes;
  }

  /// Fragmenta un mensaje largo en partes de máximo 180 bytes útiles.
  /// Retorna lista de strings con formato: FRAG|msgId|fragNum|total|datos
  List<String> fragmentMessage(String msgId, String content) {
    final contentBytes = utf8.encode(content);

    if (contentBytes.length <= maxMeshBytes) {
      return [content]; // No necesita fragmentación
    }

    final fragments = <String>[];
    var offset = 0;
    var fragNum = 1;

    // Primero calculamos cuántos fragmentos necesitamos
    final chunks = <String>[];
    while (offset < contentBytes.length) {
      var end = offset + maxPayloadBytes;
      if (end > contentBytes.length) end = contentBytes.length;

      // Asegurar corte en frontera de carácter UTF-8 válido
      while (end > offset && (contentBytes[end - 1] & 0xC0) == 0x80) {
        end--;
      }
      if (end > offset && contentBytes[end - 1] >= 0xC0) {
        // Verificar si el carácter multibyte está completo
        final leadByte = contentBytes[end - 1];
        int expectedLen;
        if ((leadByte & 0xE0) == 0xC0) {
          expectedLen = 2;
        } else if ((leadByte & 0xF0) == 0xE0) {
          expectedLen = 3;
        } else {
          expectedLen = 4;
        }
        if (end - 1 + expectedLen > end) {
          end = end - 1; // Excluir carácter incompleto
        }
      }

      final chunk = utf8.decode(contentBytes.sublist(offset, end), allowMalformed: true);
      chunks.add(chunk);
      offset = end;
    }

    final total = chunks.length;
    for (final chunk in chunks) {
      fragments.add('FRAG|$msgId|$fragNum|$total|$chunk');
      fragNum++;
    }

    return fragments;
  }

  /// Recibe un fragmento y trata de reensamblar el mensaje completo.
  /// Retorna el mensaje completo si se tienen todos los fragmentos, null si faltan.
  String? receiveFragment(String fragMessage) {
    _cleanupExpired();

    // Parse: FRAG|msgId|fragNum|total|datos
    final firstPipe = fragMessage.indexOf('|');
    final secondPipe = fragMessage.indexOf('|', firstPipe + 1);
    final thirdPipe = fragMessage.indexOf('|', secondPipe + 1);
    final fourthPipe = fragMessage.indexOf('|', thirdPipe + 1);

    if (fourthPipe == -1) return null;

    final msgId = fragMessage.substring(firstPipe + 1, secondPipe);
    final fragNum = int.tryParse(fragMessage.substring(secondPipe + 1, thirdPipe));
    final total = int.tryParse(fragMessage.substring(thirdPipe + 1, fourthPipe));
    final data = fragMessage.substring(fourthPipe + 1);

    if (fragNum == null || total == null) return null;

    _pendingFragments.putIfAbsent(msgId, () => {});
    _pendingFragments[msgId]![fragNum] = data;
    _expectedTotals[msgId] = total;
    _fragmentTimestamps[msgId] = DateTime.now();

    // Verificar si tenemos todos los fragmentos
    if (_pendingFragments[msgId]!.length == total) {
      final buffer = StringBuffer();
      for (var i = 1; i <= total; i++) {
        buffer.write(_pendingFragments[msgId]![i] ?? '');
      }
      // Limpiar
      _pendingFragments.remove(msgId);
      _expectedTotals.remove(msgId);
      _fragmentTimestamps.remove(msgId);
      return buffer.toString();
    }

    return null;
  }

  /// Retorna lista de fragmentos faltantes para un msgId dado
  List<int> getMissingFragments(String msgId) {
    final total = _expectedTotals[msgId];
    if (total == null) return [];

    final received = _pendingFragments[msgId]?.keys.toSet() ?? {};
    final missing = <int>[];
    for (var i = 1; i <= total; i++) {
      if (!received.contains(i)) missing.add(i);
    }
    return missing;
  }

  /// Limpia fragmentos expirados
  void _cleanupExpired() {
    final now = DateTime.now();
    final expired = <String>[];
    _fragmentTimestamps.forEach((msgId, timestamp) {
      if (now.difference(timestamp) > fragmentTimeout) {
        expired.add(msgId);
      }
    });
    for (final msgId in expired) {
      _pendingFragments.remove(msgId);
      _expectedTotals.remove(msgId);
      _fragmentTimestamps.remove(msgId);
    }
  }

  /// Verifica si hay fragmentos pendientes para un msgId
  bool hasPendingFragments(String msgId) {
    return _pendingFragments.containsKey(msgId);
  }
}
