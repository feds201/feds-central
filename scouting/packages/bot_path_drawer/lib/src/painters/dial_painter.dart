import 'dart:math';

import 'package:flutter/material.dart';

/// Paints the rotation dial as a donut shape with a colored indicator.
///
/// The dial consists of a dark donut ring (near-black outer circle with a
/// slightly lighter inner circle), a colored indicator circle positioned
/// on the ring at the current [rotation] angle, and a small directional
/// arrow drawn from the center toward the rotation angle.
///
/// The indicator and arrow use [indicatorColor], which is typically set
/// to match the path color for visual consistency.
class DialPainter extends CustomPainter {
  /// Current rotation angle in radians.
  ///
  /// 0 means facing right (3 o'clock position). Positive values rotate
  /// clockwise. The indicator circle is positioned on the ring at this
  /// angle.
  final double rotation;

  /// Color for the indicator circle and the directional arrow.
  ///
  /// Typically matches the path color from [BotPathConfig.pathColor].
  final Color indicatorColor;

  /// Creates a [DialPainter] with the given [rotation] and [indicatorColor].
  const DialPainter({
    required this.rotation,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final ringWidth = outerRadius * 0.50;
    final midRadius = outerRadius - ringWidth / 2;
    final innerRadius = outerRadius - ringWidth;
    final indicatorRadius = ringWidth / 2;

    // Dark donut ring background
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()..color = const Color(0xDD222222),
    );
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = const Color(0xFF333333),
    );

    // Indicator circle at the current rotation angle on the ring
    final indicatorCenter = Offset(
      center.dx + midRadius * cos(rotation),
      center.dy + midRadius * sin(rotation),
    );
    canvas.drawCircle(
      indicatorCenter,
      indicatorRadius,
      Paint()..color = indicatorColor,
    );

    // Small directional arrow from center toward the rotation angle
    final arrowTip = Offset(
      center.dx + innerRadius * 0.5 * cos(rotation),
      center.dy + innerRadius * 0.5 * sin(rotation),
    );
    canvas.drawLine(
      center,
      arrowTip,
      Paint()
        ..color = indicatorColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.indicatorColor != indicatorColor;
}
