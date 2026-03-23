import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/match_list.dart';

class SearchTab extends StatelessWidget {
  final DataStore dataStore;
  final List<SearchChip> chips;
  final void Function(MatchWithVideos) onMatchTap;

  const SearchTab({
    super.key,
    required this.dataStore,
    required this.chips,
    required this.onMatchTap,
  });

  Set<int> _expandChipsToTeamNumbers() {
    final teamNumbers = <int>{};
    for (final chip in chips) {
      switch (chip.type) {
        case SearchChipType.team:
          if (chip.teamNumber != null) teamNumbers.add(chip.teamNumber!);
        case SearchChipType.alliance:
          if (chip.alliancePicks != null) {
            for (final pick in chip.alliancePicks!) {
              final num = int.tryParse(pick.replaceFirst('frc', ''));
              if (num != null) teamNumbers.add(num);
            }
          }
      }
    }
    return teamNumbers;
  }

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for teams or alliances',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final teamNumbers = _expandChipsToTeamNumbers();
    final eventKeys = dataStore.settings.selectedEventKeys;
    final allMatches = dataStore.getMatchesWithVideos(eventKeys);
    final showMultiEvent = eventKeys.length > 1;

    final filtered = allMatches.where((mwv) {
      for (final num in teamNumbers) {
        final teamKey = 'frc$num';
        if (mwv.match.redTeamKeys.contains(teamKey) ||
            mwv.match.blueTeamKeys.contains(teamKey)) {
          return true;
        }
      }
      return false;
    }).toList();

    return MatchList(
      matches: filtered,
      yourTeamNumber: dataStore.settings.teamNumber,
      highlightTeamNumbers: teamNumbers,
      showYourMatchesSection: false,
      showEventLabel: showMultiEvent,
      onMatchTap: onMatchTap,
    );
  }
}
