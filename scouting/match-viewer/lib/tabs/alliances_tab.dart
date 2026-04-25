import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../widgets/alliance_tile.dart';

class AlliancesTab extends StatelessWidget {
  final DataStore dataStore;
  final void Function(Alliance) onAllianceTap;
  final int selectedEventIndex;

  const AlliancesTab({
    super.key,
    required this.dataStore,
    required this.onAllianceTap,
    required this.selectedEventIndex,
  });

  @override
  Widget build(BuildContext context) {
    final eventKeys = dataStore.settings.selectedEventKeys;
    final alliances = dataStore.getAlliancesForEvents(eventKeys);
    final yourTeamNumber = dataStore.settings.teamNumber;
    final showMultiEvent = eventKeys.length > 1;

    if (alliances.isEmpty) {
      return Center(
        child: Text(
          'No alliances loaded',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    if (!showMultiEvent) {
      Alliance? yourAlliance;
      if (yourTeamNumber != null) {
        yourAlliance =
            dataStore.getAllianceForTeam(yourTeamNumber, eventKeys);
      }
      return _buildFlat(context, alliances, yourAlliance);
    }

    final clampedIndex = selectedEventIndex.clamp(0, eventKeys.length - 1);
    final selectedEventKey = eventKeys[clampedIndex];
    final eventAlliances =
        alliances.where((a) => a.eventKey == selectedEventKey).toList();

    Alliance? yourAlliance;
    if (yourTeamNumber != null) {
      yourAlliance = dataStore
          .getAllianceForTeam(yourTeamNumber, [selectedEventKey]);
    }

    return _buildFlat(context, eventAlliances, yourAlliance);
  }

  Widget _buildFlat(
    BuildContext context,
    List<Alliance> alliances,
    Alliance? yourAlliance,
  ) {
    final sorted = List<Alliance>.from(alliances)
      ..sort((a, b) => a.allianceNumber.compareTo(b.allianceNumber));

    final items = <_ListItem>[];

    if (yourAlliance != null) {
      items.add(_ListItem.alliance(yourAlliance, isYours: true));
      items.add(const _ListItem.divider());
    }

    for (final a in sorted) {
      items.add(_ListItem.alliance(a,
          isYours: yourAlliance != null &&
              a.allianceNumber == yourAlliance.allianceNumber &&
              a.eventKey == yourAlliance.eventKey));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDivider) return const Divider(height: 1);
        return AllianceTile(
          alliance: item.alliance!,
          isYourAlliance: item.isYours,
          onTap: () => onAllianceTap(item.alliance!),
        );
      },
    );
  }
}

class _ListItem {
  final Alliance? alliance;
  final bool isDivider;
  final bool isYours;

  const _ListItem.alliance(this.alliance, {this.isYours = false})
      : isDivider = false;

  const _ListItem.divider()
      : alliance = null,
        isDivider = true,
        isYours = false;
}
