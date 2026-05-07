import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/data_store.dart';
import 'package:match_record/data/json_persistence.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/import/integrity_checker.dart';

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
  late DataStore dataStore;
  late Directory tempDir;
  late String recordingsDir;
  late IntegrityChecker checker;

  Recording makeRecording({
    String id = 'rec-1',
    String matchKey = '2026mimid_qm1',
    String allianceSide = 'red',
    String fileExtension = '.mp4',
  }) =>
      Recording(
        id: id,
        eventKey: '2026mimid',
        matchKey: matchKey,
        allianceSide: allianceSide,
        fileExtension: fileExtension,
        recordingStartTime: DateTime(2026, 3, 20, 10, 0),
        durationMs: 150000,
        fileSizeBytes: 50000000,
        sourceDeviceType: 'ios',
        originalFilename: 'video.mp4',
        team1: 201,
        team2: 100,
        team3: 300,
      );

  setUp(() async {
    fakePersistence = FakeJsonPersistence();
    dataStore = DataStore(fakePersistence);
    await dataStore.init();

    tempDir = await Directory.systemTemp.createTemp('integrity_test_');
    recordingsDir = '${tempDir.path}/recordings';
    await Directory(recordingsDir).create(recursive: true);

    checker = IntegrityChecker();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('clean state with no orphans returns 0', () async {
    // Add a recording to the DataStore
    final rec = makeRecording();
    await dataStore.addRecording(rec);

    // Create the corresponding file on disk
    await File('$recordingsDir/${rec.id}${rec.fileExtension}')
        .writeAsString('video data');

    final count = await checker.reconcile(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
    );

    expect(count, 0, reason: 'No orphans should mean zero cleanup');
    expect(dataStore.allRecordings.length, 1,
        reason: 'Recording should still be in DataStore');
    expect(
      await File('$recordingsDir/${rec.id}${rec.fileExtension}').exists(),
      isTrue,
      reason: 'File should still exist on disk',
    );
  });

  test('orphaned file (file exists, no DB entry) is deleted', () async {
    // Create a file on disk with no matching DB entry
    final orphanFile = File('$recordingsDir/orphan-file.mp4');
    await orphanFile.writeAsString('orphan data');

    final count = await checker.reconcile(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
    );

    expect(count, 1, reason: 'One orphaned file should be cleaned up');
    expect(
      await orphanFile.exists(),
      isFalse,
      reason: 'Orphaned file should be deleted from disk',
    );
  });

  test('orphaned DB entry (DB entry, no file) is removed and added to skip history', () async {
    // Add a recording to the DataStore but don't create the file
    final rec = makeRecording(id: 'missing-file');
    await dataStore.addRecording(rec);

    expect(dataStore.allRecordings.length, 1);

    final count = await checker.reconcile(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
    );

    expect(count, 1, reason: 'One orphaned DB entry should be cleaned up');
    expect(dataStore.allRecordings, isEmpty,
        reason: 'Recording should be removed from DataStore');

    // DataStore.deleteRecording adds to skip history with reason "deleted"
    final identity = VideoIdentity(
      recordingStartTime: rec.recordingStartTime,
      durationMs: rec.durationMs,
      fileSizeBytes: rec.fileSizeBytes,
    );
    expect(dataStore.isSkipped(identity), isTrue,
        reason: 'Should be added to skip history');
  });

  test('mixed orphans (both types) are all cleaned up', () async {
    // Orphaned file: file on disk, no DB entry
    final orphanFile = File('$recordingsDir/orphan-file.mp4');
    await orphanFile.writeAsString('orphan data');

    // Orphaned DB entry: DB entry, no file
    final rec = makeRecording(id: 'missing-file');
    await dataStore.addRecording(rec);

    // Also add a valid recording with its file (should NOT be cleaned up)
    final validRec = makeRecording(
      id: 'valid-rec',
      matchKey: '2026mimid_qm2',
    );
    await dataStore.addRecording(validRec);
    await File('$recordingsDir/${validRec.id}${validRec.fileExtension}')
        .writeAsString('valid data');

    final count = await checker.reconcile(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
    );

    expect(count, 2, reason: 'Both orphaned file and orphaned DB entry should be cleaned up');

    // Orphaned file should be deleted
    expect(await orphanFile.exists(), isFalse);

    // Orphaned DB entry should be removed
    expect(dataStore.allRecordings.length, 1);
    expect(dataStore.allRecordings[0].id, 'valid-rec');

    // Valid recording and file should remain
    expect(
      await File('$recordingsDir/${validRec.id}${validRec.fileExtension}').exists(),
      isTrue,
    );
  });

  test('empty directory and empty DB returns 0', () async {
    final count = await checker.reconcile(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
    );

    expect(count, 0,
        reason: 'Empty state should have nothing to clean up');
  });

  test('recordings directory that does not exist is created and returns cleanup count for DB orphans', () async {
    // Use a non-existent directory
    final nonExistentDir = '${tempDir.path}/nonexistent_recordings';

    // Add a recording to DB (it won't have a file since dir doesn't exist)
    final rec = makeRecording(id: 'no-dir-file');
    await dataStore.addRecording(rec);

    final count = await checker.reconcile(
      recordingsDir: nonExistentDir,
      dataStore: dataStore,
    );

    expect(count, 1,
        reason: 'DB entry without file should be cleaned up even when dir did not exist');
    expect(await Directory(nonExistentDir).exists(), isTrue,
        reason: 'Directory should be created');
    expect(dataStore.allRecordings, isEmpty);
  });

  test('multiple orphaned files are all deleted', () async {
    // Create multiple orphan files
    await File('$recordingsDir/orphan1.mp4').writeAsString('data1');
    await File('$recordingsDir/orphan2.mov').writeAsString('data2');
    await File('$recordingsDir/orphan3.mp4').writeAsString('data3');

    final count = await checker.reconcile(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
    );

    expect(count, 3);
    expect(await File('$recordingsDir/orphan1.mp4').exists(), isFalse);
    expect(await File('$recordingsDir/orphan2.mov').exists(), isFalse);
    expect(await File('$recordingsDir/orphan3.mp4').exists(), isFalse);
  });

  test('recording with different file extension is matched correctly', () async {
    final rec = makeRecording(id: 'mov-rec', fileExtension: '.mov');
    await dataStore.addRecording(rec);
    await File('$recordingsDir/mov-rec.mov').writeAsString('mov data');

    final count = await checker.reconcile(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
    );

    expect(count, 0, reason: '.mov recording should match its file');
    expect(dataStore.allRecordings.length, 1);
  });
}
