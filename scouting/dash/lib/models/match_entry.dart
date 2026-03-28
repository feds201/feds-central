/// One selectable row in the match dropdown.
/// Each TBA match produces TWO entries (one per alliance).
class MatchEntry {
  final String matchKey;
  final String compLevel; // "qm", "sf", "f"
  final int matchNumber;
  final int setNumber;
  final String alliance; // "red" or "blue"
  final bool isOurAlliance;
  final List<int> teamNumbers; // the 3 teams on this alliance

  MatchEntry({
    required this.matchKey,
    required this.compLevel,
    required this.matchNumber,
    required this.setNumber,
    required this.alliance,
    required this.isOurAlliance,
    required this.teamNumbers,
  });

  /// Display label, e.g. "Q7: Red (us)" or "SF1-2: Blue (them)"
  String get label {
    final prefix = switch (compLevel) {
      'qm' => 'Q$matchNumber',
      'sf' => 'SF$setNumber-$matchNumber',
      'f' => 'F$matchNumber',
      _ => '$compLevel$matchNumber',
    };
    final color = alliance == 'red' ? 'red' : 'blue';
    final tag = isOurAlliance ? 'us' : 'them';
    return '$prefix: $tag ($color)';
  }

  /// Sort key: qm < sf < f, then set, then match, then red before blue.
  int get sortKey {
    final levelWeight = switch (compLevel) {
      'qm' => 0,
      'sf' => 1000000,
      'f' => 2000000,
      _ => 3000000,
    };
    return levelWeight +
        setNumber * 10000 +
        matchNumber * 10 +
        (alliance == 'red' ? 0 : 1);
  }
}

/// Parse TBA /event/{key}/matches JSON into a sorted list of [MatchEntry].
/// Only includes matches where [ourTeamKey] is on one of the alliances.
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
            [];
    final blueKeys =
        (alliances['blue']?['team_keys'] as List<dynamic>?)?.cast<String>() ??
            [];

    final onRed = redKeys.contains(ourTeamKey);
    final onBlue = blueKeys.contains(ourTeamKey);
    if (!onRed && !onBlue) continue;

    List<int> parseTeamKeys(List<String> keys) => keys
        .map((k) => int.tryParse(k.replaceFirst('frc', '')))
        .whereType<int>()
        .toList();

    final compLevel = match['comp_level'] as String? ?? '';
    final matchNumber = match['match_number'] as int? ?? 0;
    final setNumber = match['set_number'] as int? ?? 0;
    final matchKey = match['key'] as String? ?? '';

    entries.add(MatchEntry(
      matchKey: matchKey,
      compLevel: compLevel,
      matchNumber: matchNumber,
      setNumber: setNumber,
      alliance: 'red',
      isOurAlliance: onRed,
      teamNumbers: parseTeamKeys(redKeys),
    ));

    entries.add(MatchEntry(
      matchKey: matchKey,
      compLevel: compLevel,
      matchNumber: matchNumber,
      setNumber: setNumber,
      alliance: 'blue',
      isOurAlliance: onBlue,
      teamNumbers: parseTeamKeys(blueKeys),
    ));
  }

  entries.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  return entries;
}
