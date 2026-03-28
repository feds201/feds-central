import 'package:flutter/material.dart';

class AppColors {
  // TBA search category colors
  static const Color searchCategory = Colors.blue;
  static const Color teamCategory = Colors.teal;
  static const Color matchCategory = Colors.orange;
  static const Color allianceCategory = Colors.green;

  // Alliance side colors
  static const Color redAlliance = Colors.red;
  static const Color blueAlliance = Colors.blue;
  static const Color fullAlliance = Colors.green;

  // Lighter variants for chips, scores, team numbers
  static final Color redAllianceLight = Colors.red.shade300;
  static final Color blueAllianceLight = Colors.blue.shade300;
  static final Color fullAllianceLight = Colors.green.shade300;

  /// Returns the alliance color for a given alliance side string.
  static Color colorForAllianceSide(String allianceSide) {
    switch (allianceSide) {
      case 'red':
        return redAlliance;
      case 'blue':
        return blueAlliance;
      default:
        return fullAlliance;
    }
  }

  /// Returns the light variant of the alliance color for a given side.
  static Color lightColorForAllianceSide(String allianceSide) {
    switch (allianceSide) {
      case 'red':
        return redAllianceLight;
      case 'blue':
        return blueAllianceLight;
      default:
        return fullAllianceLight;
    }
  }
}

class AppConstants {
  // Import thresholds
  static const int defaultShortVideoThresholdMs = 30000;
  static const int defaultSequentialGapMinMinutes = 10;
  static const int defaultSequentialGapMaxMinutes = 20;

  // Scrub settings
  static const double defaultScrubExponent = 2.5;
  static const int defaultScrubMaxRangeMs = 90000;
  static const int defaultScrubCoalescingIntervalMs = 25;

  // Touch deadzone (shared by scrub and drawing)
  static const double touchDeadZonePx = 3.0;

  // Drawing
  static const double strokeWidth = 3.5;

  // Storage
  static const int lowStorageWarningBytes = 1024 * 1024 * 1024; // 1GB
  static const int blockImportBytes = 100 * 1024 * 1024; // 100MB

  // TBA
  static const String tbaBaseUrl = 'https://www.thebluealliance.com/api/v3';

  // Recordings directory name
  static const String recordingsDirName = 'recordings';

  // Search debounce
  static const int searchDebounceMs = 250;

  // Match notifications
  static const int matchNotificationWindowSeconds = 3 * 60 * 60; // 3 hours
  static const int queueMatchesBefore = 2;
  static const String redChannelId = 'red_alliance_matches';
  static const String blueChannelId = 'blue_alliance_matches';
}
