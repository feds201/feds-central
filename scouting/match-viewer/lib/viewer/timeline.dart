import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../data/models.dart';

/// Identifies a player by its role in a match (red phone, blue phone, full-field).
enum PlayerRole { red, blue, full }

/// Narrow interface that [Timeline] consumes from each underlying video source.
/// In production this is implemented by a [Player] adapter; tests provide
/// a fake implementation backed by [StreamController]s.
abstract class TimelineSource {
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get completedStream;
  Stream<int?> get widthStream;
  Stream<int?> get heightStream;

  bool get isPlaying;
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  void setVolume(double volume);
  void dispose();

  /// The video controller for rendering this source in a Flutter [Video]
  /// widget. Null in tests where rendering doesn't matter.
  VideoController? get controller;
}

/// The unified master clock for synchronized playback of 1, 2, or 3 video sources.
///
/// Every UI consumer of position/duration MUST go through this class. There is
/// no per-player position math anywhere outside [Timeline]'s own internals.
///
/// ## The unified timeline
///
/// All sources are placed on a single timeline whose origin is the earliest
/// recording start across all provided sources. Each source has a non-negative
/// `startOffset` (delay from origin). The unified duration is the union of all
/// source windows: `max over slots of (startOffset + duration)`.
///
/// In dual mode this gives three periods:
/// - **Period 1**: only the earliest source has frames
/// - **Period 2**: all sources are within their own windows
/// - **Period 3**: only the latest-ending source has frames
///
/// In single mode there is one slot at offset 0 — the unified position and
/// duration pass through to that one source.
///
/// ## Clock-slot handoff (the Period-3 fix)
///
/// `unifiedPosition` is computed from the active source(s) currently in their
/// windows. When the source driving the master clock ends, the next still-running
/// source takes over driving the clock and `unifiedPosition` continues advancing.
/// A monotonic floor prevents a sub-frame backwards glitch at the handoff.
class Timeline {
  final List<_Slot> _slots;

  /// True when the timeline as a whole is in "playing" mode. Independent of
  /// individual source `isPlaying` because per-source playing flips false
  /// naturally at end-of-video, but the timeline stays "playing" if another
  /// source is still running.
  bool _isPlaying = false;
  Duration _unifiedPosition = Duration.zero;
  Duration _unifiedDuration = Duration.zero;

  /// Set during a paused-scrub seek — overrides [unifiedPosition] until
  /// a real source position event arrives that matches it.
  Duration? _intendedUnifiedPosition;

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _dimensionsController = StreamController<PlayerRole>.broadcast();

  final List<StreamSubscription> _subs = [];

  Timeline._(this._slots) {
    _wireSubscriptions();
    _recomputeDuration();
  }

  /// Build a Timeline from whichever recordings + players are provided.
  /// Accepts 1, 2, or 3 sources uniformly. Real-app constructor.
  factory Timeline.fromRecordings({
    Recording? redRecording,
    Player? redPlayer,
    VideoController? redController,
    Recording? blueRecording,
    Player? bluePlayer,
    VideoController? blueController,
    Recording? fullRecording,
    Player? fullPlayer,
    VideoController? fullController,
  }) {
    final raw = <({PlayerRole role, Recording rec, TimelineSource source})>[];
    if (redRecording != null && redPlayer != null && redController != null) {
      raw.add((
        role: PlayerRole.red,
        rec: redRecording,
        source: _PlayerSource(redPlayer, redController),
      ));
    }
    if (blueRecording != null && bluePlayer != null && blueController != null) {
      raw.add((
        role: PlayerRole.blue,
        rec: blueRecording,
        source: _PlayerSource(bluePlayer, blueController),
      ));
    }
    if (fullRecording != null && fullPlayer != null && fullController != null) {
      raw.add((
        role: PlayerRole.full,
        rec: fullRecording,
        source: _PlayerSource(fullPlayer, fullController),
      ));
    }

    if (raw.isEmpty) {
      throw ArgumentError('Timeline requires at least one source');
    }

    final offsets = computeStartOffsets(
      raw.map((r) => r.rec.recordingStartTime).toList(),
    );

    final slots = [
      for (var i = 0; i < raw.length; i++)
        _Slot(
          role: raw[i].role,
          source: raw[i].source,
          startOffset: offsets[i],
        ),
    ];

    return Timeline._(slots);
  }

