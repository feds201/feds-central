import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../widgets/team_tile.dart';

class TeamsTab extends StatelessWidget {
  final DataStore dataStore;
  final void Function(Team) onTeamTap;

  const TeamsTab({
    super.key,
    required this.dataStore,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventKeys = dataStore.settings.selectedEventKeys;
    final teams = dataStore.getTeamsForEvents(eventKeys);
    final yourTeamNumber = dataStore.settings.teamNumber;

    final sorted = List<Team>.from(teams)
      ..sort((a, b) => a.teamNumber.compareTo(b.teamNumber));

    Team? yourTeam;
    if (yourTeamNumber != null) {
      for (final t in sorted) {
        if (t.teamNumber == yourTeamNumber) {
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
      items.add(_ListItem.team(t, isYours: t.teamNumber == yourTeamNumber));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDivider) return const Divider(height: 1);
        return TeamTile(
          team: item.team!,
          isYourTeam: item.isYours,
          onTap: () => onTeamTap(item.team!),
        );
      },
    );
  }
}

class _ListItem {
  final Team? team;
  final bool isDivider;
  final bool isYours;

  const _ListItem.team(this.team, {this.isYours = false}) : isDivider = false;
  const _ListItem.divider()
      : team = null,
        isDivider = true,
        isYours = false;
}
