import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../util/constants.dart';

import '../viewer/drawing_controller.dart';
import '../viewer/scrub_controller.dart';
import '../viewer/sync_engine.dart';
import '../widgets/control_sidebar.dart';
import '../widgets/scrubber_bar.dart';
import '../widgets/stroke_painter.dart';
import '../widgets/video_pane.dart';

/// Full-screen landscape video viewer for match recordings.
///
/// Supports dual-video synchronized playback with touch scrubbing,
/// drawing overlay, and audio/view mode controls.
class VideoViewer extends StatefulWidget {
  final MatchWithVideos matchWithVideos;
  final DataStore dataStore;

  const VideoViewer({
    super.key,
    required this.matchWithVideos,
    required this.dataStore,
  });

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  // Players
  Player? _redPlayer;
  Player? _bluePlayer;
  Player? _fullPlayer;
  VideoController? _redController;
  VideoController? _blueController;
  VideoController? _fullController;

  // Sync
  SyncEngine? _syncEngine;

  // Convenience getters for what recordings exist
  bool get _hasRedBlue =>
      widget.matchWithVideos.redRecording != null &&
      widget.matchWithVideos.blueRecording != null;
  bool get _hasFull => widget.matchWithVideos.fullRecording != null;

  /// Ordered list of view modes available for this match's recordings.
  /// Priority: both > fullOnly > redOnly > blueOnly.
  List<ViewMode> get _availableViewModes {
    final modes = <ViewMode>[];
    if (_hasRedBlue) modes.add(ViewMode.both);
    if (_hasFull) modes.add(ViewMode.fullOnly);
    if (widget.matchWithVideos.redRecording != null) modes.add(ViewMode.redOnly);
    if (widget.matchWithVideos.blueRecording != null) modes.add(ViewMode.blueOnly);
    return modes;
  }

  /// Ordered list of mute states available for this match's recordings.
  List<MuteState> get _availableMuteStates {
    final states = [MuteState.muted];
    if (_hasFull) states.add(MuteState.fullAudio);
    if (widget.matchWithVideos.redRecording != null) states.add(MuteState.redAudio);
    if (widget.matchWithVideos.blueRecording != null) states.add(MuteState.blueAudio);
    return states;
  }

  // State
  MuteState _muteState = MuteState.muted;
  late ViewMode _viewMode;
  late bool _sidesSwapped;
  bool _isPlaying = false;
  DrawingColor? _drawingColor; // null while playing, red/blue while paused
  bool _isScrubBarDragging = false;
  bool _isFingerScrubbing = false;
  bool _wasPlayingBeforeScrub = false;
  Duration _scrubBasePosition = Duration.zero;

  // Per-pane rotation (quarter turns, 0-3)
  int _redQuarterTurns = 0;
  int _blueQuarterTurns = 0;
  int _fullQuarterTurns = 0;
  bool _redManuallyRotated = false;
  bool _blueManuallyRotated = false;
  bool _fullManuallyRotated = false;

  // Position tracking
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _laterWaiting = false;
  Duration _countdownRemaining = Duration.zero;

  // Single drawing controller — strokes are in screen space, not per-pane
  final _drawingController = DrawingController();

  // Zoom controllers (one per video source)
  final _redZoomController = TransformationController();
  final _blueZoomController = TransformationController();
  final _fullZoomController = TransformationController();

  // Unified pointer tracking for the top-level Listener
  final Set<int> _activePointers = {}; // all pointers currently down
  int? _primaryPointer; // pointer ID for 1-finger scrub or draw
  bool _primaryPointerIsScrub = false; // true = scrub, false = draw
  bool _multiTouchDetected = false; // true once 2+ fingers detected
  double? _scrubStartX; // initial X for scrub delta calculation

  // Gesture layer width (full video area) for scrub calculations
  double _gestureLayerWidth = 1.0;

  // Global keys for pane positions (used for chrome overlay)
  final _leftPaneKey = GlobalKey();
  final _rightPaneKey = GlobalKey();
  final _singlePaneKey = GlobalKey();

  final _scrubController = ScrubController();

