import 'dart:math';

import '../util/constants.dart';

/// Non-linear scrub math and cancel-and-replace seek throttling.
///
/// The static [computeScrubOffsetMs] is a pure function for testability.
/// The instance methods manage seek throttling state for a live scrub session.
class ScrubController {
  bool _seekInFlight = false;
  Duration? _pendingPosition;

  /// Whether a seek is currently in progress.
  bool get seekInFlight => _seekInFlight;

  /// Computes the non-linear scrub offset in milliseconds from a horizontal
  /// drag delta.
  ///
  /// - [deltaX]: horizontal pixel distance from the initial touch point.
  ///   Positive = forward, negative = backward.
  /// - [paneWidth]: width of the video pane in pixels.
  /// - [exponent]: controls the non-linearity curve. Higher = more fine control
  ///   near the touch point, coarser at extremes.
  /// - [maxRangeMs]: maximum seek range in milliseconds at full deflection.
  /// - [deadZonePx]: minimum pixel movement before any scrub offset is produced.
  static int computeScrubOffsetMs(
    double deltaX,
    double paneWidth, {
    double exponent = AppConstants.defaultScrubExponent,
    int maxRangeMs = AppConstants.defaultScrubMaxRangeMs,
    double deadZonePx = AppConstants.scrubDeadZonePx,
  }) {
    if (paneWidth <= 0) return 0;

    final halfWidth = paneWidth / 2.0;
    final absDelta = deltaX.abs();

    if (absDelta < deadZonePx) return 0;

    final normalized = (absDelta / halfWidth).clamp(0.0, 1.0);
    final fraction = pow(normalized, exponent).toDouble();
    final offsetMs = deltaX.sign * fraction * maxRangeMs;
    return offsetMs.round();
  }

  /// Enqueue a seek position and dispatch if no seek is in flight.
  ///
  /// [seekFn] performs the actual seek (e.g., seeking both players).
  /// Uses cancel-and-replace: if a seek is already in flight, the new position
  /// replaces any previously pending position. When the in-flight seek
  /// completes, the latest pending position is dispatched.
  void enqueueSeek(Duration position, Future<void> Function(Duration) seekFn) {
    _pendingPosition = position;
    _dispatchSeek(seekFn);
  }

  void _dispatchSeek(Future<void> Function(Duration) seekFn) {
    if (_seekInFlight) return;
    final pos = _pendingPosition;
    if (pos == null) return;

    _pendingPosition = null;
    _seekInFlight = true;

    seekFn(pos).whenComplete(() {
      _seekInFlight = false;
      if (_pendingPosition != null) {
        _dispatchSeek(seekFn);
      }
    });
  }

  /// Reset throttling state (e.g., when scrub gesture ends).
  void reset() {
    _seekInFlight = false;
    _pendingPosition = null;
  }
}