  /// Test-only constructor that accepts pre-built sources directly.
  /// Tests pass [TimelineSource] fakes with explicit start offsets so they
  /// can drive the streams and assert on Timeline's responses without needing
  /// a real media_kit [Player].
  factory Timeline.forTesting(
    List<({PlayerRole role, Duration startOffset, TimelineSource source})>
        sources,
  ) {
    if (sources.isEmpty) {
      throw ArgumentError('Timeline requires at least one source');
    }
    final slots = [
      for (final s in sources)
        _Slot(role: s.role, source: s.source, startOffset: s.startOffset),
    ];
    return Timeline._(slots);
  }

  // --- Master clock observables (the single source of truth) ---

  /// Current unified-timeline position. Never freezes: when one source ends,
  /// the next still-running source takes over driving the master clock.
  Duration get unifiedPosition => _intendedUnifiedPosition ?? _unifiedPosition;

  /// Total unified-timeline duration: union of all source windows.
  /// `max over slots of (startOffset + duration)`.
  Duration get unifiedDuration => _unifiedDuration;

  /// Fires whenever any source advances. Emits unified-timeline positions.
  Stream<Duration> get unifiedPositionStream => _positionController.stream;

  /// Fires whenever any source's duration becomes known and recomputes
  /// the unified duration.
  Stream<Duration> get unifiedDurationStream => _durationController.stream;

  bool get isPlaying => _isPlaying;
  Stream<bool> get isPlayingStream => _playingController.stream;

  // --- Coordinated commands ---

  /// Plays each slot whose unified-time window contains [unifiedPosition].
  /// Out-of-window slots stay paused; the position monitor will wake them
  /// when unified time crosses their start, and pause them when it exits
  /// their end.
  Future<void> play() async {
    _isPlaying = true;
    _playingController.add(true);
    final pos = unifiedPosition;
    await Future.wait(_slots.map((slot) async {
      if (_isInWindow(slot, pos)) {
        await slot.source.play();
      } else {
        await slot.source.pause();
      }
    }));
  }

  Future<void> pause() async {
    _isPlaying = false;
    _playingController.add(false);
    await Future.wait(_slots.map((s) => s.source.pause()));
  }

  Future<void> restart() async {
    await pause();
    await seek(Duration.zero);
    await play();
  }

  /// Seek every slot to its corresponding local position. Slots outside
  /// their window are paused and reset to their nearest boundary.
  Future<void> seek(Duration unified) async {
    if (unified < Duration.zero) unified = Duration.zero;
    if (_unifiedDuration > Duration.zero && unified > _unifiedDuration) {
      unified = _unifiedDuration;
    }

    _intendedUnifiedPosition = unified;
    _unifiedPosition = unified;
    _positionController.add(unified);

    await Future.wait(_slots.map((slot) async {
      final localTarget = unified - slot.startOffset;
      if (localTarget < Duration.zero) {
        // Unified is before this slot's window — pause + reset to start.
        await slot.source.pause();
        await slot.source.seek(Duration.zero);
      } else if (slot.duration > Duration.zero && localTarget > slot.duration) {
        // Unified is past this slot's window — pause + park at end.
        await slot.source.pause();
        await slot.source.seek(slot.duration);
      } else {
        // In window. Seek + (re)play if the timeline is currently playing.
        await slot.source.seek(localTarget);
        if (_isPlaying) {
          await slot.source.play();
        }
      }
    }));
  }

  // --- Per-player accessors (intentionally narrow — see CLAUDE.md plan §1.2) ---

  /// The video controller for [role], for rendering one pane. Null if
  /// no source for that role exists.
  VideoController? controllerFor(PlayerRole role) =>
      _slotFor(role)?.source.controller;

