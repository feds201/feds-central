import 'dart:async';
import 'dart:ui';

import 'package:media_kit/media_kit.dart';

import '../data/models.dart';

/// Manages dual-player synchronization for side-by-side video playback.
///
/// One recording started earlier (the "earlier" player), the other started later.
/// The earlier player is the primary clock. The later player's position is
/// always derived: `laterPos = earlierPos - syncOffset`.
///
/// Key insight from prototype: `player.state.position` is updated asynchronously
/// via streams, so after `seek()` it may still reflect the OLD position. We track
/// `_intendedEarlierPosition` separately to avoid race conditions.
class SyncEngine {
  final Player earlierPlayer;
  final Player laterPlayer;
  final Duration syncOffset;

  /// True if the earlier player corresponds to the red recording.
  final bool earlierIsRed;

  Duration _intendedEarlierPosition = Duration.zero;

  /// Whether the later player is waiting for the earlier to reach the offset.
  bool laterWaiting = false;

  /// Countdown remaining until the later player starts.
  Duration countdownRemaining = Duration.zero;

  StreamSubscription<Duration>? _positionSubscription;

  SyncEngine._({
    required this.earlierPlayer,
    required this.laterPlayer,
    required this.syncOffset,
    required this.earlierIsRed,
  }) {
    laterWaiting = syncOffset > Duration.zero;
    countdownRemaining = syncOffset;
  }

  /// Create a SyncEngine from two recordings and their pre-created players.
  ///
  /// Determines which recording started earlier and computes the sync offset.
  /// [redPlayer] and [bluePlayer] must already be created (but not necessarily
  /// opened yet).
  factory SyncEngine.fromRecordings({
    required Recording redRecording,
    required Recording blueRecording,
    required Player redPlayer,
    required Player bluePlayer,
  }) {
    final offset = computeSyncOffset(
      redRecording.recordingStartTime,
      blueRecording.recordingStartTime,
    );

    final redIsEarlier =
        !redRecording.recordingStartTime.isAfter(blueRecording.recordingStartTime);

    return SyncEngine._(
      earlierPlayer: redIsEarlier ? redPlayer : bluePlayer,
      laterPlayer: redIsEarlier ? bluePlayer : redPlayer,
      syncOffset: offset,
      earlierIsRed: redIsEarlier,
    );
  }

  /// The current intended position of the earlier player.
  Duration get intendedEarlierPosition => _intendedEarlierPosition;

  /// Get the red player regardless of which is earlier/later.
  Player get redPlayer => earlierIsRed ? earlierPlayer : laterPlayer;

  /// Get the blue player regardless of which is earlier/later.
  Player get bluePlayer => earlierIsRed ? laterPlayer : earlierPlayer;

  /// Whether a given side is the later (waiting) side.
  bool isLaterSide(String allianceSide) {
    if (earlierIsRed) return allianceSide == 'blue';
    return allianceSide == 'red';
  }

  /// Compute the sync offset from two recording start times.
  ///
  /// Returns the absolute difference between the two timestamps.
  static Duration computeSyncOffset(DateTime startA, DateTime startB) {
    final diff = startA.difference(startB);
    return diff.abs();
  }

  /// Compute the later player's position for a given earlier player position.
  ///
  /// Returns null if the earlier position hasn't reached the sync offset yet
  /// (meaning the later video hasn't started recording yet at that point).
  static Duration? laterPositionFor(Duration earlierPos, Duration syncOffset) {
    if (earlierPos < syncOffset) return null;
    return earlierPos - syncOffset;
  }

  /// Subscribe to the earlier player's position stream to manage countdown
  /// and trigger the later player when the offset is reached.
  ///
  /// [onStateChanged] is called whenever countdown/waiting state changes,
  /// so the UI can rebuild.
  void startPositionMonitoring(VoidCallback onStateChanged) {
    _positionSubscription?.cancel();
    _positionSubscription =
        earlierPlayer.stream.position.listen((pos) {
      if (!laterWaiting) return;

      if (pos >= syncOffset) {
        laterWaiting = false;
        countdownRemaining = Duration.zero;
        onStateChanged();
        laterPlayer.seek(pos - syncOffset);
        laterPlayer.play();
      } else {
        countdownRemaining = syncOffset - pos;
        onStateChanged();
      }
    });
  }

  /// Start synced playback from the current intended position.
  Future<void> startSyncedPlayback() async {
    final earlierPos = _intendedEarlierPosition;
    final laterTarget = laterPositionFor(earlierPos, syncOffset);

    if (syncOffset == Duration.zero || laterTarget != null) {
      laterWaiting = false;
      await earlierPlayer.play();
      if (laterTarget != null) {
        await laterPlayer.seek(laterTarget);
      }
      await laterPlayer.play();
    } else {
      // Earlier player starts, later waits for position stream to trigger it
      laterWaiting = true;
      countdownRemaining = syncOffset - earlierPos;
      await earlierPlayer.play();
    }
  }

  /// Pause both players.
  Future<void> pauseBoth() async {
    await earlierPlayer.pause();
    await laterPlayer.pause();
  }

  /// Seek to a position on the earlier player's timeline.
  ///
  /// Clamps to valid range. Updates the later player accordingly — either
  /// seeking it to the derived position or putting it in waiting state.
  Future<void> seekToEarlierPosition(Duration earlierPos) async {
    if (earlierPos < Duration.zero) earlierPos = Duration.zero;
    final earlierDur = earlierPlayer.state.duration;
    if (earlierDur > Duration.zero && earlierPos > earlierDur) {
      earlierPos = earlierDur;
    }

    _intendedEarlierPosition = earlierPos;

    final laterTarget = laterPositionFor(earlierPos, syncOffset);
    if (laterTarget == null) {
      laterWaiting = true;
      countdownRemaining = syncOffset - earlierPos;
      // Seek earlier player while pausing+resetting later player in parallel
      await Future.wait([
        earlierPlayer.seek(earlierPos),
        laterPlayer.pause().then((_) => laterPlayer.seek(Duration.zero)),
      ]);
    } else {
      var clampedLater = laterTarget;
      final laterDur = laterPlayer.state.duration;
      if (laterDur > Duration.zero && clampedLater > laterDur) {
        clampedLater = laterDur;
      }
      laterWaiting = false;
      countdownRemaining = Duration.zero;
      // Seek both players in parallel for responsive scrubbing
      await Future.wait([
        earlierPlayer.seek(earlierPos),
        laterPlayer.seek(clampedLater),
      ]);
    }
  }

  /// Restart both players from the beginning.
  Future<void> restartBoth() async {
    await earlierPlayer.pause();
    await laterPlayer.pause();
    await earlierPlayer.seek(Duration.zero);
    await laterPlayer.seek(Duration.zero);

    _intendedEarlierPosition = Duration.zero;
    laterWaiting = syncOffset > Duration.zero;
    countdownRemaining = syncOffset;
  }

  /// Update the intended earlier position (e.g., during scrub or stream updates).
  void updateIntendedPosition(Duration position) {
    _intendedEarlierPosition = position;
  }

  /// Dispose of subscriptions.
  void dispose() {
    _positionSubscription?.cancel();
  }
}
