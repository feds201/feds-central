import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../widgets/team_tile.dart';

class TeamsTab extends StatelessWidget {
  final DataStore dataStore;
  final void Function(Team) onTeamTap;
  final int selectedEventIndex;

  const TeamsTab({
    super.key,
    required this.dataStore,
    required this.onTeamTap,
    required this.selectedEventIndex,
  });

  @override
  Widget build(BuildContext context) {
    final eventKeys = dataStore.settings.selectedEventKeys;
    final yourTeamNumber = dataStore.settings.teamNumber;
    final showMultiEvent = eventKeys.length > 1;

    // When multi-event, filter teams to the selected event
    final List<String> filterKeys;
    if (showMultiEvent) {
      final clampedIndex = selectedEventIndex.clamp(0, eventKeys.length - 1);
      filterKeys = [eventKeys[clampedIndex]];
    } else {
      filterKeys = eventKeys;
    }

    final teamsWithEvents = dataStore.getDeduplicatedTeams(filterKeys);

    final sorted = List<TeamWithEvents>.from(teamsWithEvents)
      ..sort((a, b) => a.team.teamNumber.compareTo(b.team.teamNumber));

    TeamWithEvents? yourTeam;
    if (yourTeamNumber != null) {
      for (final t in sorted) {
        if (t.team.teamNumber == yourTeamNumber) {
          yourTeam = t;
          break;
        }
      }
    }

    if (sorted.isEmpty) {
      return Center(
        child: Text(
          'No teams loaded',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final items = <_ListItem>[];

    if (yourTeam != null) {
      items.add(_ListItem.team(yourTeam, isYours: true));
      items.add(const _ListItem.divider());
    }

    for (final t in sorted) {
      if (yourTeam != null && t.team.teamNumber == yourTeamNumber) continue;
      items.add(_ListItem.team(t));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDivider) return const Divider(height: 1);
        return TeamTile(
          team: item.teamWithEvents!.team,
          isYourTeam: item.isYours,
          eventSubtitle: showMultiEvent
              ? item.teamWithEvents!.eventShortNames.join(' \u2014\u2014 ')
              : null,
          onTap: () => onTeamTap(item.teamWithEvents!.team),
        );
      },
    );
  }
}

class _ListItem {
  final TeamWithEvents? teamWithEvents;
  final bool isDivider;
  final bool isYours;

  const _ListItem.team(this.teamWithEvents, {this.isYours = false})
      : isDivider = false;
  const _ListItem.divider()
      : teamWithEvents = null,
        isDivider = true,
        isYours = false;
}
