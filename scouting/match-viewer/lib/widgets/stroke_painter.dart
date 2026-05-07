import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../viewer/drawing_controller.dart';

/// CustomPainter that renders drawing strokes with quadratic bezier smoothing.
///
/// Supports per-stroke colors via [ColoredStroke]. The current in-progress
/// stroke uses [currentColor]. Opacity is adjustable via [opacity].
class StrokePainter extends CustomPainter {
  final List<ColoredStroke> strokes;
  final List<Offset> currentStrokePoints;
  final DrawingColor currentColor;
  final double opacity;

  /// Stroke width in logical pixels.
  static const double strokeWidth = 3.5;

  StrokePainter({
    required this.strokes,
    required this.currentStrokePoints,
    required this.currentColor,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final paint = _makePaint(stroke.color);
      _drawStroke(canvas, stroke.points, paint);
    }

    if (currentStrokePoints.isNotEmpty) {
      final paint = _makePaint(currentColor);
      _drawStroke(canvas, currentStrokePoints, paint);
    }
  }

  Paint _makePaint(DrawingColor color) {
    return Paint()
      ..color = color.color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(points[0], strokeWidth / 2, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      return;
    }

    final path = ui.Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      // Quadratic bezier through midpoints for smooth curves
      for (int i = 1; i < points.length - 1; i++) {
        final midX = (points[i].dx + points[i + 1].dx) / 2;
        final midY = (points[i].dy + points[i + 1].dy) / 2;
        path.quadraticBezierTo(
          points[i].dx,
          points[i].dy,
          midX,
          midY,
        );
      }
      // Draw to the last point
      final last = points.last;
      path.lineTo(last.dx, last.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}
