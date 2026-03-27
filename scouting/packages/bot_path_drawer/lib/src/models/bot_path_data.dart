import 'dart:math';

import 'package:fit_curve/fit_curve.dart' show CubicCurve;
import 'package:flutter/material.dart';

/// Represents a serialized robot path with position, rotation, and timing data.
///
/// The path geometry is stored as cubic Bezier curves in **normalized
/// coordinates** (0-1 range). Both x and y are divided by
/// `max(canvasWidth, canvasHeight)` at recording time, which preserves
/// the original aspect ratio. Pixel scaling happens only at render time
/// via [scaledCurves], [scaledEndpoints], and [toFlutterPath].
///
/// ## Serialization Format
///
/// The path serializes to a compact string:
/// ```
/// SVG_PATH|rot:ts,rot:ts,...
/// ```
///
/// - **SVG_PATH**: Standard SVG path commands (M for moveTo, C for cubic
///   Bezier) using normalized 0-1 coordinates.
/// - **rot:ts pairs**: Rotation in radians and timestamp in milliseconds
///   at each waypoint (start point + each curve endpoint).
///
/// Example:
/// ```
/// M0.083,0.573C0.098,0.559 0.241,0.397 0.390,0.317|0.00:0,1.57:450,3.14:1200
/// ```
class BotPathData {
  /// Cubic Bezier curves in normalized coordinates (0-1 range).
  ///
  /// Both x and y are divided by `max(canvasWidth, canvasHeight)` to
  /// preserve aspect ratio. Use [scaledCurves] to obtain pixel coordinates.
  final List<CubicCurve> curves;

  /// Rotation (radians) at each waypoint.
  ///
  /// Length is `curves.length + 1` (one for the start point, plus one
  /// for each curve endpoint).
  final List<double> rotations;

  /// Timestamp (milliseconds) at each waypoint.
  ///
  /// Timestamps are relative to the start of drawing (first point is 0).
  /// Length matches [rotations].
  final List<int> timestamps;

  /// Creates a new [BotPathData] from pre-normalized curves and metadata.
  ///
  /// The [curves] must already be in normalized 0-1 coordinates.
  const BotPathData({
    required this.curves,
    required this.rotations,
    required this.timestamps,
  });

  /// Creates a [BotPathData] by normalizing pixel-coordinate curves.
  ///
  /// [curves] are in pixel coordinates from the recording canvas.
  /// [canvasSize] is the canvas size at time of recording, used to compute
  /// the normalization scale factor `max(width, height)`.
  factory BotPathData.fromPixelCurves({
    required List<CubicCurve> curves,
    required List<double> rotations,
    required List<int> timestamps,
    required Size canvasSize,
  }) {
    final scale = max(canvasSize.width, canvasSize.height);
    final normalized = curves
        .map((c) => CubicCurve(
              Point(c.point1.x / scale, c.point1.y / scale),
              Point(c.handle1.x / scale, c.handle1.y / scale),
              Point(c.handle2.x / scale, c.handle2.y / scale),
              Point(c.point2.x / scale, c.point2.y / scale),
            ))
        .toList();
    return BotPathData(
      curves: normalized,
      rotations: rotations,
      timestamps: timestamps,
    );
  }

  /// Serializes this path data to a compact string representation.
  ///
  /// Coordinates are already normalized (0-1 range) so they are written
  /// directly. The returned string uses the format `SVG_PATH|rot:ts,rot:ts,...`.
  /// Coordinates use 3 decimal places, rotations use 2, and timestamps
  /// are integers.
  String serialize() {
    final svgBuffer = StringBuffer();

    // Move to the start point of the first curve
    final start = curves.first.point1;
    svgBuffer.write(
      'M${_fmt3(start.x)},${_fmt3(start.y)}',
    );

    // Append cubic bezier commands for each curve
    for (final curve in curves) {
      svgBuffer.write(
        'C${_fmt3(curve.handle1.x)},${_fmt3(curve.handle1.y)} '
        '${_fmt3(curve.handle2.x)},${_fmt3(curve.handle2.y)} '
        '${_fmt3(curve.point2.x)},${_fmt3(curve.point2.y)}',
      );
    }

    // Build the rotation:timestamp pairs
    final rotTsPairs = <String>[];
    for (var i = 0; i < rotations.length; i++) {
      rotTsPairs.add('${_fmt2(rotations[i])}:${timestamps[i]}');
    }

    return '$svgBuffer|${rotTsPairs.join(',')}';
  }

