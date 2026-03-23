import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../widgets/alliance_tile.dart';

class AlliancesTab extends StatelessWidget {
  final DataStore dataStore;
  final void Function(Alliance) onAllianceTap;

  const AlliancesTab({
    super.key,
    required this.dataStore,
    required this.onAllianceTap,
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

    Alliance? yourAlliance;
    if (yourTeamNumber != null) {
      yourAlliance =
          dataStore.getAllianceForTeam(yourTeamNumber, eventKeys);
    }

    if (showMultiEvent) {
      return _buildGroupedByEvent(context, alliances, yourAlliance, eventKeys);
    }

    return _buildFlat(context, alliances, yourAlliance);
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
        if (item.isHeader) {
          return _buildSectionHeader(context, item.headerLabel!);
        }
        return AllianceTile(
          alliance: item.alliance!,
          isYourAlliance: item.isYours,
          onTap: () => onAllianceTap(item.alliance!),
        );
      },
    );
  }

  Widget _buildGroupedByEvent(
    BuildContext context,
    List<Alliance> alliances,
    Alliance? yourAlliance,
    List<String> eventKeys,
  ) {
    final eventMap = <String, List<Alliance>>{};
    for (final a in alliances) {
      (eventMap[a.eventKey] ??= []).add(a);
    }

    final events = dataStore.events;
    final eventNameMap = <String, String>{};
    for (final e in events) {
      eventNameMap[e.eventKey] = e.shortName;
    }

    final items = <_ListItem>[];

    if (yourAlliance != null) {
      items.add(_ListItem.alliance(yourAlliance, isYours: true));
      items.add(const _ListItem.divider());
    }

    for (final eventKey in eventKeys) {
      final eventAlliances = eventMap[eventKey];
      if (eventAlliances == null || eventAlliances.isEmpty) continue;

      final sorted = List<Alliance>.from(eventAlliances)
        ..sort((a, b) => a.allianceNumber.compareTo(b.allianceNumber));

      items.add(_ListItem.header(eventNameMap[eventKey] ?? eventKey));
      for (final a in sorted) {
        items.add(_ListItem.alliance(a,
            isYours: yourAlliance != null &&
                a.allianceNumber == yourAlliance.allianceNumber &&
                a.eventKey == yourAlliance.eventKey));
      }
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDivider) return const Divider(height: 1);
        if (item.isHeader) {
          return _buildSectionHeader(context, item.headerLabel!);
        }
        return AllianceTile(
          alliance: item.alliance!,
          isYourAlliance: item.isYours,
          onTap: () => onAllianceTap(item.alliance!),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ListItem {
  final Alliance? alliance;
  final bool isDivider;
  final bool isHeader;
  final String? headerLabel;
  final bool isYours;

  const _ListItem.alliance(this.alliance, {this.isYours = false})
      : isDivider = false,
        isHeader = false,
        headerLabel = null;

  const _ListItem.divider()
      : alliance = null,
        isDivider = true,
        isHeader = false,
        headerLabel = null,
        isYours = false;

  const _ListItem.header(this.headerLabel)
      : alliance = null,
        isDivider = false,
        isHeader = true,
        isYours = false;
}
