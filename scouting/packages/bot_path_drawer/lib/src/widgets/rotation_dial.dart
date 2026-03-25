import 'dart:math';

import 'package:flutter/material.dart';

import '../painters/dial_painter.dart';

/// A donut-shaped dial widget for controlling robot rotation.
///
/// Users drag anywhere on the ring to set the direction the robot's
/// intake faces. The angle is calculated from the touch position
/// relative to the dial's center using [atan2].
///
/// Typically placed below the drawing canvas on touch devices to give
/// users fine-grained control over robot heading without needing a
/// second finger on the field image.
///
/// {@tool snippet}
/// ```dart
/// RotationDial(
///   size: 120,
///   rotation: currentRotation,
///   onChanged: (angle) => setState(() => currentRotation = angle),
///   color: Colors.yellow,
/// )
/// ```
/// {@end-tool}
class RotationDial extends StatelessWidget {
  /// Diameter of the dial in logical pixels.
  ///
  /// The dial is rendered as a square of this size. The donut ring is
  /// inscribed within this square.
  final double size;

  /// Current rotation angle in radians.
  ///
  /// 0 means the intake faces right (3 o'clock position). Positive
  /// values rotate clockwise. This value is displayed by the indicator
  /// circle on the dial ring.
  final double rotation;

  /// Called when the user drags on the dial to change rotation.
  ///
  /// The callback receives the new angle in radians, calculated as the
  /// [atan2] of the touch position relative to the dial center.
  final ValueChanged<double> onChanged;

  /// Color for the indicator circle and directional arrow.
  ///
  /// Typically set to the path color ([BotPathConfig.pathColor]) so the
  /// dial visually matches the path being drawn.
  final Color color;

  /// Creates a [RotationDial] with the given [size], [rotation], callback,
  /// and [color].
  const RotationDial({
    super.key,
    required this.size,
    required this.rotation,
    required this.onChanged,
    required this.color,
  });

  void _handleTouch(Offset localPosition) {
    final center = Offset(size / 2, size / 2);
    onChanged(
      atan2(localPosition.dy - center.dy, localPosition.dx - center.dx),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _handleTouch(details.localPosition),
      onPanUpdate: (details) => _handleTouch(details.localPosition),
      child: CustomPaint(
        size: Size(size, size),
        painter: DialPainter(
          rotation: rotation,
          indicatorColor: color,
        ),
      ),
    );
  }
}
