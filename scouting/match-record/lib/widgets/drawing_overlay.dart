import 'package:flutter/material.dart';

import '../viewer/drawing_controller.dart';
import 'stroke_painter.dart';

/// Overlay widget that captures raw pointer events for drawing.
///
/// Uses [Listener] instead of [GestureDetector] for raw pointer events.
/// Intentionally does NOT track pointer IDs — multi-touch points interleave
/// into the same stroke, which is acceptable for stylus/finger drawing.
class DrawingOverlay extends StatelessWidget {
  final DrawingController controller;

  const DrawingOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Listener(
          onPointerDown: (event) {
            controller.onPointerDown(event.localPosition);
          },
          onPointerMove: (event) {
            controller.onPointerMove(event.localPosition);
          },
          onPointerUp: (_) {
            controller.onPointerUp();
          },
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: StrokePainter(
              strokes: controller.strokes,
              currentStroke: controller.currentStroke,
              opacity: controller.opacity,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}
