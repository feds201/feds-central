import 'dart:math';

import 'package:fit_curve/fit_curve.dart' show CubicCurve;
import 'package:flutter/material.dart';

/// Represents a serialized robot path with position, rotation, and timing data.
///
/// The path geometry is stored as cubic Bezier curves in **normalized
/// coordinates** (0-1 range). Pixel scaling happens only at render time
/// via [scaledCurves], [scaledEndpoints], and [toFlutterPath].
///
/// ## Path Format Versions
///
/// - **v1** (implicit/legacy): Coordinates normalized by
///   `max(canvasWidth, canvasHeight)` where canvas dimensions include the
///   crop. Paths recorded at different crop fractions produce different
///   normalized coordinates for the same physical field position, causing
///   distortion when viewed at a different crop.
///
/// - **v2** (current): Coordinates normalized by
///   `max(canvasWidth / cropFraction, canvasHeight)`, effectively
///   normalizing against the full uncropped image dimensions. This makes
///   paths crop-independent — a path recorded at crop 0.70 displays
///   correctly at crop 1.0.
///
/// ## Serialization Format
///
/// The path serializes to a compact string:
/// ```
/// [vN:]SVG_PATH|rot:ts,rot:ts,...
/// ```
///
/// - **vN:** (optional): Version prefix. Absent for v1 (legacy).
/// - **SVG_PATH**: Standard SVG path commands (M for moveTo, C for cubic
///   Bezier) using normalized 0-1 coordinates.
/// - **rot:ts pairs**: Rotation in radians and timestamp in milliseconds
///   at each waypoint (start point + each curve endpoint).
///
/// Example (v2):
/// ```
/// v2:M0.083,0.573C0.098,0.559 0.241,0.397 0.390,0.317|0.00:0,1.57:450,3.14:1200
/// ```
class BotPathData {
  /// Current serialization format version.
  ///
  /// Newly recorded paths are always written at this version.
  /// See the class-level documentation for what each version means.
  static const int version = 2;

  /// Cubic Bezier curves in normalized coordinates (0-1 range).
  ///
  /// Use [scaledCurves] to obtain pixel coordinates.
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

  /// The format version this path was recorded/parsed with.
  ///
  /// Controls how [scaledCurves], [scaledEndpoints], and [toFlutterPath]
  /// compute the scale factor. See [scaleFactor].
  final int formatVersion;

  /// Creates a new [BotPathData] from pre-normalized curves and metadata.
  ///
  /// The [curves] must already be in normalized 0-1 coordinates.
  /// [formatVersion] defaults to the current [version].
  const BotPathData({
    required this.curves,
    required this.rotations,
    required this.timestamps,
    this.formatVersion = version,
  });

  /// Computes the scale factor for normalizing/scaling coordinates.
  ///
  /// The scale factor depends on [formatVersion]:
  /// - **v1**: `max(canvasWidth, canvasHeight)` (legacy, crop-dependent)
  /// - **v2**: `max(canvasWidth / cropFraction, canvasHeight)` (crop-independent)
  ///
  /// To add a new version, add a case to the switch below.
  static double scaleFactor(
    int formatVersion,
    Size canvasSize,
    double cropFraction,
  ) {
    switch (formatVersion) {
      case 1:
        return max(canvasSize.width, canvasSize.height);
      case 2:
      default:
        return max(canvasSize.width / cropFraction, canvasSize.height);
    }
  }

  /// Creates a [BotPathData] by normalizing pixel-coordinate curves.
  ///
  /// [curves] are in pixel coordinates from the recording canvas.
  /// [canvasSize] is the canvas size at time of recording.
  /// [cropFraction] is the crop fraction used when recording, needed to
  /// compute the crop-independent normalization scale.
  factory BotPathData.fromPixelCurves({
    required List<CubicCurve> curves,
    required List<double> rotations,
    required List<int> timestamps,
    required Size canvasSize,
    required double cropFraction,
  }) {
    final scale = scaleFactor(version, canvasSize, cropFraction);
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
  /// directly. The returned string uses the format
  /// `[vN:]SVG_PATH|rot:ts,rot:ts,...`. The version prefix is omitted for
  /// v1 (legacy) paths. Coordinates use 3 decimal places, rotations use 2,
  /// and timestamps are integers.
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

    final payload = '$svgBuffer|${rotTsPairs.join(',')}';
    return formatVersion >= 2 ? 'v$formatVersion:$payload' : payload;
  }

  /// Parses a serialized path string into normalized [BotPathData].
  ///
  /// Returns `null` if [data] is malformed or cannot be parsed.
  /// The returned [BotPathData] contains normalized 0-1 coordinates.
  /// Detects the version prefix (`vN:`) if present; defaults to v1.
  static BotPathData? tryParse(String data) {
    try {
      // Detect version prefix: "v2:", "v3:", etc.
      var formatVersion = 1;
      var payload = data;
      final versionMatch = RegExp(r'^v(\d+):').firstMatch(data);
      if (versionMatch != null) {
        formatVersion = int.parse(versionMatch.group(1)!);
        payload = data.substring(versionMatch.end);
      }

      final parts = payload.split('|');
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
        formatVersion: formatVersion,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns curves scaled to pixel coordinates for the given [canvasSize].
  ///
  /// [cropFraction] is the crop fraction of the viewing canvas, used by v2+
  /// paths to compute the correct scale. Defaults to 1.0 (full image).
  List<CubicCurve> scaledCurves(Size canvasSize, {double cropFraction = 1.0}) {
    final scale = scaleFactor(formatVersion, canvasSize, cropFraction);
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
  ///
  /// [cropFraction] is the crop fraction of the viewing canvas, used by v2+
  /// paths to compute the correct scale. Defaults to 1.0 (full image).
  List<Offset> scaledEndpoints(Size canvasSize, {double cropFraction = 1.0}) {
    if (curves.isEmpty) return [];

    final scale = scaleFactor(formatVersion, canvasSize, cropFraction);
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
  ///
  /// [cropFraction] is the crop fraction of the viewing canvas, used by v2+
  /// paths to compute the correct scale. Defaults to 1.0 (full image).
  Path toFlutterPath(Size canvasSize, {double cropFraction = 1.0}) {
    final path = Path();
    if (curves.isEmpty) return path;

    final scale = scaleFactor(formatVersion, canvasSize, cropFraction);

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
