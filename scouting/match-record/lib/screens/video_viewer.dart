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
import '../viewer/coordinate_transform.dart';
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
  DrawingColor? _drawingColor; // null = off, red/blue = active drawing mode
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

  // Drawing controllers (one per video source)
  final _redDrawingController = DrawingController();
  final _blueDrawingController = DrawingController();
  final _fullDrawingController = DrawingController();

  // Zoom controllers (one per video source)
  final _redZoomController = TransformationController();
  final _blueZoomController = TransformationController();
  final _fullZoomController = TransformationController();

  // Track which pane is being drawn on (for cross-pane detection)
  int? _activeDrawingPointer;
  bool? _activeDrawingOnLeft;

  // Global keys to get pane positions for coordinate transform
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
    _redDrawingController.addListener(_onDrawingChanged);
    _blueDrawingController.addListener(_onDrawingChanged);
    _fullDrawingController.addListener(_onDrawingChanged);
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
            setState(() => _duration = dur);
          }
        }),
      );
      _subscriptions.add(
        primaryPlayer.stream.playing.listen((playing) {
          if (mounted) {
            setState(() {
              _isPlaying = playing;
              final opacity = playing ? 0.3 : 1.0;
              _redDrawingController.setOpacity(opacity);
              _blueDrawingController.setOpacity(opacity);
              _fullDrawingController.setOpacity(opacity);
              if (playing) _drawingColor = null;
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
    _redDrawingController.removeListener(_onDrawingChanged);
    _blueDrawingController.removeListener(_onDrawingChanged);
    _fullDrawingController.removeListener(_onDrawingChanged);
    _redDrawingController.dispose();
    _blueDrawingController.dispose();
    _fullDrawingController.dispose();
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
    setState(() => _viewMode = available[nextIndex]);
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

  // --- Scrubbing ---

  void _onScrubStart() {
    _isFingerScrubbing = true;
    _wasPlayingBeforeScrub = _isPlaying;
    _scrubBasePosition = _syncEngine?.intendedEarlierPosition ?? _position;
    if (_isPlaying) {
      if (_syncEngine != null) {
        _syncEngine!.pauseBoth();
      } else {
        (_redPlayer ?? _bluePlayer ?? _fullPlayer)?.pause();
      }
    }

    // Start coalescing timer for smooth finger scrubbing
    _scrubController.startCoalescing(
      intervalMs: widget.dataStore.settings.scrubCoalescingIntervalMs,
      onTick: _onScrubCoalescingTick,
    );
  }

  void _onScrubUpdate(double deltaX, double paneWidth) {
    final offsetMs = ScrubController.computeScrubOffsetMs(
      deltaX,
      paneWidth,
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

  void _onScrubEnd() {
    _isFingerScrubbing = false;

    // Stop coalescing timer and do a final seek if needed
    final finalPosition = _scrubController.stopCoalescing();
    if (finalPosition != null) {
      _onScrubCoalescingTick(finalPosition);
    }

    _scrubController.reset();
    if (_wasPlayingBeforeScrub) {
      _wasPlayingBeforeScrub = false;
      _togglePlayPause();
    }
  }

  // --- Drawing ---

  void _toggleDrawing() {
    setState(() {
      // Cycle: off → red → blue → off
      switch (_drawingColor) {
        case null:
          _drawingColor = DrawingColor.red;
        case DrawingColor.red:
          _drawingColor = DrawingColor.blue;
        case DrawingColor.blue:
          _drawingColor = null;
      }
      // Update all drawing controllers with the new color
      if (_drawingColor != null) {
        for (final c in _activeDrawingControllers) {
          c.setColor(_drawingColor!);
        }
      }
    });
  }

  /// Get the active drawing controllers for the current view mode.
  List<DrawingController> get _activeDrawingControllers {
    switch (_viewMode) {
      case ViewMode.both:
        return [_redDrawingController, _blueDrawingController];
      case ViewMode.redOnly:
        return [_redDrawingController];
      case ViewMode.blueOnly:
        return [_blueDrawingController];
      case ViewMode.fullOnly:
        return [_fullDrawingController];
    }
  }

  bool get _combinedCanUndo =>
      _activeDrawingControllers.any((c) => c.canUndo);

  bool get _combinedCanRedo =>
      _activeDrawingControllers.any((c) => c.canRedo);

  bool get _combinedHasDrawings =>
      _activeDrawingControllers.any((c) => c.hasNonEmptyStrokes);

  void _combinedUndo() {
    for (final c in _activeDrawingControllers) {
      c.undo();
    }
  }

  void _combinedRedo() {
    for (final c in _activeDrawingControllers) {
      c.redo();
    }
  }

  void _combinedClear() {
    for (final c in _activeDrawingControllers) {
      c.clear();
    }
  }

  /// Determine which pane a screen point falls in and return its info.
  /// Returns null if the point is outside all panes.
  _PaneHitInfo? _hitTestPane(Offset screenPoint) {
    if (_viewMode == ViewMode.both) {
      // Check left pane
      final leftInfo = _hitTestGlobalKey(
        _leftPaneKey,
        screenPoint,
        _sidesSwapped ? _blueZoomController : _redZoomController,
        _sidesSwapped ? _blueQuarterTurns : _redQuarterTurns,
        _sidesSwapped ? _blueDrawingController : _redDrawingController,
        isLeft: true,
      );
      if (leftInfo != null) return leftInfo;

      // Check right pane
      final rightInfo = _hitTestGlobalKey(
        _rightPaneKey,
        screenPoint,
        _sidesSwapped ? _redZoomController : _blueZoomController,
        _sidesSwapped ? _redQuarterTurns : _blueQuarterTurns,
        _sidesSwapped ? _redDrawingController : _blueDrawingController,
        isLeft: false,
      );
      return rightInfo;
    } else {
      // Single pane mode
      final controller = switch (_viewMode) {
        ViewMode.redOnly => _redDrawingController,
        ViewMode.blueOnly => _blueDrawingController,
        ViewMode.fullOnly => _fullDrawingController,
        ViewMode.both => _redDrawingController, // unreachable
      };
      final zoomController = switch (_viewMode) {
        ViewMode.redOnly => _redZoomController,
        ViewMode.blueOnly => _blueZoomController,
        ViewMode.fullOnly => _fullZoomController,
        ViewMode.both => _redZoomController, // unreachable
      };
      final quarterTurns = switch (_viewMode) {
        ViewMode.redOnly => _redQuarterTurns,
        ViewMode.blueOnly => _blueQuarterTurns,
        ViewMode.fullOnly => _fullQuarterTurns,
        ViewMode.both => 0, // unreachable
      };
      return _hitTestGlobalKey(
        _singlePaneKey,
        screenPoint,
        zoomController,
        quarterTurns,
        controller,
        isLeft: true,
      );
    }
  }

  _PaneHitInfo? _hitTestGlobalKey(
    GlobalKey key,
    Offset screenPoint,
    TransformationController zoomController,
    int quarterTurns,
    DrawingController drawingController, {
    required bool isLeft,
  }) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final paneTopLeft = renderBox.localToGlobal(Offset.zero);
    final paneSize = renderBox.size;
    final paneRect = paneTopLeft & paneSize;
    if (!paneRect.contains(screenPoint)) return null;

    final paneLocal = screenPoint - paneTopLeft;
    final videoSpace = CoordinateTransform.toVideoSpace(
      paneLocal,
      zoomController.value,
      quarterTurns,
      paneSize,
    );

    return _PaneHitInfo(
      drawingController: drawingController,
      videoSpacePoint: videoSpace,
      isLeft: isLeft,
    );
  }

  void _onDrawPointerDown(PointerDownEvent event) {
    if (_drawingColor == null) return;
    // Only handle single-finger drawing
    if (event.down && _activeDrawingPointer != null) return;

    final hit = _hitTestPane(event.position);
    if (hit == null) return;

    _activeDrawingPointer = event.pointer;
    _activeDrawingOnLeft = hit.isLeft;
    hit.drawingController.onPointerDown(hit.videoSpacePoint);

    // Push no-op to the other controller in dual mode to keep undo stacks synced
    if (_viewMode == ViewMode.both) {
      final otherController = hit.isLeft
          ? (_sidesSwapped ? _redDrawingController : _blueDrawingController)
          : (_sidesSwapped ? _blueDrawingController : _redDrawingController);
      otherController.pushNoOp();
    }
  }

  void _onDrawPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activeDrawingPointer) return;

    final hit = _hitTestPane(event.position);
    if (hit == null) return;

    // If finger crossed pane boundary in dual mode, finalize on old pane
    // and start new stroke on the new pane
    if (_viewMode == ViewMode.both && hit.isLeft != _activeDrawingOnLeft) {
      // Finalize stroke on the originating pane
      final oldController = _activeDrawingOnLeft!
          ? (_sidesSwapped ? _blueDrawingController : _redDrawingController)
          : (_sidesSwapped ? _redDrawingController : _blueDrawingController);
      oldController.onPointerUp();

      // Start new stroke on destination pane
      _activeDrawingOnLeft = hit.isLeft;
      hit.drawingController.onPointerDown(hit.videoSpacePoint);

      // Push no-op to the other controller
      final otherController = hit.isLeft
          ? (_sidesSwapped ? _redDrawingController : _blueDrawingController)
          : (_sidesSwapped ? _blueDrawingController : _redDrawingController);
      otherController.pushNoOp();
      return;
    }

    hit.drawingController.onPointerMove(hit.videoSpacePoint);
  }

  void _onDrawPointerUp(PointerUpEvent event) {
    if (event.pointer != _activeDrawingPointer) return;

    // Finalize stroke on the active pane
    if (_activeDrawingOnLeft != null) {
      final controller = _viewMode == ViewMode.both
          ? (_activeDrawingOnLeft!
              ? (_sidesSwapped ? _blueDrawingController : _redDrawingController)
              : (_sidesSwapped ? _redDrawingController : _blueDrawingController))
          : _activeDrawingControllers.first;
      controller.onPointerUp();
    }

    _activeDrawingPointer = null;
    _activeDrawingOnLeft = null;
  }

  // --- Rotation ---

  void _rotatePane({bool? isRed, bool isFull = false}) {
    setState(() {
      if (isFull) {
        _fullQuarterTurns = (_fullQuarterTurns + 1) % 4;
        _fullManuallyRotated = true;
      } else if (isRed == true) {
        _redQuarterTurns = (_redQuarterTurns + 1) % 4;
        _redManuallyRotated = true;
      } else {
        _blueQuarterTurns = (_blueQuarterTurns + 1) % 4;
        _blueManuallyRotated = true;
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
    _subscriptions.add(
      player.stream.width.listen((width) {
        final height = player.state.height;
        if (width != null && height != null && width > 0 && height > 0) {
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

      if (!_redManuallyRotated &&
          _redVideoWidth != null &&
          _redVideoHeight != null) {
        final isLandscapeVideo = _redVideoWidth! > _redVideoHeight!;
        if (isSingleMode) {
          // Single: wider should be horizontal — landscape videos need no rotation
          _redQuarterTurns = isLandscapeVideo ? 0 : 1;
        } else {
          // Dual: wider should be vertical — landscape videos need rotation
          _redQuarterTurns = isLandscapeVideo ? 1 : 0;
        }
      }

      if (!_blueManuallyRotated &&
          _blueVideoWidth != null &&
          _blueVideoHeight != null) {
        final isLandscapeVideo = _blueVideoWidth! > _blueVideoHeight!;
        if (isSingleMode) {
          _blueQuarterTurns = isLandscapeVideo ? 0 : 1;
        } else {
          _blueQuarterTurns = isLandscapeVideo ? 1 : 0;
        }
      }

      // Full player is always displayed full-screen (single mode)
      if (!_fullManuallyRotated &&
          _fullVideoWidth != null &&
          _fullVideoHeight != null) {
        final isLandscapeVideo = _fullVideoWidth! > _fullVideoHeight!;
        _fullQuarterTurns = isLandscapeVideo ? 0 : 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // Video panes take remaining space
            Expanded(child: _buildVideoPanesWithDrawing()),
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
              canUndo: _combinedCanUndo,
              canRedo: _combinedCanRedo,
              hasDrawings: _combinedHasDrawings,
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
              onToggleDrawing: _toggleDrawing,
              onUndo: _combinedUndo,
              onRedo: _combinedRedo,
              onClearDrawing: _combinedClear,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPanesWithDrawing() {
    return Stack(
      children: [
        Positioned.fill(child: _buildVideoPanes()),
        // Drawing input layer — top-level Listener spanning all panes
        if (_drawingColor != null)
          Positioned.fill(
            child: Listener(
              onPointerDown: _onDrawPointerDown,
              onPointerMove: _onDrawPointerMove,
              onPointerUp: _onDrawPointerUp,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }

  /// Wraps a video pane in InteractiveViewer → Stack with:
  /// - RotatedBox containing video + drawing overlay (rotates)
  /// - Positioned buttons on top (don't rotate, but zoom with the video)
  Widget _buildZoomablePane({
    required GlobalKey paneKey,
    required TransformationController zoomController,
    required DrawingController drawingController,
    required int quarterTurns,
    required Widget videoPane,
    VoidCallback? onRotate,
    VoidCallback? onEdit,
  }) {
    return InteractiveViewer(
      key: paneKey,
      transformationController: zoomController,
      panEnabled: false,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 5.0,
      child: Stack(
        children: [
          // Video + drawing layer — rotates together
          RotatedBox(
            quarterTurns: quarterTurns,
            child: Stack(
              children: [
                videoPane,
                // Passive drawing layer — rendered inside zoom transform
                // so strokes zoom with the video
                IgnorePointer(
                  ignoring: true,
                  child: ListenableBuilder(
                    listenable: drawingController,
                    builder: (context, _) => CustomPaint(
                      painter: StrokePainter(
                        strokes: drawingController.strokes,
                        currentStrokePoints: drawingController.currentStrokePoints,
                        currentColor: drawingController.currentColor,
                        opacity: drawingController.opacity,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rotate and edit buttons — outside rotation so they stay upright
          Positioned(
            top: 2,
            right: 2,
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
      ),
    );
  }

  Widget _buildVideoPanes() {
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
        drawingController: _fullDrawingController,
        quarterTurns: _fullQuarterTurns,
        onRotate: () => _rotatePane(isFull: true),
        onEdit: _openEditMetadata,
        videoPane: VideoPane(
          player: _fullPlayer!,
          videoController: _fullController!,
          allianceColor: Colors.purple,
          containsUserTeam: _containsUserTeam(fullRec),
          isDrawingMode: _drawingColor != null,
          isWaiting: false,
          countdownRemaining: Duration.zero,
          onScrubStart: _onScrubStart,
          onScrubUpdate: _onScrubUpdate,
          onScrubEnd: _onScrubEnd,
        ),
      );
    }

    // Single red/blue mode
    if (_viewMode != ViewMode.both) {
      Player? player;
      VideoController? controller;
      Color color;
      Recording? recording;
      bool isWaiting = false;
      bool isRed = true;

      if (_viewMode == ViewMode.redOnly || (redRec != null && blueRec == null)) {
        player = _redPlayer;
        controller = _redController;
        color = Colors.red;
        recording = redRec;
        isWaiting = _isRedWaiting();
        isRed = true;
      } else {
        player = _bluePlayer;
        controller = _blueController;
        color = Colors.blue;
        recording = blueRec;
        isWaiting = _isBlueWaiting();
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
        drawingController: isRed ? _redDrawingController : _blueDrawingController,
        quarterTurns: isRed ? _redQuarterTurns : _blueQuarterTurns,
        onRotate: () => _rotatePane(isRed: isRed),
        onEdit: _openEditMetadata,
        videoPane: VideoPane(
          player: player,
          videoController: controller,
          allianceColor: color,
          containsUserTeam: _containsUserTeam(recording),
          isDrawingMode: _drawingColor != null,
          isWaiting: isWaiting,
          countdownRemaining: _countdownRemaining,
          onScrubStart: _onScrubStart,
          onScrubUpdate: _onScrubUpdate,
          onScrubEnd: _onScrubEnd,
        ),
      );
    }

    // Dual video mode — red on left, blue on right (or swapped)
    final leftColor = _sidesSwapped ? Colors.blue : Colors.red;
    final rightColor = _sidesSwapped ? Colors.red : Colors.blue;
    final leftPlayer = _sidesSwapped ? _bluePlayer! : _redPlayer!;
    final rightPlayer = _sidesSwapped ? _redPlayer! : _bluePlayer!;
    final leftController = _sidesSwapped ? _blueController! : _redController!;
    final rightController = _sidesSwapped ? _redController! : _blueController!;
    final leftRec = _sidesSwapped ? blueRec : redRec;
    final rightRec = _sidesSwapped ? redRec : blueRec;
    final leftWaiting = _sidesSwapped ? _isBlueWaiting() : _isRedWaiting();
    final rightWaiting = _sidesSwapped ? _isRedWaiting() : _isBlueWaiting();
    final leftIsRed = !_sidesSwapped;
    final rightIsRed = _sidesSwapped;

    return Row(
      children: [
        Expanded(
          child: _buildZoomablePane(
            paneKey: _leftPaneKey,
            zoomController: leftIsRed ? _redZoomController : _blueZoomController,
            drawingController: leftIsRed ? _redDrawingController : _blueDrawingController,
            quarterTurns: leftIsRed ? _redQuarterTurns : _blueQuarterTurns,
            onRotate: () => _rotatePane(isRed: leftIsRed),
            onEdit: _openEditMetadata,
            videoPane: VideoPane(
              player: leftPlayer,
              videoController: leftController,
              allianceColor: leftColor,
              containsUserTeam: _containsUserTeam(leftRec),
              isDrawingMode: _drawingColor != null,
              isWaiting: leftWaiting,
              countdownRemaining: _countdownRemaining,
              onScrubStart: _onScrubStart,
              onScrubUpdate: _onScrubUpdate,
              onScrubEnd: _onScrubEnd,
            ),
          ),
        ),
        Expanded(
          child: _buildZoomablePane(
            paneKey: _rightPaneKey,
            zoomController: rightIsRed ? _redZoomController : _blueZoomController,
            drawingController: rightIsRed ? _redDrawingController : _blueDrawingController,
            quarterTurns: rightIsRed ? _redQuarterTurns : _blueQuarterTurns,
            onRotate: () => _rotatePane(isRed: rightIsRed),
            onEdit: _openEditMetadata,
            videoPane: VideoPane(
              player: rightPlayer,
              videoController: rightController,
              allianceColor: rightColor,
              containsUserTeam: _containsUserTeam(rightRec),
              isDrawingMode: _drawingColor != null,
              isWaiting: rightWaiting,
              countdownRemaining: _countdownRemaining,
              onScrubStart: _onScrubStart,
              onScrubUpdate: _onScrubUpdate,
              onScrubEnd: _onScrubEnd,
            ),
          ),
        ),
      ],
    );
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

/// Result of hit-testing a screen point against a video pane.
class _PaneHitInfo {
  final DrawingController drawingController;
  final Offset videoSpacePoint;
  final bool isLeft;

  _PaneHitInfo({
    required this.drawingController,
    required this.videoSpacePoint,
    required this.isLeft,
  });
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

  Future<void> _save() async {
    if (_editingRecording == null) return;

    final updated = _editingRecording!.copyWith(
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
    final matches = widget.dataStore.getMatchesForEvents(eventKeys);
    final isFull = _allianceSide == 'full';

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
            DropdownButtonFormField<String>(
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
                  selectedColor: Colors.red.shade300,
                  onSelected: (_) => setState(() => _allianceSide = 'red'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Blue'),
                  selected: _allianceSide == 'blue',
                  selectedColor: Colors.blue.shade300,
                  onSelected: (_) => setState(() => _allianceSide = 'blue'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Full'),
                  selected: _allianceSide == 'full',
                  selectedColor: Colors.purple.shade300,
                  onSelected: (_) => setState(() => _allianceSide = 'full'),
                ),
              ],
            ),
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
