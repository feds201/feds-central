import 'package:flutter/material.dart';

void _defaultOnTap(TapUpDetails details) {}
Widget buildMap(BuildContext context, Offset? circlePosition, Size size, String AllianceColor, {Function(TapUpDetails) onTap = _defaultOnTap}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7.0),
        child: Stack(
          children: [
            GestureDetector(
              onTapUp: (details) {
                onTap(details);

              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0), // Add border radius here
                child: Image.asset(
                  'assets/${AllianceColor}Alliance_StartPosition.png',
                ),
              ),
            ),
            if (circlePosition != null)
              Positioned(
                left: circlePosition.dx - 15, // Center the circle
                top: circlePosition.dy - 15, // Center the circle
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15), // Add border radius here
                    child: Image.asset(
                      'assets/Swerve.png',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}