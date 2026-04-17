import 'package:flutter/material.dart';

/// Which alliance a team belongs to.
enum Alliance { red, blue }

/// A team's collection of paths, used by [BotPathViewerWithSelector].
///
/// Each entry in [paths] maps a human-readable path name to its serialized
/// path string (as produced by [BotPathDrawer]).
class TeamPaths {
  /// Map of path name → serialized path data.
  final Map<String, String> paths;

  /// Optional base color for this team.
  ///
  /// If null, the widget auto-assigns a color from a default palette.
  final Color? color;

  /// Optional alliance for this team.
  ///
  /// When all teams have an alliance set, the viewer groups teams by alliance
  /// and applies horizontal reflection for blue alliance paths.
  final Alliance? alliance;

  /// Creates a [TeamPaths].
  const TeamPaths({required this.paths, this.color, this.alliance});
}
