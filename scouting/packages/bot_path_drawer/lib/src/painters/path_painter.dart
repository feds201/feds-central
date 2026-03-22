import 'dart:math';

import 'package:fit_curve/fit_curve.dart' show CubicCurve;
import 'package:flutter/material.dart';

import '../models/bot_path_config.dart';

/// Paints the robot path overlay on the field canvas.
///
/// This painter renders all visual elements of a recorded robot path:
/// - The raw trail while recording (semi-transparent line following the finger)
/// - The simplified Bezier curve path after recording is finalized
/// - Start (green) and end (red) indicator circles at path endpoints
/// - The live robot rectangle while the user is drawing
/// - A highlight circle around the live robot for touch visibility
/// - The end-of-path robot when the path is finalized but not playing
/// - The animated playback robot during path replay
///
/// Used by both the drawer widget (during recording) and the viewer widget
/// (during playback). All colors and sizes are driven by [BotPathConfig].
class PathPainter extends CustomPainter {
  /// Configuration for colors and sizing.
  final BotPathConfig config;

  /// Raw trail points captured while recording.
  ///
  /// When this list has 2 or more points, a semi-transparent trail is
  /// drawn connecting them. This list is typically empty once the path
  /// has been finalized into [fittedCurves].
  final List<Offset> rawPath;

  /// Simplified cubic Bezier curves representing the finalized path.
  ///
  /// When non-empty, the full Bezier path is drawn along with start/end
  /// indicator circles. This list is typically empty while still recording.
  final List<CubicCurve> fittedCurves;

  /// The live robot position while the user's finger is down.
  ///
  /// When non-null, a highlight circle and robot rectangle are drawn
  /// at this position. Typically set during active path recording.
  final Offset? robotPosition;

  /// The rotation angle of the live robot in radians.
  ///
  /// 0 means the intake (front) faces right.
  final double robotRotation;

  /// Robot position at the end of the finalized path.
  ///
  /// When non-null and [playbackRobotPos] is null, a robot rectangle
  /// is drawn at this position to show where the path ends.
  final Offset? endRobotPos;

  /// Rotation angle of the end-of-path robot in radians.
  final double endRobotRot;

  /// Robot position during animated playback.
  ///
  /// When non-null, a robot rectangle is drawn at this position.
  /// This takes priority over [endRobotPos] — when a playback robot
  /// is visible, the end-of-path robot is hidden.
  final Offset? playbackRobotPos;

  /// Rotation angle of the playback robot in radians.
  final double playbackRobotRot;

  /// Whether to show the touch highlight circle around the live robot.
  /// Typically true on touch devices, false on desktop.
  final bool showHighlight;

