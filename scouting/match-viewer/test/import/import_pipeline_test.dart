import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/data_store.dart';
import 'package:match_record/data/json_persistence.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/import/drive_access.dart';
import 'package:match_record/import/import_pipeline.dart';
import 'package:match_record/import/video_metadata_service.dart';
import 'package:match_record/import/alliance_suggester.dart';
import 'package:match_record/util/result.dart';

/// Fake persistence for tests
class FakeJsonPersistence implements JsonPersistence {
  AppData _data = AppData.empty();

  @override
  Future<AppData> load() async => _data;

  @override
  Future<void> save(AppData data) async {
    _data = data;
  }
}

/// Fake metadata service for tests.
/// Constructs VideoMetadata via the real factory constructor using values
/// from the DriveFile. No synthetic/estimated data — uses the same inference
/// the factory constructor provides (extension, iOS detection, start time).
///
/// [durationOverrides] maps filename -> durationMs for tests that need
/// specific durations (e.g. short video auto-skip tests).
class FakeVideoMetadataService extends VideoMetadataService {
  final Map<String, int> durationOverrides;

  FakeVideoMetadataService({this.durationOverrides = const {}});

  @override
  Future<VideoMetadata> getMetadata(DriveFile file) async {
    final ext = file.name.contains('.')
        ? '.${file.name.split('.').last}'.toLowerCase()
        : '';
    final isIOS = ext == '.mov';
    final durationMs = durationOverrides[file.name] ?? 150000;
    return VideoMetadata(
      sourceUri: file.uri,
      originalFilename: file.name,
      durationMs: durationMs,
      date: file.lastModified,
      fileSize: file.sizeBytes,
      ftypBrand: isIOS ? 'qt  ' : 'isom',
    );
  }
}

/// Fake drive access for tests
class FakeDriveAccess implements DriveAccess {
  final List<DriveFile> files;
  final String? configJson;
  final String label;
  bool copyWasCalled = false;

  FakeDriveAccess({
    this.files = const [],
    this.configJson,
    this.label = 'Test Drive',
  });

  @override
  Future<String?> pickDrive() async => 'test://drive';

  @override
  Future<bool> hasPermission(String driveUri) async => true;

  @override
  Future<Result<List<DriveFile>>> listVideoFiles(String driveUri) async {
    return Ok(files);
  }

  @override
  Future<Result<String?>> readTextFile(String driveUri, String filename) async {
    if (filename == 'config.json') return Ok(configJson);
    return const Ok(null);
  }

  @override
  Future<Result<String>> getDriveLabel(String driveUri) async {
    return Ok(label);
  }

  @override
  Future<Result<void>> copyToLocal(
    String sourceUri,
    String destPath,
    void Function(int bytesCopied)? onProgress,
  ) async {
    copyWasCalled = true;
    // Don't actually copy files in tests
    onProgress?.call(1000);
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteFile(String fileUri) async => const Ok(null);
}

void main() {
  late FakeJsonPersistence persistence;
  late DataStore dataStore;
  late FakeDriveAccess driveAccess;
  late VideoMetadataService metadataService;
  late ImportPipeline pipeline;

  // Matches with known timestamps for testing
  final baseTime = DateTime.utc(2026, 3, 22, 14, 0, 0);
  final baseUnix = baseTime.millisecondsSinceEpoch ~/ 1000;

  setUp(() async {
    persistence = FakeJsonPersistence();
    dataStore = DataStore(persistence);
    await dataStore.init();

    // Set up event and matches
    await dataStore.setEvents([
      Event(
        eventKey: '2026mimid',
        name: 'Midland',
        shortName: 'Mid',
        startDate: DateTime(2026, 3, 20),
        endDate: DateTime(2026, 3, 22),
        playoffType: 10,
        timezone: 'America/Detroit',
      ),
    ]);
    await dataStore.updateSettings(
      dataStore.settings.copyWith(selectedEventKeys: ['2026mimid']),
    );
    await dataStore.setMatchesForEvent('2026mimid', [
      Match(
        matchKey: '2026mimid_qm1',
        eventKey: '2026mimid',
        compLevel: 'qm',
        setNumber: 1,
        matchNumber: 1,
        time: baseUnix,
        redTeamKeys: const ['frc201', 'frc100', 'frc300'],
        blueTeamKeys: const ['frc400', 'frc500', 'frc600'],
      ),
      Match(
        matchKey: '2026mimid_qm2',
        eventKey: '2026mimid',
        compLevel: 'qm',
        setNumber: 1,
        matchNumber: 2,
        time: baseUnix + 900,
        redTeamKeys: const ['frc201', 'frc700', 'frc800'],
        blueTeamKeys: const ['frc900', 'frc1000', 'frc1100'],
      ),
    ]);

    metadataService = FakeVideoMetadataService();
  });

  group('ImportPipeline.scanDrive', () {
    test('scan drive with video files creates preview rows', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
          DriveFile(
            uri: 'test://drive/video2.MOV',
            name: 'video2.MOV',
            sizeBytes: 25000000,
            lastModified: baseTime.add(const Duration(minutes: 5)),
          ),
        ],
        configJson: '{"type": "blue"}',
        label: 'My Drive',
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');

      expect(result, isA<Ok<ImportSessionState>>());
      final state = (result as Ok<ImportSessionState>).value;

      expect(state.driveLabel, 'My Drive');
      expect(state.allianceSuggestion.side, 'blue');
      expect(state.rows.length, 2);

      // Alliance side should be the suggested side
      for (final row in state.rows) {
        expect(row.allianceSide, 'blue');
      }
    });

    test('scan drive with no config returns null alliance', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.mp4',
            name: 'video1.mp4',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');
      final state = (result as Ok<ImportSessionState>).value;

      expect(state.allianceSuggestion.side, isNull);
      // Default side should be 'red' when no suggestion
      expect(state.rows.first.allianceSide, 'red');
    });

