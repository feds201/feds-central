import 'dart:io';

import '../util/result.dart';
import 'drive_access.dart';

/// Metadata for a test video file (non-const since DateTime isn't const).
class _TestVideoFile {
  final String filename;
  final int sizeBytes;
  final DateTime lastModified;

  _TestVideoFile({
    required this.filename,
    required this.sizeBytes,
    required this.lastModified,
  });
}

/// Metadata for a test drive.
class _TestDrive {
  final String uri;
  final String label;
  final String subDir;
  final List<_TestVideoFile> videos;
  final String configJson;

  _TestDrive({
    required this.uri,
    required this.label,
    required this.subDir,
    required this.videos,
    required this.configJson,
  });
}

/// Test implementation of DriveAccess that reads sample videos from the device
/// filesystem. Used when TestFlags.useSampleVideos is true.
///
/// Videos must be pushed to the device before use:
///   adb push ~/Downloads/flash_drive_ios /sdcard/match_record_samples/flash_drive_ios
///   adb push ~/Downloads/flash_drive_android /sdcard/match_record_samples/flash_drive_android
class TestDriveAccess implements DriveAccess {
  /// Base path where sample videos live on the device filesystem.
  /// Push videos with:
  ///   adb push ~/Downloads/flash_drive_ios /sdcard/match_record_samples/flash_drive_ios
  ///   adb push ~/Downloads/flash_drive_android /sdcard/match_record_samples/flash_drive_android
  static const String _basePath = '/sdcard/match_record_samples';

  static final List<_TestDrive> _drives = [
    _TestDrive(
      uri: 'test://flash_drive_ios',
      label: 'iOS Flash Drive',
      subDir: 'flash_drive_ios',
      videos: [
        _TestVideoFile(
          filename: 'IMG_9857.MOV',
          sizeBytes: 428521454, // ~409MB
          // iOS creation_time = recording start
          lastModified: DateTime.utc(2026, 3, 23, 16, 29, 30),
        ),
      ],
      configJson: '{"alliance": "red"}',
    ),
    _TestDrive(
      uri: 'test://flash_drive_android',
      label: 'Android Flash Drive',
      subDir: 'flash_drive_android',
      videos: [
        _TestVideoFile(
          filename: 'PXL_20260323_162929108.mp4',
          sizeBytes: 546752370, // ~521MB
          // Android creation_time = recording end (16:31:57), started ~16:29:29
          lastModified: DateTime.utc(2026, 3, 23, 16, 31, 57),
        ),
      ],
      configJson: '{"alliance": "blue"}',
    ),
  ];

  /// Returns the list of available test drive URIs.
  static List<String> get availableDriveUris =>
      _drives.map((d) => d.uri).toList();

  _TestDrive? _findDrive(String uri) {
    for (final d in _drives) {
      if (d.uri == uri) return d;
    }
    return null;
  }

  @override
  Future<String?> pickDrive() async {
    // In test mode, return the first drive automatically
    return _drives.first.uri;
  }

  @override
  Future<bool> hasPermission(String driveUri) async {
    return _findDrive(driveUri) != null;
  }

  @override
  Future<Result<List<DriveFile>>> listVideoFiles(String driveUri) async {
    final drive = _findDrive(driveUri);
    if (drive == null) return const Err('Drive not found');

    final files = drive.videos.map((v) {
      return DriveFile(
        uri: '${drive.uri}/${v.filename}',
        name: v.filename,
        sizeBytes: v.sizeBytes,
        lastModified: v.lastModified,
      );
    }).toList();

    return Ok(files);
  }

  @override
  Future<Result<String?>> readTextFile(String driveUri, String filename) async {
    final drive = _findDrive(driveUri);
    if (drive == null) return const Err('Drive not found');

    if (filename == 'config.json') {
      return Ok(drive.configJson);
    }
    return const Ok(null);
  }

  @override
  Future<Result<String>> getDriveLabel(String driveUri) async {
    final drive = _findDrive(driveUri);
    if (drive == null) return const Err('Drive not found');
    return Ok(drive.label);
  }

  @override
  Future<Result<void>> copyToLocal(
    String sourceUri,
    String destPath,
    void Function(int bytesCopied)? onProgress,
  ) async {
    for (final drive in _drives) {
      for (final video in drive.videos) {
        final fileUri = '${drive.uri}/${video.filename}';
        if (fileUri == sourceUri) {
          try {
            final sourcePath = '$_basePath/${drive.subDir}/${video.filename}';
            final sourceFile = File(sourcePath);
            if (!await sourceFile.exists()) {
              return Err(
                'Sample video not found at $sourcePath. '
                'On Android, push with: adb push ~/Downloads/${drive.subDir} '
                '/sdcard/match_record_samples/${drive.subDir}',
              );
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
      }
    }

    return const Err('Source file not found');
  }

  @override
  Future<Result<void>> deleteFile(String fileUri) async {
    // No-op for test drives
    return const Ok(null);
  }
}
