import 'package:bot_path_drawer/bot_path_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auto_path_data.dart';
import '../models/match_entry.dart';
import '../models/playoff_alliance.dart';
import '../services/data_service.dart';
import '../services/local_prefs.dart';
import '../theme.dart';
import '../widgets/alliance_selector.dart';
import '../widgets/match_selector.dart';
import '../widgets/neon_data_tabs.dart';
import '../widgets/team_selector.dart';

/// Main strategy screen: match + alliance pickers, 3 red vs 3 blue team grid,
/// shared field viewer, and alliance data tabs.
class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final List<int?> _redTeams = [null, null, null];
  final List<int?> _blueTeams = [null, null, null];
  MatchEntry? _selectedMatch;
  PlayoffAlliance? _selectedRedAlliance;
  PlayoffAlliance? _selectedBlueAlliance;

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

  Future<void> _saveLocalPath(
      String teamKey, String pathName, String pathData) async {
    final teamPaths = Map<String, String>.from(_localPaths[teamKey] ?? {});
    teamPaths[pathName] = pathData;
    _localPaths = Map.from(_localPaths)..[teamKey] = teamPaths;
    await LocalPrefs.saveLocalPaths(_localPaths);
    if (mounted) setState(() {});
  }

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
              onPressed: () =>
                  Navigator.of(ctx).pop(nameController.text.trim()),
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
        matchEntries: svc.matchEntries,
        playoffAlliances: svc.playoffAlliances,
        teamNames: svc.teamNames,
      );
    }
  }

  // ── Selection handlers ─────────────────────────────────────────────

  void _onMatchSelected(MatchEntry match) {
    setState(() {
      _selectedMatch = match;
      _selectedRedAlliance = null;
      _selectedBlueAlliance = null;
      _fillSlots(_redTeams, match.redTeams);
      _fillSlots(_blueTeams, match.blueTeams);
    });
  }

  void _onMatchCleared() {
    setState(() {
      _selectedMatch = null;
      _selectedRedAlliance = null;
      _selectedBlueAlliance = null;
      _fillSlots(_redTeams, const []);
      _fillSlots(_blueTeams, const []);
    });
  }

  void _onAllianceSelected(Alliance alliance, PlayoffAlliance pa) {
    setState(() {
      _selectedMatch = null;
      if (alliance == Alliance.red) {
        _selectedRedAlliance = pa;
        _fillSlots(_redTeams, pa.teams);
      } else {
        _selectedBlueAlliance = pa;
        _fillSlots(_blueTeams, pa.teams);
      }
    });
  }

  void _onAllianceCleared(Alliance alliance) {
    setState(() {
      if (alliance == Alliance.red) {
        _selectedRedAlliance = null;
        _fillSlots(_redTeams, const []);
      } else {
        _selectedBlueAlliance = null;
        _fillSlots(_blueTeams, const []);
      }
    });
  }

  void _onTeamChanged(Alliance alliance, int slot, int? team) {
    setState(() {
      final list = alliance == Alliance.red ? _redTeams : _blueTeams;
      list[slot] = team;
    });
  }

  void _fillSlots(List<int?> slots, List<int> teams) {
    for (int i = 0; i < slots.length; i++) {
      slots[i] = i < teams.length ? teams[i] : null;
    }
  }

  // ── Build teams map for BotPathViewerWithSelector ──────────────────

  Map<String, TeamPaths> _buildTeamsMap(DataService svc) {
    final teamsMap = <String, TeamPaths>{};

    void addTeam(int? team, Alliance alliance, int slot) {
      if (team == null) return;
      final teamKey = '$team';
      if (teamsMap.containsKey(teamKey)) return;

      final pathsMap = <String, String>{};

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

      final local = _localPaths[teamKey] ?? {};
      for (final entry in local.entries) {
        var key = '📍 ${entry.key}';
        if (pathsMap.containsKey(key)) key = '$key (local)';
        pathsMap[key] = entry.value;
      }

      if (pathsMap.isEmpty && _localPaths[teamKey] == null) return;

      // Pin color to the dash's slot palette so the drawer doesn't re-derive
      // it from alliance-group index (which shifts when a slot is empty).
      teamsMap[teamKey] = TeamPaths(
        paths: pathsMap,
        alliance: alliance,
        color: AppTheme.allianceTeamColors[alliance]![slot],
      );
    }

    for (int i = 0; i < _redTeams.length; i++) {
      addTeam(_redTeams[i], Alliance.red, i);
    }
    for (int i = 0; i < _blueTeams.length; i++) {
      addTeam(_blueTeams[i], Alliance.blue, i);
    }

    return teamsMap;
  }

  int get _filledCount =>
      _redTeams.where((t) => t != null).length +
      _blueTeams.where((t) => t != null).length;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final teamsMap = _buildTeamsMap(svc);
    final showAllianceRow = svc.playoffAlliances.isNotEmpty;

    final config = BotPathConfig(
      backgroundImage: const AssetImage('assets/Aerna2026.png'),
      brightness: Brightness.dark,
    );

    return Scaffold(
      body: Column(
        children: [
          _TopBar(onRefresh: _refresh),
          if (svc.error != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.red.withOpacity(0.10),
              child: Text(
                svc.error!,
                style: const TextStyle(color: AppTheme.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MatchSelector(
                    value: _selectedMatch,
                    onSelected: _onMatchSelected,
                    onCleared: _onMatchCleared,
                  ),
                  if (showAllianceRow) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AllianceSelector(
                            label: 'Red alliance',
                            accent: AppTheme
                                .allianceTeamColors[Alliance.red]!.first,
                            value: _selectedRedAlliance,
                            onSelected: (pa) =>
                                _onAllianceSelected(Alliance.red, pa),
                            onCleared: () =>
                                _onAllianceCleared(Alliance.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AllianceSelector(
                            label: 'Blue alliance',
                            accent: AppTheme
                                .allianceTeamColors[Alliance.blue]!.first,
                            value: _selectedBlueAlliance,
                            onSelected: (pa) =>
                                _onAllianceSelected(Alliance.blue, pa),
                            onCleared: () =>
                                _onAllianceCleared(Alliance.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (int i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TeamSelector(
                            alliance: Alliance.red,
                            slot: i,
                            value: _redTeams[i],
                            onChanged: (t) =>
                                _onTeamChanged(Alliance.red, i, t),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TeamSelector(
                            alliance: Alliance.blue,
                            slot: i,
                            value: _blueTeams[i],
                            onChanged: (t) =>
                                _onTeamChanged(Alliance.blue, i, t),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_filledCount == 0)
                    _EmptyState()
                  else ...[
                    Card(
                      child: SizedBox(
                        height: 520,
                        child: teamsMap.isEmpty
                            ? const Center(
                                child: Text(
                                  'No path data for selected teams.\n'
                                  'Use the + button to add a path locally.',
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
                    NeonDataTabs(
                      redTeams: _redTeams,
                      blueTeams: _blueTeams,
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
              onPressed: () => Navigator.of(context).pushNamed(
                '/',
                arguments: {'autoLoad': false, 'dismissible': true},
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 8),
            Text('Match Dash', style: Theme.of(context).textTheme.titleLarge),
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
            'Pick a match or alliance above',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 6),
          Text(
            'Or choose teams manually in the red/blue grid',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
