import 'package:flutter/material.dart';
import 'package:sirius_edu/models/chat_message.dart';

/// Indicador visual del estado de entrega de un mensaje.
class DeliveryIndicator extends StatelessWidget {
  final DeliveryStatus status;
  final double size;

  const DeliveryIndicator({
    super.key,
    required this.status,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DeliveryStatus.sending:
        return Icon(Icons.access_time, size: size, color: const Color(0xFF95A5A6));
      case DeliveryStatus.delivered:
        return Icon(Icons.done, size: size, color: const Color(0xFF27AE60));
      case DeliveryStatus.failed:
        return Icon(Icons.error_outline, size: size, color: const Color(0xFFE74C3C));
      case DeliveryStatus.none:
        return SizedBox(width: size, height: size);
    }
  }
}
