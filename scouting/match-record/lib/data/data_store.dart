import 'package:flutter/foundation.dart';

import 'json_persistence.dart';
import 'models.dart';

class DataStore extends ChangeNotifier {
  final JsonPersistence _persistence;
  late AppData _data;

  DataStore(this._persistence);

  Future<void> init() async {
    _data = await _persistence.load();
  }

  // --- TBA Data ---

  List<Event> get events => List.unmodifiable(_data.events);

  List<Team> getTeamsForEvents(List<String> eventKeys) {
    final keySet = eventKeys.toSet();
    return _data.teams.where((t) => keySet.contains(t.eventKey)).toList();
  }

  List<Match> getMatchesForEvents(List<String> eventKeys) {
    final keySet = eventKeys.toSet();
    return _data.matches.where((m) => keySet.contains(m.eventKey)).toList();
  }

  List<Match> getMatchesForTeam(int teamNumber, List<String> eventKeys) {
    final teamKey = 'frc$teamNumber';
    final keySet = eventKeys.toSet();
    return _data.matches
        .where((m) =>
            keySet.contains(m.eventKey) &&
            (m.redTeamKeys.contains(teamKey) ||
                m.blueTeamKeys.contains(teamKey)))
        .toList();
  }

  Match? getMatchByKey(String matchKey) {
    for (final m in _data.matches) {
      if (m.matchKey == matchKey) return m;
    }
    return null;
  }

  Match? getNearestMatch(DateTime timestamp, List<String> eventKeys) {
    final unixSeconds = timestamp.millisecondsSinceEpoch ~/ 1000;
    final keySet = eventKeys.toSet();
    Match? nearest;
    int? minDiff;

    for (final m in _data.matches) {
      if (!keySet.contains(m.eventKey)) continue;
      final bt = m.bestTime;
      if (bt == null) continue;
      final diff = (unixSeconds - bt).abs();
      if (minDiff == null || diff < minDiff) {
        minDiff = diff;
        nearest = m;
      }
    }

    return nearest;
  }

  List<Alliance> getAlliancesForEvents(List<String> eventKeys) {
    final keySet = eventKeys.toSet();
    return _data.alliances.where((a) => keySet.contains(a.eventKey)).toList();
  }

  Alliance? getAllianceForTeam(int teamNumber, List<String> eventKeys) {
    final teamKey = 'frc$teamNumber';
    final keySet = eventKeys.toSet();
    for (final a in _data.alliances) {
      if (keySet.contains(a.eventKey) && a.picks.contains(teamKey)) {
        return a;
      }
    }
    return null;
  }

  bool get hasAllianceData => _data.alliances.isNotEmpty;

  Future<void> setEvents(List<Event> events) async {
    _data = _data.copyWith(events: events);
    await _save();
  }

  Future<void> setTeamsForEvent(String eventKey, List<Team> teams) async {
    final existing =
        _data.teams.where((t) => t.eventKey != eventKey).toList();
    _data = _data.copyWith(teams: [...existing, ...teams]);
    await _save();
  }

  Future<void> setMatchesForEvent(
      String eventKey, List<Match> matches) async {
    final existing =
        _data.matches.where((m) => m.eventKey != eventKey).toList();
    _data = _data.copyWith(matches: [...existing, ...matches]);
    await _save();
  }

  Future<void> setAlliancesForEvent(
      String eventKey, List<Alliance> alliances) async {
    final existing =
        _data.alliances.where((a) => a.eventKey != eventKey).toList();
    _data = _data.copyWith(alliances: [...existing, ...alliances]);
    await _save();
  }

  // --- Recordings ---

  List<Recording> get allRecordings => List.unmodifiable(_data.recordings);

  List<Recording> getRecordingsForMatch(String matchKey) {
    return _data.recordings.where((r) => r.matchKey == matchKey).toList();
  }

  Recording? getRecordingByIdentity(VideoIdentity identity) {
    for (final r in _data.recordings) {
      if (r.recordingStartTime == identity.recordingStartTime &&
          r.durationMs == identity.durationMs &&
          r.fileSizeBytes == identity.fileSizeBytes) {
        return r;
      }
    }
    return null;
  }

  Future<void> addRecording(Recording recording) async {
    final existing = List<Recording>.from(_data.recordings);

    existing.removeWhere((r) =>
        r.matchKey == recording.matchKey &&
        r.allianceSide == recording.allianceSide);

    existing.add(recording);
    _data = _data.copyWith(recordings: existing);
    await _save();
  }