    test('short videos are auto-skipped', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/short.MOV',
            name: 'short.MOV',
            sizeBytes: 500000,
            lastModified: baseTime,
          ),
        ],
      );

      final shortMetadataService = FakeVideoMetadataService(
        durationOverrides: {'short.MOV': 5000}, // 5 seconds — under 30s threshold
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: shortMetadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');
      final state = (result as Ok<ImportSessionState>).value;

      expect(state.rows.first.isAutoSkipped, isTrue);
      expect(state.rows.first.isSelected, isFalse);
    });

    test('previously skipped videos are auto-skipped', () async {
      // Mark a video identity as skipped (must match what FakeVideoMetadataService produces)
      // FakeVideoMetadataService returns durationMs=150000 and for .MOV (iOS),
      // recordingStartTime = date = lastModified = baseTime.
      final identity = VideoIdentity(
        recordingStartTime: baseTime,
        durationMs: 150000,
        fileSizeBytes: 16000000,
      );
      await dataStore.markAsSkipped(identity, 'user_unchecked');

      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');
      final state = (result as Ok<ImportSessionState>).value;

      expect(state.rows.length, 1);
      expect(state.rows.first.isAutoSkipped, isTrue);
      expect(state.rows.first.autoSkipReason, 'This video was skipped before');
    });
  });

  group('ImportPipeline.scanDrive with newerThan', () {
    test('excludes videos with recordingStartTime before newerThan', () async {
      // Two videos: one old (baseTime), one recent (baseTime + 2 hours)
      final recentTime = baseTime.add(const Duration(hours: 2));
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/old.MOV',
            name: 'old.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
          DriveFile(
            uri: 'test://drive/recent.MOV',
            name: 'recent.MOV',
            sizeBytes: 16000000,
            lastModified: recentTime,
          ),
        ],
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      // Set newerThan to 1 hour after baseTime — should exclude the old video
      final cutoff = baseTime.add(const Duration(hours: 1));
      final result = await pipeline.scanDrive('test://drive', newerThan: cutoff);

      expect(result, isA<Ok<ImportSessionState>>());
      final state = (result as Ok<ImportSessionState>).value;

      // Only the recent video should be included
      expect(state.rows.length, 1);
      expect(state.rows.first.metadata.originalFilename, 'recent.MOV');
    });

    test('includes videos at exactly the newerThan boundary', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/boundary.MOV',
            name: 'boundary.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      // For .MOV (iOS), recordingStartTime = lastModified (date)
      // Set newerThan to exactly the recording start time
      final result = await pipeline.scanDrive('test://drive', newerThan: baseTime);

      expect(result, isA<Ok<ImportSessionState>>());
      final state = (result as Ok<ImportSessionState>).value;
      expect(state.rows.length, 1);
    });

    test('null newerThan includes all videos', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/v1.MOV',
            name: 'v1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
          DriveFile(
            uri: 'test://drive/v2.MOV',
            name: 'v2.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime.add(const Duration(hours: 5)),
          ),
        ],
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');

      final state = (result as Ok<ImportSessionState>).value;
      expect(state.rows.length, 2);
    });
  });

  group('ImportPipeline.executeImport', () {
    test('execute import creates recordings in DataStore', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
        configJson: '{"type": "blue"}',
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final scanResult = await pipeline.scanDrive('test://drive');
      final state = (scanResult as Ok<ImportSessionState>).value;

      // Ensure the row has a match assigned and is selected
      expect(state.rows.first.matchKey, isNotNull);
      expect(state.rows.first.isSelected, isTrue);

      final importResult = await pipeline.executeImport(state, null);

      expect(importResult, isA<Ok<int>>());
      final count = (importResult as Ok<int>).value;
      expect(count, 1);

      // Verify recording was added to DataStore
      expect(dataStore.allRecordings.length, 1);
      final recording = dataStore.allRecordings.first;
      expect(recording.allianceSide, 'blue');
      expect(driveAccess.copyWasCalled, isTrue);
    });

    test('execute import with no selected rows returns 0', () async {
      driveAccess = FakeDriveAccess(files: []);

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final state = ImportSessionState(
        driveUri: 'test://drive',
        driveLabel: 'Test',
        allianceSuggestion: const AllianceSuggestion(),
        rows: [],
      );

      final result = await pipeline.executeImport(state, null);
      expect((result as Ok<int>).value, 0);
    });

    test('execute import creates import session in DataStore', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
        configJson: '{"type": "red"}',
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final scanResult = await pipeline.scanDrive('test://drive');
      final state = (scanResult as Ok<ImportSessionState>).value;

      await pipeline.executeImport(state, null);

      // Verify import session was created
      expect(dataStore.importSessions.length, 1);
      final session = dataStore.importSessions.first;
      expect(session.driveLabel, 'Test Drive');
    });
  });

  group('ImportPipeline.cascadeMatchChange', () {
    test('changing match at row 0 cascades to subsequent rows', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/v1.MOV',
            name: 'v1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
          DriveFile(
            uri: 'test://drive/v2.MOV',
            name: 'v2.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime.add(const Duration(minutes: 5)),
          ),
        ],
        configJson: '{"type": "red"}',
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final scanResult = await pipeline.scanDrive('test://drive');
      final state = (scanResult as Ok<ImportSessionState>).value;

      // Change row 0 to qm1
      pipeline.cascadeMatchChange(state, 0, '2026mimid_qm1');

      expect(state.rows[0].matchKey, '2026mimid_qm1');
      // Row 1 should cascade to qm2
      expect(state.rows[1].matchKey, '2026mimid_qm2');
    });
  });

  group('ImportPipeline multi-event eventKey', () {
    test('scanDrive sets eventKey from matched match', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
        configJson: '{"type": "red"}',
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');
      final state = (result as Ok<ImportSessionState>).value;

      // The match was suggested from '2026mimid' event, so eventKey should match
      expect(state.rows.first.eventKey, '2026mimid');
    });

    test('scanDrive defaults eventKey to single event when no match suggested', () async {
      // Use a video timestamp far from any match so no suggestion is made
      final farTime = baseTime.add(const Duration(days: 30));
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: farTime,
          ),
        ],
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');
      final state = (result as Ok<ImportSessionState>).value;

      // Single event selected, so eventKey should default to it
      expect(state.rows.first.eventKey, '2026mimid');
    });

    test('scanDrive leaves eventKey null when multiple events and no matches exist', () async {
      // Add second event, remove all matches so no suggestion is possible
      await dataStore.setEvents([
        Event(
          eventKey: '2026mimid',
          name: 'Midland',
          shortName: 'Mid',
          startDate: DateTime(2026, 3, 20),
          endDate: DateTime(2026, 3, 22),
          playoffType: 10,
          timezone: 'America/Detroit',
        ),
        Event(
          eventKey: '2026miwat',
          name: 'Waterford',
          shortName: 'Wat',
          startDate: DateTime(2026, 4, 10),
          endDate: DateTime(2026, 4, 12),
          playoffType: 10,
          timezone: 'America/Detroit',
        ),
      ]);
      await dataStore.updateSettings(
        dataStore.settings.copyWith(selectedEventKeys: ['2026mimid', '2026miwat']),
      );
      // Clear all matches so no suggestion is possible
      await dataStore.setMatchesForEvent('2026mimid', []);

      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final result = await pipeline.scanDrive('test://drive');
      final state = (result as Ok<ImportSessionState>).value;

      // Multiple events, no matches at all — eventKey should be null
      expect(state.rows.first.eventKey, isNull);
    });

    test('executeImport uses row eventKey for recording', () async {
      driveAccess = FakeDriveAccess(
        files: [
          DriveFile(
            uri: 'test://drive/video1.MOV',
            name: 'video1.MOV',
            sizeBytes: 16000000,
            lastModified: baseTime,
          ),
        ],
        configJson: '{"type": "blue"}',
      );

      pipeline = ImportPipeline(
        driveAccess: driveAccess,
        metadataService: metadataService,
        dataStore: dataStore,
        storageDir: '/tmp/test_storage',
      );

      final scanResult = await pipeline.scanDrive('test://drive');
      final state = (scanResult as Ok<ImportSessionState>).value;

      // Verify eventKey is set on the row
      expect(state.rows.first.eventKey, '2026mimid');

      await pipeline.executeImport(state, null);

      // Verify the recording's eventKey matches the row's eventKey
      final recording = dataStore.allRecordings.first;
      expect(recording.eventKey, '2026mimid');
    });
  });
}
