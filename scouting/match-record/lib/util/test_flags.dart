/// Test flags for development. Set these to true to use sample data.
class TestFlags {
  /// When true, use sample videos from the device filesystem instead of USB
  /// drive access. Videos must be pushed to the device first — see
  /// TestDriveAccess doc comment for adb push instructions.
  static const bool useSampleVideos = true;

  /// When true, force the event to 2026mimid
  static const bool forceEventId = true;
  static const String forcedEventId = '2026mimid';

  /// When true, assign sample videos to specific quals matches
  static const bool forceSampleMatchAssignment = true;
  // Which match numbers to assign the 2 sample videos to
  static const int sampleMatch1Number = 1; // qm1
  static const int sampleMatch2Number = 2; // qm2
}
