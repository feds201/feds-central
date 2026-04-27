import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/bot_path_data.dart';
import 'bezier_math.dart';

/// Vertical line where Mid is decided. Crossing this line left→right means
/// the robot reached "Mid". The y at the crossing also picks Trench vs Bump.
/// Expressed as a fraction of the FULL background image width.
const double _midLineX = 0.28;

/// Robots dipping into the leftmost slice of the field (to either Depot or
/// Outpost) cross this line. Expressed as a fraction of the full bg image
/// width.
const double _leftDipX = 0.07;

/// Number of samples taken along each cubic bezier segment when scanning
/// for events.
const int _samplesPerCurve = 32;

/// Suggests a default human-readable name for a path based on its geometry.
///
/// Output: title-cased tokens joined by single spaces, e.g.
///   "Left Trench Mid", "Center Depot", "Right",
///   "Left Trench Mid Outpost Depot".
///
/// Tokens are emitted in the order they first occur along the path, each
/// at most once:
///   1. Start label ("Left" / "Center" / "Right") — from the first waypoint's
///      y, by thirds of bg image height.
///   2. "Trench" or "Bump" — at every left→right crossing of x=0.28, the
///      interpolated y picks a band of bg image height:
///        [0, 0.2) ∪ [0.8, 1.0]   → "Trench"
///        [0.2, 0.4) ∪ [0.6, 0.8) → "Bump"
///        [0.4, 0.6)              → omitted (impassable middle)
///   3. "Mid" — any left→right crossing of x=0.28. (Trench/Bump fires
///      immediately before Mid when both happen at the same crossing — the
///      approach precedes the destination.)
///   4. "Depot" — any sample with x < 0.07 in the top half of the field.
///   5. "Outpost" — any sample with x < 0.07 in the bottom half.
///
/// Returns null for an empty path or for a v1 (legacy) path. v1 paths use
/// crop-dependent normalization that this function deliberately does not
/// handle — see "v1 vs v2" below.
///
/// ## v1 vs v2 — IMPORTANT
///
/// This function ONLY supports v2 paths (the current format). v2 normalizes
/// coordinates against the full uncropped bg image, so x=0.28 always means
/// "28% of the bg image width" no matter what crop is being viewed. v1
/// normalizes against the cropped canvas, which would require the crop
/// fraction at recording time to interpret correctly — and that isn't stored
/// with the path. Rather than guess, this function refuses (returns null)
/// and logs a warning via [debugPrint].
///
/// In practice this is a non-issue: [BotPathDrawer] always writes v2
/// (`BotPathData.version`), so any freshly-recorded path passed here works.
String? suggestedPathName({
  required BotPathData path,
  required Size backgroundImageSize,
}) {
  if (path.curves.isEmpty) return null;

  if (path.formatVersion < 2) {
    debugPrint(
      'suggestedPathName: skipping v${path.formatVersion} path '
      '(only v2+ is supported)',
    );
    return null;
  }

  // Convert normalized y → fraction of bg image height (in [0, 1]).
  // v2 normalizes by max(canvasW/cropFraction, canvasH) which equals the bg
  // image's max dimension (its width, since the field image is landscape).
  // So normalized y ranges from 0 to bgH/bgW; multiply by bgW/bgH to get a
  // fraction of bg image height.
  final yScale = backgroundImageSize.width / backgroundImageSize.height;
  double fracY(double normY) => normY * yScale;

  final tokens = <String>[];

  // 1. Start label — from the first waypoint's y.
  final startFracY = fracY(path.curves.first.point1.y);
  if (startFracY < 1 / 3) {
    tokens.add('Left');
  } else if (startFracY < 2 / 3) {
    tokens.add('Center');
  } else {
    tokens.add('Right');
  }

  // 2-5. Walk the path, sampling each curve, and detect events.
  // Each event fires at most once, in chronological order.
  var sawTrench = false;
  var sawBump = false;
  var sawMid = false;
  var sawDepot = false;
  var sawOutpost = false;

  Offset? prev;
  for (final curve in path.curves) {
    for (var i = 0; i <= _samplesPerCurve; i++) {
      // Skip duplicate sample at the seam between consecutive curves
      // (curve[n].point2 == curve[n+1].point1).
      if (i == 0 && prev != null) continue;

      final t = i / _samplesPerCurve;
      final p = evalBezier(curve, t);

      if (prev != null) {
        // Left → right crossing of the mid decision line.
        if (prev.dx < _midLineX && p.dx >= _midLineX) {
          // Interpolate y at the exact crossing. Linear is fine — samples
          // are dense enough that the curve is near-linear over one step.
          final lerp = (_midLineX - prev.dx) / (p.dx - prev.dx);
          final crossingY = fracY(prev.dy + lerp * (p.dy - prev.dy));

          if (!sawTrench && !sawBump) {
            if (crossingY < 0.2 || crossingY >= 0.8) {
              tokens.add('Trench');
              sawTrench = true;
            } else if (crossingY < 0.4 || crossingY >= 0.6) {
              tokens.add('Bump');
              sawBump = true;
            }
            // else: nonsense middle band — omit.
          }
          if (!sawMid) {
            tokens.add('Mid');
            sawMid = true;
          }
        }
      }

      // Depot / Outpost dip — checked on every sample (including the first).
      if (p.dx < _leftDipX) {
        final pY = fracY(p.dy);
        if (pY < 0.5) {
          if (!sawDepot) {
            tokens.add('Depot');
            sawDepot = true;
          }
        } else {
          if (!sawOutpost) {
            tokens.add('Outpost');
            sawOutpost = true;
          }
        }
      }

      prev = p;
    }
  }

  return tokens.join(' ');
}
