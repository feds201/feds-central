import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/json_persistence.dart';
import 'package:match_record/data/models.dart';

void main() {
  late Directory tempDir;
  late JsonPersistence persistence;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('json_persistence_test_');
    persistence = JsonPersistence(directoryPath: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('JsonPersistence', () {
    test('load returns empty AppData when file does not exist', () async {
      final data = await persistence.load();
      expect(data.version, AppData.currentVersion);
      expect(data.events, isEmpty);
      expect(data.teams, isEmpty);
      expect(data.matches, isEmpty);
      expect(data.recordings, isEmpty);
      expect(data.settings, equals(const AppSettings()));
    });

    test('save then load round-trip preserves data', () async {
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
            time: 1000,
            redTeamKeys: ['frc201', 'frc100', 'frc300'],
            blueTeamKeys: ['frc400', 'frc500', 'frc600'],
            redScore: 42,
            blueScore: 30,
            winningAlliance: 'red',
          ),
        ],
        alliances: const [
          Alliance(
            eventKey: '2026mimid',
            allianceNumber: 1,
            name: 'Alliance 1',
            picks: ['frc201', 'frc100'],
          ),
        ],
        recordings: [
          Recording(
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
          ),
        ],
        localRippedVideos: const [
          LocalRippedVideo(
            matchKey: '2026mimid_qm1',
            filePath: '/path/video.mp4',
          ),
        ],
        importSessions: [
          ImportSession(
            id: 'imp-1',
            importedAt: DateTime(2026, 3, 20, 12, 0),
            driveLabel: 'USB',
            driveUri: '/media/usb',
            videoCount: 1,
            entries: const [
              ImportSessionEntry(
                recordingId: 'rec-1',
                originalFilename: 'video.mp4',
                wasSelected: true,
                wasAutoSkipped: false,
              ),
            ],
          ),
        ],
        skipHistory: [
          VideoSkipEntry(
            recordingStartTime: DateTime(2026, 3, 20, 9, 0),
            durationMs: 5000,
            fileSizeBytes: 1000,
            skipReason: 'too short',
          ),
        ],
        settings: const AppSettings(
          teamNumber: 201,
          selectedEventKeys: ['2026mimid'],
        ),
      );

      await persistence.save(data);
      final loaded = await persistence.load();

      expect(loaded, equals(data));
    });

    test('save writes to tmp file then renames (atomic write)', () async {
      final data = AppData.empty();
      await persistence.save(data);

      final mainFile = File('${tempDir.path}/app_data.json');
      final tmpFile = File('${tempDir.path}/app_data.json.tmp');

      expect(await mainFile.exists(), isTrue,
          reason: 'Main file should exist after save');
      expect(await tmpFile.exists(), isFalse,
          reason: 'Tmp file should not exist after rename');
    });

    test('save overwrites existing data', () async {
      final data1 = AppData.empty().copyWith(
        settings: const AppSettings(teamNumber: 201),
      );
      await persistence.save(data1);

      final data2 = AppData.empty().copyWith(
        settings: const AppSettings(teamNumber: 999),
      );
      await persistence.save(data2);

      final loaded = await persistence.load();
      expect(loaded.settings.teamNumber, 999);
    });

    test('load preserves all nested structures', () async {
      final data = AppData(
        version: 1,
        events: const [],
        teams: const [],
        matches: const [],
        alliances: const [],
        recordings: const [],
        localRippedVideos: const [],
        importSessions: [
          ImportSession(
            id: 'imp-1',
            importedAt: DateTime(2026, 3, 20),
            driveLabel: 'USB',
            driveUri: '/media/usb',
            videoCount: 2,
            entries: [
              ImportSessionEntry(
                recordingId: 'rec-1',
                originalFilename: 'a.mp4',
                wasSelected: true,
                wasAutoSkipped: false,
                recordingStartTime: DateTime(2026, 3, 20, 10, 0),
                durationMs: 100000,
                fileSizeBytes: 5000000,
              ),
              const ImportSessionEntry(
                originalFilename: 'b.mp4',
                wasSelected: false,
                wasAutoSkipped: true,
                skipReason: 'too short',
              ),
            ],
          ),
        ],
        skipHistory: const [],
        settings: const AppSettings(),
      );

      await persistence.save(data);
      final loaded = await persistence.load();

      expect(loaded.importSessions.length, 1);
      expect(loaded.importSessions[0].entries.length, 2);
      expect(loaded.importSessions[0].entries[0].recordingId, 'rec-1');
      expect(loaded.importSessions[0].entries[1].wasAutoSkipped, isTrue);
      expect(loaded.importSessions[0].entries[1].skipReason, 'too short');
    });
  });
}
