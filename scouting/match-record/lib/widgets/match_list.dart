import 'package:flutter/material.dart';

import '../data/models.dart';
import 'match_row.dart';

class MatchList extends StatelessWidget {
  final List<MatchWithVideos> matches;
  final int? yourTeamNumber;
  final Set<int>? highlightTeamNumbers;
  final bool showYourMatchesSection;
  final bool showEventLabel;
  final bool highlightOwnTeam;
  final List<Alliance> alliances;
  final void Function(MatchWithVideos) onMatchTap;

  const MatchList({
    super.key,
    required this.matches,
    this.yourTeamNumber,
    this.highlightTeamNumbers,
    this.showYourMatchesSection = false,
    this.showEventLabel = false,
    this.highlightOwnTeam = true,
    this.alliances = const [],
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

  /// Builds the list items for the "Your Matches" / "Quals" / "Playoffs" sections.
  /// Used when showYourMatchesSection is true (the Matches tab).
  List<_ListItem> _buildSectionedItems(List<MatchWithVideos> sorted) {
    final yourMatches = _sortByTime(sorted.where(_isYourMatch).toList());
    final quals = sorted.where((m) => m.match.compLevel == 'qm').toList();
    final playoffs = sorted.where((m) => m.match.compLevel != 'qm').toList();

    final items = <_ListItem>[];

    // "Our Matches" section
    if (yourMatches.isNotEmpty) {
      items.add(const _ListItem.header('Our Matches'));
      for (final m in yourMatches) {
        items.add(_ListItem.match(m, isYourMatch: true));
      }
      items.add(const _ListItem.divider());
    }

    // "Quals" section
    if (quals.isNotEmpty) {
      items.add(const _ListItem.header('Quals'));
      for (final m in quals) {
        items.add(_ListItem.match(m, isYourMatch: _isYourMatch(m)));
      }
    }

    // "Playoffs" section
    if (playoffs.isNotEmpty) {
      if (quals.isNotEmpty) {
        items.add(const _ListItem.divider());
      }
      items.add(const _ListItem.header('Playoffs'));
      for (final m in playoffs) {
        items.add(_ListItem.match(m, isYourMatch: _isYourMatch(m)));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(child: Text('No matches'));
    }

    final sorted = _sortByTime(matches);

    if (!showYourMatchesSection) {
      return ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) => _buildRow(sorted[index]),
      );
    }

    final items = _buildSectionedItems(sorted);

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
            return _buildRow(
              item.matchWithVideos!,
              isYourMatch: item.isYourMatch,
            );
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

  Widget _buildRow(MatchWithVideos mwv, {bool isYourMatch = false}) {
    return MatchRow(
      matchWithVideos: mwv,
      yourTeamNumber: yourTeamNumber,
      highlightTeamNumbers: highlightTeamNumbers,
      showEventLabel: showEventLabel,
      isYourMatch: isYourMatch,
      highlightOwnTeam: highlightOwnTeam,
      alliances: alliances,
      onTap: () => onMatchTap(mwv),
    );
  }
}

enum _ItemType { header, divider, match }

class _ListItem {
  final _ItemType type;
  final String? label;
  final MatchWithVideos? matchWithVideos;
  final bool isYourMatch;

  const _ListItem.header(this.label)
      : type = _ItemType.header,
        matchWithVideos = null,
        isYourMatch = false;

  const _ListItem.divider()
      : type = _ItemType.divider,
        label = null,
        matchWithVideos = null,
        isYourMatch = false;

  const _ListItem.match(this.matchWithVideos, {this.isYourMatch = false})
      : type = _ItemType.match,
        label = null;
}
