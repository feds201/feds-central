import 'dart:convert';
import 'dart:html' show window;

/// Thin wrapper around browser localStorage for persisting config and data.
class LocalPrefs {
  static const _kEventKey = 'scout_ops.eventKey';
  static const _kTableName = 'scout_ops.tableName';
  static const _kNeonConn = 'scout_ops.neonConn';
  static const _kTbaKey = 'scout_ops.tbaKey';
  static const _kCachedEvent = 'scout_ops.cachedEvent';
  static const _kCachedData = 'scout_ops.cachedData';
  static const _kLastUpdated = 'scout_ops.lastUpdated';

  // ── Config ──────────────────────────────────────────────────────────

  static void saveConfig({
    required String eventKey,
    required String tableName,
    required String neonConn,
    required String tbaKey,
  }) {
    try {
      final s = window.localStorage;
      s[_kEventKey] = eventKey;
      s[_kTableName] = tableName;
      s[_kNeonConn] = neonConn;
      s[_kTbaKey] = tbaKey;
      print('[LocalPrefs] saveConfig OK');
    } catch (e) {
      print('[LocalPrefs] saveConfig FAILED: $e');
    }
  }

  /// Resolve config from URL params (highest priority) then localStorage.
  /// Returns null if no Neon connection string is available.
  static ({
    String eventKey,
    String tableName,
    String neonConn,
    String tbaKey,
  })? resolveConfig() {
    final params = Uri.base.queryParameters;
    final s = window.localStorage;

    final neonConn = params['neon'] ?? s[_kNeonConn] ?? '';
    if (neonConn.isEmpty) return null;

    return (
      eventKey: params['event'] ?? s[_kEventKey] ?? '',
      tableName: params['table'] ?? s[_kTableName] ?? 'scouting_data',
      neonConn: neonConn,
      tbaKey: params['tba'] ?? s[_kTbaKey] ?? '',
    );
  }

  // ── Data cache ──────────────────────────────────────────────────────

  static void saveData({
    required String eventKey,
    required Map<int, List<Map<String, dynamic>>> scoutingByTeam,
    required List<String> scoutingColumns,
    required Map<int, double> oprByTeam,
    required Map<int, double> epaByTeam,
  }) {
    final s = window.localStorage;
    s[_kCachedEvent] = eventKey;
    s[_kLastUpdated] = DateTime.now().toIso8601String();

    // Drop base64 image columns to stay under localStorage quota.
    const dropCols = {'botimage1', 'botimage2', 'botimage3'};
    final teamData = scoutingByTeam.map(
      (k, v) => MapEntry(
        k.toString(),
        v.map((row) => Map.fromEntries(
          row.entries.where((e) => !dropCols.contains(e.key)),
        )).toList(),
      ),
    );
    final opr = oprByTeam.map((k, v) => MapEntry(k.toString(), v));
    final epa = epaByTeam.map((k, v) => MapEntry(k.toString(), v));

    final encoded = json.encode({
      'scoutingByTeam': teamData,
      'scoutingColumns': scoutingColumns,
      'oprByTeam': opr,
      'epaByTeam': epa,
    });

    final sizeKb = (encoded.length / 1024).toStringAsFixed(1);
    print('[LocalPrefs] saveData: ${sizeKb}KB, '
        '${scoutingByTeam.length} teams, '
        '${scoutingColumns.length} cols');

    try {
      s[_kCachedData] = encoded;
    } catch (e) {
      print('[LocalPrefs] saveData FAILED: $e');
      s.remove(_kCachedData);
      s.remove(_kCachedEvent);
      s.remove(_kLastUpdated);
    }
  }

  /// Load cached data if it matches [eventKey]. Returns null on mismatch
  /// or if no cache exists.
  static ({
    Map<int, List<Map<String, dynamic>>> scoutingByTeam,
    List<String> scoutingColumns,
    Map<int, double> oprByTeam,
    Map<int, double> epaByTeam,
  })? loadData(String eventKey) {
    final s = window.localStorage;
    if (s[_kCachedEvent] != eventKey) return null;

    final raw = s[_kCachedData];
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

      return (
        scoutingByTeam: teamMap,
        scoutingColumns: columns,
        oprByTeam: opr,
        epaByTeam: epa,
      );
    } on Exception {
      // Corrupted cache — clear and return null.
      s.remove(_kCachedData);
      s.remove(_kCachedEvent);
      s.remove(_kLastUpdated);
      return null;
    }
  }

  // ── Last updated ────────────────────────────────────────────────────

  static DateTime? get lastUpdated {
    final raw = window.localStorage[_kLastUpdated];
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  // ── Clear ───────────────────────────────────────────────────────────

  static void clear() {
    final s = window.localStorage;
    s.remove(_kEventKey);
    s.remove(_kTableName);
    s.remove(_kNeonConn);
    s.remove(_kTbaKey);
    s.remove(_kCachedData);
    s.remove(_kCachedEvent);
    s.remove(_kLastUpdated);
  }
}
