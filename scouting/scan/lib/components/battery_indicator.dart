import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BatteryIndicator extends StatelessWidget {
  final int percentage;
  final String label;
  final Color? color;

  const BatteryIndicator({
    super.key,
    required this.percentage,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color batteryColor = color ?? _getBatteryColor(percentage);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage}%',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: batteryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.yellow;
    if (percentage >= 20) return Colors.orange;
    return Colors.red;
  }
}
