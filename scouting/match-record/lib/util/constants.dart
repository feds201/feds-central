class AppConstants {
  // Import thresholds
  static const int defaultShortVideoThresholdMs = 30000;
  static const int defaultSequentialGapMinMinutes = 10;
  static const int defaultSequentialGapMaxMinutes = 20;

  // Scrub settings
  static const double defaultScrubExponent = 2.5;
  static const int defaultScrubMaxRangeMs = 120000;
  static const double scrubDeadZonePx = 3.0;

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
}
