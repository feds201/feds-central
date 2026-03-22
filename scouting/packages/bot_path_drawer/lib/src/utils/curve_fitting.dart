import 'dart:math';

import 'package:fit_curve/fit_curve.dart' hide Curve;
import 'package:fit_curve/fit_curve.dart' as fc show CubicCurve;
import 'package:flutter/painting.dart';

/// A raw recorded point with position, rotation, and timestamp.
///
/// Captured during the drawing gesture, before any filtering or curve fitting.
class RawPathPoint {
  /// The pixel position of this point on the canvas.
  final Offset position;

  /// The robot rotation in radians at this point.
  final double rotation;

  /// Milliseconds elapsed since the start of recording.
  final int timestamp;

  /// Creates a raw path point with the given [position], [rotation], and
  /// [timestamp].
  const RawPathPoint(this.position, this.rotation, this.timestamp);
}

/// Result of curve fitting: the fitted curves plus rotation and timestamp
/// data at each waypoint.
class FitResult {
  /// The fitted cubic Bezier curves.
  final List<fc.CubicCurve> curves;

  /// Rotation (radians) at each waypoint (start point + each curve endpoint).
  final List<double> rotations;

  /// Timestamp (ms) at each waypoint (start point + each curve endpoint).
  final List<int> timestamps;

  /// Creates a [FitResult] with the given [curves], [rotations], and
  /// [timestamps].
  const FitResult(this.curves, this.rotations, this.timestamps);
}

/// Filters raw points to remove jitter, then fits cubic Bezier curves
/// using the Schneider algorithm.
///
/// [rawPoints] - the raw recorded path points with position, rotation,
/// and timestamp.
///
/// [maxError] - error tolerance for curve fitting. Lower values produce
/// more curves with a tighter fit. Higher values produce fewer, more
/// simplified curves.
///
/// [minPointDistance] - minimum pixel distance between consecutive kept
/// points. Points closer than this are discarded to reduce noise from
/// a stationary or slow-moving finger.
///
/// Returns null if there aren't enough points (fewer than 2) after
/// filtering to fit curves.
FitResult? fitPath(
  List<RawPathPoint> rawPoints, {
  double maxError = 50,
  double minPointDistance = 2.0,
}) {
  if (rawPoints.length < 2) return null;

  // Filter out near-duplicate points (jitter removal).
  // Always keep the first point. For subsequent points, only keep them
  // if they are at least minPointDistance away from the last kept point.
  // Always keep the last point to preserve the path endpoint.
  final filtered = <RawPathPoint>[rawPoints.first];

  for (var i = 1; i < rawPoints.length - 1; i++) {
    final lastKept = filtered.last;
    final dx = rawPoints[i].position.dx - lastKept.position.dx;
    final dy = rawPoints[i].position.dy - lastKept.position.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist >= minPointDistance) {
      filtered.add(rawPoints[i]);
    }
  }

  // Always keep the last point
  if (rawPoints.length > 1) {
    filtered.add(rawPoints.last);
  }

  if (filtered.length < 2) return null;

  // Convert filtered points to Point<double> for the fit_curve library
  final points = filtered
      .map((p) => Point<double>(p.position.dx, p.position.dy))
      .toList();

  // Fit cubic Bezier curves using the Schneider algorithm
  final curves = fitCurve(points, maxError.round());

  if (curves.isEmpty) return null;

  // Build rotation and timestamp lists for each waypoint.
  // Waypoints are: start of first curve + endpoint of each curve.
  // For each waypoint, find the closest raw point by walking forward
  // through the raw points in order to preserve timing/pauses.
  final rotations = <double>[];
  final timestamps = <int>[];

  // Collect all waypoint positions
  final waypoints = <Point<double>>[curves.first.point1];
  for (final curve in curves) {
    waypoints.add(curve.point2);
  }

  // Walk through raw points in order, finding the nearest match
  // for each waypoint. We search forward from the previous match
  // position to preserve temporal ordering.
  var searchStart = 0;
  for (final waypoint in waypoints) {
    var bestIdx = searchStart;
    var bestDist = double.infinity;

    for (var i = searchStart; i < rawPoints.length; i++) {
      final dx = rawPoints[i].position.dx - waypoint.x;
      final dy = rawPoints[i].position.dy - waypoint.y;
      final dist = dx * dx + dy * dy;

      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }

    rotations.add(rawPoints[bestIdx].rotation);
    timestamps.add(rawPoints[bestIdx].timestamp);
    searchStart = bestIdx;
  }

  return FitResult(curves, rotations, timestamps);
}
