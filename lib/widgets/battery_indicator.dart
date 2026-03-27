import 'package:flutter/material.dart';

/// Indicador visual del nivel de batería de un nodo mesh.
class BatteryIndicator extends StatelessWidget {
  final int? batteryLevel;
  final double? voltage;
  final double size;

  const BatteryIndicator({
    super.key,
    this.batteryLevel,
    this.voltage,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (batteryLevel == null) {
      return Icon(Icons.battery_unknown, size: size, color: const Color(0xFF95A5A6));
    }

    // USB powered
    if (batteryLevel! > 100) {
      return Icon(Icons.power, size: size, color: const Color(0xFF27AE60));
    }

    final level = batteryLevel!;
    IconData icon;
    Color color;

    if (level > 80) {
      icon = Icons.battery_full;
      color = const Color(0xFF27AE60);
    } else if (level > 50) {
      icon = Icons.battery_5_bar;
      color = const Color(0xFF27AE60);
    } else if (level > 20) {
      icon = Icons.battery_3_bar;
      color = const Color(0xFFE67E22);
    } else {
      icon = Icons.battery_1_bar;
      color = const Color(0xFFE74C3C);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size, color: color),
        const SizedBox(width: 2),
        Text(
          '$level%',
          style: TextStyle(fontSize: size * 0.55, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