  /// Parses a serialized path string into normalized [BotPathData].
  ///
  /// Returns `null` if [data] is malformed or cannot be parsed.
  /// The returned [BotPathData] contains normalized 0-1 coordinates.
  static BotPathData? tryParse(String data) {
    try {
      final parts = data.split('|');
      if (parts.length != 2) return null;

      final svgPart = parts[0];
      final rotTsPart = parts[1];

      // Parse rotation:timestamp pairs
      final pairs = rotTsPart.split(',');
      final rotations = <double>[];
      final timestamps = <int>[];
      for (final pair in pairs) {
        final components = pair.split(':');
        if (components.length != 2) return null;
        rotations.add(double.parse(components[0]));
        timestamps.add(int.parse(components[1]));
      }

      // Parse SVG path to extract cubic bezier curves.
      // We only handle M (moveTo) and C (cubic bezier) commands since
      // that is all we generate in serialize().
      final curves = <CubicCurve>[];
      Point<double>? currentPoint;

      final commandRegex = RegExp(r'[MC]');
      final segments = <String>[];
      final commandTypes = <String>[];

      var lastIndex = 0;
      for (final match in commandRegex.allMatches(svgPart)) {
        if (lastIndex != match.start) {
          segments.add(svgPart.substring(lastIndex, match.start));
        }
        commandTypes.add(match.group(0)!);
        lastIndex = match.end;
      }
      if (lastIndex < svgPart.length) {
        segments.add(svgPart.substring(lastIndex));
      }

      // The first segment is empty (before first M), shift alignment
      for (var i = 0; i < commandTypes.length; i++) {
        final cmd = commandTypes[i];
        final args = segments[i].trim();

        if (cmd == 'M') {
          final coords = args.split(',');
          if (coords.length != 2) return null;
          currentPoint = Point(
            double.parse(coords[0]),
            double.parse(coords[1]),
          );
        } else if (cmd == 'C') {
          if (currentPoint == null) return null;
          // Parse "h1x,h1y h2x,h2y px,py"
          final pointStrs = args.split(RegExp(r'\s+'));
          if (pointStrs.length != 3) return null;

          final h1 = pointStrs[0].split(',');
          final h2 = pointStrs[1].split(',');
          final p2 = pointStrs[2].split(',');

          if (h1.length != 2 || h2.length != 2 || p2.length != 2) return null;

          final endPoint = Point(
            double.parse(p2[0]),
            double.parse(p2[1]),
          );

          curves.add(CubicCurve(
            currentPoint,
            Point(double.parse(h1[0]), double.parse(h1[1])),
            Point(double.parse(h2[0]), double.parse(h2[1])),
            endPoint,
          ));

          currentPoint = endPoint;
        }
      }

      if (curves.isEmpty) return null;
      if (rotations.length != curves.length + 1) return null;
      if (timestamps.length != rotations.length) return null;

      return BotPathData(
        curves: curves,
        rotations: rotations,
        timestamps: timestamps,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns curves scaled to pixel coordinates for the given [canvasSize].
  ///
  /// The scale factor is `max(canvasSize.width, canvasSize.height)`, matching
  /// the normalization used during recording.
  List<CubicCurve> scaledCurves(Size canvasSize) {
    final scale = max(canvasSize.width, canvasSize.height);
    return curves
        .map((c) => CubicCurve(
              Point(c.point1.x * scale, c.point1.y * scale),
              Point(c.handle1.x * scale, c.handle1.y * scale),
              Point(c.handle2.x * scale, c.handle2.y * scale),
              Point(c.point2.x * scale, c.point2.y * scale),
            ))
        .toList();
  }

  /// Returns waypoint positions scaled to pixel coordinates.
  ///
  /// The list contains the start point followed by each curve endpoint,
  /// giving `curves.length + 1` entries. Useful for drawing robot
  /// rectangles at waypoints.
  List<Offset> scaledEndpoints(Size canvasSize) {
    if (curves.isEmpty) return [];

    final scale = max(canvasSize.width, canvasSize.height);
    final points = <Offset>[
      Offset(curves.first.point1.x * scale, curves.first.point1.y * scale),
    ];

    for (final curve in curves) {
      points.add(Offset(curve.point2.x * scale, curve.point2.y * scale));
    }

    return points;
  }

  /// Converts the normalized curves to a Flutter [Path] in pixel coordinates.
  ///
  /// The returned path can be drawn directly onto a canvas of the given
  /// [canvasSize].
  Path toFlutterPath(Size canvasSize) {
    final path = Path();
    if (curves.isEmpty) return path;

    final scale = max(canvasSize.width, canvasSize.height);

    final start = curves.first.point1;
    path.moveTo(start.x * scale, start.y * scale);

    for (final curve in curves) {
      path.cubicTo(
        curve.handle1.x * scale,
        curve.handle1.y * scale,
        curve.handle2.x * scale,
        curve.handle2.y * scale,
        curve.point2.x * scale,
        curve.point2.y * scale,
      );
    }

    return path;
  }

  /// Formats a double to 3 decimal places.
  static String _fmt3(double value) => value.toStringAsFixed(3);

  /// Formats a double to 2 decimal places.
  static String _fmt2(double value) => value.toStringAsFixed(2);
}
