import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../widgets/match_list.dart';

class MatchesTab extends StatelessWidget {
  final DataStore dataStore;
  final void Function(MatchWithVideos) onMatchTap;

  const MatchesTab({
    super.key,
    required this.dataStore,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventKeys = dataStore.settings.selectedEventKeys;
    final matches = dataStore.getMatchesWithVideosFiltered(eventKeys);
    final showMultiEvent = eventKeys.length > 1;

    final alliances = dataStore.getAlliancesForEvents(eventKeys);

    return MatchList(
      matches: matches,
      yourTeamNumber: dataStore.settings.teamNumber,
      showYourMatchesSection: true,
      showEventLabel: showMultiEvent,
      alliances: alliances,
      onMatchTap: onMatchTap,
    );
  }
}
