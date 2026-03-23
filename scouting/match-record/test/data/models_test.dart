import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/util/constants.dart';

void main() {
  group('Event', () {
    Event makeEvent() => Event(
          eventKey: '2026mimid',
          name: 'FIM District Midland Event',
          shortName: 'Midland',
          startDate: DateTime(2026, 3, 20),
          endDate: DateTime(2026, 3, 22),
          playoffType: 10,
          timezone: 'America/Detroit',
        );

    test('toJson/fromJson round-trip', () {
      final event = makeEvent();
      final json = event.toJson();
      final restored = Event.fromJson(json);
      expect(restored, equals(event));
    });

    test('fromJson with missing fields uses defaults', () {
      final event = Event.fromJson({});
      expect(event.eventKey, '');
      expect(event.name, '');
      expect(event.shortName, '');
      expect(event.playoffType, 0);
      expect(event.timezone, '');
    });

    test('copyWith creates modified copy', () {
      final event = makeEvent();
      final modified = event.copyWith(name: 'New Name');
      expect(modified.name, 'New Name');
      expect(modified.eventKey, event.eventKey);
    });

    test('equality works', () {
      expect(makeEvent(), equals(makeEvent()));
    });

    test('hashCode is consistent with equality', () {
      expect(makeEvent().hashCode, equals(makeEvent().hashCode));
    });
  });

  group('Team', () {
    Team makeTeam() => const Team(
          eventKey: '2026mimid',
          teamNumber: 201,
          nickname: 'The FEDS',
        );

    test('toJson/fromJson round-trip', () {
      final team = makeTeam();
      final json = team.toJson();
      final restored = Team.fromJson(json);
      expect(restored, equals(team));
    });

    test('fromJson with missing fields uses defaults', () {
      final team = Team.fromJson({});
      expect(team.eventKey, '');
      expect(team.teamNumber, 0);
      expect(team.nickname, '');
    });

    test('default nickname is empty string', () {
      const team = Team(eventKey: 'e', teamNumber: 1);
      expect(team.nickname, '');
    });

    test('copyWith creates modified copy', () {
      final team = makeTeam();
      final modified = team.copyWith(nickname: 'New Nick');
      expect(modified.nickname, 'New Nick');
      expect(modified.teamNumber, 201);
    });

    test('equality works', () {
      expect(makeTeam(), equals(makeTeam()));
    });
  });

  group('Match', () {
    Match makeMatch({
      String compLevel = 'qm',
      int setNumber = 1,
      int matchNumber = 5,
      int? time,
      int? actualTime,
      int? predictedTime,
      String? youtubeKey,
    }) =>
        Match(
          matchKey: '2026mimid_qm5',
          eventKey: '2026mimid',
          compLevel: compLevel,
          setNumber: setNumber,
          matchNumber: matchNumber,
          time: time,
          actualTime: actualTime,
          predictedTime: predictedTime,
          redTeamKeys: const ['frc201', 'frc100', 'frc300'],
          blueTeamKeys: const ['frc400', 'frc500', 'frc600'],
          redScore: 42,
          blueScore: 30,
          winningAlliance: 'red',
          youtubeKey: youtubeKey,
        );

    test('toJson/fromJson round-trip', () {
      final match = makeMatch(time: 1000, actualTime: 1100);
      final json = match.toJson();
      final restored = Match.fromJson(json);
      expect(restored, equals(match));
    });

    test('fromJson with missing fields uses defaults', () {
      final match = Match.fromJson({});
      expect(match.matchKey, '');
      expect(match.compLevel, 'qm');
      expect(match.setNumber, 1);
      expect(match.redTeamKeys, isEmpty);
      expect(match.blueTeamKeys, isEmpty);
      expect(match.redScore, -1);
      expect(match.blueScore, -1);
      expect(match.winningAlliance, '');
      expect(match.time, isNull);
      expect(match.actualTime, isNull);
      expect(match.predictedTime, isNull);
      expect(match.youtubeKey, isNull);
    });

    test('copyWith creates modified copy', () {
      final match = makeMatch(time: 100);
      final modified = match.copyWith(
        redScore: 99,
        time: () => null,
        youtubeKey: () => 'abc',
      );
      expect(modified.redScore, 99);
      expect(modified.time, isNull);
      expect(modified.youtubeKey, 'abc');
      expect(modified.matchKey, match.matchKey);
    });

    group('displayName', () {
      test('quals match', () {
        expect(makeMatch(compLevel: 'qm', matchNumber: 5).displayName, 'Q5');
      });

      test('semifinal', () {
        expect(
            makeMatch(compLevel: 'sf', setNumber: 3).displayName, 'SF 3');
      });

      test('final', () {
        expect(makeMatch(compLevel: 'f', matchNumber: 2).displayName, 'F2');
      });

      test('eighth-final', () {
        expect(
            makeMatch(compLevel: 'ef', matchNumber: 4).displayName, 'EF 4');
      });

      test('quarterfinal', () {
        expect(
            makeMatch(compLevel: 'qf', setNumber: 2, matchNumber: 1)
                .displayName,
            'QF 2-1');
      });

      test('unknown comp level falls back to matchKey', () {
        expect(makeMatch(compLevel: 'zz').displayName, '2026mimid_qm5');
      });
    });

    group('bestTime', () {
      test('prefers actualTime', () {
        final m =
            makeMatch(time: 100, actualTime: 200, predictedTime: 150);
        expect(m.bestTime, 200);
      });

      test('falls back to predictedTime when no actualTime', () {
        final m = makeMatch(time: 100, predictedTime: 150);
        expect(m.bestTime, 150);
      });

      test('falls back to time when no actualTime or predictedTime', () {
        final m = makeMatch(time: 100);
        expect(m.bestTime, 100);
      });

      test('returns null when all times are null', () {
        final m = makeMatch();
        expect(m.bestTime, isNull);
      });
    });

    group('compLevelPriority', () {
      test('qm = 0', () {
        expect(makeMatch(compLevel: 'qm').compLevelPriority, 0);
      });

      test('ef = 1', () {
        expect(makeMatch(compLevel: 'ef').compLevelPriority, 1);
      });

      test('qf = 2', () {
        expect(makeMatch(compLevel: 'qf').compLevelPriority, 2);
      });

      test('sf = 3', () {
        expect(makeMatch(compLevel: 'sf').compLevelPriority, 3);
      });

      test('f = 4', () {
        expect(makeMatch(compLevel: 'f').compLevelPriority, 4);
      });

      test('unknown = 5', () {
        expect(makeMatch(compLevel: 'xx').compLevelPriority, 5);
      });
    });

    test('equality works', () {
      expect(makeMatch(time: 100), equals(makeMatch(time: 100)));
    });

    test('inequality when lists differ', () {
      final m1 = makeMatch();
      final m2 = m1.copyWith(redTeamKeys: ['frc999']);
      expect(m1, isNot(equals(m2)));
    });
  });

  group('Alliance', () {
    Alliance makeAlliance() => const Alliance(
          eventKey: '2026mimid',
          allianceNumber: 1,
          name: 'Alliance 1',
          picks: ['frc201', 'frc100', 'frc300'],
        );

    test('toJson/fromJson round-trip', () {
      final alliance = makeAlliance();
      final json = alliance.toJson();
      final restored = Alliance.fromJson(json);
      expect(restored, equals(alliance));
    });

    test('fromJson with missing fields uses defaults', () {
      final alliance = Alliance.fromJson({});
      expect(alliance.eventKey, '');
      expect(alliance.allianceNumber, 0);
      expect(alliance.name, '');
      expect(alliance.picks, isEmpty);
    });

    test('copyWith creates modified copy', () {
      final alliance = makeAlliance();
      final modified = alliance.copyWith(name: 'Alliance 2');
      expect(modified.name, 'Alliance 2');
      expect(modified.allianceNumber, 1);
    });

    test('equality works', () {
      expect(makeAlliance(), equals(makeAlliance()));
    });

    test('inequality when picks differ', () {
      final a1 = makeAlliance();
      final a2 = a1.copyWith(picks: ['frc999']);
      expect(a1, isNot(equals(a2)));
    });
  });

  group('Recording', () {
    Recording makeRecording() => Recording(
          id: 'rec-1',
          eventKey: '2026mimid',
          matchKey: '2026mimid_qm1',
          allianceSide: 'red',
          fileExtension: '.mp4',
          recordingStartTime: DateTime(2026, 3, 20, 10, 0),
          durationMs: 150000,
          fileSizeBytes: 50000000,
          sourceDeviceType: 'ios',
          originalFilename: 'IMG_0001.MOV',
          team1: 201,
          team2: 100,
          team3: 300,
        );

    test('toJson/fromJson round-trip', () {
      final recording = makeRecording();
      final json = recording.toJson();
      final restored = Recording.fromJson(json);
      expect(restored, equals(recording));
    });

    test('fromJson with missing fields uses defaults', () {
      final recording = Recording.fromJson({});
      expect(recording.id, '');
      expect(recording.fileExtension, '.mp4');
      expect(recording.durationMs, 0);
      expect(recording.fileSizeBytes, 0);
      expect(recording.team1, 0);
    });

    test('copyWith creates modified copy', () {
      final recording = makeRecording();
      final modified = recording.copyWith(allianceSide: 'blue');
      expect(modified.allianceSide, 'blue');
      expect(modified.id, 'rec-1');
    });

    test('equality works', () {
      expect(makeRecording(), equals(makeRecording()));
    });
  });

  group('LocalRippedVideo', () {
    test('toJson/fromJson round-trip', () {
      const video = LocalRippedVideo(
        matchKey: '2026mimid_qm1',
        filePath: '/path/to/video.mp4',
      );
      final json = video.toJson();
      final restored = LocalRippedVideo.fromJson(json);
      expect(restored, equals(video));
    });

    test('fromJson with missing fields uses defaults', () {
      final video = LocalRippedVideo.fromJson({});
      expect(video.matchKey, '');
      expect(video.filePath, '');
    });

    test('copyWith creates modified copy', () {
      const video = LocalRippedVideo(
        matchKey: '2026mimid_qm1',
        filePath: '/path/to/video.mp4',
      );
      final modified = video.copyWith(filePath: '/new/path.mp4');
      expect(modified.filePath, '/new/path.mp4');
      expect(modified.matchKey, '2026mimid_qm1');
    });
  });

  group('ImportSession', () {
    ImportSession makeImportSession() => ImportSession(
          id: 'imp-1',
          importedAt: DateTime(2026, 3, 20, 12, 0),
          driveLabel: 'USB Drive',
          driveUri: '/media/usb',
          videoCount: 2,
          entries: const [
            ImportSessionEntry(
              recordingId: 'rec-1',
              originalFilename: 'video1.mp4',
              wasSelected: true,
              wasAutoSkipped: false,
              recordingStartTime: null,
              durationMs: 150000,
              fileSizeBytes: 50000000,
            ),
          ],
        );

    test('toJson/fromJson round-trip', () {
      final session = makeImportSession();
      final json = session.toJson();
      final restored = ImportSession.fromJson(json);
      expect(restored, equals(session));
    });

    test('fromJson with missing fields uses defaults', () {
      final session = ImportSession.fromJson({});
      expect(session.id, '');
      expect(session.driveLabel, '');
      expect(session.videoCount, 0);
      expect(session.entries, isEmpty);
    });

    test('copyWith creates modified copy', () {
      final session = makeImportSession();
      final modified = session.copyWith(videoCount: 5);
      expect(modified.videoCount, 5);
      expect(modified.id, 'imp-1');
    });

    test('equality works', () {
      expect(makeImportSession(), equals(makeImportSession()));
    });
  });

  group('ImportSessionEntry', () {
    test('toJson/fromJson round-trip', () {
      final entry = ImportSessionEntry(
        recordingId: 'rec-1',
        originalFilename: 'video.mp4',
        wasSelected: true,
        wasAutoSkipped: false,
        skipReason: null,
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      final json = entry.toJson();
      final restored = ImportSessionEntry.fromJson(json);
      expect(restored, equals(entry));
    });

    test('fromJson with missing fields uses defaults', () {
      final entry = ImportSessionEntry.fromJson({});
      expect(entry.recordingId, isNull);
      expect(entry.originalFilename, '');
      expect(entry.wasSelected, false);
      expect(entry.wasAutoSkipped, false);
      expect(entry.skipReason, isNull);
      expect(entry.recordingStartTime, isNull);
      expect(entry.durationMs, isNull);
      expect(entry.fileSizeBytes, isNull);
    });

    test('copyWith with nullable fields', () {
      final entry = ImportSessionEntry(
        recordingId: 'rec-1',
        originalFilename: 'video.mp4',
        wasSelected: true,
        wasAutoSkipped: false,
        recordingStartTime: DateTime(2026, 3, 20),
      );
      final modified = entry.copyWith(
        recordingId: () => null,
        wasSelected: false,
      );
      expect(modified.recordingId, isNull);
      expect(modified.wasSelected, false);
      expect(modified.originalFilename, 'video.mp4');
    });
  });

  group('VideoSkipEntry', () {
    test('toJson/fromJson round-trip', () {
      final entry = VideoSkipEntry(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
        skipReason: 'too short',
      );
      final json = entry.toJson();
      final restored = VideoSkipEntry.fromJson(json);
      expect(restored, equals(entry));
    });

    test('fromJson with missing fields uses defaults', () {
      final entry = VideoSkipEntry.fromJson({});
      expect(entry.durationMs, 0);
      expect(entry.fileSizeBytes, 0);
      expect(entry.skipReason, isNull);
    });

    test('copyWith with nullable skipReason', () {
      final entry = VideoSkipEntry(
        recordingStartTime: DateTime(2026, 3, 20),
        durationMs: 100,
        fileSizeBytes: 200,
        skipReason: 'reason',
      );
      final modified = entry.copyWith(skipReason: () => null);
      expect(modified.skipReason, isNull);
      expect(modified.durationMs, 100);
    });
  });

  group('VideoIdentity', () {
    test('equal objects have same hashCode', () {
      final v1 = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      final v2 = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
    });

    test('different objects are not equal', () {
      final v1 = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      final v2 = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150001,
        fileSizeBytes: 50000000,
      );
      expect(v1, isNot(equals(v2)));
    });

    test('works as map key', () {
      final key = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      final map = {key: 'found'};
      final lookup = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      expect(map[lookup], 'found');
    });

    test('works in sets', () {
      final v1 = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      final v2 = VideoIdentity(
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
      );
      final set = {v1};
      expect(set.contains(v2), isTrue);
    });
  });

  group('AppSettings', () {
    test('default constructor uses AppConstants defaults', () {
      const settings = AppSettings();
      expect(settings.teamNumber, isNull);
      expect(settings.selectedEventKeys, isEmpty);
      expect(settings.shortVideoThresholdMs,
          AppConstants.defaultShortVideoThresholdMs);
      expect(settings.sequentialGapMinMinutes,
          AppConstants.defaultSequentialGapMinMinutes);
      expect(settings.sequentialGapMaxMinutes,
          AppConstants.defaultSequentialGapMaxMinutes);
      expect(settings.scrubExponent, AppConstants.defaultScrubExponent);
      expect(settings.scrubMaxRangeMs, AppConstants.defaultScrubMaxRangeMs);
      expect(settings.recordedMatchesOnly, isFalse);
    });

    test('toJson/fromJson round-trip', () {
      const settings = AppSettings(
        teamNumber: 201,
        selectedEventKeys: ['2026mimid'],
        shortVideoThresholdMs: 50000,
        scrubExponent: 3.0,
      );
      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored, equals(settings));
    });

    test('toJson/fromJson round-trip with recordedMatchesOnly true', () {
      const settings = AppSettings(
        teamNumber: 201,
        recordedMatchesOnly: true,
      );
      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored, equals(settings));
      expect(restored.recordedMatchesOnly, isTrue);
    });

    test('fromJson with missing fields uses defaults', () {
      final settings = AppSettings.fromJson({});
      expect(settings.teamNumber, isNull);
      expect(settings.selectedEventKeys, isEmpty);
      expect(settings.shortVideoThresholdMs,
          AppConstants.defaultShortVideoThresholdMs);
      expect(settings.recordedMatchesOnly, isFalse);
    });

    test('copyWith with nullable teamNumber', () {
      const settings = AppSettings(teamNumber: 201);
      final modified = settings.copyWith(teamNumber: () => null);
      expect(modified.teamNumber, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const settings = AppSettings(
        teamNumber: 201,
        selectedEventKeys: ['2026mimid'],
      );
      final modified = settings.copyWith(
        selectedEventKeys: ['2026mimid', '2026miwat'],
      );
      expect(modified.teamNumber, 201);
      expect(modified.selectedEventKeys, ['2026mimid', '2026miwat']);
    });

    test('copyWith recordedMatchesOnly', () {
      const settings = AppSettings(recordedMatchesOnly: false);
      final modified = settings.copyWith(recordedMatchesOnly: true);
      expect(modified.recordedMatchesOnly, isTrue);
    });

    test('copyWith preserves recordedMatchesOnly when not specified', () {
      const settings = AppSettings(recordedMatchesOnly: true);
      final modified = settings.copyWith(teamNumber: () => 201);
      expect(modified.recordedMatchesOnly, isTrue);
    });

    test('equality works', () {
      expect(const AppSettings(), equals(const AppSettings()));
    });

    test('inequality when selectedEventKeys differ', () {
      const s1 = AppSettings(selectedEventKeys: ['a']);
      const s2 = AppSettings(selectedEventKeys: ['b']);
      expect(s1, isNot(equals(s2)));
    });

    test('inequality when recordedMatchesOnly differs', () {
      const s1 = AppSettings(recordedMatchesOnly: false);
      const s2 = AppSettings(recordedMatchesOnly: true);
      expect(s1, isNot(equals(s2)));
    });

    test('lastTbaFetchTime defaults to null', () {
      const settings = AppSettings();
      expect(settings.lastTbaFetchTime, isNull);
    });

    test('toJson/fromJson round-trip with lastTbaFetchTime', () {
      final fetchTime = DateTime(2026, 3, 15, 14, 30);
      final settings = AppSettings(
        teamNumber: 201,
        lastTbaFetchTime: fetchTime,
      );
      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.lastTbaFetchTime, equals(fetchTime));
      expect(restored, equals(settings));
    });

    test('fromJson with missing lastTbaFetchTime defaults to null', () {
      final settings = AppSettings.fromJson({});
      expect(settings.lastTbaFetchTime, isNull);
    });

    test('copyWith lastTbaFetchTime sets value', () {
      const settings = AppSettings();
      final fetchTime = DateTime(2026, 3, 15, 14, 30);
      final modified = settings.copyWith(lastTbaFetchTime: () => fetchTime);
      expect(modified.lastTbaFetchTime, equals(fetchTime));
    });

    test('copyWith lastTbaFetchTime can clear to null', () {
      final settings = AppSettings(
        lastTbaFetchTime: DateTime(2026, 3, 15, 14, 30),
      );
      final modified = settings.copyWith(lastTbaFetchTime: () => null);
      expect(modified.lastTbaFetchTime, isNull);
    });

    test('copyWith preserves lastTbaFetchTime when not specified', () {
      final fetchTime = DateTime(2026, 3, 15, 14, 30);
      final settings = AppSettings(lastTbaFetchTime: fetchTime);
      final modified = settings.copyWith(teamNumber: () => 201);
      expect(modified.lastTbaFetchTime, equals(fetchTime));
    });

    test('inequality when lastTbaFetchTime differs', () {
      final s1 = AppSettings(lastTbaFetchTime: DateTime(2026, 3, 15));
      final s2 = AppSettings(lastTbaFetchTime: DateTime(2026, 3, 16));
      expect(s1, isNot(equals(s2)));
    });
  });

  group('AppData', () {
    test('empty() factory creates default state', () {
      final data = AppData.empty();
      expect(data.version, AppData.currentVersion);
      expect(data.events, isEmpty);
      expect(data.teams, isEmpty);
      expect(data.matches, isEmpty);
      expect(data.alliances, isEmpty);
      expect(data.recordings, isEmpty);
      expect(data.localRippedVideos, isEmpty);
      expect(data.importSessions, isEmpty);
      expect(data.skipHistory, isEmpty);
      expect(data.settings, equals(const AppSettings()));
    });

    test('toJson/fromJson round-trip', () {
      final data = AppData(
        version: 1,
        events: [
          Event(
            eventKey: '2026mimid',
            name: 'Midland',
            shortName: 'Mid',
            startDate: DateTime(2026, 3, 20),
            endDate: DateTime(2026, 3, 22),
            playoffType: 10,
            timezone: 'America/Detroit',
          ),
        ],
        teams: const [
          Team(eventKey: '2026mimid', teamNumber: 201, nickname: 'FEDS'),
        ],
        matches: const [
          Match(
            matchKey: '2026mimid_qm1',
            eventKey: '2026mimid',
            compLevel: 'qm',
            setNumber: 1,
            matchNumber: 1,
            redTeamKeys: ['frc201'],
            blueTeamKeys: ['frc100'],
          ),
        ],
        alliances: const [],
        recordings: [],
        localRippedVideos: const [],
        importSessions: const [],
        skipHistory: const [],
        settings: const AppSettings(teamNumber: 201),
      );
      final json = data.toJson();
      final restored = AppData.fromJson(json);
      expect(restored, equals(data));
    });

    test('fromJson with missing fields uses defaults', () {
      final data = AppData.fromJson({});
      expect(data.version, AppData.currentVersion);
      expect(data.events, isEmpty);
      expect(data.settings, equals(const AppSettings()));
    });

    test('fromJson with null settings uses default', () {
      final data = AppData.fromJson({'settings': null});
      expect(data.settings, equals(const AppSettings()));
    });

    test('copyWith creates modified copy', () {
      final data = AppData.empty();
      final modified = data.copyWith(version: 2);
      expect(modified.version, 2);
      expect(modified.events, isEmpty);
    });

    test('equality works', () {
      expect(AppData.empty(), equals(AppData.empty()));
    });
  });

  group('MatchWithVideos', () {
    Match makeMatch({String? youtubeKey}) => Match(
          matchKey: '2026mimid_qm1',
          eventKey: '2026mimid',
          compLevel: 'qm',
          setNumber: 1,
          matchNumber: 1,
          redTeamKeys: const ['frc201'],
          blueTeamKeys: const ['frc100'],
          youtubeKey: youtubeKey,
        );

    Recording makeRecording(String side) => Recording(
          id: 'rec-$side',
          eventKey: '2026mimid',
          matchKey: '2026mimid_qm1',
          allianceSide: side,
          fileExtension: '.mp4',
          recordingStartTime: DateTime(2026, 3, 20, 10, 0),
          durationMs: 150000,
          fileSizeBytes: 50000000,
          sourceDeviceType: 'ios',
          originalFilename: 'video.mp4',
          team1: 201,
          team2: 100,
          team3: 300,
        );

    test('hasRecordings is true when red recording exists', () {
      final mwv = MatchWithVideos(
        match: makeMatch(),
        redRecording: makeRecording('red'),
      );
      expect(mwv.hasRecordings, isTrue);
    });

    test('hasRecordings is true when blue recording exists', () {
      final mwv = MatchWithVideos(
        match: makeMatch(),
        blueRecording: makeRecording('blue'),
      );
      expect(mwv.hasRecordings, isTrue);
    });

    test('hasRecordings is false when no recordings', () {
      final mwv = MatchWithVideos(match: makeMatch());
      expect(mwv.hasRecordings, isFalse);
    });

    test('hasYouTube is true when youtubeKey is present', () {
      final mwv = MatchWithVideos(
        match: makeMatch(youtubeKey: 'abc123'),
      );
      expect(mwv.hasYouTube, isTrue);
    });

    test('hasYouTube is false when youtubeKey is null', () {
      final mwv = MatchWithVideos(match: makeMatch());
      expect(mwv.hasYouTube, isFalse);
    });

    test('hasLocalRippedVideo when present', () {
      final mwv = MatchWithVideos(
        match: makeMatch(),
        localRippedVideo: const LocalRippedVideo(
          matchKey: '2026mimid_qm1',
          filePath: '/path.mp4',
        ),
      );
      expect(mwv.hasLocalRippedVideo, isTrue);
    });

    test('hasLocalRippedVideo is false when absent', () {
      final mwv = MatchWithVideos(match: makeMatch());
      expect(mwv.hasLocalRippedVideo, isFalse);
    });
  });
}
