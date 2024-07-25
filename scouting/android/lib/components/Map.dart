import 'package:flutter/material.dart';

Widget buildMap(BuildContext context, Offset? _circlePosition, Size size, Function(Offset) onTap, String AllianceColor) {
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
              onTapDown: (details) {
                onTap(details.localPosition);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0), // Add border radius here
                child: Image.asset(
                  'assets/${AllianceColor}Alliance_StartPosition.png',
                ),
              ),
            ),
            if (_circlePosition != null)
              Positioned(
                left: _circlePosition.dx - 15, // Center the circle
                top: _circlePosition.dy - 15, // Center the circle
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