  /// Set the audio volume for [role]. Hides the underlying source.
  Future<void> setVolumeFor(PlayerRole role, double volume) async {
    _slotFor(role)?.source.setVolume(volume);
  }

  /// True if [role] exists but its source hasn't started yet at the
  /// current unified position (pre-start chrome).
  bool isWaitingFor(PlayerRole role) {
    final slot = _slotFor(role);
    if (slot == null) return false;
    return unifiedPosition < slot.startOffset;
  }

  /// True if [role] exists but its source has ended at the current unified
  /// position (post-end dimming chrome).
  bool hasEnded(PlayerRole role) {
    final slot = _slotFor(role);
    if (slot == null || slot.duration == Duration.zero) return false;
    return unifiedPosition > slot.startOffset + slot.duration;
  }

  /// How long ago [role]'s source ended, as positive [Duration]. Returns
  /// [Duration.zero] when not ended.
  Duration endedAgoFor(PlayerRole role) {
    final slot = _slotFor(role);
    if (slot == null || slot.duration == Duration.zero) return Duration.zero;
    final endAt = slot.startOffset + slot.duration;
    if (unifiedPosition <= endAt) return Duration.zero;
    return unifiedPosition - endAt;
  }

  /// How long until [role]'s source starts ("starts in X" overlay).
  /// Returns [Duration.zero] when [role] is not waiting.
  Duration countdownFor(PlayerRole role) {
    final slot = _slotFor(role);
    if (slot == null) return Duration.zero;
    final delta = slot.startOffset - unifiedPosition;
    return delta > Duration.zero ? delta : Duration.zero;
  }

  /// Native width (px) of [role]'s video, or null until the source reports it.
  int? widthFor(PlayerRole role) => _slotFor(role)?.width;

  /// Native height (px) of [role]'s video, or null until the source reports it.
  int? heightFor(PlayerRole role) => _slotFor(role)?.height;

