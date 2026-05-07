import 'package:flutter/material.dart';

/// A team's collection of paths, used by [BotPathViewerWithSelector].
///
/// Each entry in [paths] maps a human-readable path name to its serialized
/// path string (as produced by [BotPathDrawer]).
class TeamPaths {
  /// Map of path name → serialized path data.
  final Map<String, String> paths;

  /// Optional base color for this team.
  ///
  /// If null, the widget auto-assigns a color from a default palette
  /// (red, green, blue) in order.
  final Color? color;

  /// Creates a [TeamPaths].
  const TeamPaths({required this.paths, this.color});
}
