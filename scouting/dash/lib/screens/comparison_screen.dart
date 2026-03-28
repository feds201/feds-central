import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bot_path_drawer/bot_path_drawer.dart';
import '../models/auto_path_data.dart';
import '../services/data_service.dart';
import '../theme.dart';
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

  void _onTeamChanged(int slot, int? team) {
    setState(() {
      _selectedTeams[slot] = team;
    });
  }

  /// Build the teams map for BotPathViewerWithSelector.
  Map<String, TeamPaths> _buildTeamsMap(DataService svc) {
    final teamsMap = <String, TeamPaths>{};

    for (int i = 0; i < 3; i++) {
      final team = _selectedTeams[i];
      if (team == null) continue;

      final rows = svc.scoutingByTeam[team];
      if (rows == null || rows.isEmpty) continue;

      final pathRaw = rows.first['pathdraw'];
      final routes = parsePathDraw(pathRaw);
      if (routes.isEmpty) continue;

      final pathsMap = <String, String>{};
      for (int j = 0; j < routes.length; j++) {
        var key = routes[j].displayName(j);
        // Ensure unique keys.
        if (pathsMap.containsKey(key)) key = '$key (${j + 1})';
        pathsMap[key] = routes[j].pathData;
      }

      teamsMap['$team'] = TeamPaths(
        paths: pathsMap,
        color: AppTheme.slotColors[i],
      );
    }

    return teamsMap;
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final filledCount = _selectedTeams.where((t) => t != null).length;
    final teamsMap = _buildTeamsMap(svc);

    final config = BotPathConfig(
        backgroundImage: const AssetImage('assets/Aerna2026.png'),
        brightness: Brightness.dark
    );
    print(teamsMap);
    return Scaffold(
      body: Column(
        children: [
          // ── Top Bar ────────────────────────────────────────────────
          _TopBar(
            selectedTeams: _selectedTeams,
            onTeamChanged: _onTeamChanged,
          ),

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
            child: filledCount == 0
                ? _EmptyState()
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── One big shared field with all paths ───────
                  Card(
                    child: SizedBox(
                      height: 450,
                      child: teamsMap.isEmpty
                          ? Center(
                        child: Text(
                          'No path data for selected teams',
                          style: TextStyle(
                              color: AppTheme.muted, fontSize: 13),
                        ),
                      )
                          : BotPathViewerWithSelector(
                        config: config,
                        teams: teamsMap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Data columns side by side ────────────────
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
  const _TopBar({
    required this.selectedTeams,
    required this.onTeamChanged,
  });

  final List<int?> selectedTeams;
  final void Function(int slot, int? team) onTeamChanged;

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
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/'),
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
            const Spacer(),
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: TeamSelector(
                  slotIndex: i,
                  value: selectedTeams[i],
                  onChanged: (team) => onTeamChanged(i, team),
                ),
              ),
            ],
            const SizedBox(width: 12),
            IconButton(
              icon: svc.loading
                  ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              )
                  : const Icon(Icons.refresh_rounded, size: 20),
              onPressed: svc.loading ? null : () => svc.fetchAll(),
              tooltip: 'Refresh all data',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
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
