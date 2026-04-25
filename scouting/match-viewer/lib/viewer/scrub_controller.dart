import 'dart:async';
import 'dart:math';

import '../util/constants.dart';

/// Non-linear scrub math and seek throttling.
///
/// The static [computeScrubOffsetMs] is a pure function for testability.
/// The instance methods manage seek throttling state for a live scrub session.
///
/// Two throttling strategies are available:
/// - **Cancel-and-replace** ([enqueueSeek]): waits for each seek to complete
///   before dispatching the next. Good for scrub bar drags.
/// - **Coalescing timer** ([startCoalescing]/[updateDesiredPosition]):
///   fires seeks at a fixed interval (default 100ms / 10Hz) regardless of
///   decoder speed. Good for finger scrubbing where responsiveness matters.
class ScrubController {
  // --- Cancel-and-replace state ---
  bool _seekInFlight = false;
  Duration? _pendingPosition;

  // --- Coalescing timer state ---
  Timer? _coalescingTimer;
  Duration? _desiredPosition;
  Duration? _lastSeekedPosition;
  void Function(Duration)? _onCoalescingTick;

  /// Whether a seek is currently in progress (cancel-and-replace mode).
  bool get seekInFlight => _seekInFlight;

  /// Whether the coalescing timer is currently running.
  bool get isCoalescing => _coalescingTimer != null;

  /// The most recently stored desired position (for testing).
  Duration? get desiredPosition => _desiredPosition;

  /// The last position that was actually dispatched to a seek (for testing).
  Duration? get lastSeekedPosition => _lastSeekedPosition;

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
    double deadZonePx = AppConstants.touchDeadZonePx,
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

  // --- Cancel-and-replace throttling ---

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

  // --- Coalescing timer throttling ---

  /// Start the coalescing timer for finger scrubbing.
  ///
  /// [intervalMs] controls how often seeks are dispatched (default 100ms).
  /// [onTick] is called each interval with the latest desired position
  /// (only if it changed since the last tick). This callback should
  /// fire-and-forget a seek — do NOT await it.
  void startCoalescing({
    required int intervalMs,
    required void Function(Duration position) onTick,
  }) {
    stopCoalescing();
    _desiredPosition = null;
    _lastSeekedPosition = null;
    _onCoalescingTick = onTick;
    _coalescingTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      _handleCoalescingTick,
    );
  }

  /// Update the desired scrub position. Called on each scrub update event.
  /// The coalescing timer will pick up the latest value on its next tick.
  void updateDesiredPosition(Duration position) {
    _desiredPosition = position;
  }

  void _handleCoalescingTick(Timer timer) {
    final desired = _desiredPosition;
    if (desired == null) return;
    if (desired == _lastSeekedPosition) return;

    _lastSeekedPosition = desired;
    _onCoalescingTick?.call(desired);
  }

  /// Stop the coalescing timer and return the final desired position
  /// (if different from the last seeked position) for a final seek.
  Duration? stopCoalescing() {
    _coalescingTimer?.cancel();
    _coalescingTimer = null;
    _onCoalescingTick = null;

    final desired = _desiredPosition;
    final lastSeeked = _lastSeekedPosition;
    _desiredPosition = null;
    _lastSeekedPosition = null;

    // Return the final position if it differs from the last seek
    if (desired != null && desired != lastSeeked) {
      return desired;
    }
    return null;
  }

  /// Reset all throttling state (e.g., when scrub gesture ends).
  void reset() {
    _seekInFlight = false;
    _pendingPosition = null;
    stopCoalescing();
  }
}
