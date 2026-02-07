import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoutHeader extends StatelessWidget {
  const ScoutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Increased height to account for status bar area
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 40.0, // Add top padding to push content down from status bar area
          bottom: 16.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Red status indicator
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            
            // Title
            Text(
              'SCOUT OPS DATA',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            
            // Spacer for alignment
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