  // Subscriptions
  final _subscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _sidesSwapped = widget.dataStore.settings.sidesSwapped;
    // Default to the highest-priority available view mode
    _viewMode = _availableViewModes.first;
    _lockLandscape();
    _drawingController.addListener(_onDrawingChanged);
    _initPlayers();
  }

  void _onDrawingChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
  }

  Future<void> _initPlayers() async {
    final redRec = widget.matchWithVideos.redRecording;
    final blueRec = widget.matchWithVideos.blueRecording;
    final fullRec = widget.matchWithVideos.fullRecording;

    if (redRec != null) {
      _redPlayer = Player();
      _redController = VideoController(_redPlayer!);
      final path = await _getVideoPath(redRec);
      await _redPlayer!.open(Media(path), play: false);
      _redPlayer!.setVolume(0);
    }

    if (blueRec != null) {
      _bluePlayer = Player();
      _blueController = VideoController(_bluePlayer!);
      final path = await _getVideoPath(blueRec);
      await _bluePlayer!.open(Media(path), play: false);
      _bluePlayer!.setVolume(0);
    }

    if (fullRec != null) {
      _fullPlayer = Player();
      _fullController = VideoController(_fullPlayer!);
      final path = await _getVideoPath(fullRec);
      await _fullPlayer!.open(Media(path), play: false);
      _fullPlayer!.setVolume(0);
    }

    // Set up sync engine whenever red+blue exist; optionally include full player.
    if (_hasRedBlue && _redPlayer != null && _bluePlayer != null) {
      _syncEngine = SyncEngine.fromRecordings(
        redRecording: redRec!,
        blueRecording: blueRec!,
        redPlayer: _redPlayer!,
        bluePlayer: _bluePlayer!,
        fullRecording: fullRec,
        fullPlayer: _fullPlayer,
      );
      _syncEngine!.startPositionMonitoring(() {
        if (mounted) {
          setState(() {
            _laterWaiting = _syncEngine!.laterWaiting;
            _countdownRemaining = _syncEngine!.countdownRemaining;
          });
        }
      });
      _laterWaiting = _syncEngine!.laterWaiting;
      _countdownRemaining = _syncEngine!.countdownRemaining;
    }

    // Auto-rotate videos so the wider dimension is vertical.
    // In landscape mode, we want phone videos (typically taller than wide)
    // to display naturally, and landscape videos rotated so wider=vertical.
    _autoRotatePlayer(_redPlayer, isRed: true, isFull: false);
    _autoRotatePlayer(_bluePlayer, isRed: false, isFull: false);
    _autoRotatePlayer(_fullPlayer, isRed: false, isFull: true);

    // Subscribe to position/duration streams from the primary player
    // (must subscribe before autoplay so we catch the playing state)
    final primaryPlayer =
        _syncEngine?.earlierPlayer ?? _redPlayer ?? _bluePlayer ?? _fullPlayer;
    if (primaryPlayer != null) {
      _subscriptions.add(
        primaryPlayer.stream.position.listen((pos) {
          if (mounted && !_isScrubBarDragging && !_isFingerScrubbing) {
            setState(() => _position = pos);
            _syncEngine?.updateIntendedPosition(pos);
          }
        }),
      );
      _subscriptions.add(
        primaryPlayer.stream.duration.listen((dur) {
          if (mounted) {
            setState(() {
              _duration = _syncEngine?.unifiedDuration ?? dur;
            });
          }
        }),
      );
      // When sync engine exists, also subscribe to the later player's duration
      // so we recompute the unified timeline when either duration becomes known.
      if (_syncEngine != null) {
        _subscriptions.add(
          _syncEngine!.laterPlayer.stream.duration.listen((dur) {
            if (mounted) {
              final unified = _syncEngine?.unifiedDuration;
              if (unified != null) {
                setState(() => _duration = unified);
              }
            }
          }),
        );
      }
      _subscriptions.add(
        primaryPlayer.stream.playing.listen((playing) {
          if (mounted) {
            setState(() {
              _isPlaying = playing;
              _drawingController.setOpacity(playing ? 0.3 : 1.0);
              // Auto-enable drawing on pause, disable on play
              if (!playing) {
                _drawingColor ??= DrawingColor.red;
                _drawingController.setColor(_drawingColor!);
              }
            });
          }
        }),
      );
    }

    // Autoplay: start playback after initialization
    if (_syncEngine != null) {
      await _syncEngine!.startSyncedPlayback();
    } else {
      final player = _redPlayer ?? _bluePlayer ?? _fullPlayer;
      await player?.play();
    }

    if (mounted) setState(() {});
  }

  Future<String> _getVideoPath(Recording recording) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${AppConstants.recordingsDirName}/${recording.id}${recording.fileExtension}';
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _syncEngine?.dispose();
    _redPlayer?.dispose();
    _bluePlayer?.dispose();
    _fullPlayer?.dispose();
    _drawingController.removeListener(_onDrawingChanged);
    _drawingController.dispose();
    _redZoomController.dispose();
    _blueZoomController.dispose();
    _fullZoomController.dispose();

    // Restore orientation and UI
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();

    super.dispose();
  }

  // --- Audio ---

  void _toggleMute() {
    final available = _availableMuteStates;
    final currentIndex = available.indexOf(_muteState);
    final nextIndex = (currentIndex + 1) % available.length;
    setState(() => _muteState = available[nextIndex]);
    _applyMuteState();
  }

  void _applyMuteState() {
    // Red/blue follows the logical alliance, not the visual position.
    // Swapping sides swaps visual position but audio follows the alliance.
    final redPlayer = _syncEngine?.redPlayer ?? _redPlayer;
    final bluePlayer = _syncEngine?.bluePlayer ?? _bluePlayer;

    switch (_muteState) {
      case MuteState.muted:
        redPlayer?.setVolume(0);
        bluePlayer?.setVolume(0);
        _fullPlayer?.setVolume(0);
      case MuteState.redAudio:
        redPlayer?.setVolume(100);
        bluePlayer?.setVolume(0);
        _fullPlayer?.setVolume(0);
      case MuteState.blueAudio:
        redPlayer?.setVolume(0);
        bluePlayer?.setVolume(100);
        _fullPlayer?.setVolume(0);
      case MuteState.fullAudio:
        redPlayer?.setVolume(0);
        bluePlayer?.setVolume(0);
        _fullPlayer?.setVolume(100);
    }
  }

  // --- View Mode ---

  void _toggleViewMode() {
    final available = _availableViewModes;
    if (available.length <= 1) return;
    final currentIndex = available.indexOf(_viewMode);
    final nextIndex = (currentIndex + 1) % available.length;
    final oldMode = _viewMode;
    setState(() => _viewMode = available[nextIndex]);
    debugPrint('[VIDEO_DEBUG] View mode: $oldMode → $_viewMode '
        '(redManual=$_redManuallyRotated, blueManual=$_blueManuallyRotated)');
    // Reset zoom when switching view modes
    _redZoomController.value = Matrix4.identity();
    _blueZoomController.value = Matrix4.identity();
    _fullZoomController.value = Matrix4.identity();
    _updateAutoRotation();
  }

  // --- Playback ---

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      if (_syncEngine != null) {
        await _syncEngine!.pauseBoth();
      } else {
        final player = _redPlayer ?? _bluePlayer ?? _fullPlayer;
        await player?.pause();
      }
    } else {
      if (_syncEngine != null) {
        await _syncEngine!.startSyncedPlayback();
      } else {
        final player = _redPlayer ?? _bluePlayer ?? _fullPlayer;
        await player?.play();
      }
    }
  }

  Future<void> _rewind10() async {
    final newPos = _position - const Duration(seconds: 10);
    await _seekTo(newPos);
  }

  Future<void> _forward10() async {
    final newPos = _position + const Duration(seconds: 10);
    await _seekTo(newPos);
  }

  Future<void> _restart() async {
    final wasPlaying = _isPlaying;
    if (_syncEngine != null) {
      await _syncEngine!.restartBoth();
      setState(() {
        _position = Duration.zero;
        _laterWaiting = _syncEngine!.laterWaiting;
        _countdownRemaining = _syncEngine!.countdownRemaining;
      });
      if (wasPlaying) {
        await _syncEngine!.startSyncedPlayback();
      }
    } else {
      final player = _redPlayer ?? _bluePlayer ?? _fullPlayer;
      await player?.pause();
      await player?.seek(Duration.zero);
      setState(() => _position = Duration.zero);
      if (wasPlaying) {
        await player?.play();
      }
    }
  }

  Future<void> _seekTo(Duration target) async {
    if (target < Duration.zero) target = Duration.zero;
    if (_duration > Duration.zero && target > _duration) target = _duration;

    if (_syncEngine != null) {
      await _syncEngine!.seekToEarlierPosition(target);
      setState(() {
        _position = target;
        _laterWaiting = _syncEngine!.laterWaiting;
        _countdownRemaining = _syncEngine!.countdownRemaining;
      });
    } else {
      final player = _redPlayer ?? _bluePlayer ?? _fullPlayer;
      await player?.seek(target);
      setState(() => _position = target);
    }
  }

  // --- Unified Pointer Handling (Scrub + Draw) ---

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);

    if (_activePointers.length == 1) {
      // First finger — start scrub or draw
      _primaryPointer = event.pointer;

      if (_isPlaying) {
        // 1-finger while playing = scrub
        _primaryPointerIsScrub = true;
        _scrubStartX = event.position.dx;
        _wasPlayingBeforeScrub = true;
        _isFingerScrubbing = true;
        _scrubBasePosition = _syncEngine?.intendedEarlierPosition ?? _position;

        // Pause players for scrub (playback suspended, not a user pause)
        if (_syncEngine != null) {
          _syncEngine!.pauseBoth();
        } else {
          (_redPlayer ?? _bluePlayer ?? _fullPlayer)?.pause();
        }

        // Start coalescing timer for smooth finger scrubbing
        _scrubController.startCoalescing(
          intervalMs: widget.dataStore.settings.scrubCoalescingIntervalMs,
          onTick: _onScrubCoalescingTick,
        );
      } else {
        // 1-finger while paused = draw
        _primaryPointerIsScrub = false;
        if (_drawingColor == null) return;
        _drawingController.onPointerDown(event.position);
      }
    } else if (!_multiTouchDetected) {
      // 2nd+ finger arrived — cancel the 1-finger action
      _multiTouchDetected = true;
      _cancelPrimaryPointerAction();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _primaryPointer) return;

    if (_primaryPointerIsScrub) {
      // Scrub: compute offset using full gesture layer width
      if (_scrubStartX == null) return;
      final deltaX = event.position.dx - _scrubStartX!;
      final offsetMs = ScrubController.computeScrubOffsetMs(
        deltaX,
        _gestureLayerWidth,
        exponent: widget.dataStore.settings.scrubExponent,
        maxRangeMs: widget.dataStore.settings.scrubMaxRangeMs,
      );

      final baseMs = _scrubBasePosition.inMilliseconds;
      final targetMs = (baseMs + offsetMs).clamp(0, _duration.inMilliseconds);
      final target = Duration(milliseconds: targetMs);

      // Update UI immediately for responsiveness
      setState(() => _position = target);

      // Store desired position — coalescing timer will dispatch the seek
      _scrubController.updateDesiredPosition(target);
    } else {
      // Draw: continue stroke
      if (_drawingColor == null) return;
      _drawingController.onPointerMove(event.position);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    if (_multiTouchDetected) {
      // Multi-touch gesture — skip all scrub/draw finalization.
      // Reset when all fingers are lifted.
      if (_activePointers.isEmpty) {
        _multiTouchDetected = false;
      }
      return;
    }

    if (event.pointer != _primaryPointer) return;

    if (_primaryPointerIsScrub) {
      _isFingerScrubbing = false;

      // Stop coalescing timer and do a final seek if needed
      final finalPosition = _scrubController.stopCoalescing();
      if (finalPosition != null) {
        _onScrubCoalescingTick(finalPosition);
      }

      _scrubController.reset();
      _scrubStartX = null;

      if (_wasPlayingBeforeScrub) {
        _wasPlayingBeforeScrub = false;
        _togglePlayPause();
      }
    } else {
      // Finalize drawing stroke
      _drawingController.onPointerUp();
    }

    _primaryPointer = null;
  }

  /// Cancel the in-progress 1-finger action (scrub or draw) because
  /// a 2nd finger was detected, indicating a zoom/pan gesture.
  void _cancelPrimaryPointerAction() {
    if (_primaryPointer == null) return;

    if (_primaryPointerIsScrub) {
      // Cancel scrub: stop coalescing, clear scrub state, resume playback
      _isFingerScrubbing = false;
      _scrubController.stopCoalescing();
      _scrubController.reset();
      _scrubStartX = null;

      // Resume playback since the user intended to zoom while playing
      if (_wasPlayingBeforeScrub) {
        _wasPlayingBeforeScrub = false;
        if (_syncEngine != null) {
          _syncEngine!.startSyncedPlayback();
        } else {
          (_redPlayer ?? _bluePlayer ?? _fullPlayer)?.play();
        }
      }
    } else {
      // Cancel draw: discard in-progress stroke
      _drawingController.cancelStroke();
    }

    _primaryPointer = null;
  }

  /// Called by the coalescing timer at fixed intervals.
  /// Fire-and-forget seek — do not await.
  void _onScrubCoalescingTick(Duration position) {
    if (_syncEngine != null) {
      _syncEngine!.seekToEarlierPosition(position);
      if (mounted) {
        setState(() {
          _laterWaiting = _syncEngine!.laterWaiting;
          _countdownRemaining = _syncEngine!.countdownRemaining;
        });
      }
    } else {
      (_redPlayer ?? _bluePlayer ?? _fullPlayer)?.seek(position);
    }
  }

  // --- Drawing ---

  void _cycleDrawingColor() {
    setState(() {
      // Cycle: red → blue → red → blue (no "off" state)
      switch (_drawingColor) {
        case null:
        case DrawingColor.blue:
          _drawingColor = DrawingColor.red;
        case DrawingColor.red:
          _drawingColor = DrawingColor.blue;
      }
      _drawingController.setColor(_drawingColor!);
    });
  }

  // --- Rotation ---

  void _rotatePane({bool? isRed, bool isFull = false}) {
    setState(() {
      if (isFull) {
        _fullQuarterTurns = (_fullQuarterTurns + 1) % 4;
        _fullManuallyRotated = true;
        debugPrint('[VIDEO_DEBUG] FULL manual rotate → quarterTurns=$_fullQuarterTurns');
      } else if (isRed == true) {
        _redQuarterTurns = (_redQuarterTurns + 1) % 4;
        _redManuallyRotated = true;
        debugPrint('[VIDEO_DEBUG] RED manual rotate → quarterTurns=$_redQuarterTurns');
      } else {
        _blueQuarterTurns = (_blueQuarterTurns + 1) % 4;
        _blueManuallyRotated = true;
        debugPrint('[VIDEO_DEBUG] BLUE manual rotate → quarterTurns=$_blueQuarterTurns');
      }
    });
  }

  // --- Swap ---

  void _swapSides() {
    setState(() => _sidesSwapped = !_sidesSwapped);
    widget.dataStore.updateSettings(
      widget.dataStore.settings.copyWith(sidesSwapped: _sidesSwapped),
    );
  }

  // --- Edit Metadata ---

  void _openEditMetadata() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _EditMetadataSheet(
        matchWithVideos: widget.matchWithVideos,
        dataStore: widget.dataStore,
        activeViewMode: _viewMode,
      ),
    );
  }

  // --- Auto-rotation ---

  // Cached video dimensions for recomputing rotation on view mode change
  int? _redVideoWidth, _redVideoHeight;
  int? _blueVideoWidth, _blueVideoHeight;
  int? _fullVideoWidth, _fullVideoHeight;

  /// Auto-rotate a video pane based on its native dimensions.
  /// Listens to the player's width stream (fires when video opens).
  void _autoRotatePlayer(Player? player, {required bool isRed, bool isFull = false}) {
    if (player == null) return;
    final tag = isFull ? 'FULL' : (isRed ? 'RED' : 'BLUE');
    _subscriptions.add(
      player.stream.width.listen((width) {
        final height = player.state.height;
        if (width != null && height != null && width > 0 && height > 0) {
          debugPrint('[VIDEO_DEBUG] $tag media_kit reports: ${width}x$height '
              '(${width > height ? "landscape" : "portrait"})');
          if (isFull) {
            _fullVideoWidth = width;
            _fullVideoHeight = height;
          } else if (isRed) {
            _redVideoWidth = width;
            _redVideoHeight = height;
          } else {
            _blueVideoWidth = width;
            _blueVideoHeight = height;
          }
          _updateAutoRotation();
        }
      }),
    );
  }

  /// Recomputes auto-rotation for all panes based on current view mode.
  /// In dual mode: wider dimension should be vertical (panes are tall/narrow).
  /// In single mode: wider dimension should be horizontal (fill landscape screen).
  /// Skips panes that the user has manually rotated.
  void _updateAutoRotation() {
    setState(() {
      final isSingleMode = _viewMode != ViewMode.both;
      debugPrint('[VIDEO_DEBUG] _updateAutoRotation: viewMode=$_viewMode, isSingleMode=$isSingleMode');

      if (!_redManuallyRotated &&
          _redVideoWidth != null &&
          _redVideoHeight != null) {
        final isLandscapeVideo = _redVideoWidth! > _redVideoHeight!;
        final oldTurns = _redQuarterTurns;
        if (isSingleMode) {
          _redQuarterTurns = isLandscapeVideo ? 0 : 1;
        } else {
          _redQuarterTurns = isLandscapeVideo ? 1 : 0;
        }
        debugPrint('[VIDEO_DEBUG] RED auto-rotate: ${_redVideoWidth}x$_redVideoHeight '
            'isLandscape=$isLandscapeVideo → quarterTurns=$_redQuarterTurns (was $oldTurns)');
      } else if (_redManuallyRotated) {
        debugPrint('[VIDEO_DEBUG] RED skipped (manually rotated), quarterTurns=$_redQuarterTurns');
      }

      if (!_blueManuallyRotated &&
          _blueVideoWidth != null &&
          _blueVideoHeight != null) {
        final isLandscapeVideo = _blueVideoWidth! > _blueVideoHeight!;
        final oldTurns = _blueQuarterTurns;
        if (isSingleMode) {
          _blueQuarterTurns = isLandscapeVideo ? 0 : 1;
        } else {
          _blueQuarterTurns = isLandscapeVideo ? 1 : 0;
        }
        debugPrint('[VIDEO_DEBUG] BLUE auto-rotate: ${_blueVideoWidth}x$_blueVideoHeight '
            'isLandscape=$isLandscapeVideo → quarterTurns=$_blueQuarterTurns (was $oldTurns)');
      } else if (_blueManuallyRotated) {
        debugPrint('[VIDEO_DEBUG] BLUE skipped (manually rotated), quarterTurns=$_blueQuarterTurns');
      }

      // Full player is always displayed full-screen (single mode)
      if (!_fullManuallyRotated &&
          _fullVideoWidth != null &&
          _fullVideoHeight != null) {
        final isLandscapeVideo = _fullVideoWidth! > _fullVideoHeight!;
        final oldTurns = _fullQuarterTurns;
        _fullQuarterTurns = isLandscapeVideo ? 0 : 1;
        debugPrint('[VIDEO_DEBUG] FULL auto-rotate: ${_fullVideoWidth}x$_fullVideoHeight '
            'isLandscape=$isLandscapeVideo → quarterTurns=$_fullQuarterTurns (was $oldTurns)');
      }
    });
  }

  // --- Helpers ---

  bool _containsUserTeam(Recording? recording) {
    final teamNum = widget.dataStore.settings.teamNumber;
    if (teamNum == null || recording == null) return false;
    return recording.team1 == teamNum ||
        recording.team2 == teamNum ||
        recording.team3 == teamNum ||
        recording.team4 == teamNum ||
        recording.team5 == teamNum ||
        recording.team6 == teamNum;
  }

  bool _isRedWaiting() {
    if (_syncEngine == null) return false;
    return _syncEngine!.isLaterSide('red') && _laterWaiting;
  }

  bool _isBlueWaiting() {
    if (_syncEngine == null) return false;
    return _syncEngine!.isLaterSide('blue') && _laterWaiting;
  }

  /// Whether the red pane's video has ended at the current position.
  bool _isRedEnded() {
    if (_syncEngine == null) return false;
    final redDur = _syncEngine!.redPlayer.state.duration;
    if (redDur == Duration.zero) return false;
    if (_syncEngine!.earlierIsRed) {
      // Red is earlier — ended when position exceeds red's duration
      return _position > redDur;
    } else {
      // Red is later — derive red's local position and check against its duration
      final redPos = SyncEngine.laterPositionFor(_position, _syncEngine!.syncOffset);
      if (redPos == null) return false; // red hasn't started yet
      return redPos > redDur;
    }
  }

  /// Whether the blue pane's video has ended at the current position.
  bool _isBlueEnded() {
    if (_syncEngine == null) return false;
    final blueDur = _syncEngine!.bluePlayer.state.duration;
    if (blueDur == Duration.zero) return false;
    if (!_syncEngine!.earlierIsRed) {
      // Blue is earlier — ended when position exceeds blue's duration
      return _position > blueDur;
    } else {
      // Blue is later — derive blue's local position and check against its duration
      final bluePos = SyncEngine.laterPositionFor(_position, _syncEngine!.syncOffset);
      if (bluePos == null) return false; // blue hasn't started yet
      return bluePos > blueDur;
    }
  }

  /// How long ago the red video ended (only meaningful when _isRedEnded()).
  Duration _redEndedAgo() {
    if (_syncEngine == null) return Duration.zero;
    final redDur = _syncEngine!.redPlayer.state.duration;
    if (_syncEngine!.earlierIsRed) {
      return _position - redDur;
    } else {
      final redPos = SyncEngine.laterPositionFor(_position, _syncEngine!.syncOffset);
      if (redPos == null) return Duration.zero;
      return redPos - redDur;
    }
  }

  /// How long ago the blue video ended (only meaningful when _isBlueEnded()).
  Duration _blueEndedAgo() {
    if (_syncEngine == null) return Duration.zero;
    final blueDur = _syncEngine!.bluePlayer.state.duration;
    if (!_syncEngine!.earlierIsRed) {
      return _position - blueDur;
    } else {
      final bluePos = SyncEngine.laterPositionFor(_position, _syncEngine!.syncOffset);
      if (bluePos == null) return Duration.zero;
      return bluePos - blueDur;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // Video area with unified gesture handling
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _gestureLayerWidth = constraints.maxWidth;
                  return Listener(
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    behavior: HitTestBehavior.translucent,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildVideoLayout()),
                        Positioned.fill(child: _buildDrawingLayer()),
                        Positioned.fill(child: _buildChromeOverlay()),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Vertical scrub bar between video and controls
            ScrubberBar(
              position: _position,
              duration: _duration,
              isDragging: _isScrubBarDragging,
              onSeek: _seekTo,
              onDragStateChanged: (dragging) {
                setState(() => _isScrubBarDragging = dragging);
              },
            ),
            ControlSidebar(
              isPlaying: _isPlaying,
              muteState: _muteState,
              viewMode: _viewMode,
              drawingColor: _drawingColor,
              canUndo: _drawingController.canUndo,
              canRedo: _drawingController.canRedo,
              hasDrawings: _drawingController.hasNonEmptyStrokes,
              canToggleViewMode: _availableViewModes.length > 1,
              isPaused: !_isPlaying,
              onBack: () => Navigator.of(context).pop(),
              onSwapSides: _swapSides,
              onToggleMute: _toggleMute,
              onToggleViewMode: _toggleViewMode,
              onPlayPause: _togglePlayPause,
              onRewind10: _rewind10,
              onForward10: _forward10,
              onRestart: _restart,
              onToggleDrawing: _cycleDrawingColor,
              onUndo: _drawingController.undo,
              onRedo: _drawingController.redo,
              onClearDrawing: _drawingController.clear,
            ),
          ],
        ),
      ),
    );
  }

  // --- Video Layout (inside InteractiveViewer, subject to zoom/rotate) ---

  Widget _buildVideoLayout() {
    final redRec = widget.matchWithVideos.redRecording;
    final blueRec = widget.matchWithVideos.blueRecording;
    final fullRec = widget.matchWithVideos.fullRecording;

    // Full-only mode
    if (_viewMode == ViewMode.fullOnly) {
      if (_fullPlayer == null || _fullController == null) {
        return const Center(
          child: Text(
            'No video available',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }
      return _buildZoomablePane(
        paneKey: _singlePaneKey,
        zoomController: _fullZoomController,

        player: _fullPlayer!,
        videoController: _fullController!,
        quarterTurns: _fullQuarterTurns,
        fit: BoxFit.contain,
      );
    }

    // Single red/blue mode
    if (_viewMode != ViewMode.both) {
      Player? player;
      VideoController? controller;
      bool isRed = true;

      if (_viewMode == ViewMode.redOnly || (redRec != null && blueRec == null)) {
        player = _redPlayer;
        controller = _redController;
        isRed = true;
      } else {
        player = _bluePlayer;
        controller = _blueController;
        isRed = false;
      }

      if (player == null || controller == null) {
        return const Center(
          child: Text(
            'No video available',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }

      return _buildZoomablePane(
        paneKey: _singlePaneKey,
        zoomController: isRed ? _redZoomController : _blueZoomController,

        player: player,
        videoController: controller,
        quarterTurns: isRed ? _redQuarterTurns : _blueQuarterTurns,
        fit: BoxFit.contain,
      );
    }

    // Dual video mode — red on left, blue on right (or swapped)
    if (_redPlayer == null || _bluePlayer == null ||
        _redController == null || _blueController == null) {
      return const Center(
        child: Text('Loading...', style: TextStyle(color: Colors.white54)),
      );
    }
    final leftPlayer = _sidesSwapped ? _bluePlayer! : _redPlayer!;
    final rightPlayer = _sidesSwapped ? _redPlayer! : _bluePlayer!;
    final leftController = _sidesSwapped ? _blueController! : _redController!;
    final rightController = _sidesSwapped ? _redController! : _blueController!;
    final leftIsRed = !_sidesSwapped;
    final rightIsRed = _sidesSwapped;

    return Row(
      children: [
        Expanded(
          child: _buildZoomablePane(
            paneKey: _leftPaneKey,
            zoomController: leftIsRed ? _redZoomController : _blueZoomController,

            player: leftPlayer,
            videoController: leftController,
            quarterTurns: leftIsRed ? _redQuarterTurns : _blueQuarterTurns,
            fit: BoxFit.fitWidth,
          ),
        ),
        Expanded(
          child: _buildZoomablePane(
            paneKey: _rightPaneKey,
            zoomController: rightIsRed ? _redZoomController : _blueZoomController,

            player: rightPlayer,
            videoController: rightController,
            quarterTurns: rightIsRed ? _redQuarterTurns : _blueQuarterTurns,
            fit: BoxFit.fitWidth,
          ),
        ),
      ],
    );
  }

  /// Wraps a video pane in InteractiveViewer → RotatedBox → VideoPane.
  /// Drawing is handled by a separate screen-space layer (see _buildDrawingLayer).
  /// Chrome is rendered separately in _buildChromeOverlay.
  Widget _buildZoomablePane({
    required GlobalKey paneKey,
    required TransformationController zoomController,
    required Player player,
    required VideoController videoController,
    required int quarterTurns,
    required BoxFit fit,
  }) {
    return InteractiveViewer(
      key: paneKey,
      transformationController: zoomController,
      panEnabled: false,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 5.0,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: VideoPane(
          player: player,
          videoController: videoController,
          fit: fit,
        ),
      ),
    );
  }

  // --- Chrome Overlay (outside InteractiveViewer, never zooms/rotates) ---

  // --- Drawing Layer (screen-space, never zooms/rotates) ---

  Widget _buildDrawingLayer() {
    return IgnorePointer(
      ignoring: true,
      child: ListenableBuilder(
        listenable: _drawingController,
        builder: (context, _) {
          return CustomPaint(
            painter: StrokePainter(
              strokes: _drawingController.strokes,
              currentStrokePoints: _drawingController.currentStrokePoints,
              currentColor: _drawingController.currentColor,
              opacity: _drawingController.opacity,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  // --- Chrome Overlay (outside InteractiveViewer, never zooms/rotates) ---

  Widget _buildChromeOverlay() {
    final children = <Widget>[];

    if (_viewMode == ViewMode.both) {
      final leftIsRed = !_sidesSwapped;
      final rightIsRed = _sidesSwapped;
      final leftColor = _sidesSwapped ? AppColors.blueAlliance : AppColors.redAlliance;
      final rightColor = _sidesSwapped ? AppColors.redAlliance : AppColors.blueAlliance;
      final leftRec = _sidesSwapped
          ? widget.matchWithVideos.blueRecording
          : widget.matchWithVideos.redRecording;
      final rightRec = _sidesSwapped
          ? widget.matchWithVideos.redRecording
          : widget.matchWithVideos.blueRecording;
      final leftWaiting = _sidesSwapped ? _isBlueWaiting() : _isRedWaiting();
      final rightWaiting = _sidesSwapped ? _isRedWaiting() : _isBlueWaiting();
      final leftEnded = _sidesSwapped ? _isBlueEnded() : _isRedEnded();
      final rightEnded = _sidesSwapped ? _isRedEnded() : _isBlueEnded();
      final leftEndedAgo = _sidesSwapped ? _blueEndedAgo() : _redEndedAgo();
      final rightEndedAgo = _sidesSwapped ? _redEndedAgo() : _blueEndedAgo();

      children.add(_buildPaneChrome(
        paneKey: _leftPaneKey,
        allianceColor: leftColor,
        containsUserTeam: _containsUserTeam(leftRec),
        onRotate: () => _rotatePane(isRed: leftIsRed),
        onEdit: _openEditMetadata,
        isWaiting: leftWaiting,
        countdownRemaining: _countdownRemaining,
        hasEnded: leftEnded,
        endedAgo: leftEndedAgo,
      ));
      children.add(_buildPaneChrome(
        paneKey: _rightPaneKey,
        allianceColor: rightColor,
        containsUserTeam: _containsUserTeam(rightRec),
        onRotate: () => _rotatePane(isRed: rightIsRed),
        onEdit: _openEditMetadata,
        isWaiting: rightWaiting,
        countdownRemaining: _countdownRemaining,
        hasEnded: rightEnded,
        endedAgo: rightEndedAgo,
      ));
    } else if (_viewMode == ViewMode.fullOnly) {
      children.add(_buildPaneChrome(
        paneKey: _singlePaneKey,
        allianceColor: AppColors.fullAlliance,
        containsUserTeam: _containsUserTeam(widget.matchWithVideos.fullRecording),
        onRotate: () => _rotatePane(isFull: true),
        onEdit: _openEditMetadata,
      ));
    } else {
      final isRed = _viewMode == ViewMode.redOnly;
      final color = isRed ? AppColors.redAlliance : AppColors.blueAlliance;
      final recording = isRed
          ? widget.matchWithVideos.redRecording
          : widget.matchWithVideos.blueRecording;
      final isWaiting = isRed ? _isRedWaiting() : _isBlueWaiting();
      final isEnded = isRed ? _isRedEnded() : _isBlueEnded();
      final endedAgo = isRed ? _redEndedAgo() : _blueEndedAgo();
      children.add(_buildPaneChrome(
        paneKey: _singlePaneKey,
        allianceColor: color,
        containsUserTeam: _containsUserTeam(recording),
        onRotate: () => _rotatePane(isRed: isRed),
        onEdit: _openEditMetadata,
        isWaiting: isWaiting,
        countdownRemaining: _countdownRemaining,
        hasEnded: isEnded,
        endedAgo: endedAgo,
      ));
    }

    return Stack(children: children);
  }

  /// Builds chrome elements (alliance bar, star, rotate/edit buttons, countdown/
  /// ended overlays) positioned over a pane identified by its GlobalKey.
  /// These are outside InteractiveViewer so they never zoom or rotate.
  Widget _buildPaneChrome({
    required GlobalKey paneKey,
    required Color allianceColor,
    required bool containsUserTeam,
    VoidCallback? onRotate,
    VoidCallback? onEdit,
    bool isWaiting = false,
    Duration countdownRemaining = Duration.zero,
    bool hasEnded = false,
    Duration endedAgo = Duration.zero,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderBox = paneKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) {
          // First frame — pane hasn't been laid out yet. Will render next frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
          return const SizedBox.shrink();
        }

        // Get pane position relative to this Stack (which is the chrome overlay's parent)
        final stackRenderBox = context.findRenderObject() as RenderBox?;
        if (stackRenderBox == null) return const SizedBox.shrink();

        final paneGlobal = renderBox.localToGlobal(Offset.zero);
        final stackGlobal = stackRenderBox.localToGlobal(Offset.zero);
        final paneLocal = paneGlobal - stackGlobal;
        final paneSize = renderBox.size;

        return Stack(
          children: [
            // Countdown overlay when waiting for sync
            if (isWaiting)
              Positioned(
                left: paneLocal.dx,
                top: paneLocal.dy,
                width: paneSize.width,
                height: paneSize.height,
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      'Starting in ${(countdownRemaining.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            // Video ended overlay
            if (hasEnded)
              Positioned(
                left: paneLocal.dx,
                top: paneLocal.dy,
                width: paneSize.width,
                height: paneSize.height,
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Text(
                      'Video ended ${(endedAgo.inMilliseconds / 1000.0).toStringAsFixed(1)}s ago',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            // Alliance color bar
            Positioned(
              left: paneLocal.dx,
              top: paneLocal.dy,
              width: paneSize.width,
              height: 3,
              child: ColoredBox(color: allianceColor),
            ),
            // Star icon for user's team
            if (containsUserTeam)
              Positioned(
                left: paneLocal.dx + 6,
                top: paneLocal.dy + 6,
                child: Icon(
                  Icons.star,
                  color: Colors.yellow.shade600,
                  size: 20,
                ),
              ),
            // Rotate and edit buttons
            Positioned(
              top: paneLocal.dy + 2,
              left: paneLocal.dx + paneSize.width - 2 - _chromeButtonsWidth(onRotate, onEdit),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRotate != null)
                    _PaneOverlayButton(
                      icon: Icons.rotate_90_degrees_cw,
                      onTap: onRotate,
                    ),
                  if (onRotate != null && onEdit != null)
                    const SizedBox(width: 2),
                  if (onEdit != null)
                    _PaneOverlayButton(
                      icon: Icons.edit,
                      onTap: onEdit,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  double _chromeButtonsWidth(VoidCallback? onRotate, VoidCallback? onEdit) {
    double width = 0;
    if (onRotate != null) width += 40;
    if (onEdit != null) width += 40;
    if (onRotate != null && onEdit != null) width += 2; // gap
    return width;
  }
}

/// A small button overlaid on the video pane with adequate touch target (40x40).
/// Placed outside the RotatedBox so it stays upright when video is rotated.
class _PaneOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PaneOverlayButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}

/// Bottom sheet for editing recording metadata (match, alliance, teams).
class _EditMetadataSheet extends StatefulWidget {
  final MatchWithVideos matchWithVideos;
  final DataStore dataStore;
  /// The view mode that was active when the sheet was opened; used to determine
  /// which recording to edit by default.
  final ViewMode activeViewMode;

  const _EditMetadataSheet({
    required this.matchWithVideos,
    required this.dataStore,
    required this.activeViewMode,
  });

  @override
  State<_EditMetadataSheet> createState() => _EditMetadataSheetState();
}

class _EditMetadataSheetState extends State<_EditMetadataSheet> {
  late String? _selectedEventKey;
  late String? _selectedMatchKey;
  late String _allianceSide;
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _team3Controller = TextEditingController();
  final _team4Controller = TextEditingController();
  final _team5Controller = TextEditingController();
  final _team6Controller = TextEditingController();
  Recording? _editingRecording;

  @override
  void initState() {
    super.initState();
    // Default to the recording for the currently active view mode.
    // Falls back to red, then blue, then full if the preferred one is absent.
    _editingRecording = switch (widget.activeViewMode) {
      ViewMode.fullOnly => widget.matchWithVideos.fullRecording ??
          widget.matchWithVideos.redRecording ??
          widget.matchWithVideos.blueRecording,
      ViewMode.blueOnly => widget.matchWithVideos.blueRecording ??
          widget.matchWithVideos.redRecording ??
          widget.matchWithVideos.fullRecording,
      _ => widget.matchWithVideos.redRecording ??
          widget.matchWithVideos.blueRecording ??
          widget.matchWithVideos.fullRecording,
    };

    if (_editingRecording != null) {
      _selectedEventKey = _editingRecording!.eventKey;
      _selectedMatchKey = _editingRecording!.matchKey;
      _allianceSide = _editingRecording!.allianceSide;
      _team1Controller.text =
          _editingRecording!.team1 > 0 ? '${_editingRecording!.team1}' : '';
      _team2Controller.text =
          _editingRecording!.team2 > 0 ? '${_editingRecording!.team2}' : '';
      _team3Controller.text =
          _editingRecording!.team3 > 0 ? '${_editingRecording!.team3}' : '';
      _team4Controller.text =
          _editingRecording!.team4 > 0 ? '${_editingRecording!.team4}' : '';
      _team5Controller.text =
          _editingRecording!.team5 > 0 ? '${_editingRecording!.team5}' : '';
      _team6Controller.text =
          _editingRecording!.team6 > 0 ? '${_editingRecording!.team6}' : '';
    } else {
      _selectedEventKey = widget.matchWithVideos.match.eventKey;
      _selectedMatchKey = widget.matchWithVideos.match.matchKey;
      _allianceSide = 'red';
    }
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _team3Controller.dispose();
    _team4Controller.dispose();
    _team5Controller.dispose();
    _team6Controller.dispose();
    super.dispose();
  }

  /// Whether the current match + alliance side already has a recording,
  /// excluding the recording being edited. Suppressed when values haven't
  /// changed from the original.
  bool _hasConflictingRecording() {
    if (_selectedMatchKey == null) return false;
    if (_selectedMatchKey == _editingRecording?.matchKey &&
        _allianceSide == _editingRecording?.allianceSide) return false;
    return widget.dataStore.hasRecordingForSide(
      _selectedMatchKey!,
      _allianceSide,
      excludeId: _editingRecording?.id,
    );
  }

  Future<void> _save() async {
    if (_editingRecording == null) return;

    final updated = _editingRecording!.copyWith(
      eventKey: _selectedEventKey,
      matchKey: _selectedMatchKey,
      allianceSide: _allianceSide,
      team1: int.tryParse(_team1Controller.text) ?? 0,
      team2: int.tryParse(_team2Controller.text) ?? 0,
      team3: int.tryParse(_team3Controller.text) ?? 0,
      team4: int.tryParse(_team4Controller.text) ?? 0,
      team5: int.tryParse(_team5Controller.text) ?? 0,
      team6: int.tryParse(_team6Controller.text) ?? 0,
    );

    await widget.dataStore.updateRecording(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final eventKeys = widget.dataStore.settings.selectedEventKeys;
    final showMultiEvent = eventKeys.length > 1;
    // Filter matches by selected event when multiple events
    final matches = List<Match>.from(
      showMultiEvent && _selectedEventKey != null
          ? widget.dataStore.getMatchesForEvents([_selectedEventKey!])
          : widget.dataStore.getMatchesForEvents(eventKeys),
    )..sort((a, b) {
        final aTime = a.bestTime;
        final bTime = b.bestTime;
        if (aTime == null && bTime == null) {
          return a.matchKey.compareTo(b.matchKey);
        }
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });
    final isFull = _allianceSide == 'full';

    // Build event name map for event dropdown
    final eventNameMap = <String, String>{};
    for (final e in widget.dataStore.events) {
      eventNameMap[e.eventKey] = e.shortName;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Recording',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (showMultiEvent) ...[
              DropdownButtonFormField<String>(
                key: ValueKey('event_$_selectedEventKey'),
                initialValue: _selectedEventKey,
                decoration: const InputDecoration(labelText: 'Event'),
                items: eventKeys
                    .map((ek) => DropdownMenuItem(
                          value: ek,
                          child: Text(eventNameMap[ek] ?? ek),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventKey = value;
                    _selectedMatchKey = null;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              key: ValueKey('match_$_selectedMatchKey'),
              initialValue: _selectedMatchKey,
              decoration: const InputDecoration(labelText: 'Match'),
              items: matches
                  .map((m) => DropdownMenuItem(
                        value: m.matchKey,
                        child: Text(m.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedMatchKey = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Alliance: '),
                ChoiceChip(
                  label: const Text('Red'),
                  selected: _allianceSide == 'red',
                  selectedColor: AppColors.redAllianceLight,
                  onSelected: (_) => setState(() => _allianceSide = 'red'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Blue'),
                  selected: _allianceSide == 'blue',
                  selectedColor: AppColors.blueAllianceLight,
                  onSelected: (_) => setState(() => _allianceSide = 'blue'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Full'),
                  selected: _allianceSide == 'full',
                  selectedColor: AppColors.fullAllianceLight,
                  onSelected: (_) => setState(() => _allianceSide = 'full'),
                ),
              ],
            ),
            if (_hasConflictingRecording()) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Recording exists for this side',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Row 1: Teams 1-3 (red alliance teams, or first 3 for full)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _team1Controller,
                    decoration: InputDecoration(
                      labelText: isFull ? 'Red 1' : 'Team 1',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _team2Controller,
                    decoration: InputDecoration(
                      labelText: isFull ? 'Red 2' : 'Team 2',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _team3Controller,
                    decoration: InputDecoration(
                      labelText: isFull ? 'Red 3' : 'Team 3',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            // Row 2: Teams 4-6 only shown for full-field recordings
            if (isFull) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _team4Controller,
                      decoration: const InputDecoration(labelText: 'Blue 1'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _team5Controller,
                      decoration: const InputDecoration(labelText: 'Blue 2'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _team6Controller,
                      decoration: const InputDecoration(labelText: 'Blue 3'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
