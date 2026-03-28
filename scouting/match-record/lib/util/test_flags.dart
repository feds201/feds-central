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

  /// When true, injects a fake match notification 15 minutes from now
  /// on every TBA sync. Uses fake team data so you can test the full
  /// notification flow without a real event.
  static const bool fakeMatchNotification = false;
}
