import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_entry.dart';
import '../models/playoff_alliance.dart';

/// Persists config, cached scouting data, and locally drawn paths.
class LocalPrefs {
  static const _kEventKey = 'scout_ops.eventKey';
  static const _kTableName = 'scout_ops.tableName';
  static const _kNeonConn = 'scout_ops.neonConn';
  static const _kTbaKey = 'scout_ops.tbaKey';
  static const _kCachedEvent = 'scout_ops.cachedEvent';
  static const _kCachedData = 'scout_ops.cachedData';
  static const _kLastUpdated = 'scout_ops.lastUpdated';
  static const _kLocalPaths = 'scout_ops.localPaths';

  // Read-only key for public TBA data — safe to commit.
  static const _defaultTbaKey =
      'nfgL68cGRgoKXYWT0D4JcGxv6lPYuWkWVz4TcYPN9VlFQ6vHoLrQjJRwjFKRcJu8';

  // ── JSON-safe value helper ───────────────────────────────────────────

  static Map<String, dynamic> _matchToJson(MatchEntry m) => {
        'matchKey': m.matchKey,
        'compLevel': m.compLevel,
        'matchNumber': m.matchNumber,
        'setNumber': m.setNumber,
        'redTeams': m.redTeams,
        'blueTeams': m.blueTeams,
        'hasOurTeam': m.hasOurTeam,
      };

  static MatchEntry _matchFromJson(Map<String, dynamic> j) => MatchEntry(
        matchKey: j['matchKey'] as String,
        compLevel: j['compLevel'] as String,
        matchNumber: j['matchNumber'] as int,
        setNumber: j['setNumber'] as int,
        redTeams: (j['redTeams'] as List).cast<int>().toList(),
        blueTeams: (j['blueTeams'] as List).cast<int>().toList(),
        hasOurTeam: j['hasOurTeam'] as bool,
      );

  static Map<String, dynamic> _allianceToJson(PlayoffAlliance a) => {
        'name': a.name,
        'teams': a.teams,
      };

  static PlayoffAlliance _allianceFromJson(Map<String, dynamic> j) =>
      PlayoffAlliance(
        name: j['name'] as String,
        teams: (j['teams'] as List).cast<int>().toList(),
      );

