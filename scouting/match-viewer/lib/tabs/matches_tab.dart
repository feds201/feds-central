import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../widgets/match_list.dart';

class MatchesTab extends StatelessWidget {
  final DataStore dataStore;
  final void Function(MatchWithVideos) onMatchTap;
  final int selectedEventIndex;

  const MatchesTab({
    super.key,
    required this.dataStore,
    required this.onMatchTap,
    required this.selectedEventIndex,
  });

  @override
  Widget build(BuildContext context) {
    final eventKeys = dataStore.settings.selectedEventKeys;
    final showMultiEvent = eventKeys.length > 1;

    if (!showMultiEvent) {
      final matches = dataStore.getMatchesWithVideosFiltered(eventKeys);
      final alliances = dataStore.getAlliancesForEvents(eventKeys);
      return MatchList(
        matches: matches,
        yourTeamNumber: dataStore.settings.teamNumber,
        showYourMatchesSection: true,
        showEventLabel: false,
        alliances: alliances,
        onMatchTap: onMatchTap,
      );
    }

    final clampedIndex = selectedEventIndex.clamp(0, eventKeys.length - 1);
    final selectedEventKey = eventKeys[clampedIndex];
    final matches = dataStore.getMatchesWithVideosFiltered([selectedEventKey]);
    final alliances = dataStore.getAlliancesForEvents([selectedEventKey]);

    return MatchList(
      matches: matches,
      yourTeamNumber: dataStore.settings.teamNumber,
      showYourMatchesSection: true,
      showEventLabel: false,
      alliances: alliances,
      onMatchTap: onMatchTap,
    );
  }
}
