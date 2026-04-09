import 'dart:math';

import 'package:flutter/material.dart';

import '../models/bot_path_config.dart';
import '../models/bot_viewer_path.dart';
import '../models/team_paths.dart';
import 'bot_path_viewer_widget.dart';

/// Width threshold below which the sidebar floats over the viewer.
const _compactBreakpoint = 600.0;

/// Hard-coded base team colors (fully saturated).
const _teamBaseColors = [
  Color(0xFFFF0000), // Red
  Color(0xFF00AA00), // Green
  Color(0xFF0055FF), // Blue
];

/// A viewer widget with a sidebar for selecting which team paths to display.
///
/// Wraps [BotPathViewer] with a collapsible sidebar showing teams and their
/// paths as checkboxes. Selected paths are rendered on the field
/// simultaneously. By default, the first path of each team is selected.
///
/// ## Color assignment
///
/// Each team is assigned a base color:
/// - If [TeamPaths.color] is set, that color is used.
/// - Otherwise, colors are auto-assigned from a palette (red, green, blue).
///
/// Within a team, selected paths vary by saturation from 100% down to 30%,
/// evenly spaced.
///
/// ## Usage
/// ```dart
/// BotPathViewerWithSelector(
///   config: BotPathConfig(backgroundImage: AssetImage('assets/field.png')),
///   teams: {
///     '201': TeamPaths(paths: {'Left': 'M0.1,...', 'Right': 'M0.5,...'}),
///     '254': TeamPaths(paths: {'Center': 'M0.3,...'}, color: Colors.purple),
///   },
/// )
/// ```
class BotPathViewerWithSelector extends StatefulWidget {
  /// Configuration for the underlying [BotPathViewer].
  final BotPathConfig config;

  /// Teams and their paths.
  ///
  /// Keys are team labels (e.g. "201"), values contain the path map
  /// and an optional base color override.
  final Map<String, TeamPaths> teams;

  /// Creates a [BotPathViewerWithSelector].
  const BotPathViewerWithSelector({
    super.key,
    required this.config,
    required this.teams,
  });

  @override
  State<BotPathViewerWithSelector> createState() =>
      _BotPathViewerWithSelectorState();
}

