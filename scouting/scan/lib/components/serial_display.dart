import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SerialDisplay extends StatelessWidget {
  final String serialNumber;

  const SerialDisplay({
    super.key,
    required this.serialNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        serialNumber,
        style: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
