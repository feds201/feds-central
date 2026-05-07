import 'package:bot_path_drawer/bot_path_drawer.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'alliance_data_card.dart';

/// RED / BLUE tab bar with an [AllianceDataCard] per alliance. Content height
/// is intrinsic so the outer scroll view handles overflow (no fixed TabBarView
/// box — avoids bottom-clipping on tables with many columns).
class NeonDataTabs extends StatelessWidget {
  const NeonDataTabs({
    super.key,
    required this.redTeams,
    required this.blueTeams,
  });

  final List<int?> redTeams;
  final List<int?> blueTeams;

  @override
  Widget build(BuildContext context) {
    final red = AppTheme.allianceTeamColors[Alliance.red]!.first;
    final blue = AppTheme.allianceTeamColors[Alliance.blue]!.first;
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TabBar(
                  labelColor: AppTheme.text,
                  unselectedLabelColor: AppTheme.muted,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppTheme.surfaceHi,
                    border: Border.all(color: AppTheme.border),
                  ),
                  labelStyle: AppTheme.mono(12),
                  tabs: [
                    Tab(child: _TabLabel(color: red, label: 'RED')),
                    Tab(child: _TabLabel(color: blue, label: 'BLUE')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: controller,
                builder: (_, __) {
                  return controller.index == 0
                      ? AllianceDataCard(
                          alliance: Alliance.red,
                          teams: redTeams,
                        )
                      : AllianceDataCard(
                          alliance: Alliance.blue,
                          teams: blueTeams,
                        );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.mono(12)),
      ],
    );
  }
}