  /// Creates a [PathPainter] that draws the path overlay.
  ///
  /// All positional parameters ([rawPath], [robotPosition], etc.) should
  /// use the same coordinate system as the canvas (pixel coordinates
  /// within the field image).
  const PathPainter({
    required this.config,
    required this.rawPath,
    required this.fittedCurves,
    required this.robotPosition,
    required this.robotRotation,
    required this.endRobotPos,
    required this.endRobotRot,
    required this.playbackRobotPos,
    required this.playbackRobotRot,
    this.showHighlight = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final robotPixels = size.width * config.robotSizeFraction;
    const lineWidth = 4.0;
    final dotRadius = lineWidth * 2;
    // For raw trail (semi-transparent path color)
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth
      ..color = Color.from(
        alpha: 0.5,
        red: config.pathColor.r,
        green: config.pathColor.g,
        blue: config.pathColor.b,
      );

    // For fitted path
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth
      ..color = config.pathColor;

    // Raw trail while recording (semi-transparent path color)
    if (rawPath.length >= 2) {
      final trail = Path();
      trail.moveTo(rawPath.first.dx, rawPath.first.dy);
      for (final p in rawPath.skip(1)) {
        trail.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(trail, trailPaint);
    }

    // Simplified Bezier path with start/end circles
    if (fittedCurves.isNotEmpty) {
      final curvePath = Path();
      final startPt = Offset(
        fittedCurves.first.point1.x,
        fittedCurves.first.point1.y,
      );
      final endPt = Offset(
        fittedCurves.last.point2.x,
        fittedCurves.last.point2.y,
      );

      curvePath.moveTo(startPt.dx, startPt.dy);
      for (final c in fittedCurves) {
        curvePath.cubicTo(
          c.handle1.x,
          c.handle1.y,
          c.handle2.x,
          c.handle2.y,
          c.point2.x,
          c.point2.y,
        );
      }
      canvas.drawPath(curvePath, curvePaint);

      canvas.drawCircle(startPt, dotRadius, Paint()..color = config.startColor);
      canvas.drawCircle(endPt, dotRadius, Paint()..color = config.endColor);
    }

    // Live robot with optional highlight circle (while finger/mouse is held down)
    if (robotPosition != null) {
      if (showHighlight) {
        final highlightRadius =
            size.width * config.robotSizeFraction * config.highlightSizeMultiplier / 2;

        canvas.drawCircle(
          robotPosition!,
          highlightRadius,
          Paint()
            ..color = Color.from(
              alpha: 0.2,
              red: config.pathColor.r,
              green: config.pathColor.g,
              blue: config.pathColor.b,
            ),
        );
      }

      drawRobot(
        canvas,
        robotPosition!,
        robotRotation,
        robotPixels,
        config.pathColor,
        config.robotColor,
      );
    }

    // Robot at end of finalized path (hidden during playback)
    if (endRobotPos != null && playbackRobotPos == null) {
      drawRobot(
        canvas,
        endRobotPos!,
        endRobotRot,
        robotPixels,
        config.pathColor,
        config.robotColor,
      );
    }

    // Playback robot (animated position during replay)
    if (playbackRobotPos != null) {
      drawRobot(
        canvas,
        playbackRobotPos!,
        playbackRobotRot,
        robotPixels,
        config.pathColor,
        config.robotColor,
      );
    }
  }

  /// Draws a robot rectangle at [center] with the given [rotation].
  ///
  /// The robot is rendered as a square with side length [robotSize], with
  /// the intake (front) edge facing right when [rotation] is 0. It consists
  /// of:
  /// - A semi-transparent fill using [robotColor]
  /// - A white border on all four sides
  /// - A thick [pathColor] line on the right edge (intake/front)
  /// - "INTAKE" text rotated vertically outside the intake edge
  ///
  /// This is a static method so it can be reused by other painters (e.g.,
  /// the dial painter) without instantiating a [PathPainter].
  static void drawRobot(
    Canvas canvas,
    Offset center,
    double rotation,
    double robotSize,
    Color pathColor,
    Color robotColor,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final half = robotSize / 2;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: robotSize,
      height: robotSize,
    );

    // Robot body fill
    canvas.drawRect(
      rect,
      Paint()
        ..color = robotColor
        ..style = PaintingStyle.fill,
    );

    // White border on all sides
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Intake (front) edge — thick colored line on the right side
    canvas.drawLine(
      Offset(half, -half),
      Offset(half, half),
      Paint()
        ..color = pathColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.square,
    );

    // "INTAKE" text rotated outside the intake edge (reads bottom to top)
    final tp = TextPainter(
      text: TextSpan(
        text: 'INTAKE',
        style: TextStyle(
          color: pathColor,
          fontSize: robotSize * 0.44,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    // Gap between rect edge and text = half the text height
    canvas.translate(half + 3.5 + tp.height * 0.5, 0);
    canvas.rotate(-pi / 2);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return config != oldDelegate.config ||
        rawPath != oldDelegate.rawPath ||
        fittedCurves != oldDelegate.fittedCurves ||
        robotPosition != oldDelegate.robotPosition ||
        robotRotation != oldDelegate.robotRotation ||
        endRobotPos != oldDelegate.endRobotPos ||
        endRobotRot != oldDelegate.endRobotRot ||
        playbackRobotPos != oldDelegate.playbackRobotPos ||
        playbackRobotRot != oldDelegate.playbackRobotRot ||
        showHighlight != oldDelegate.showHighlight;
  }
}
