import 'package:flutter/material.dart';

import '../data/models.dart';
import '../util/constants.dart';

enum AutocompleteResultType { team, match, alliance }

class AutocompleteResult {
  final AutocompleteResultType type;
  final String label;
  final String? subtitle;
  final Team? team;
  final MatchWithVideos? matchWithVideos;
  final Alliance? alliance;
  /// Event disambiguation line, shown when multiple events are selected.
  final String? eventInfo;

  const AutocompleteResult.team(this.team, {this.eventInfo})
      : type = AutocompleteResultType.team,
        label = '',
        subtitle = null,
        matchWithVideos = null,
        alliance = null;

  const AutocompleteResult.match(this.matchWithVideos, {this.eventInfo})
      : type = AutocompleteResultType.match,
        label = '',
        subtitle = null,
        team = null,
        alliance = null;

  const AutocompleteResult.alliance(this.alliance, {this.eventInfo})
      : type = AutocompleteResultType.alliance,
        label = '',
        subtitle = null,
        team = null,
        matchWithVideos = null;

  String get displayLabel {
    switch (type) {
      case AutocompleteResultType.team:
        final t = team!;
        return t.nickname.isNotEmpty
            ? '${t.teamNumber} - ${t.nickname}'
            : '${t.teamNumber}';
      case AutocompleteResultType.match:
        return matchWithVideos!.match.displayName;
      case AutocompleteResultType.alliance:
        return alliance!.name;
    }
  }

  String? get displaySubtitle {
    switch (type) {
      case AutocompleteResultType.team:
        return null;
      case AutocompleteResultType.match:
        final m = matchWithVideos!.match;
        final red = m.redTeamKeys.map((k) => k.replaceFirst('frc', '')).join(' \u00b7 ');
        final blue = m.blueTeamKeys.map((k) => k.replaceFirst('frc', '')).join(' \u00b7 ');
        return '$red  vs  $blue';
      case AutocompleteResultType.alliance:
        return alliance!.picks
            .map((k) => k.replaceFirst('frc', ''))
            .join(' \u00b7 ');
    }
  }
}

class AutocompleteOverlay extends StatelessWidget {
  final List<AutocompleteResult> results;
  final ValueChanged<AutocompleteResult> onResultTap;

  const AutocompleteOverlay({
    super.key,
    required this.results,
    required this.onResultTap,
  });

  static const _typeColors = {
    AutocompleteResultType.team: AppColors.teamCategory,
    AutocompleteResultType.match: AppColors.matchCategory,
    AutocompleteResultType.alliance: AppColors.allianceCategory,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainer,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            final color = _typeColors[result.type] ?? Colors.grey;
            return InkWell(
              onTap: () => onResultTap(result),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: color, width: 4),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (result.displaySubtitle != null)
                      Text(
                        result.displaySubtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (result.eventInfo != null)
                      Text(
                        result.eventInfo!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
