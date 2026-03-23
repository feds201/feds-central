import 'dart:io';

import 'package:logger/logger.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../util/constants.dart';

/// Reconciles the recordings directory on disk with the DataStore at startup.
///
/// - Files on disk with no matching DB entry -> deleted from disk.
/// - DB entries whose file is missing from disk -> removed from DataStore
///   and added to skip history with reason "deleted".
class IntegrityChecker {
  final Logger _logger = Logger(printer: SimplePrinter());

  /// Scans [recordingsDir] and reconciles with [dataStore].
  /// Returns the number of items cleaned up.
  Future<int> reconcile({
    required String recordingsDir,
    required DataStore dataStore,
  }) async {
    int cleanedUp = 0;

    final dir = Directory(recordingsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      // No files to reconcile, but check for DB entries without files
      cleanedUp += await _removeOrphanedDbEntries(
        recordingsDir: recordingsDir,
        dataStore: dataStore,
        filesOnDisk: {},
      );
      return cleanedUp;
    }

    // Step 1: List all files in the recordings directory
    final filesOnDisk = <String>{};
    await for (final entity in dir.list()) {
      if (entity is File) {
        final filename = entity.uri.pathSegments.last;
        filesOnDisk.add(filename);
      }
    }

    // Step 2: Build a set of expected filenames from the DataStore
    final recordings = dataStore.allRecordings;
    final expectedFiles = <String, Recording>{};
    for (final r in recordings) {
      final filename = '${r.id}${r.fileExtension}';
      expectedFiles[filename] = r;
    }

    // Step 3: Files without DB entries -> delete the file
    for (final filename in filesOnDisk) {
      if (!expectedFiles.containsKey(filename)) {
        final filePath = '$recordingsDir/$filename';
        try {
          await File(filePath).delete();
          _logger.i('Integrity check: deleted orphaned file $filename');
          cleanedUp++;
        } catch (e) {
          _logger.w('Integrity check: failed to delete orphaned file $filename: $e');
        }
      }
    }

    // Step 4: DB entries without files -> remove from DataStore + add to skip history
    cleanedUp += await _removeOrphanedDbEntries(
      recordingsDir: recordingsDir,
      dataStore: dataStore,
      filesOnDisk: filesOnDisk,
    );

    if (cleanedUp > 0) {
      _logger.i('Integrity check: cleaned up $cleanedUp item(s)');
    }

    return cleanedUp;
  }

  Future<int> _removeOrphanedDbEntries({
    required String recordingsDir,
    required DataStore dataStore,
    required Set<String> filesOnDisk,
  }) async {
    int cleanedUp = 0;
    final recordings = dataStore.allRecordings;

    for (final r in recordings) {
      final filename = '${r.id}${r.fileExtension}';
      if (!filesOnDisk.contains(filename)) {
        _logger.i('Integrity check: removing DB entry for missing file $filename (recording ${r.id})');
        await dataStore.deleteRecording(r.id);
        cleanedUp++;
      }
    }

    return cleanedUp;
  }
}
