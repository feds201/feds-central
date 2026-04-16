import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bot_path_drawer/bot_path_drawer.dart';
import '../models/auto_path_data.dart';
import '../services/data_service.dart';
import '../services/local_prefs.dart';
import '../theme.dart';
import '../widgets/match_selector.dart';
import '../widgets/team_selector.dart';
import '../widgets/team_data_column.dart';

/// Main screen: 3 team slots, one big shared field with paths, data below.
class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final List<int?> _selectedTeams = [null, null, null];

  // Alliance assignments per slot: null = unassigned, red, or blue
  final List<Alliance?> _alliances = [null, null, null];

  // Locally saved paths per team: { teamNumber: { pathName: pathData } }
  Map<String, Map<String, String>> _localPaths = {};

  @override
  void initState() {
    super.initState();
    _loadLocalPaths();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<DataService>();
      if (svc.dataSource == 'cache') {
        _refresh();
      }
    });
  }

  // ── Local path storage ─────────────────────────────────────────────

  Future<void> _loadLocalPaths() async {
    final saved = await LocalPrefs.loadLocalPaths();
    if (mounted) setState(() => _localPaths = saved);
  }

  Future<void> _saveLocalPath(String teamKey, String pathName, String pathData) async {
    final teamPaths = Map<String, String>.from(_localPaths[teamKey] ?? {});
    teamPaths[pathName] = pathData;
    _localPaths = Map.from(_localPaths)..[teamKey] = teamPaths;
    await LocalPrefs.saveLocalPaths(_localPaths);
    if (mounted) setState(() {});
  }

  // ── Open BotPathDrawer to add a path for a team ────────────────────

  Future<void> _addPathForTeam(String teamKey) async {
    final config = BotPathConfig(
      backgroundImage: const AssetImage('assets/Aerna2026.png'),
      brightness: Brightness.dark,
    );

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('Draw path for Team $teamKey',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(null),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              child: BotPathDrawer(
                config: config,
                onSave: (String? pathData) {
                  Navigator.of(ctx).pop(pathData);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Ask for a name
      final nameController = TextEditingController(
        text: 'Path ${(_localPaths[teamKey]?.length ?? 0) + 1}',
      );
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Name this path'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Left Start'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (name != null && name.isNotEmpty) {
        await _saveLocalPath(teamKey, name, result);
      }
    }
  }

  // ── Refresh ────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final svc = context.read<DataService>();
    await svc.fetchAll();
    if (mounted && svc.scoutingByTeam.isNotEmpty) {
      await LocalPrefs.saveData(
        eventKey: svc.eventKey,
        scoutingByTeam: svc.scoutingByTeam,
        scoutingColumns: svc.scoutingColumns,
        oprByTeam: svc.oprByTeam,
        epaByTeam: svc.epaByTeam,
      );
    }
  }

  void _onTeamChanged(int slot, int? team) {
    setState(() {
      _selectedTeams[slot] = team;
    });
  }

  void _onAllianceChanged(int slot, Alliance? alliance) {
    setState(() {
      _alliances[slot] = alliance;
    });
  }

  void _onMatchSelected(List<int> teams) {
    setState(() {
      for (int i = 0; i < 3 && i < teams.length; i++) {
        _selectedTeams[i] = teams[i];
      }
    });
  }

  // ── Build teams map for BotPathViewerWithSelector ──────────────────

  Map<String, TeamPaths> _buildTeamsMap(DataService svc) {
    final teamsMap = <String, TeamPaths>{};

    for (int i = 0; i < 3; i++) {
      final team = _selectedTeams[i];
      if (team == null) continue;

      final teamKey = '$team';
      final pathsMap = <String, String>{};

      // Paths from database
      final rows = svc.scoutingByTeam[team];
      if (rows != null && rows.isNotEmpty) {
        final pathRaw = rows.first['pathdraw'];
        final routes = parsePathDraw(pathRaw);
        for (int j = 0; j < routes.length; j++) {
          var key = routes[j].displayName(j);
          if (pathsMap.containsKey(key)) key = '$key (${j + 1})';
          pathsMap[key] = routes[j].pathData;
        }
      }

      // Locally saved paths (prefixed so they don't collide with DB paths)
      final local = _localPaths[teamKey] ?? {};
      for (final entry in local.entries) {
        var key = '📍 ${entry.key}';
        if (pathsMap.containsKey(key)) key = '$key (local)';
        pathsMap[key] = entry.value;
      }

      if (pathsMap.isEmpty && _localPaths[teamKey] == null) continue;

      teamsMap[teamKey] = TeamPaths(
        paths: pathsMap,
        color: AppTheme.slotColors[i],
        alliance: _alliances[i],
      );
    }

    return teamsMap;
  }

  // ── Check if all assigned slots have an alliance set ───────────────
  bool get _allianceModeActive {
    final filledSlots = _selectedTeams
        .asMap()
        .entries
        .where((e) => e.value != null)
        .toList();
    if (filledSlots.isEmpty) return false;
    return filledSlots.every((e) => _alliances[e.key] != null);
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final filledCount = _selectedTeams.where((t) => t != null).length;
    final teamsMap = _buildTeamsMap(svc);

    final config = BotPathConfig(
      backgroundImage: const AssetImage('assets/Aerna2026.png'),
      brightness: Brightness.dark,
      // cropFraction forced to 1.0 by the package when alliance mode is active
    );

    return Scaffold(
      body: Column(
        children: [
          // ── Top Bar ────────────────────────────────────────────────
          _TopBar(onRefresh: _refresh),

          // ── Error banner ───────────────────────────────────────────
          if (svc.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.red.withOpacity(0.10),
              child: Text(
                svc.error!,
                style: const TextStyle(color: AppTheme.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Body ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Selectors ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        MatchSelector(onSelected: _onMatchSelected),
                        const SizedBox(height: 8),
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TeamSelector(
                                  slotIndex: i,
                                  value: _selectedTeams[i],
                                  onChanged: (team) => _onTeamChanged(i, team),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Alliance picker
                              _AlliancePicker(
                                value: _alliances[i],
                                onChanged: _selectedTeams[i] != null
                                    ? (a) => _onAllianceChanged(i, a)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Alliance mode hint ────────────────────────────
                  if (filledCount > 0 && !_allianceModeActive)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 13, color: AppTheme.muted),
                          const SizedBox(width: 6),
                          Text(
                            'Assign alliances to all teams to enable full-field mode',
                            style: AppTheme.mono(11, color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Field viewer ──────────────────────────────────
                  if (filledCount == 0)
                    _EmptyState()
                  else ...[
                    Card(
                      child: SizedBox(
                        height: _allianceModeActive ? 520 : 450,
                        child: teamsMap.isEmpty
                            ? Center(
                          child: Text(
                            'No path data for selected teams.\nUse the + button to add a path locally.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.muted, fontSize: 13),
                          ),
                        )
                            : BotPathViewerWithSelector(
                          config: config,
                          teams: teamsMap,
                          onAddPath: (teamKey) =>
                              _addPathForTeam(teamKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Data columns ──────────────────────────────
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _selectedTeams[i] != null
                                  ? TeamDataColumn(
                                teamNumber: _selectedTeams[i]!,
                                slotIndex: i,
                              )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Alliance Picker
// ═══════════════════════════════════════════════════════════════════════

class _AlliancePicker extends StatelessWidget {
  const _AlliancePicker({required this.value, required this.onChanged});

  final Alliance? value;
  final ValueChanged<Alliance?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AllianceBtn(
          label: 'R',
          color: Colors.red,
          selected: value == Alliance.red,
          onTap: onChanged == null
              ? null
              : () => onChanged!(
            value == Alliance.red ? null : Alliance.red,
          ),
        ),
        const SizedBox(width: 4),
        _AllianceBtn(
          label: 'B',
          color: Colors.blue,
          selected: value == Alliance.blue,
          onTap: onChanged == null
              ? null
              : () => onChanged!(
            value == Alliance.blue ? null : Alliance.blue,
          ),
        ),
      ],
    );
  }
}

class _AllianceBtn extends StatelessWidget {
  const _AllianceBtn({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.85) : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Top Bar
// ═══════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRefresh});

  final VoidCallback onRefresh;

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    final time = '$hour:$min $amPm';
    if (diff.inMinutes < 1) return 'Updated just now';
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return 'Updated $time';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Updated ${months[dt.month - 1]} ${dt.day}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings_rounded, size: 20),
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed('/', arguments: {'autoLoad': false}),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.radar_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text('Scout-Ops', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                svc.eventKey,
                style: AppTheme.mono(11, color: AppTheme.accent),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: svc.loading ? null : onRefresh,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: svc.loading
                        ? AppTheme.border
                        : AppTheme.accent.withOpacity(0.4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: svc.loading
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent),
                )
                    : Icon(Icons.refresh_rounded,
                    size: 16, color: AppTheme.accent),
                label: Text(
                  svc.loading ? 'Refreshing...' : 'Refresh Data',
                  style: TextStyle(
                    color: svc.loading ? AppTheme.muted : AppTheme.accent,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (svc.lastUpdated != null) ...[
              const SizedBox(width: 10),
              Text(
                _formatTimestamp(svc.lastUpdated),
                style: AppTheme.mono(11, color: AppTheme.muted),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows_rounded,
              size: 48, color: AppTheme.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Select up to 3 teams to compare',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 6),
          Text(
            'Use the dropdowns above to pick teams',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}