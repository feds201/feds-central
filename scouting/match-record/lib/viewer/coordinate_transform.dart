import 'package:flutter/rendering.dart';

/// Transforms screen-space coordinates to video-space coordinates by inverting
/// zoom/pan (from InteractiveViewer) and rotation (from RotatedBox).
///
/// Used to route drawing input from the top-level Listener to the correct
/// position within a zoomed/rotated video pane.
class CoordinateTransform {
  /// Convert a pane-local point to video-space coordinates.
  ///
  /// [paneLocalPoint] is relative to the pane's top-left corner.
  /// [zoomMatrix] is the current TransformationController value.
  /// [quarterTurns] is the RotatedBox rotation (0-3, clockwise).
  /// [paneSize] is the size of the pane widget.
  static Offset toVideoSpace(
    Offset paneLocalPoint,
    Matrix4 zoomMatrix,
    int quarterTurns,
    Size paneSize,
  ) {
    // 1. Inverse zoom+pan
    final inverted = Matrix4.inverted(zoomMatrix);
    final unzoomed = MatrixUtils.transformPoint(inverted, paneLocalPoint);

    // 2. Inverse rotation
    return inverseRotate(unzoomed, quarterTurns, paneSize);
  }

  /// Apply inverse rotation to undo RotatedBox's clockwise quarter turns.
  ///
  /// RotatedBox rotates the child clockwise by [quarterTurns] * 90 degrees.
  /// To map a point from the rotated coordinate space back to the original
  /// (video) coordinate space, we apply the inverse rotation.
  static Offset inverseRotate(Offset point, int quarterTurns, Size paneSize) {
    switch (quarterTurns % 4) {
      case 0:
        return point;
      case 1:
        // CW 90: inverse is CCW 90 → (y, width - x)
        return Offset(point.dy, paneSize.width - point.dx);
      case 2:
        // CW 180: inverse is CW 180 → (width - x, height - y)
        return Offset(paneSize.width - point.dx, paneSize.height - point.dy);
      case 3:
        // CW 270: inverse is CW 90 → (height - y, x)
        return Offset(paneSize.height - point.dy, point.dx);
      default:
        return point;
    }
  }
}
