import 'dart:io';

import '../util/result.dart';
import 'drive_access.dart';

/// Well-known directory paths for local video sources on Android.
const kCameraDir = '/sdcard/DCIM/Camera';
const kQuickShareDir = '/sdcard/Download/Quick Share';

/// Video file extensions recognized by the import pipeline.
const _videoExtensions = {'.mp4', '.mov', '.avi', '.mkv', '.3gp'};

/// DriveAccess implementation for fixed filesystem directories (Camera, Quick Share).
/// Unlike USB drives which use SAF, these are regular directories on the device.
class LocalDriveAccess implements DriveAccess {
  final String dirPath;
  final String label;

  const LocalDriveAccess({required this.dirPath, required this.label});

  @override
  Future<String?> pickDrive() async => dirPath;

  @override
  Future<bool> hasPermission(String driveUri) async {
    return Directory(driveUri).existsSync();
  }

  @override
  Future<Result<List<DriveFile>>> listVideoFiles(String driveUri) async {
    try {
      final dir = Directory(driveUri);
      if (!await dir.exists()) {
        return Err('Directory not found: $driveUri');
      }

      final files = <DriveFile>[];
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('.')) continue;
        final ext = name.contains('.')
            ? '.${name.split('.').last}'.toLowerCase()
            : '';
        if (!_videoExtensions.contains(ext)) continue;

        final stat = await entity.stat();
        files.add(DriveFile(
          uri: entity.path,
          name: name,
          sizeBytes: stat.size,
          lastModified: stat.modified,
        ));
      }

      return Ok(files);
    } catch (e) {
      return Err('Failed to list files: $e');
    }
  }

  @override
  Future<Result<String?>> readTextFile(String driveUri, String filename) async {
    try {
      final file = File('$driveUri/$filename');
      if (!await file.exists()) return const Ok(null);
      final content = await file.readAsString();
      return Ok(content);
    } catch (e) {
      return const Ok(null);
    }
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
    try {
      final sourceFile = File(sourceUri);
      if (!await sourceFile.exists()) {
        return Err('Source file not found: $sourceUri');
      }

      final destFile = File(destPath);
      await destFile.parent.create(recursive: true);
      await sourceFile.copy(destPath);

      final size = await sourceFile.length();
      onProgress?.call(size);
      return const Ok(null);
    } catch (e) {
      return Err('Failed to copy file: $e');
    }
  }

  @override
  Future<Result<void>> deleteFile(String fileUri) async {
    try {
      final file = File(fileUri);
      if (await file.exists()) {
        await file.delete();
      }
      return const Ok(null);
    } catch (e) {
      return Err('Failed to delete file: $e');
    }
  }
}
