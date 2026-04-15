import 'dart:math';

import 'package:flutter/material.dart';

import '../models/bot_path_config.dart';
import '../models/bot_viewer_path.dart';
import '../models/team_paths.dart';
import 'bot_path_viewer_widget.dart';

/// Width threshold below which the sidebar floats over the viewer.
const _compactBreakpoint = 600.0;

/// Hard-coded base team colors (fully saturated).
///
/// Indices 0-2 are warm (used for red alliance when alliances are active).
/// Indices 3-5 are cool (used for blue alliance when alliances are active).
const _teamBaseColors = [
  Color(0xFFFF0000), // Red
  Color(0xFFFF9900), // Orange
  Color(0xFFFFFF00), // Yellow
  Color(0xFF0044FF), // Blue
  Color(0xFF00FF44), // Green
  Color(0xFF00FFFF), // Cyan
];

/// Warm color subset indices for red alliance teams.
const _warmIndices = [0, 1, 2];

/// Cool color subset indices for blue alliance teams.
const _coolIndices = [3, 4, 5];

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
/// - Otherwise, colors are auto-assigned from a palette of 6 colors.
/// - When alliance mode is active, warm colors are used for red alliance
///   teams and cool colors for blue alliance teams.
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

  /// Optional callback invoked when the user taps the add-path button
  /// on a team header. The team label is passed as the argument.
  ///
  /// If null, no add-path button is shown.
  final void Function(String teamLabel)? onAddPath;

  /// Creates a [BotPathViewerWithSelector].
  const BotPathViewerWithSelector({
    super.key,
    required this.config,
    required this.teams,
    this.onAddPath,
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

  /// Which paths are vertically mirrored (teamKey → set of pathNames).
  late Map<String, Set<String>> _mirrored;

  /// Whether the sidebar is visible. Null means not yet resolved (will be
  /// set on first build based on available width).
  bool? _sidebarVisible;

  /// Whether alliance mode is active (all teams have alliance set).
  bool _allianceMode = false;

  /// Effective crop fraction (may be overridden when alliance mode is active).
  double _effectiveCropFraction = 1.0;

  @override
  void initState() {
    super.initState();
    _initSelection();
    _resolveAllianceMode();
  }

  @override
  void didUpdateWidget(BotPathViewerWithSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_teamsEqual(oldWidget.teams, widget.teams)) {
      _initSelection();
      _resolveAllianceMode();
    } else if (oldWidget.config.cropFraction != widget.config.cropFraction) {
      _resolveAllianceMode();
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
      if (aTeam.alliance != bTeam.alliance) return false;
      final aPaths = aTeam.paths;
      final bPaths = bTeam.paths;
      if (aPaths.length != bPaths.length) return false;
      for (final pathKey in aPaths.keys) {
        if (aPaths[pathKey] != bPaths[pathKey]) return false;
      }
    }
    return true;
  }

  /// Determines whether alliance mode should be active.
  void _resolveAllianceMode() {
    final teams = widget.teams.values;
    final withAlliance = teams.where((t) => t.alliance != null).length;

    if (withAlliance == teams.length && teams.isNotEmpty) {
      _allianceMode = true;
    } else {
      _allianceMode = false;
      if (withAlliance > 0) {
        debugPrint(
          'Warning: alliance set for some but not all teams, '
          'ignoring alliance fields',
        );
      }
    }

    if (_allianceMode && widget.config.cropFraction != 1.0) {
      debugPrint(
        'Warning: cropFraction ignored when both alliances shown, using 1.0',
      );
      _effectiveCropFraction = 1.0;
    } else {
      _effectiveCropFraction = widget.config.cropFraction;
    }
  }

  /// Initializes the selection state: first path of each team is selected.
  void _initSelection() {
    _selected = {};
    _expandedTeams = {};
    _mirrored = {};
    for (final entry in widget.teams.entries) {
      final teamKey = entry.key;
      final pathKeys = entry.value.paths.keys.toList();
      _expandedTeams.add(teamKey);
      if (pathKeys.isNotEmpty) {
        _selected[teamKey] = {pathKeys.first};
      } else {
        _selected[teamKey] = {};
      }
      _mirrored[teamKey] = {};
    }
  }

  /// Returns the base color for a team at the given [colorIndex].
  ///
  /// When alliance mode is active, [colorIndex] indexes into the warm or
  /// cool subset based on the team's alliance. Otherwise it indexes into
  /// the full palette.
  Color _teamBaseColor(String teamKey, int colorIndex) {
    final teamData = widget.teams[teamKey];
    if (teamData?.color != null) return teamData!.color!;

    if (_allianceMode) {
      final alliance = teamData?.alliance;
      final subset = alliance == Alliance.red ? _warmIndices : _coolIndices;
      return _teamBaseColors[subset[colorIndex % subset.length]];
    }

    return _teamBaseColors[colorIndex % _teamBaseColors.length];
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

  /// Returns teams grouped by alliance when alliance mode is active.
  /// The first list is red alliance teams, the second is blue.
  (List<String>, List<String>) _teamsByAlliance() {
    final red = <String>[];
    final blue = <String>[];
    for (final entry in widget.teams.entries) {
      if (entry.value.alliance == Alliance.red) {
        red.add(entry.key);
      } else {
        blue.add(entry.key);
      }
    }
    return (red, blue);
  }

  /// Returns the color index for a team within its alliance group.
  int _allianceColorIndex(String teamKey, List<String> allianceTeams) {
    return allianceTeams.indexOf(teamKey);
  }

  /// Builds the list of [BotViewerPath] from the current selection.
  List<BotViewerPath> _buildViewerPaths() {
    final viewerPaths = <BotViewerPath>[];

    if (_allianceMode) {
      final (redTeams, blueTeams) = _teamsByAlliance();
      _addViewerPathsForTeams(redTeams, redTeams, viewerPaths);
      _addViewerPathsForTeams(blueTeams, blueTeams, viewerPaths);
    } else {
      final allTeams = widget.teams.keys.toList();
      var colorIndex = 0;
      for (final teamKey in allTeams) {
        final teamData = widget.teams[teamKey]!;
        final baseColor = _teamBaseColor(teamKey, colorIndex);
        final selectedPaths = _selected[teamKey] ?? {};
        final mirroredPaths = _mirrored[teamKey] ?? {};

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
              mirrored: mirroredPaths.contains(pathName),
            ));
          }
        }
        colorIndex++;
      }
    }

    return viewerPaths;
  }

  /// Helper to add viewer paths for a list of teams within an alliance group.
  void _addViewerPathsForTeams(
    List<String> teams,
    List<String> allianceGroup,
    List<BotViewerPath> viewerPaths,
  ) {
    for (final teamKey in teams) {
      final teamData = widget.teams[teamKey]!;
      final colorIdx = _allianceColorIndex(teamKey, allianceGroup);
      final baseColor = _teamBaseColor(teamKey, colorIdx);
      final selectedPaths = _selected[teamKey] ?? {};
      final mirroredPaths = _mirrored[teamKey] ?? {};

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
            alliance: teamData.alliance,
            mirrored: mirroredPaths.contains(pathName),
          ));
        }
      }
    }
  }

  /// Returns the color for the dot next to a path checkbox.
  /// If the path is selected, returns its computed color; otherwise grey.
  Color _pathDotColor(String teamKey, int colorIndex, String pathName) {
    final selected = _selected[teamKey] ?? {};
    if (!selected.contains(pathName)) {
      return Colors.grey.shade400;
    }

    final baseColor = _teamBaseColor(teamKey, colorIndex);
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
              children: _buildTeamList(theme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of team section widgets, with alliance headers if active.
  List<Widget> _buildTeamList(ThemeData theme, bool isDark) {
    if (!_allianceMode) {
      final allTeams = widget.teams.keys.toList();
      return [
        for (var i = 0; i < allTeams.length; i++)
          _buildTeamSection(allTeams[i], i, theme, isDark),
      ];
    }

    final (redTeams, blueTeams) = _teamsByAlliance();
    return [
      // Red alliance header
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          'RED ALLIANCE',
          style: theme.textTheme.titleSmall?.copyWith(
            color: _teamBaseColors[0],
          ),
        ),
      ),
      for (var i = 0; i < redTeams.length; i++)
        _buildTeamSection(redTeams[i], i, theme, isDark),
      const Divider(),
      // Blue alliance header
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          'BLUE ALLIANCE',
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF4488FF),
          ),
        ),
      ),
      for (var i = 0; i < blueTeams.length; i++)
        _buildTeamSection(blueTeams[i], i, theme, isDark),
    ];
  }

  /// Returns the effective config, with cropFraction overridden if needed.
  BotPathConfig get _effectiveConfig {
    if (_effectiveCropFraction != widget.config.cropFraction) {
      return widget.config.copyWith(cropFraction: _effectiveCropFraction);
    }
    return widget.config;
  }

  @override
  Widget build(BuildContext context) {
    final viewerPaths = _buildViewerPaths();
    final theme = Theme.of(context);
    final brightness = widget.config.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final viewer = BotPathViewer(
      config: _effectiveConfig,
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
    int colorIndex,
    ThemeData theme,
    bool isDark,
  ) {
    final teamData = widget.teams[teamKey]!;
    final isExpanded = _expandedTeams.contains(teamKey);
    final baseColor = _teamBaseColor(teamKey, colorIndex);
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
                if (widget.onAddPath != null)
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => widget.onAddPath!(teamKey),
                    tooltip: 'Add path',
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
                    colorIndex,
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
    int colorIndex,
    String pathName,
    bool isChecked,
    ThemeData theme,
  ) {
    final dotColor = _pathDotColor(teamKey, colorIndex, pathName);
    final isMirrored =
        (_mirrored[teamKey] ?? {}).contains(pathName);

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
            // Mirror toggle button (only shown when path is checked)
            if (isChecked)
              IconButton(
                icon: Icon(
                  Icons.swap_vert,
                  size: 18,
                  color: isMirrored
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha(100),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: () {
                  setState(() {
                    final set = _mirrored[teamKey] ??= {};
                    if (set.contains(pathName)) {
                      set.remove(pathName);
                    } else {
                      set.add(pathName);
                    }
                  });
                },
                tooltip: isMirrored ? 'Unmirror path' : 'Mirror path',
              ),
          ],
        ),
      ),
    );
  }
}
