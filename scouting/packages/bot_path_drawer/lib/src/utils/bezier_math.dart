import 'dart:math';

import 'package:fit_curve/fit_curve.dart' show CubicCurve;
import 'package:flutter/painting.dart';

/// Evaluates a cubic Bezier curve at parameter [t] (0.0 to 1.0).
///
/// Returns the point on the curve at the given parameter value.
/// At t=0 returns the start point, at t=1 returns the end point.
///
/// Uses the standard cubic Bezier formula:
/// B(t) = (1-t)^3 * P0 + 3*(1-t)^2*t * P1 + 3*(1-t)*t^2 * P2 + t^3 * P3
Offset evalBezier(CubicCurve curve, double t) {
  final u = 1.0 - t;
  final u2 = u * u;
  final u3 = u2 * u;
  final t2 = t * t;
  final t3 = t2 * t;

  final x = u3 * curve.point1.x +
      3 * u2 * t * curve.handle1.x +
      3 * u * t2 * curve.handle2.x +
      t3 * curve.point2.x;

  final y = u3 * curve.point1.y +
      3 * u2 * t * curve.handle1.y +
      3 * u * t2 * curve.handle2.y +
      t3 * curve.point2.y;

  return Offset(x, y);
}

/// Interpolates between two angles taking the shortest rotational path.
///
/// Handles wraparound at +/- pi so that interpolation between 170 degrees
/// and -170 degrees takes the short 20-degree path, not the long 340-degree
/// path.
///
/// [from] and [to] are angles in radians. [t] is the interpolation
/// parameter (0.0 returns [from], 1.0 returns [to]).
double lerpAngle(double from, double to, double t) {
  var delta = (to - from) % (2 * pi);

  // Force the shortest path by wrapping delta into (-pi, pi]
  if (delta > pi) {
    delta -= 2 * pi;
  } else if (delta <= -pi) {
    delta += 2 * pi;
  }

  return from + delta * t;
}
