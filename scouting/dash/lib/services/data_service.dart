import 'package:flutter/foundation.dart';
import '../models/match_entry.dart';
import 'neon_service.dart';
import 'tba_service.dart';
import 'statbotics_service.dart';
import 'csv_loader.dart';

/// Central state object exposed via Provider.
class DataService extends ChangeNotifier {
  // ── Configuration ──────────────────────────────────────────────────
  String _eventKey = '';
  String _tableName = '';
  String _neonConnString = '';
  String _tbaApiKey = '';

  String get eventKey => _eventKey;
  String get tableName => _tableName;

  void configure({
    required String eventKey,
    required String tableName,
    String neonConnString = '',
    String tbaApiKey = '',
  }) {
    _eventKey = eventKey;
    _tableName = tableName;
    if (neonConnString.isNotEmpty) _neonConnString = neonConnString;
    if (tbaApiKey.isNotEmpty) _tbaApiKey = tbaApiKey;
  }

  // ── State ──────────────────────────────────────────────────────────
  bool loading = false;
  String? error;
  String _dataSource = ''; // 'neon', 'csv', or 'cache'
  DateTime? lastUpdated;

  String get dataSource => _dataSource;

  List<String> scoutingColumns = [];
  Map<int, List<Map<String, dynamic>>> scoutingByTeam = {};
  Map<int, double> oprByTeam = {};
  Map<int, double> epaByTeam = {};
  List<MatchEntry> matchEntries = [];

  List<int> get teamNumbers {
    final nums = scoutingByTeam.keys.toList()..sort();
    return nums;
  }

  List<String> get displayColumns {
    const skip = {'team', 'match_key'};
    return scoutingColumns
        .where((c) => !skip.contains(c.toLowerCase()))
        .toList();
  }

  // ── Load from cache ─────────────────────────────────────────────────

  void loadFromCache({
    required Map<int, List<Map<String, dynamic>>> scoutingByTeam,
    required List<String> scoutingColumns,
    required Map<int, double> oprByTeam,
    required Map<int, double> epaByTeam,
    DateTime? lastUpdated,
  }) {
    this.scoutingByTeam = scoutingByTeam;
    this.scoutingColumns = scoutingColumns;
    this.oprByTeam = oprByTeam;
    this.epaByTeam = epaByTeam;
    this.lastUpdated = lastUpdated;
    _dataSource = 'cache';
    notifyListeners();
  }

  // ── Load from CSV string ───────────────────────────────────────────

  void loadFromCsv(String csvText) {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final rows = CsvLoader.parse(csvText);
      scoutingColumns = CsvLoader.columns(csvText);

      scoutingByTeam = {};
      for (final row in rows) {
        final raw = row['team'];
        final teamNum = raw is int ? raw : int.tryParse(raw.toString());
        if (teamNum == null) continue;
        scoutingByTeam.putIfAbsent(teamNum, () => []).add(row);
      }

      _dataSource = 'csv';
      error = null;
    } catch (e) {
      error = 'CSV parse error: $e';
    } finally {
      loading = false;
      lastUpdated = DateTime.now();
      notifyListeners();
    }
  }

  // ── Fetch from Neon + TBA + Statbotics ─────────────────────────────

  Future<void> fetchAll() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final neon = NeonService(_neonConnString);
      final tba = TbaService(_tbaApiKey);
      final statbotics = StatboticsService();

      final errors = <String>[];

      try {
        final results = await Future.wait([
          neon.fetchAll(_tableName),
          neon.columns(_tableName),
        ]);
        final rows = results[0] as List<Map<String, dynamic>>;
        scoutingColumns = results[1] as List<String>;

        scoutingByTeam = {};
        for (final row in rows) {
          final raw = row['team'];
          final teamNum = raw is int ? raw : int.tryParse(raw.toString());
          if (teamNum == null) continue;
          scoutingByTeam.putIfAbsent(teamNum, () => []).add(row);
        }
        _dataSource = 'neon';
      } catch (e) {
        errors.add('Neon: $e');
      }

      try {
        oprByTeam = await tba.fetchOprs(_eventKey);
      } catch (e) {
        errors.add('TBA OPR: $e');
      }

      try {
        final rawMatches = await tba.fetchMatches(_eventKey);
        matchEntries = parseMatches(rawMatches, ourTeamKey: 'frc201');
      } catch (e) {
        errors.add('TBA matches: $e');
      }

      try {
        epaByTeam = await statbotics.fetchEpas(_eventKey);
      } catch (e) {
        errors.add('Statbotics: $e');
      }

      error = errors.isEmpty ? null : errors.join('\n');
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      lastUpdated = DateTime.now();
      notifyListeners();
    }
  }

  // ── Fetch TBA/Statbotics only (for CSV mode) ──────────────────────

  Future<void> fetchExternalOnly() async {
    loading = true;
    notifyListeners();

    final errors = <String>[];
    final tba = TbaService(_tbaApiKey);
    final statbotics = StatboticsService();

    try {
      oprByTeam = await tba.fetchOprs(_eventKey);
    } catch (e) {
      errors.add('TBA OPR: $e');
    }

    try {
      final rawMatches = await tba.fetchMatches(_eventKey);
      matchEntries = parseMatches(rawMatches, ourTeamKey: 'frc201');
    } catch (e) {
      errors.add('TBA matches: $e');
    }

    try {
      epaByTeam = await statbotics.fetchEpas(_eventKey);
    } catch (e) {
      errors.add('Statbotics: $e');
    }

    if (errors.isNotEmpty) {
      error = (error != null ? '$error\n' : '') + errors.join('\n');
    }

    loading = false;
    notifyListeners();
  }

  // ── Convenience ────────────────────────────────────────────────────

  Map<String, dynamic> summaryForTeam(int team) {
    final rows = scoutingByTeam[team];
    if (rows == null || rows.isEmpty) return {};
    return rows.first;
  }

  String? detectAutoPathColumn() {
    for (final col in scoutingColumns) {
      for (final rows in scoutingByTeam.values) {
        for (final row in rows) {
          final val = row[col];
          if (val is String && val.contains('|') && val.contains('M')) {
            return col;
          }
        }
      }
    }
    return null;
  }
}
