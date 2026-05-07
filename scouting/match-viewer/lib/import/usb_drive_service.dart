import 'package:flutter/services.dart';

import '../util/result.dart';
import 'alliance_suggester.dart';
import 'local_drive_access.dart';

/// A USB drive detected by the platform.
class UsbDrive {
  final String path;
  final String label;

  const UsbDrive({required this.path, required this.label});
}

/// A USB drive with alliance side detection result.
class DetectedUsbDrive {
  final UsbDrive drive;

  /// "red", "blue", "full", or null if unknown.
  final String? allianceSide;

  /// How the alliance side was inferred: "config", "label", or "none".
  final String inferenceSource;

  const DetectedUsbDrive({
    required this.drive,
    required this.allianceSide,
    required this.inferenceSource,
  });
}

/// Service for discovering USB drives connected to the device.
///
/// Uses a Kotlin platform channel to enumerate removable storage volumes
/// via Android's StorageManager API.
class UsbDriveService {
  static const _channel = MethodChannel('com.feds201.match_record/native');

  /// Pattern matching FEDS drive naming convention.
  /// Accepts any separator: dash, underscore, dot, slash, backslash, space, etc.
  static final _labelPattern = RegExp(
    r'feds[\s\-_./\\]*(red|blue|full)',
    caseSensitive: false,
  );

  /// Get raw USB volumes from the platform channel.
  Future<List<UsbDrive>> getConnectedDrives() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getUsbDrives');
      if (result == null) return [];

      return result
          .whereType<Map>()
          .map((m) {
            final path = m['path'];
            final label = m['label'];
            if (path is! String || label is! String) return null;
            return UsbDrive(path: path, label: label);
          })
          .whereType<UsbDrive>()
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  /// Get USB drives with alliance side auto-detection.
  ///
  /// For each drive, tries config.json first, then falls back to
  /// the drive label naming convention (FEDS-RED, FEDS-BLUE, FEDS-FULL).
  Future<List<DetectedUsbDrive>> detectDrives() async {
    final drives = await getConnectedDrives();
    final results = <DetectedUsbDrive>[];

    for (final drive in drives) {
      results.add(await detectAllianceSide(drive));
    }

    return results;
  }

  /// Detect alliance side for a single drive.
  ///
  /// Priority: config.json > drive label naming convention.
  Future<DetectedUsbDrive> detectAllianceSide(UsbDrive drive) async {
    // Try config.json first
    final access = LocalDriveAccess(dirPath: drive.path, label: drive.label);
    final configResult = await access.readTextFile(drive.path, 'config.json');
    if (configResult is Ok<String?>) {
      final content = (configResult as Ok<String?>).value;
      if (content != null) {
        final suggestion = AllianceSuggester.suggest(configJsonContent: content);
        if (suggestion.side != null) {
          return DetectedUsbDrive(
            drive: drive,
            allianceSide: suggestion.side,
            inferenceSource: 'config',
          );
        }
      }
    }

    // Fall back to label naming convention
    final labelSide = inferSideFromLabel(drive.label);
    if (labelSide != null) {
      return DetectedUsbDrive(
        drive: drive,
        allianceSide: labelSide,
        inferenceSource: 'label',
      );
    }

    return DetectedUsbDrive(
      drive: drive,
      allianceSide: null,
      inferenceSource: 'none',
    );
  }

  /// Infer alliance side from a drive volume label.
  ///
  /// Matches the FEDS naming convention with flexible separators:
  /// FEDS-RED, feds_blue, FEDS.FULL, Feds Red, FEDS\RED, feds/blue, etc.
  static String? inferSideFromLabel(String label) {
    final match = _labelPattern.firstMatch(label.trim());
    if (match == null) return null;
    return match.group(1)!.toLowerCase();
  }
}