  /// Fires the role when both width and height become known for that role
  /// (used by viewer auto-rotation logic).
  Stream<PlayerRole> get dimensionsStream => _dimensionsController.stream;

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    for (final slot in _slots) {
      slot.source.dispose();
    }
    _positionController.close();
    _durationController.close();
    _playingController.close();
    _dimensionsController.close();
  }

  // --- Static pure helpers (testable without a real media_kit Player) ---

  /// Given a list of recording start times (some may be null), compute the
  /// per-slot offset from the earliest known start. Sources with a null
  /// start are treated as starting at the earliest known time (offset 0).
  /// If all starts are null, every offset is zero.
  static List<Duration> computeStartOffsets(List<DateTime?> starts) {
    DateTime? earliest;
    for (final t in starts) {
      if (t != null && (earliest == null || t.isBefore(earliest))) {
        earliest = t;
      }
    }
    if (earliest == null) {
      return List.filled(starts.length, Duration.zero);
    }
    return [
      for (final t in starts)
        t == null ? Duration.zero : t.difference(earliest),
    ];
  }

  /// Given parallel lists of per-slot start offsets and durations, compute
  /// the unified-timeline total: max over slots of (offset + duration).
  static Duration computeUnifiedDuration(
    List<Duration> startOffsets,
    List<Duration> durations,
  ) {
    assert(startOffsets.length == durations.length);
    Duration max = Duration.zero;
    for (var i = 0; i < startOffsets.length; i++) {
      final end = startOffsets[i] + durations[i];
      if (end > max) max = end;
    }
    return max;
  }

  // --- Internal ---

  _Slot? _slotFor(PlayerRole role) {
    for (final s in _slots) {
      if (s.role == role) return s;
    }
    return null;
  }

  bool _isInWindow(_Slot slot, Duration unified) {
    if (unified < slot.startOffset) return false;
    if (slot.duration > Duration.zero &&
        unified > slot.startOffset + slot.duration) {
      return false;
    }
    return true;
  }

  void _wireSubscriptions() {
    for (final slot in _slots) {
      _subs.add(slot.source.durationStream.listen((dur) {
        slot.duration = dur;
        _recomputeDuration();
        _maybeWakeOrPark();
      }));
      _subs.add(slot.source.positionStream.listen((pos) {
        _onPlayerPosition(slot, pos);
      }));
      _subs.add(slot.source.completedStream.listen((completed) {
        if (completed) {
          // This slot finished. Park it; the next position event from any
          // still-running slot will drive the unified clock forward.
          slot.source.pause();
        }
      }));
      _subs.add(slot.source.widthStream.listen((w) {
        slot.width = w;
        if (slot.width != null && slot.height != null) {
          _dimensionsController.add(slot.role);
        }
      }));
      _subs.add(slot.source.heightStream.listen((h) {
        slot.height = h;
        if (slot.width != null && slot.height != null) {
          _dimensionsController.add(slot.role);
        }
      }));
    }
  }

  void _recomputeDuration() {
    Duration max = Duration.zero;
    for (final s in _slots) {
      final end = s.startOffset + s.duration;
      if (end > max) max = end;
    }
    if (max != _unifiedDuration) {
      _unifiedDuration = max;
      _durationController.add(max);
    }
  }

  void _onPlayerPosition(_Slot slot, Duration localPos) {
    final asUnified = slot.startOffset + localPos;

    // Clear the intended-position override once any source's position has
    // caught up to it (within a small tolerance, since position is sampled).
    if (_intendedUnifiedPosition != null) {
      final intended = _intendedUnifiedPosition!;
      if (_isInWindow(slot, intended)) {
        final intendedLocal = intended - slot.startOffset;
        if ((localPos - intendedLocal).abs() <
            const Duration(milliseconds: 250)) {
          _intendedUnifiedPosition = null;
        }
      }
    }

    if (_intendedUnifiedPosition == null) {
      // Only update the master clock from a slot whose window contains
      // its own position (otherwise we'd accept stale events from a source
      // parked at its end after a seek).
      if (_isInWindow(slot, asUnified)) {
        // Monotonic floor: only accept forward (or equal) movements. The
        // only legitimate backward jumps are real seeks, and those go
        // through `seek()` which sets `_intendedUnifiedPosition` first —
        // we wouldn't be in this branch in that case. So a backward event
        // here is always stale (ordering jitter, or a slot reporting an
        // old position after another slot already advanced unified).
        if (asUnified >= _unifiedPosition) {
          _unifiedPosition = asUnified;
          _positionController.add(asUnified);
        }
      }
    }

    _maybeWakeOrPark();
  }

  /// When the unified clock crosses a slot's start anchor, start that slot.
  /// When it exceeds a slot's end anchor, pause it.
  void _maybeWakeOrPark() {
    if (!_isPlaying) return;
    final pos = unifiedPosition;
    for (final slot in _slots) {
      final inWindow = _isInWindow(slot, pos);
      if (inWindow) {
        if (!slot.source.isPlaying) {
          final localTarget = pos - slot.startOffset;
          if (localTarget >= Duration.zero) {
            slot.source.seek(localTarget);
          }
          slot.source.play();
        }
      } else {
        if (slot.source.isPlaying) {
          slot.source.pause();
        }
      }
    }
  }
}

class _Slot {
  final PlayerRole role;
  final TimelineSource source;
  final Duration startOffset;
  Duration duration;
  int? width;
  int? height;

  _Slot({
    required this.role,
    required this.source,
    required this.startOffset,
    Duration? duration,
  }) : duration = duration ?? Duration.zero;
}

/// Production [TimelineSource] adapter wrapping a media_kit [Player] +
/// [VideoController] pair.
class _PlayerSource implements TimelineSource {
  final Player _player;
  final VideoController _controller;

  _PlayerSource(this._player, this._controller);

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get completedStream => _player.stream.completed;

  @override
  Stream<int?> get widthStream => _player.stream.width;

  @override
  Stream<int?> get heightStream => _player.stream.height;

  @override
  bool get isPlaying => _player.state.playing;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void setVolume(double volume) => _player.setVolume(volume);

  @override
  void dispose() => _player.dispose();

  @override
  VideoController? get controller => _controller;
}