  Future<void> updateRecording(Recording recording) async {
    final recordings = _data.recordings.map((r) {
      return r.id == recording.id ? recording : r;
    }).toList();
    _data = _data.copyWith(recordings: recordings);
    await _save();
  }

  Future<void> deleteRecording(String id) async {
    Recording? deleted;
    final recordings = <Recording>[];
    for (final r in _data.recordings) {
      if (r.id == id) {
        deleted = r;
      } else {
        recordings.add(r);
      }
    }

    if (deleted != null) {
      final skipEntry = VideoSkipEntry(
        recordingStartTime: deleted.recordingStartTime,
        durationMs: deleted.durationMs,
        fileSizeBytes: deleted.fileSizeBytes,
        skipReason: 'deleted',
      );
      _data = _data.copyWith(
        recordings: recordings,
        skipHistory: [..._data.skipHistory, skipEntry],
      );
    } else {
      _data = _data.copyWith(recordings: recordings);
    }

    await _save();
  }

  // --- Local Ripped Videos ---

  LocalRippedVideo? getLocalRippedVideo(String matchKey) {
    for (final v in _data.localRippedVideos) {
      if (v.matchKey == matchKey) return v;
    }
    return null;
  }

  // --- Import History ---

  List<ImportSession> get importSessions =>
      List.unmodifiable(_data.importSessions);

  Future<void> addImportSession(ImportSession session) async {
    _data = _data.copyWith(
      importSessions: [..._data.importSessions, session],
    );
    await _save();
  }

  Future<void> updateImportSession(ImportSession session) async {
    final sessions = _data.importSessions.map((s) {
      return s.id == session.id ? session : s;
    }).toList();
    _data = _data.copyWith(importSessions: sessions);
    await _save();
  }

  // --- Skip History ---

  bool isSkipped(VideoIdentity identity) {
    return _data.skipHistory.any((s) =>
        s.recordingStartTime == identity.recordingStartTime &&
        s.durationMs == identity.durationMs &&
        s.fileSizeBytes == identity.fileSizeBytes);
  }

  Future<void> markAsSkipped(VideoIdentity identity, String reason) async {
    final entry = VideoSkipEntry(
      recordingStartTime: identity.recordingStartTime,
      durationMs: identity.durationMs,
      fileSizeBytes: identity.fileSizeBytes,
      skipReason: reason,
    );
    _data = _data.copyWith(
      skipHistory: [..._data.skipHistory, entry],
    );
    await _save();
  }

  // --- Settings ---

  AppSettings get settings => _data.settings;

  Future<void> updateSettings(AppSettings settings) async {
    _data = _data.copyWith(settings: settings);
    await _save();
  }

  // --- View Models ---

  List<MatchWithVideos> getMatchesWithVideos(List<String> eventKeys) {
    final matches = getMatchesForEvents(eventKeys);
    final eventMap = <String, Event>{};
    for (final e in _data.events) {
      eventMap[e.eventKey] = e;
    }

    return matches.map((m) {
      final recordings = getRecordingsForMatch(m.matchKey);
      final redRec = recordings
          .where((r) => r.allianceSide == 'red')
          .cast<Recording?>()
          .firstOrNull;
      final blueRec = recordings
          .where((r) => r.allianceSide == 'blue')
          .cast<Recording?>()
          .firstOrNull;
      final localRipped = getLocalRippedVideo(m.matchKey);
      final event = eventMap[m.eventKey];

      return MatchWithVideos(
        match: m,
        redRecording: redRec,
        blueRecording: blueRec,
        localRippedVideo: localRipped,
        eventShortName: event?.shortName,
      );
    }).toList();
  }

  MatchWithVideos? getMatchWithVideos(String matchKey) {
    final m = getMatchByKey(matchKey);
    if (m == null) return null;

    final recordings = getRecordingsForMatch(matchKey);
    final redRec = recordings
        .where((r) => r.allianceSide == 'red')
        .cast<Recording?>()
        .firstOrNull;
    final blueRec = recordings
        .where((r) => r.allianceSide == 'blue')
        .cast<Recording?>()
        .firstOrNull;
    final localRipped = getLocalRippedVideo(matchKey);

    String? eventShortName;
    for (final e in _data.events) {
      if (e.eventKey == m.eventKey) {
        eventShortName = e.shortName;
        break;
      }
    }

    return MatchWithVideos(
      match: m,
      redRecording: redRec,
      blueRecording: blueRec,
      localRippedVideo: localRipped,
      eventShortName: eventShortName,
    );
  }

  // --- Internal ---

  Future<void> _save() async {
    await _persistence.save(_data);
    notifyListeners();
  }
}
