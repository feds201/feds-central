import 'dart:async';
import 'dart:ui';

import 'package:media_kit/media_kit.dart';

import '../data/models.dart';

/// Manages synchronized playback of two or three match recordings.
///
/// One recording always started before the other (red/blue). The earlier player
/// is the primary clock. The later player's position is always derived:
/// `laterPos = earlierPos - syncOffset`.
///
/// An optional full-field player can be added. It has its own offset relative
/// to the earlier player's start time and is kept in sync with no countdown UI.
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

  /// Optional full-field player and its offset relative to earlierPlayer's start.
  final Player? fullPlayer;
  final Duration fullOffset;

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
    this.fullPlayer,
    this.fullOffset = Duration.zero,
  }) {
    laterWaiting = syncOffset > Duration.zero;
    countdownRemaining = syncOffset;
  }

  /// Create a SyncEngine from recordings and their pre-created players.
  ///
  /// Determines which recording started earlier and computes the sync offset.
  /// [redPlayer] and [bluePlayer] must already be created (but not necessarily
  /// opened yet). [fullRecording] and [fullPlayer] are optional; if provided,
  /// the full-field player is kept in sync alongside red/blue.
  factory SyncEngine.fromRecordings({
    required Recording redRecording,
    required Recording blueRecording,
    required Player redPlayer,
    required Player bluePlayer,
    Recording? fullRecording,
    Player? fullPlayer,
  }) {
    // Viewer-local effective start times: if one recording has null start time,
    // treat it as starting at the same time as the other (sync offset = 0).
    // These are NEVER persisted back to the Recording or database.
    final redStart = redRecording.recordingStartTime
        ?? blueRecording.recordingStartTime
        ?? DateTime.now();
    final blueStart = blueRecording.recordingStartTime
        ?? redRecording.recordingStartTime
        ?? DateTime.now();

    final offset = computeSyncOffset(redStart, blueStart);

    final redIsEarlier = !redStart.isAfter(blueStart);

    final earlierStartTime = redIsEarlier ? redStart : blueStart;

    Duration computedFullOffset = Duration.zero;
    if (fullRecording != null) {
      final fullStart = fullRecording.recordingStartTime ?? earlierStartTime;
      computedFullOffset = computeSyncOffset(earlierStartTime, fullStart);
      // If full started before the earlier player, its offset is negative in
      // the timeline sense — the full player starts before earlier. We handle
      // this by treating the full player as simply offset 0 relative to itself;
      // use signed difference so we can compute the correct derived position.
      final signedDiff = fullStart.difference(earlierStartTime);
      computedFullOffset = signedDiff.isNegative
          ? Duration(milliseconds: -signedDiff.inMilliseconds.abs())
          : signedDiff.abs();
    }

    return SyncEngine._(
      earlierPlayer: redIsEarlier ? redPlayer : bluePlayer,
      laterPlayer: redIsEarlier ? bluePlayer : redPlayer,
      syncOffset: offset,
      earlierIsRed: redIsEarlier,
      fullPlayer: fullRecording != null ? fullPlayer : null,
      fullOffset: computedFullOffset,
    );
  }

  /// The current intended position of the earlier player.
  Duration get intendedEarlierPosition => _intendedEarlierPosition;

  /// Get the red player regardless of which is earlier/later.
  Player get redPlayer => earlierIsRed ? earlierPlayer : laterPlayer;

  /// Get the blue player regardless of which is earlier/later.
  Player get bluePlayer => earlierIsRed ? laterPlayer : earlierPlayer;

  /// The total duration of the unified timeline:
  /// max(earlierDuration, syncOffset + laterDuration).
  /// Returns null if neither player has reported a duration yet.
  Duration? get unifiedDuration {
    final earlierDur = earlierPlayer.state.duration;
    final laterDur = laterPlayer.state.duration;
    if (earlierDur == Duration.zero && laterDur == Duration.zero) return null;
    final laterEnd = syncOffset + laterDur;
    return earlierDur > laterEnd ? earlierDur : laterEnd;
  }

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
  /// (meaning the later video hadn't started recording yet at that point).
  static Duration? laterPositionFor(Duration earlierPos, Duration syncOffset) {
    if (earlierPos < syncOffset) return null;
    return earlierPos - syncOffset;
  }

  /// Compute the full player's derived position for a given earlier player position.
  ///
  /// fullOffset can be negative (full started before earlier) or positive (after).
  /// Returns zero if the derived position would be negative (full hadn't started yet).
  Duration _fullPositionFor(Duration earlierPos) {
    final derivedMs = earlierPos.inMilliseconds - fullOffset.inMilliseconds;
    if (derivedMs < 0) return Duration.zero;
    return Duration(milliseconds: derivedMs);
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

    // Full player: seek to derived position and play (no countdown)
    if (fullPlayer != null) {
      final fullTarget = _fullPositionFor(earlierPos);
      await fullPlayer!.seek(fullTarget);
      await fullPlayer!.play();
    }
  }

  /// Pause all players.
  Future<void> pauseBoth() async {
    await earlierPlayer.pause();
    await laterPlayer.pause();
    if (fullPlayer != null) {
      await fullPlayer!.pause();
    }
  }

  /// Seek to a position on the unified timeline.
  ///
  /// [earlierPos] is the unified timeline position (may exceed the earlier
  /// player's actual duration when the later video extends further).
  /// Each player's seek is clamped independently to its own duration.
  Future<void> seekToEarlierPosition(Duration earlierPos) async {
    if (earlierPos < Duration.zero) earlierPos = Duration.zero;

    _intendedEarlierPosition = earlierPos;

    // Clamp the earlier player's actual seek to its own duration
    final earlierDur = earlierPlayer.state.duration;
    var clampedEarlier = earlierPos;
    if (earlierDur > Duration.zero && clampedEarlier > earlierDur) {
      clampedEarlier = earlierDur;
    }

    final laterTarget = laterPositionFor(earlierPos, syncOffset);

    // Build parallel seek list
    final seeks = <Future<void>>[];

    if (laterTarget == null) {
      laterWaiting = true;
      countdownRemaining = syncOffset - earlierPos;
      // Seek earlier player while pausing+resetting later player in parallel
      seeks.add(earlierPlayer.seek(clampedEarlier));
      seeks.add(laterPlayer.pause().then((_) => laterPlayer.seek(Duration.zero)));
    } else {
      var clampedLater = laterTarget;
      final laterDur = laterPlayer.state.duration;
      if (laterDur > Duration.zero && clampedLater > laterDur) {
        clampedLater = laterDur;
      }
      laterWaiting = false;
      countdownRemaining = Duration.zero;
      seeks.add(earlierPlayer.seek(clampedEarlier));
      seeks.add(laterPlayer.seek(clampedLater));
    }

    // Full player: always seek to its derived position (no countdown)
    if (fullPlayer != null) {
      var fullTarget = _fullPositionFor(earlierPos);
      final fullDur = fullPlayer!.state.duration;
      if (fullDur > Duration.zero && fullTarget > fullDur) {
        fullTarget = fullDur;
      }
      seeks.add(fullPlayer!.seek(fullTarget));
    }

    await Future.wait(seeks);
  }

  /// Restart all players from the beginning.
  Future<void> restartBoth() async {
    await earlierPlayer.pause();
    await laterPlayer.pause();
    await earlierPlayer.seek(Duration.zero);
    await laterPlayer.seek(Duration.zero);

    if (fullPlayer != null) {
      await fullPlayer!.pause();
      await fullPlayer!.seek(Duration.zero);
    }

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
