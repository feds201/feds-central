/// Test flags for development. Set these to true to use sample data.
class TestFlags {
  /// When true, use sample videos from the device filesystem instead of USB
  /// drive access. Videos must be pushed to the device first — see
  /// TestDriveAccess doc comment for adb push instructions.
  static const bool useSampleVideos = true;

  /// When true, force-load these events on first launch
  static const bool forceEventId = true;
  static const List<String> forcedEventIds = [
    '2025micmp',
    '2025micmp1',
    '2025micmp2',
    '2025micmp3',
    '2025micmp4',
    '2026mimid',
  ];

  /// When true, assign sample videos to specific quals matches
  static const bool forceSampleMatchAssignment = true;
  // Which match numbers to assign the 2 sample videos to
  static const int sampleMatch1Number = 1; // qm1
  static const int sampleMatch2Number = 2; // qm2
}
