import 'package:flutter/services.dart';

import '../util/constants.dart';

enum StorageStatus {
  /// Enough free space to import.
  ok,

  /// Free space is below the warning threshold (1GB) but above the blocking
  /// threshold (100MB). Import can proceed but user should be warned.
  low,

  /// Free space is below the blocking threshold (100MB). Import should not
  /// proceed.
  blocked,
}

/// Checks available device storage before starting an import.
///
/// Uses the platform channel's `getFreeSpace` method (Kotlin `StatFs`).
/// Falls back to [StorageStatus.ok] when the platform channel is unavailable
/// (e.g. in tests or on desktop).
class StorageChecker {
  static const _channel = MethodChannel('com.feds201.match_record/native');

  /// Check free space at [path] and return a [StorageStatus].
  static Future<StorageStatus> check(String path) async {
    final freeBytes = await getFreeBytes(path);
    if (freeBytes == null) return StorageStatus.ok;

    if (freeBytes < AppConstants.blockImportBytes) {
      return StorageStatus.blocked;
    }
    if (freeBytes < AppConstants.lowStorageWarningBytes) {
      return StorageStatus.low;
    }
    return StorageStatus.ok;
  }

  /// Get free bytes at [path], or null if the platform channel is unavailable.
  static Future<int?> getFreeBytes(String path) async {
    try {
      final result = await _channel.invokeMethod<int>('getFreeSpace', {
        'path': path,
      });
      if (result != null && result >= 0) return result;
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
