import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// CustomPainter that renders drawing strokes with quadratic bezier smoothing.
///
/// All strokes are drawn in red with adjustable opacity via [opacity].
/// Uses quadratic bezier curves through midpoints for smooth lines.
class StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final double opacity;

  /// Stroke width in logical pixels.
  static const double strokeWidth = 3.5;

  StrokePainter({
    required this.strokes,
    required this.currentStroke,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
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