class _BotPathViewerWithSelectorState
    extends State<BotPathViewerWithSelector> {
  /// Which paths are selected per team.
  late Map<String, Set<String>> _selected;

  /// Which teams are expanded in the sidebar.
  late Set<String> _expandedTeams;

  /// Whether the sidebar is visible. Null means not yet resolved (will be
  /// set on first build based on available width).
  bool? _sidebarVisible;

  @override
  void initState() {
    super.initState();
    _initSelection();
  }

  @override
  void didUpdateWidget(BotPathViewerWithSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_teamsEqual(oldWidget.teams, widget.teams)) {
      _initSelection();
    }
  }

  /// Deep-compares two team maps by structure and content.
  static bool _teamsEqual(
    Map<String, TeamPaths> a,
    Map<String, TeamPaths> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final aTeam = a[key]!;
      final bTeam = b[key]!;
      if (aTeam.color != bTeam.color) return false;
      final aPaths = aTeam.paths;
      final bPaths = bTeam.paths;
      if (aPaths.length != bPaths.length) return false;
      for (final pathKey in aPaths.keys) {
        if (aPaths[pathKey] != bPaths[pathKey]) return false;
      }
    }
    return true;
  }

  /// Initializes the selection state: first path of each team is selected.
  void _initSelection() {
    _selected = {};
    _expandedTeams = {};
    for (final entry in widget.teams.entries) {
      final teamKey = entry.key;
      final pathKeys = entry.value.paths.keys.toList();
      _expandedTeams.add(teamKey);
      if (pathKeys.isNotEmpty) {
        _selected[teamKey] = {pathKeys.first};
      } else {
        _selected[teamKey] = {};
      }
    }
  }

  /// Returns the base color for a team at the given [index] in the team list.
  Color _teamBaseColor(String teamKey, int index) {
    final teamData = widget.teams[teamKey];
    if (teamData?.color != null) return teamData!.color!;
    // Auto-assign from palette, wrapping around
    return _teamBaseColors[index % _teamBaseColors.length];
  }

  /// Computes the display color for a path within a team.
  ///
  /// Selected paths are spread from 100% saturation down to 30%,
  /// evenly spaced. [selectedIndex] is this path's position among
  /// the selected paths for its team, and [selectedCount] is the total.
  Color _pathColor(Color baseColor, int selectedIndex, int selectedCount) {
    if (selectedCount <= 1) return baseColor;

    // Convert to HSL and vary saturation from 1.0 down to 0.3
    final hsl = HSLColor.fromColor(baseColor);
    final minSat = 0.3;
    final maxSat = hsl.saturation;
    final t = selectedIndex / (selectedCount - 1);
    final saturation = maxSat - t * (maxSat - minSat);
    return hsl.withSaturation(saturation.clamp(0.0, 1.0)).toColor();
  }

  /// Builds the list of [BotViewerPath] from the current selection.
  List<BotViewerPath> _buildViewerPaths() {
    final viewerPaths = <BotViewerPath>[];
    var teamIndex = 0;

    for (final entry in widget.teams.entries) {
      final teamKey = entry.key;
      final teamData = entry.value;
      final baseColor = _teamBaseColor(teamKey, teamIndex);
      final selectedPaths = _selected[teamKey] ?? {};

      // Collect selected path names in their original order
      final selectedOrdered = teamData.paths.keys
          .where((name) => selectedPaths.contains(name))
          .toList();

      for (var i = 0; i < selectedOrdered.length; i++) {
        final pathName = selectedOrdered[i];
        final pathData = teamData.paths[pathName];
        if (pathData != null) {
          viewerPaths.add(BotViewerPath(
            pathData: pathData,
            color: _pathColor(baseColor, i, selectedOrdered.length),
          ));
        }
      }

      teamIndex++;
    }

    return viewerPaths;
  }

  /// Returns the color for the dot next to a path checkbox.
  /// If the path is selected, returns its computed color; otherwise grey.
  Color _pathDotColor(String teamKey, int teamIndex, String pathName) {
    final selected = _selected[teamKey] ?? {};
    if (!selected.contains(pathName)) {
      return Colors.grey.shade400;
    }

    final baseColor = _teamBaseColor(teamKey, teamIndex);
    final teamData = widget.teams[teamKey]!;
    final selectedOrdered = teamData.paths.keys
        .where((name) => selected.contains(name))
        .toList();
    final selectedIndex = selectedOrdered.indexOf(pathName);
    return _pathColor(baseColor, selectedIndex, selectedOrdered.length);
  }

  /// Builds the sidebar content (collapse button + team list).
  Widget _buildSidebarContent(
    double width,
    ThemeData theme,
    bool isDark,
  ) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () => setState(() => _sidebarVisible = false),
              tooltip: 'Hide sidebar',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (var i = 0; i < widget.teams.length; i++)
                  _buildTeamSection(
                    widget.teams.keys.elementAt(i),
                    i,
                    theme,
                    isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewerPaths = _buildViewerPaths();
    final theme = Theme.of(context);
    final brightness = widget.config.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final viewer = BotPathViewer(
      config: widget.config,
      paths: viewerPaths,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _compactBreakpoint;

        // Resolve initial sidebar visibility on first build.
        _sidebarVisible ??= !isCompact;

        final sidebarVisible = _sidebarVisible!;

        if (isCompact) {
          // Compact: viewer fills the space, sidebar floats on top.
          final sidebarWidth =
              min(220.0, constraints.maxWidth * 0.65);
          return Stack(
            children: [
              Positioned.fill(child: viewer),
              // Toggle button (always visible when sidebar is hidden)
              if (!sidebarVisible)
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () =>
                        setState(() => _sidebarVisible = true),
                    tooltip: 'Show sidebar',
                  ),
                ),
              // Scrim + floating sidebar
              if (sidebarVisible) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _sidebarVisible = false),
                    child: ColoredBox(
                      color: Colors.black54,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: Material(
                    elevation: 8,
                    color: theme.colorScheme.surface,
                    child: _buildSidebarContent(
                      sidebarWidth,
                      theme,
                      isDark,
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        // Wide: inline sidebar in a Row.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sidebarVisible)
              _buildSidebarContent(220, theme, isDark),
            if (!sidebarVisible)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () =>
                      setState(() => _sidebarVisible = true),
                  tooltip: 'Show sidebar',
                ),
              ),
            Expanded(child: viewer),
          ],
        );
      },
    );
  }

  Widget _buildTeamSection(
    String teamKey,
    int teamIndex,
    ThemeData theme,
    bool isDark,
  ) {
    final teamData = widget.teams[teamKey]!;
    final isExpanded = _expandedTeams.contains(teamKey);
    final baseColor = _teamBaseColor(teamKey, teamIndex);
    final pathCount = teamData.paths.length;
    final selected = _selected[teamKey] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team header
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedTeams.remove(teamKey);
              } else {
                _expandedTeams.add(teamKey);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                ),
                const SizedBox(width: 4),
                // Team color dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    teamKey,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '($pathCount)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Path checkboxes
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                for (final pathName in teamData.paths.keys)
                  _buildPathRow(
                    teamKey,
                    teamIndex,
                    pathName,
                    selected.contains(pathName),
                    theme,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildPathRow(
    String teamKey,
    int teamIndex,
    String pathName,
    bool isChecked,
    ThemeData theme,
  ) {
    final dotColor = _pathDotColor(teamKey, teamIndex, pathName);

    return InkWell(
      onTap: () {
        setState(() {
          final set = _selected[teamKey] ??= {};
          if (set.contains(pathName)) {
            set.remove(pathName);
          } else {
            set.add(pathName);
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    final set = _selected[teamKey] ??= {};
                    if (value == true) {
                      set.add(pathName);
                    } else {
                      set.remove(pathName);
                    }
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            // Path color dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pathName,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
