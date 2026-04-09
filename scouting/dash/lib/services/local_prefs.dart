import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists config and cached scouting data using SharedPreferences (Android).
class LocalPrefs {
  static const _kEventKey = 'scout_ops.eventKey';
  static const _kTableName = 'scout_ops.tableName';
  static const _kNeonConn = 'scout_ops.neonConn';
  static const _kTbaKey = 'scout_ops.tbaKey';
  static const _kCachedEvent = 'scout_ops.cachedEvent';
  static const _kCachedData = 'scout_ops.cachedData';
  static const _kLastUpdated = 'scout_ops.lastUpdated';

  // ── Config ──────────────────────────────────────────────────────────
  static dynamic _toJsonSafe(dynamic value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _toJsonSafe(v)));
    if (value is List) return value.map(_toJsonSafe).toList();
    return value;
  }
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
    tbaKey: prefs.getString(_kTbaKey) ?? '',
    );
  }

  // ── Data cache ──────────────────────────────────────────────────────

  static Future<void> saveData({
    required String eventKey,
    required Map<int, List<Map<String, dynamic>>> scoutingByTeam,
    required List<String> scoutingColumns,
    required Map<int, double> oprByTeam,
    required Map<int, double> epaByTeam,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedEvent, eventKey);
    await prefs.setString(_kLastUpdated, DateTime.now().toIso8601String());

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
      await prefs.setString(_kCachedData, encoded);
    } catch (e) {
      print('[LocalPrefs] saveData FAILED: $e');
      await prefs.remove(_kCachedData);
      await prefs.remove(_kCachedEvent);
      await prefs.remove(_kLastUpdated);
    }
  }

  static Future<({
  Map<int, List<Map<String, dynamic>>> scoutingByTeam,
  List<String> scoutingColumns,
  Map<int, double> oprByTeam,
  Map<int, double> epaByTeam,
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
      final columns = (decoded['scoutingColumns'] as List).cast<String>().toList();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedData);
      await prefs.remove(_kCachedEvent);
      await prefs.remove(_kLastUpdated);
      return null;
    }
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
  }
}

// ---------------
