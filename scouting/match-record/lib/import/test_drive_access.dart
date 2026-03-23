import 'dart:io';

import 'package:flutter/services.dart';

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
  final String assetDir;
  final List<_TestVideoFile> videos;
  final String configJson;

  _TestDrive({
    required this.uri,
    required this.label,
    required this.assetDir,
    required this.videos,
    required this.configJson,
  });
}

/// Test implementation of DriveAccess using embedded sample data from assets.
/// Used when TestFlags.useEmbeddedSampleVideos is true.
class TestDriveAccess implements DriveAccess {
  static final List<_TestDrive> _drives = [
    _TestDrive(
      uri: 'test://flash_drive_ios',
      label: 'iOS Flash Drive',
      assetDir: 'sample_data/flash_drive_ios',
      videos: [
        _TestVideoFile(
          filename: 'IMG_9848.MOV',
          sizeBytes: 16777216, // ~16MB
          // iOS recording start time for match 1
          lastModified: DateTime.utc(2026, 3, 22, 14, 30, 0),
        ),
        _TestVideoFile(
          filename: 'IMG_9849.MOV',
          sizeBytes: 26214400, // ~25MB
          // iOS recording start time for match 2
          lastModified: DateTime.utc(2026, 3, 22, 14, 45, 0),
        ),
      ],
      configJson: '{"alliance": "blue"}',
    ),
    _TestDrive(
      uri: 'test://flash_drive_android',
      label: 'Android Flash Drive',
      assetDir: 'sample_data/flash_drive_android',
      videos: [
        _TestVideoFile(
          filename: 'PXL_20260322_200436398.mp4',
          sizeBytes: 17825792, // ~17MB
          lastModified: DateTime.utc(2026, 3, 22, 20, 4, 36),
        ),
        _TestVideoFile(
          filename: 'PXL_20260322_200456612.mp4',
          sizeBytes: 22020096, // ~21MB
          lastModified: DateTime.utc(2026, 3, 22, 20, 4, 56),
        ),
      ],
      configJson: '{"alliance": "red"}',
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
    // Find the drive and file from the source URI
    for (final drive in _drives) {
      for (final video in drive.videos) {
        final fileUri = '${drive.uri}/${video.filename}';
        if (fileUri == sourceUri) {
          try {
            final assetPath = '${drive.assetDir}/${video.filename}';
            final data = await rootBundle.load(assetPath);
            final bytes = data.buffer.asUint8List();
            final file = File(destPath);
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes);
            onProgress?.call(bytes.length);
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
    // No-op for test drives -- we don't delete embedded assets
    return const Ok(null);
  }
}
