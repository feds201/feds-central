import 'package:flutter/material.dart';

import '../data/models.dart';
import 'match_row.dart';

class MatchList extends StatelessWidget {
  final List<MatchWithVideos> matches;
  final int? yourTeamNumber;
  final Set<int>? highlightTeamNumbers;
  final bool showYourMatchesSection;
  final bool showEventLabel;
  final void Function(MatchWithVideos) onMatchTap;

  const MatchList({
    super.key,
    required this.matches,
    this.yourTeamNumber,
    this.highlightTeamNumbers,
    this.showYourMatchesSection = false,
    this.showEventLabel = false,
    required this.onMatchTap,
  });

  List<MatchWithVideos> _sortByTime(List<MatchWithVideos> list) {
    final sorted = List<MatchWithVideos>.from(list);
    sorted.sort((a, b) {
      final aTime = a.match.time;
      final bTime = b.match.time;
      if (aTime != null && bTime != null) return aTime.compareTo(bTime);
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      final levelCmp =
          a.match.compLevelPriority.compareTo(b.match.compLevelPriority);
      if (levelCmp != 0) return levelCmp;
      final setCmp = a.match.setNumber.compareTo(b.match.setNumber);
      if (setCmp != 0) return setCmp;
      return a.match.matchNumber.compareTo(b.match.matchNumber);
    });
    return sorted;
  }

  bool _isYourMatch(MatchWithVideos mwv) {
    if (yourTeamNumber == null) return false;
    final teamKey = 'frc$yourTeamNumber';
    return mwv.match.redTeamKeys.contains(teamKey) ||
        mwv.match.blueTeamKeys.contains(teamKey);
  }

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(child: Text('No matches'));
    }

    final sorted = _sortByTime(matches);

    if (!showYourMatchesSection || yourTeamNumber == null) {
      return ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) => _buildRow(sorted[index]),
      );
    }

    final yourMatches = _sortByTime(sorted.where(_isYourMatch).toList());
    final allMatches = sorted;

    final items = <_ListItem>[];

    if (yourMatches.isNotEmpty) {
      items.add(const _ListItem.header('Your Matches'));
      for (final m in yourMatches) {
        items.add(_ListItem.match(m));
      }
      items.add(const _ListItem.divider());
    }

    items.add(const _ListItem.header('All Matches'));
    for (final m in allMatches) {
      items.add(_ListItem.match(m));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        switch (item.type) {
          case _ItemType.header:
            return _buildSectionHeader(context, item.label!);
          case _ItemType.divider:
            return const Divider(height: 1);
          case _ItemType.match:
            return _buildRow(item.matchWithVideos!);
        }
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

  Widget _buildRow(MatchWithVideos mwv) {
    return MatchRow(
      matchWithVideos: mwv,
      yourTeamNumber: yourTeamNumber,
      highlightTeamNumbers: highlightTeamNumbers,
      showEventLabel: showEventLabel,
      onTap: () => onMatchTap(mwv),
    );
  }
}

enum _ItemType { header, divider, match }

class _ListItem {
  final _ItemType type;
  final String? label;
  final MatchWithVideos? matchWithVideos;

  const _ListItem.header(this.label)
      : type = _ItemType.header,
        matchWithVideos = null;

  const _ListItem.divider()
      : type = _ItemType.divider,
        label = null,
        matchWithVideos = null;

  const _ListItem.match(this.matchWithVideos)
      : type = _ItemType.match,
        label = null;
}
