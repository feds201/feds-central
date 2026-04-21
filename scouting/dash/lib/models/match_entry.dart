/// One row in the match dropdown — a single match with both alliances.
class MatchEntry {
  final String matchKey;
  final String compLevel; // "qm", "sf", "f"
  final int matchNumber;
  final int setNumber;
  final List<int> redTeams;
  final List<int> blueTeams;
  final bool hasOurTeam;

  MatchEntry({
    required this.matchKey,
    required this.compLevel,
    required this.matchNumber,
    required this.setNumber,
    required this.redTeams,
    required this.blueTeams,
    required this.hasOurTeam,
  });

  /// Short identifier, e.g. "Q7", "SF1-2", "F1".
  String get shortLabel => switch (compLevel) {
        'qm' => 'Q$matchNumber',
        'sf' => 'SF$setNumber-$matchNumber',
        'f' => 'F$matchNumber',
        _ => '$compLevel$matchNumber',
      };

  /// Sort key: qm < sf < f, then set, then match.
  int get sortKey {
    final levelWeight = switch (compLevel) {
      'qm' => 0,
      'sf' => 1000000,
      'f' => 2000000,
      _ => 3000000,
    };
    return levelWeight + setNumber * 10000 + matchNumber;
  }
}

/// Parse TBA /event/{key}/matches JSON into a sorted list of [MatchEntry].
/// One entry per match; both alliances retained.
/// Placeholder team keys like "frc0" (used in unresolved playoff brackets)
/// are filtered out.
List<MatchEntry> parseMatches(
  List<dynamic> json, {
  String ourTeamKey = 'frc201',
}) {
  final entries = <MatchEntry>[];

  for (final match in json) {
    final alliances = match['alliances'] as Map<String, dynamic>?;
    if (alliances == null) continue;

    final redKeys =
        (alliances['red']?['team_keys'] as List<dynamic>?)?.cast<String>() ??
            const [];
    final blueKeys =
        (alliances['blue']?['team_keys'] as List<dynamic>?)?.cast<String>() ??
            const [];

    final hasOurTeam =
        redKeys.contains(ourTeamKey) || blueKeys.contains(ourTeamKey);

    List<int> parseTeamKeys(List<String> keys) => keys
        .map((k) => int.tryParse(k.replaceFirst('frc', '')))
        .whereType<int>()
        .where((n) => n > 0)
        .toList();

    entries.add(MatchEntry(
      matchKey: match['key'] as String? ?? '',
      compLevel: match['comp_level'] as String? ?? '',
      matchNumber: match['match_number'] as int? ?? 0,
      setNumber: match['set_number'] as int? ?? 0,
      redTeams: parseTeamKeys(redKeys),
      blueTeams: parseTeamKeys(blueKeys),
      hasOurTeam: hasOurTeam,
    ));
  }

  entries.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  return entries;
}
