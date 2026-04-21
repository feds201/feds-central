/// One playoff alliance from TBA `/event/{key}/alliances`.
class PlayoffAlliance {
  final String name;
  final List<int> teams;

  const PlayoffAlliance({required this.name, required this.teams});
}

/// Parse the raw TBA `/event/{key}/alliances` response.
/// Returns `[]` for null, empty, or malformed inputs.
/// Alliance names are synthesized as "Alliance N" (1-indexed) since TBA's
/// `name` field is usually null outside of CMP events.
List<PlayoffAlliance> parsePlayoffAlliances(dynamic raw) {
  if (raw is! List) return const [];

  final alliances = <PlayoffAlliance>[];
  for (var i = 0; i < raw.length; i++) {
    final item = raw[i];
    if (item is! Map) continue;
    final picks = (item['picks'] as List<dynamic>?)?.cast<String>() ?? const [];
    final teams = picks
        .map((k) => int.tryParse(k.replaceFirst('frc', '')))
        .whereType<int>()
        .where((n) => n > 0)
        .toList();
    if (teams.isEmpty) continue;
    final givenName = item['name'] as String?;
    alliances.add(PlayoffAlliance(
      name: (givenName != null && givenName.isNotEmpty)
          ? givenName
          : 'Alliance ${i + 1}',
      teams: teams,
    ));
  }
  return alliances;
}
