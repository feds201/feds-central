import 'package:flutter/material.dart';

/// A single robot path with its display color, used by [BotPathViewer].
///
/// The [color] is used for:
/// - Path line (full opacity)
/// - Robot body fill (at 30% opacity)
/// - Intake edge on the robot
/// - Outline ring on start/end indicator dots
class BotViewerPath {
  /// Serialized path string produced by [BotPathDrawer].
  final String pathData;

  /// Display color for this path's line, robot, and dot outlines.
  final Color color;

  /// Creates a [BotViewerPath].
  const BotViewerPath({required this.pathData, required this.color});
}
