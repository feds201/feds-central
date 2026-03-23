import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:match_record/data/data_store.dart';
import 'package:match_record/data/json_persistence.dart';
import 'package:match_record/data/models.dart';

class MockJsonPersistence extends Mock implements JsonPersistence {}

class FakeJsonPersistence implements JsonPersistence {
  AppData _data = AppData.empty();

  @override
  Future<AppData> load() async => _data;

  @override
  Future<void> save(AppData data) async {
    _data = data;
  }
}

void main() {
  late FakeJsonPersistence fakePersistence;
  late DataStore store;

  setUp(() async {
    fakePersistence = FakeJsonPersistence();
    store = DataStore(fakePersistence);
    await store.init();
  });

  Event makeEvent({String key = '2026mimid'}) => Event(
        eventKey: key,
        name: 'Midland',
        shortName: 'Mid',
        startDate: DateTime(2026, 3, 20),
        endDate: DateTime(2026, 3, 22),
        playoffType: 10,
        timezone: 'America/Detroit',
      );

  Match makeMatch({
    String key = '2026mimid_qm1',
    String eventKey = '2026mimid',
    String compLevel = 'qm',
    int matchNumber = 1,
    int? time,
    List<String> redTeamKeys = const ['frc201', 'frc100', 'frc300'],
    List<String> blueTeamKeys = const ['frc400', 'frc500', 'frc600'],
    String? youtubeKey,
  }) =>
      Match(
        matchKey: key,
        eventKey: eventKey,
        compLevel: compLevel,
        setNumber: 1,
        matchNumber: matchNumber,
        time: time,
        redTeamKeys: redTeamKeys,
        blueTeamKeys: blueTeamKeys,
        youtubeKey: youtubeKey,
      );

  Recording makeRecording({
    String id = 'rec-1',
    String matchKey = '2026mimid_qm1',
    String allianceSide = 'red',
    DateTime? recordingStartTime,
    int durationMs = 150000,
    int fileSizeBytes = 50000000,
  }) =>
      Recording(
        id: id,
        eventKey: '2026mimid',
        matchKey: matchKey,
        allianceSide: allianceSide,
        fileExtension: '.mp4',
        recordingStartTime: recordingStartTime ?? DateTime(2026, 3, 20, 10, 0),
        durationMs: durationMs,
        fileSizeBytes: fileSizeBytes,
        sourceDeviceType: 'ios',
        originalFilename: 'video.mp4',
        team1: 201,
        team2: 100,
        team3: 300,
      );

  group('init', () {
    test('initializes with empty state', () {
      expect(store.events, isEmpty);
      expect(store.allRecordings, isEmpty);
      expect(store.settings, equals(const AppSettings()));
    });

    test('loads existing data from persistence', () async {
      final persistence = FakeJsonPersistence();
      persistence._data = AppData.empty().copyWith(
        settings: const AppSettings(teamNumber: 201),
      );
      final store2 = DataStore(persistence);
      await store2.init();
      expect(store2.settings.teamNumber, 201);
    });
  });

  group('Events', () {
    test('setEvents and get events', () async {
      final events = [makeEvent()];
      await store.setEvents(events);
      expect(store.events, equals(events));
    });

    test('setEvents replaces all events', () async {
      await store.setEvents([makeEvent()]);
      await store.setEvents(
          [makeEvent(key: '2026miwat')]);
      expect(store.events.length, 1);
      expect(store.events[0].eventKey, '2026miwat');
    });
  });

  group('Teams', () {
    test('setTeamsForEvent and getTeamsForEvents', () async {
      const teams = [
        Team(eventKey: '2026mimid', teamNumber: 201, nickname: 'FEDS'),
        Team(eventKey: '2026mimid', teamNumber: 100),
      ];
      await store.setTeamsForEvent('2026mimid', teams);
      final result = store.getTeamsForEvents(['2026mimid']);
      expect(result.length, 2);
    });

    test('setTeamsForEvent replaces only that event teams', () async {
      const teams1 = [
        Team(eventKey: '2026mimid', teamNumber: 201),
      ];
      const teams2 = [
        Team(eventKey: '2026miwat', teamNumber: 100),
      ];
      await store.setTeamsForEvent('2026mimid', teams1);
      await store.setTeamsForEvent('2026miwat', teams2);

      expect(store.getTeamsForEvents(['2026mimid']).length, 1);
      expect(store.getTeamsForEvents(['2026miwat']).length, 1);
      expect(
          store.getTeamsForEvents(['2026mimid', '2026miwat']).length, 2);
    });

    test('setTeamsForEvent overwrites existing teams for same event',
        () async {
      const teams1 = [
        Team(eventKey: '2026mimid', teamNumber: 201),
        Team(eventKey: '2026mimid', teamNumber: 100),
      ];
      const teams2 = [
        Team(eventKey: '2026mimid', teamNumber: 999),
      ];
      await store.setTeamsForEvent('2026mimid', teams1);
      await store.setTeamsForEvent('2026mimid', teams2);

      final result = store.getTeamsForEvents(['2026mimid']);
      expect(result.length, 1);
      expect(result[0].teamNumber, 999);
    });

    test('getTeamsForEvents returns empty for unknown event', () {
      expect(store.getTeamsForEvents(['unknown']), isEmpty);
    });
  });

  group('Matches', () {
    test('setMatchesForEvent and getMatchesForEvents', () async {
      final matches = [makeMatch()];
      await store.setMatchesForEvent('2026mimid', matches);
      expect(store.getMatchesForEvents(['2026mimid']).length, 1);
    });

    test('setMatchesForEvent replaces only that event matches', () async {
      await store.setMatchesForEvent('2026mimid', [makeMatch()]);
      await store.setMatchesForEvent('2026miwat', [
        makeMatch(key: '2026miwat_qm1', eventKey: '2026miwat'),
      ]);

      expect(store.getMatchesForEvents(['2026mimid']).length, 1);
      expect(store.getMatchesForEvents(['2026miwat']).length, 1);
    });

    test('getMatchesForTeam filters by team', () async {
      await store.setMatchesForEvent('2026mimid', [
        makeMatch(
          key: '2026mimid_qm1',
          redTeamKeys: ['frc201'],
          blueTeamKeys: ['frc100'],
        ),
        makeMatch(
          key: '2026mimid_qm2',
          matchNumber: 2,
          redTeamKeys: ['frc300'],
          blueTeamKeys: ['frc400'],
        ),
      ]);

      final forTeam201 =
          store.getMatchesForTeam(201, ['2026mimid']);
      expect(forTeam201.length, 1);
      expect(forTeam201[0].matchKey, '2026mimid_qm1');

      final forTeam400 =
          store.getMatchesForTeam(400, ['2026mimid']);
      expect(forTeam400.length, 1);
      expect(forTeam400[0].matchKey, '2026mimid_qm2');
    });

    test('getMatchesForTeam returns empty when team not in any match',
        () async {
      await store.setMatchesForEvent('2026mimid', [makeMatch()]);
      expect(store.getMatchesForTeam(999, ['2026mimid']), isEmpty);
    });

    test('getMatchByKey returns match', () async {
      await store.setMatchesForEvent('2026mimid', [makeMatch()]);
      final match = store.getMatchByKey('2026mimid_qm1');
      expect(match, isNotNull);
      expect(match!.matchKey, '2026mimid_qm1');
    });

    test('getMatchByKey returns null for unknown key', () {
      expect(store.getMatchByKey('unknown'), isNull);
    });

    test('getNearestMatch finds closest match by timestamp', () async {
      await store.setMatchesForEvent('2026mimid', [
        makeMatch(key: '2026mimid_qm1', time: 1000),
        makeMatch(
            key: '2026mimid_qm2', matchNumber: 2, time: 2000),
        makeMatch(
            key: '2026mimid_qm3', matchNumber: 3, time: 3000),
      ]);

      final nearest = store.getNearestMatch(
        DateTime.fromMillisecondsSinceEpoch(1800 * 1000),
        ['2026mimid'],
      );
      expect(nearest, isNotNull);
      expect(nearest!.matchKey, '2026mimid_qm2');
    });

    test('getNearestMatch returns null when no matches have times', () async {
      await store.setMatchesForEvent('2026mimid', [makeMatch()]);
      final nearest = store.getNearestMatch(
        DateTime.now(),
        ['2026mimid'],
      );
      expect(nearest, isNull);
    });

    test('getNearestMatch returns null when no matches exist', () {
      expect(
        store.getNearestMatch(DateTime.now(), ['2026mimid']),
        isNull,
      );
    });
  });

  group('Alliances', () {
    test('setAlliancesForEvent and getAlliancesForEvents', () async {
      const alliances = [
        Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201', 'frc100'],
        ),
      ];
      await store.setAlliancesForEvent('2026mimid', alliances);
      expect(store.getAlliancesForEvents(['2026mimid']).length, 1);
    });

    test('setAlliancesForEvent replaces only that event alliances',
        () async {
      await store.setAlliancesForEvent('2026mimid', [
        const Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201'],
        ),
      ]);
      await store.setAlliancesForEvent('2026miwat', [
        const Alliance(
          eventKey: '2026miwat',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc300'],
        ),
      ]);

      expect(store.getAlliancesForEvents(['2026mimid']).length, 1);
      expect(store.getAlliancesForEvents(['2026miwat']).length, 1);
    });

    test('getAllianceForTeam finds alliance containing team', () async {
      await store.setAlliancesForEvent('2026mimid', [
        const Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201', 'frc100'],
        ),
        const Alliance(
          eventKey: '2026mimid',
          allianceNumber: 2,
          name: 'Alliance 2',
          picks: ['frc300', 'frc400'],
        ),
      ]);

      final alliance =
          store.getAllianceForTeam(201, ['2026mimid']);
      expect(alliance, isNotNull);
      expect(alliance!.allianceNumber, 1);
    });

    test('getAllianceForTeam returns null when team not in any alliance',
        () async {
      await store.setAlliancesForEvent('2026mimid', [
        const Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201'],
        ),
      ]);
      expect(store.getAllianceForTeam(999, ['2026mimid']), isNull);
    });

    test('hasAllianceData returns false when empty', () {
      expect(store.hasAllianceData, isFalse);
    });

    test('hasAllianceData returns true when alliances exist', () async {
      await store.setAlliancesForEvent('2026mimid', [
        const Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201'],
        ),
      ]);
      expect(store.hasAllianceData, isTrue);
    });
  });

  group('Recordings', () {
    test('addRecording and getRecordingsForMatch', () async {
      final recording = makeRecording();
      await store.addRecording(recording);
      final result =
          store.getRecordingsForMatch('2026mimid_qm1');
      expect(result.length, 1);
      expect(result[0].id, 'rec-1');
    });

    test('addRecording enforces uniqueness per match+side', () async {
      final rec1 = makeRecording(id: 'rec-1', allianceSide: 'red');
      final rec2 = makeRecording(id: 'rec-2', allianceSide: 'red');

      await store.addRecording(rec1);
      await store.addRecording(rec2);

      final result =
          store.getRecordingsForMatch('2026mimid_qm1');
      expect(result.length, 1);
      expect(result[0].id, 'rec-2',
          reason: 'Second recording should replace the first');
    });

    test('addRecording allows different sides for same match', () async {
      final redRec = makeRecording(id: 'rec-red', allianceSide: 'red');
      final blueRec =
          makeRecording(id: 'rec-blue', allianceSide: 'blue');

      await store.addRecording(redRec);
      await store.addRecording(blueRec);

      final result =
          store.getRecordingsForMatch('2026mimid_qm1');
      expect(result.length, 2);
    });

    test('addRecording allows same side for different matches', () async {
      final rec1 = makeRecording(
          id: 'rec-1', matchKey: '2026mimid_qm1');
      final rec2 = makeRecording(
          id: 'rec-2', matchKey: '2026mimid_qm2');

      await store.addRecording(rec1);
      await store.addRecording(rec2);

      expect(store.allRecordings.length, 2);
    });

    test('updateRecording modifies existing recording', () async {
      final rec = makeRecording();
      await store.addRecording(rec);

      final updated = rec.copyWith(durationMs: 200000);
      await store.updateRecording(updated);

      final result = store.getRecordingsForMatch('2026mimid_qm1');
      expect(result[0].durationMs, 200000);
    });

    test('deleteRecording removes recording and adds to skip history',
        () async {
      final rec = makeRecording();
      await store.addRecording(rec);
      await store.deleteRecording('rec-1');

      expect(store.allRecordings, isEmpty);

      final identity = VideoIdentity(
        recordingStartTime: rec.recordingStartTime,
        durationMs: rec.durationMs,
        fileSizeBytes: rec.fileSizeBytes,
      );
      expect(store.isSkipped(identity), isTrue);
    });

    test('deleteRecording with non-existent id does not add to skip history',
        () async {
      await store.deleteRecording('non-existent');
      // No skip history should be added
      final identity = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      expect(store.isSkipped(identity), isFalse);
    });

    test('getRecordingByIdentity finds matching recording', () async {
      final rec = makeRecording();
      await store.addRecording(rec);

      final identity = VideoIdentity(
        recordingStartTime: rec.recordingStartTime,
        durationMs: rec.durationMs,
        fileSizeBytes: rec.fileSizeBytes,
      );
      final found = store.getRecordingByIdentity(identity);
      expect(found, isNotNull);
      expect(found!.id, 'rec-1');
    });

    test('getRecordingByIdentity returns null when not found', () {
      final identity = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      expect(store.getRecordingByIdentity(identity), isNull);
    });
  });

  group('Skip history', () {
    test('isSkipped returns false when not skipped', () {
      final identity = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      expect(store.isSkipped(identity), isFalse);
    });

    test('markAsSkipped then isSkipped returns true', () async {
      final identity = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      await store.markAsSkipped(identity, 'too short');
      expect(store.isSkipped(identity), isTrue);
    });

    test('markAsSkipped adds entry with reason', () async {
      final identity = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      await store.markAsSkipped(identity, 'duplicate');
      // Verify the reason was stored by checking persistence
      final data = await fakePersistence.load();
      expect(data.skipHistory.length, 1);
      expect(data.skipHistory[0].skipReason, 'duplicate');
    });
  });

  group('Import sessions', () {
    ImportSession makeSession({String id = 'imp-1'}) => ImportSession(
          id: id,
          importedAt: DateTime(2026, 3, 20, 12, 0),
          driveLabel: 'USB',
          driveUri: '/media/usb',
          videoCount: 1,
          entries: const [],
        );

    test('addImportSession and get importSessions', () async {
      final session = makeSession();
      await store.addImportSession(session);
      expect(store.importSessions.length, 1);
      expect(store.importSessions[0].id, 'imp-1');
    });

    test('addImportSession appends to existing sessions', () async {
      await store.addImportSession(makeSession(id: 'imp-1'));
      await store.addImportSession(makeSession(id: 'imp-2'));
      expect(store.importSessions.length, 2);
    });

    test('updateImportSession modifies existing session', () async {
      await store.addImportSession(makeSession());
      final updated = makeSession().copyWith(videoCount: 5);
      await store.updateImportSession(updated);
      expect(store.importSessions[0].videoCount, 5);
    });

    test('updateImportSession does not affect non-matching sessions',
        () async {
      await store.addImportSession(makeSession(id: 'imp-1'));
      await store.addImportSession(makeSession(id: 'imp-2'));
      final updated = makeSession(id: 'imp-1').copyWith(videoCount: 5);
      await store.updateImportSession(updated);
      expect(store.importSessions[0].videoCount, 5);
      expect(store.importSessions[1].videoCount, 1);
    });
  });

  group('Settings', () {
    test('default settings', () {
      expect(store.settings.teamNumber, isNull);
      expect(store.settings.selectedEventKeys, isEmpty);
    });

    test('updateSettings persists new settings', () async {
      const newSettings = AppSettings(
        teamNumber: 201,
        selectedEventKeys: ['2026mimid'],
      );
      await store.updateSettings(newSettings);
      expect(store.settings.teamNumber, 201);
      expect(store.settings.selectedEventKeys, ['2026mimid']);
    });

    test('updateSettings replaces existing settings', () async {
      await store.updateSettings(
        const AppSettings(teamNumber: 201),
      );
      await store.updateSettings(
        const AppSettings(teamNumber: 999),
      );
      expect(store.settings.teamNumber, 999);
    });
  });

  group('getMatchesWithVideos', () {
    test('joins matches with recordings and local ripped videos', () async {
      await store.setEvents([makeEvent()]);
      await store.setMatchesForEvent('2026mimid', [
        makeMatch(key: '2026mimid_qm1'),
        makeMatch(key: '2026mimid_qm2', matchNumber: 2),
      ]);
      await store.addRecording(makeRecording(
        id: 'rec-red',
        matchKey: '2026mimid_qm1',
        allianceSide: 'red',
      ));
      await store.addRecording(makeRecording(
        id: 'rec-blue',
        matchKey: '2026mimid_qm1',
        allianceSide: 'blue',
      ));

      final result = store.getMatchesWithVideos(['2026mimid']);
      expect(result.length, 2);

      final qm1 =
          result.firstWhere((m) => m.match.matchKey == '2026mimid_qm1');
      expect(qm1.redRecording, isNotNull);
      expect(qm1.blueRecording, isNotNull);
      expect(qm1.hasRecordings, isTrue);
      expect(qm1.eventShortName, 'Mid');

      final qm2 =
          result.firstWhere((m) => m.match.matchKey == '2026mimid_qm2');
      expect(qm2.redRecording, isNull);
      expect(qm2.blueRecording, isNull);
      expect(qm2.hasRecordings, isFalse);
    });

    test('getMatchWithVideos returns null for unknown match', () {
      expect(store.getMatchWithVideos('unknown'), isNull);
    });

    test('getMatchWithVideos returns single match with videos', () async {
      await store.setEvents([makeEvent()]);
      await store.setMatchesForEvent('2026mimid', [makeMatch()]);
      await store.addRecording(
          makeRecording(allianceSide: 'red'));

      final result = store.getMatchWithVideos('2026mimid_qm1');
      expect(result, isNotNull);
      expect(result!.redRecording, isNotNull);
      expect(result.blueRecording, isNull);
      expect(result.eventShortName, 'Mid');
    });
  });

  group('getMatchesWithVideosFiltered', () {
    test('returns all matches when recordedMatchesOnly is false', () async {
      await store.setEvents([makeEvent()]);
      await store.setMatchesForEvent('2026mimid', [
        makeMatch(key: '2026mimid_qm1'),
        makeMatch(key: '2026mimid_qm2', matchNumber: 2),
      ]);
      await store.addRecording(makeRecording(
        id: 'rec-1',
        matchKey: '2026mimid_qm1',
        allianceSide: 'red',
      ));

      // recordedMatchesOnly defaults to false
      final result = store.getMatchesWithVideosFiltered(['2026mimid']);
      expect(result.length, 2);
    });

    test('returns only recorded matches when recordedMatchesOnly is true',
        () async {
      await store.setEvents([makeEvent()]);
      await store.setMatchesForEvent('2026mimid', [
        makeMatch(key: '2026mimid_qm1'),
        makeMatch(key: '2026mimid_qm2', matchNumber: 2),
        makeMatch(key: '2026mimid_qm3', matchNumber: 3),
      ]);
      await store.addRecording(makeRecording(
        id: 'rec-1',
        matchKey: '2026mimid_qm1',
        allianceSide: 'red',
      ));

      await store.updateSettings(
        store.settings.copyWith(recordedMatchesOnly: true),
      );

      final result = store.getMatchesWithVideosFiltered(['2026mimid']);
      expect(result.length, 1);
      expect(result[0].match.matchKey, '2026mimid_qm1');
    });

    test('includes matches with only blue recording when filtered', () async {
      await store.setEvents([makeEvent()]);
      await store.setMatchesForEvent('2026mimid', [
        makeMatch(key: '2026mimid_qm1'),
        makeMatch(key: '2026mimid_qm2', matchNumber: 2),
      ]);
      await store.addRecording(makeRecording(
        id: 'rec-blue',
        matchKey: '2026mimid_qm2',
        allianceSide: 'blue',
      ));

      await store.updateSettings(
        store.settings.copyWith(recordedMatchesOnly: true),
      );

      final result = store.getMatchesWithVideosFiltered(['2026mimid']);
      expect(result.length, 1);
      expect(result[0].match.matchKey, '2026mimid_qm2');
    });

    test('returns empty list when no matches have recordings and filter is on',
        () async {
      await store.setEvents([makeEvent()]);
      await store.setMatchesForEvent('2026mimid', [
        makeMatch(key: '2026mimid_qm1'),
        makeMatch(key: '2026mimid_qm2', matchNumber: 2),
      ]);

      await store.updateSettings(
        store.settings.copyWith(recordedMatchesOnly: true),
      );

      final result = store.getMatchesWithVideosFiltered(['2026mimid']);
      expect(result, isEmpty);
    });
  });

  group('Local ripped videos', () {
    test('getLocalRippedVideo returns null when none exists', () {
      expect(store.getLocalRippedVideo('2026mimid_qm1'), isNull);
    });
  });

  group('notifyListeners', () {
    test('setEvents notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.setEvents([makeEvent()]);
      expect(notified, isTrue);
    });

    test('addRecording notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.addRecording(makeRecording());
      expect(notified, isTrue);
    });

    test('updateSettings notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.updateSettings(const AppSettings(teamNumber: 201));
      expect(notified, isTrue);
    });

    test('deleteRecording notifies listeners', () async {
      await store.addRecording(makeRecording());
      var notified = false;
      store.addListener(() => notified = true);
      await store.deleteRecording('rec-1');
      expect(notified, isTrue);
    });

    test('markAsSkipped notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.markAsSkipped(
        VideoIdentity(
          recordingStartTime: DateTime(2026, 3, 20),
          durationMs: 100,
          fileSizeBytes: 200,
        ),
        'test',
      );
      expect(notified, isTrue);
    });

    test('setTeamsForEvent notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.setTeamsForEvent('2026mimid', const [
        Team(eventKey: '2026mimid', teamNumber: 201),
      ]);
      expect(notified, isTrue);
    });

    test('setMatchesForEvent notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.setMatchesForEvent('2026mimid', [makeMatch()]);
      expect(notified, isTrue);
    });

    test('setAlliancesForEvent notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.setAlliancesForEvent('2026mimid', const [
        Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201'],
        ),
      ]);
      expect(notified, isTrue);
    });

    test('addImportSession notifies listeners', () async {
      var notified = false;
      store.addListener(() => notified = true);
      await store.addImportSession(ImportSession(
        id: 'imp-1',
        importedAt: DateTime(2026, 3, 20),
        driveLabel: 'USB',
        driveUri: '/media/usb',
        videoCount: 0,
        entries: const [],
      ));
      expect(notified, isTrue);
    });

    test('updateImportSession notifies listeners', () async {
      final session = ImportSession(
        id: 'imp-1',
        importedAt: DateTime(2026, 3, 20),
        driveLabel: 'USB',
        driveUri: '/media/usb',
        videoCount: 0,
        entries: const [],
      );
      await store.addImportSession(session);
      var notified = false;
      store.addListener(() => notified = true);
      await store.updateImportSession(session.copyWith(videoCount: 5));
      expect(notified, isTrue);
    });

    test('updateRecording notifies listeners', () async {
      final rec = makeRecording();
      await store.addRecording(rec);
      var notified = false;
      store.addListener(() => notified = true);
      await store.updateRecording(rec.copyWith(durationMs: 999));
      expect(notified, isTrue);
    });
  });

  group('persistence integration', () {
    test('all mutations are persisted', () async {
      await store.setEvents([makeEvent()]);
      await store.setTeamsForEvent('2026mimid', const [
        Team(eventKey: '2026mimid', teamNumber: 201),
      ]);
      await store.setMatchesForEvent('2026mimid', [makeMatch()]);
      await store.addRecording(makeRecording());
      await store.updateSettings(const AppSettings(teamNumber: 201));

      final persisted = await fakePersistence.load();
      expect(persisted.events.length, 1);
      expect(persisted.teams.length, 1);
      expect(persisted.matches.length, 1);
      expect(persisted.recordings.length, 1);
      expect(persisted.settings.teamNumber, 201);
    });
  });
}
