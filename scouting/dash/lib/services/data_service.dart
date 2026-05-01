import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/match_entry.dart';
import '../models/playoff_alliance.dart';
import 'neon_service.dart';
import 'tba_service.dart';
import 'statbotics_service.dart';
import 'csv_loader.dart';

enum SyncTaskStatus { loading, done, fail }

/// Snapshot of all in-flight sync tasks. Iteration order = launch order.
class SyncProgress {
  SyncProgress(this.statuses);
  final Map<String, SyncTaskStatus> statuses;

  int get total => statuses.length;
  int get finished => statuses.values
      .where((s) => s == SyncTaskStatus.done || s == SyncTaskStatus.fail)
      .length;

  /// "2/4 — neon: done, tba opr: loading, tba matches: fail, statbotics: done"
  String get summary {
    final parts = statuses.entries.map((e) => '${e.key}: ${e.value.name}');
    return '$finished/$total — ${parts.join(', ')}';
  }
}

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
  String _dataSource = '';
  DateTime? lastUpdated;
  Timer? _errorDismissTimer;

  /// Returns true iff every error in [errors] looks like a network-offline
  /// failure (DNS lookup / socket). Empty list → false.
  static bool _allOffline(List<String> errors) {
    if (errors.isEmpty) return false;
    return errors.every((e) =>
        e.contains('SocketException') || e.contains('Failed host lookup'));
  }

  /// If [errors] are all offline-style, sets a friendly one-liner and
  /// schedules it to auto-dismiss after 5s. Otherwise returns false so the
  /// caller can fall back to the detailed message.
  bool _applyOfflineErrorIfAllOffline(List<String> errors) {
    if (!_allOffline(errors)) return false;
    error = 'No internet connection — showing last-loaded data.';
    _errorDismissTimer?.cancel();
    _errorDismissTimer = Timer(const Duration(seconds: 5), () {
      error = null;
      notifyListeners();
    });
    return true;
  }

  @override
  void dispose() {
    _errorDismissTimer?.cancel();
    super.dispose();
  }

  String get dataSource => _dataSource;

  List<String> scoutingColumns = [];
  Map<int, List<Map<String, dynamic>>> scoutingByTeam = {};
  Map<int, double> oprByTeam = {};
  Map<int, double> epaByTeam = {};
  List<MatchEntry> matchEntries = [];
  List<PlayoffAlliance> playoffAlliances = [];
  Map<int, String> teamNames = {};

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
    required List<MatchEntry> matchEntries,
    required List<PlayoffAlliance> playoffAlliances,
    required Map<int, String> teamNames,
    DateTime? lastUpdated,
  }) {
    this.scoutingByTeam = scoutingByTeam;
    this.scoutingColumns = scoutingColumns;
    this.oprByTeam = oprByTeam;
    this.epaByTeam = epaByTeam;
    this.matchEntries = matchEntries;
    this.playoffAlliances = playoffAlliances;
    this.teamNames = teamNames;
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
      final cols = CsvLoader.columns(csvText);

      final next = <int, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final raw = row['team'];
        final teamNum = raw is int ? raw : int.tryParse(raw.toString());
        if (teamNum == null) continue;
        next.putIfAbsent(teamNum, () => []).add(row);
      }

      if (next.isNotEmpty) {
        scoutingByTeam = next;
        scoutingColumns = cols;
        _dataSource = 'csv';
      }
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

  Future<void> fetchAll({void Function(SyncProgress)? onProgress}) async {
    _errorDismissTimer?.cancel();
    loading = true;
    error = null;
    notifyListeners();

    final neon = NeonService(_neonConnString);
    final tba = TbaService(_tbaApiKey);
    final statbotics = StatboticsService();

    final errors = <String>[];

    final tasks = <String, Future<void> Function()>{
      'neon': () async {
        final rows = await neon.fetchAll(_tableName);
        final cols = await neon.columns(_tableName);
        final next = <int, List<Map<String, dynamic>>>{};
        for (final row in rows) {
          final raw = row['team'];
          final teamNum = raw is int ? raw : int.tryParse(raw.toString());
          if (teamNum == null) continue;
          next.putIfAbsent(teamNum, () => []).add(row);
        }
        if (next.isNotEmpty) {
          scoutingByTeam = next;
          scoutingColumns = cols;
          _dataSource = 'neon';
        }
      },
      'tba opr': () async {
        final opr = await tba.fetchOprs(_eventKey);
        if (opr.isNotEmpty) oprByTeam = opr;
      },
      'tba matches': () async {
        final raw = await tba.fetchMatches(_eventKey);
        final parsed = parseMatches(raw, ourTeamKey: 'frc201');
        if (parsed.isNotEmpty) matchEntries = parsed;
      },
      'tba alliances': () async {
        final raw = await tba.fetchPlayoffAlliances(_eventKey);
        final parsed = parsePlayoffAlliances(raw);
        if (parsed.isNotEmpty) playoffAlliances = parsed;
      },
      'tba names': () async {
        final names = await tba.fetchTeamNames(_eventKey);
        if (names.isNotEmpty) teamNames = names;
      },
      'statbotics': () async {
        final epa = await statbotics.fetchEpas(_eventKey);
        if (epa.isNotEmpty) epaByTeam = epa;
      },
    };

    await _runParallel(tasks, errors, onProgress);

    if (!_applyOfflineErrorIfAllOffline(errors)) {
      error = errors.isEmpty ? null : errors.join('\n');
    }

    loading = false;
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  // ── Fetch TBA/Statbotics only (for CSV mode) ──────────────────────

  Future<void> fetchExternalOnly({
    void Function(SyncProgress)? onProgress,
  }) async {
    _errorDismissTimer?.cancel();
    loading = true;
    notifyListeners();

    final tba = TbaService(_tbaApiKey);
    final statbotics = StatboticsService();

    final errors = <String>[];

    final tasks = <String, Future<void> Function()>{
      'tba opr': () async {
        final opr = await tba.fetchOprs(_eventKey);
        if (opr.isNotEmpty) oprByTeam = opr;
      },
      'tba matches': () async {
        final raw = await tba.fetchMatches(_eventKey);
        final parsed = parseMatches(raw, ourTeamKey: 'frc201');
        if (parsed.isNotEmpty) matchEntries = parsed;
      },
      'tba alliances': () async {
        final raw = await tba.fetchPlayoffAlliances(_eventKey);
        final parsed = parsePlayoffAlliances(raw);
        if (parsed.isNotEmpty) playoffAlliances = parsed;
      },
      'tba names': () async {
        final names = await tba.fetchTeamNames(_eventKey);
        if (names.isNotEmpty) teamNames = names;
      },
      'statbotics': () async {
        final epa = await statbotics.fetchEpas(_eventKey);
        if (epa.isNotEmpty) epaByTeam = epa;
      },
    };

    await _runParallel(tasks, errors, onProgress);

    if (errors.isNotEmpty) {
      if (!_applyOfflineErrorIfAllOffline(errors)) {
        error = (error != null ? '$error\n' : '') + errors.join('\n');
      }
    }

    loading = false;
    notifyListeners();
  }

  /// Launches every task in [tasks] simultaneously, emits a [SyncProgress]
  /// snapshot when any task transitions, and accumulates failures into
  /// [errors] as `"<key>: <exception>"`.
  Future<void> _runParallel(
    Map<String, Future<void> Function()> tasks,
    List<String> errors,
    void Function(SyncProgress)? onProgress,
  ) async {
    final statuses = <String, SyncTaskStatus>{
      for (final k in tasks.keys) k: SyncTaskStatus.loading,
    };

    void emit() {
      onProgress?.call(SyncProgress(Map.of(statuses)));
    }

    emit();

    await Future.wait(tasks.entries.map((entry) async {
      try {
        await entry.value();
        statuses[entry.key] = SyncTaskStatus.done;
      } catch (e) {
        statuses[entry.key] = SyncTaskStatus.fail;
        errors.add('${entry.key}: $e');
      }
      emit();
    }));
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