import 'package:flutter/material.dart';

import 'team_paths.dart';

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

  /// Optional alliance for this path (used for horizontal reflection).
  final Alliance? alliance;

  /// Whether this path should be vertically mirrored.
  final bool mirrored;

  /// Creates a [BotViewerPath].
  const BotViewerPath({
    required this.pathData,
    required this.color,
    this.alliance,
    this.mirrored = false,
  });
}
