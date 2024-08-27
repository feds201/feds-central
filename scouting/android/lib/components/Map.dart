import 'package:flutter/material.dart';

void _defaultOnTap(TapUpDetails details) {}

Widget buildMap(BuildContext context, Offset? circlePosition, Size size, String allianceColor, {Function(TapUpDetails)? onTap, Image? image}) {
  onTap ??= _defaultOnTap;
  image ??= Image.asset('assets/${allianceColor}Alliance_StartPosition.png');
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2.0,
            blurRadius: 5.0,
            offset: const Offset(0.0, 3.0), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7.0),
        child: Stack(
          children: [
            GestureDetector(
              onTapUp: (details) {
                onTap!(details);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0), // Add border radius here
                child: image,
              ),
            ),
            if (circlePosition != null)
              Positioned(
                left: circlePosition.dx - 15.0, // Center the circle
                top: circlePosition.dy - 15.0, // Center the circle
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    // Add border radius here
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