  static dynamic _toJsonSafe(dynamic value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toJsonSafe(v)));
    }
    if (value is List) return value.map(_toJsonSafe).toList();
    return value;
  }

  // ── Config ──────────────────────────────────────────────────────────

  static Future<void> saveConfig({
    required String eventKey,
    required String tableName,
    required String neonConn,
    required String tbaKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kEventKey, eventKey);
      await prefs.setString(_kTableName, tableName);
      await prefs.setString(_kNeonConn, neonConn);
      await prefs.setString(_kTbaKey, tbaKey);
      print('[LocalPrefs] saveConfig OK');
    } catch (e) {
      print('[LocalPrefs] saveConfig FAILED: $e');
    }
  }

  static Future<({
  String eventKey,
  String tableName,
  String neonConn,
  String tbaKey,
  })?> resolveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final neonConn = prefs.getString(_kNeonConn) ?? '';
    if (neonConn.isEmpty) return null;

    return (
    eventKey: prefs.getString(_kEventKey) ?? '',
    tableName: prefs.getString(_kTableName) ?? 'scouting_data',
    neonConn: neonConn,
    tbaKey: prefs.getString(_kTbaKey) ?? _defaultTbaKey,
    );
  }

  // ── Data cache ──────────────────────────────────────────────────────

  static Future<void> saveData({
    required String eventKey,
    required Map<int, List<Map<String, dynamic>>> scoutingByTeam,
    required List<String> scoutingColumns,
    required Map<int, double> oprByTeam,
    required Map<int, double> epaByTeam,
    required List<MatchEntry> matchEntries,
    required List<PlayoffAlliance> playoffAlliances,
    required Map<int, String> teamNames,
  }) async {
    if (scoutingByTeam.isEmpty) {
      print('[LocalPrefs] saveData SKIPPED: empty scouting data');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Snapshot prior values for rollback if the write fails partway through.
    final oldData = prefs.getString(_kCachedData);
    final oldEvent = prefs.getString(_kCachedEvent);
    final oldUpdated = prefs.getString(_kLastUpdated);

    const dropCols = {'botimage1', 'botimage2', 'botimage3'};
    final teamData = scoutingByTeam.map(
          (k, v) => MapEntry(
        k.toString(),
        v.map((row) => Map.fromEntries(
          row.entries
              .where((e) => !dropCols.contains(e.key))
              .map((e) => MapEntry(e.key, _toJsonSafe(e.value))),
        )).toList(),
      ),
    );
    final opr = oprByTeam.map((k, v) => MapEntry(k.toString(), v));
    final epa = epaByTeam.map((k, v) => MapEntry(k.toString(), v));
    final matches = matchEntries.map(_matchToJson).toList();
    final alliances = playoffAlliances.map(_allianceToJson).toList();
    final names = teamNames.map((k, v) => MapEntry(k.toString(), v));

    final encoded = json.encode({
      'scoutingByTeam': teamData,
      'scoutingColumns': scoutingColumns,
      'oprByTeam': opr,
      'epaByTeam': epa,
      'matchEntries': matches,
      'playoffAlliances': alliances,
      'teamNames': names,
    });

    final sizeKb = (encoded.length / 1024).toStringAsFixed(1);
    print('[LocalPrefs] saveData: ${sizeKb}KB, '
        '${scoutingByTeam.length} teams, '
        '${scoutingColumns.length} cols');

    try {
      await prefs.setString(_kCachedData, encoded);
      await prefs.setString(_kCachedEvent, eventKey);
      await prefs.setString(_kLastUpdated, DateTime.now().toIso8601String());
    } catch (e) {
      print('[LocalPrefs] saveData FAILED, rolling back: $e');
      await _restore(prefs, _kCachedData, oldData);
      await _restore(prefs, _kCachedEvent, oldEvent);
      await _restore(prefs, _kLastUpdated, oldUpdated);
    }
  }

  static Future<void> _restore(
      SharedPreferences prefs, String key, String? oldValue) async {
    if (oldValue != null) {
      await prefs.setString(key, oldValue);
    } else {
      await prefs.remove(key);
    }
  }

  static Future<({
  Map<int, List<Map<String, dynamic>>> scoutingByTeam,
  List<String> scoutingColumns,
  Map<int, double> oprByTeam,
  Map<int, double> epaByTeam,
  List<MatchEntry> matchEntries,
  List<PlayoffAlliance> playoffAlliances,
  Map<int, String> teamNames,
  })?> loadData(String eventKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kCachedEvent) != eventKey) return null;

    final raw = prefs.getString(_kCachedData);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;

      final teamMap = (decoded['scoutingByTeam'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(
          int.parse(k),
          (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        ),
      );
      final columns =
      (decoded['scoutingColumns'] as List).cast<String>().toList();
      final opr = (decoded['oprByTeam'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      );
      final epa = (decoded['epaByTeam'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      );
      final matches = ((decoded['matchEntries'] as List?) ?? const [])
          .map((e) => _matchFromJson(e as Map<String, dynamic>))
          .toList();
      final alliances = ((decoded['playoffAlliances'] as List?) ?? const [])
          .map((e) => _allianceFromJson(e as Map<String, dynamic>))
          .toList();
      final names = ((decoded['teamNames'] as Map<String, dynamic>?) ?? const {})
          .map((k, v) => MapEntry(int.parse(k), v as String));

      return (
      scoutingByTeam: teamMap,
      scoutingColumns: columns,
      oprByTeam: opr,
      epaByTeam: epa,
      matchEntries: matches,
      playoffAlliances: alliances,
      teamNames: names,
      );
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedData);
      await prefs.remove(_kCachedEvent);
      await prefs.remove(_kLastUpdated);
      return null;
    }
  }

  // ── Locally drawn paths ─────────────────────────────────────────────
  // Stored as: { "201": { "Left Start": "v2:M...", "Center": "v2:M..." }, ... }

  static Future<Map<String, Map<String, String>>> loadLocalPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLocalPaths);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((teamKey, paths) => MapEntry(
        teamKey,
        (paths as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString())),
      ));
    } catch (e) {
      print('[LocalPrefs] loadLocalPaths FAILED: $e');
      return {};
    }
  }

  static Future<void> saveLocalPaths(
      Map<String, Map<String, String>> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(paths);
    await prefs.setString(_kLocalPaths, encoded);
    print('[LocalPrefs] saveLocalPaths OK — ${paths.length} teams');
  }

  static Future<void> deleteLocalPath(String teamKey, String pathName) async {
    final all = await loadLocalPaths();
    all[teamKey]?.remove(pathName);
    if (all[teamKey]?.isEmpty ?? false) all.remove(teamKey);
    await saveLocalPaths(all);
  }

  // ── Last updated ────────────────────────────────────────────────────

  static Future<DateTime?> get lastUpdated async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastUpdated);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  // ── Clear ───────────────────────────────────────────────────────────

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEventKey);
    await prefs.remove(_kTableName);
    await prefs.remove(_kNeonConn);
    await prefs.remove(_kTbaKey);
    await prefs.remove(_kCachedData);
    await prefs.remove(_kCachedEvent);
    await prefs.remove(_kLastUpdated);
    // Note: local paths are NOT cleared on config reset — intentional
  }
}