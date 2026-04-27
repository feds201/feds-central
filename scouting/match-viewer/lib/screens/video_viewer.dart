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
import '../util/format.dart';

import '../viewer/drawing_controller.dart';
import '../viewer/scrub_controller.dart';
import '../viewer/timeline.dart';
import '../widgets/control_sidebar.dart';
import '../widgets/scrubber_bar.dart';
import '../widgets/stroke_painter.dart';
import '../widgets/video_pane.dart';

/// Full-screen landscape video viewer for match recordings.
///
/// Supports synchronized playback of 1, 2, or 3 sources via [Timeline]
/// with touch scrubbing, drawing overlay, and audio/view mode controls.
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
  /// Single source of truth for all position/duration math, audio routing,
  /// and per-pane chrome questions. Created in [_initPlayers] from whichever
  /// recordings exist; null only during initial async setup.
  Timeline? _timeline;

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
  bool _drawButtonHeld = false;
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

  // Position state — mirrored from Timeline streams via setState. Read these
  // in build(); never compute time math from them. The Timeline is authoritative.
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  /// Unified-timeline position the user marked as "match started", or null
  /// until they first tap the Mark Start button. Resets when leaving this
  /// screen (no disk persistence).
  Duration? _markedStartPosition;

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

  // Hacky workaround: users have reported finger-scrubbing stops responding
  // permanently mid-session. We have not been able to reproduce it. We tried
  // multiple hypotheses (multi-touch state corruption, leaked pointer IDs from
  // PointerCancelEvent, draw-button stuck held, scrub-bar drag flag stuck,
  // unawaited-pause leaving the player half-paused) — none reproduced. Rather
  // than guess at a fix, we drop every gesture-layer flag back to a neutral
  // state on play/pause press, so any stuck flag gets healed before the next
  // finger touch. Intentionally does NOT touch the players, position, view
  // mode, drawn strokes, mute state, or _drawButtonHeld — only gesture
  // interpretation. Remove once the root cause is found and fixed.
  void _resetGestureState() {
    _activePointers.clear();
    _primaryPointer = null;
    _primaryPointerIsScrub = false;
    _isFingerScrubbing = false;
    _multiTouchDetected = false;
    _isScrubBarDragging = false;
    _scrubStartX = null;
    _wasPlayingBeforeScrub = false;
    _scrubController.reset();
    _drawingController.cancelStroke();
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

    Player? redPlayer;
    VideoController? redCtl;
    Player? bluePlayer;
    VideoController? blueCtl;
    Player? fullPlayer;
    VideoController? fullCtl;

    if (redRec != null) {
      redPlayer = Player();
      redCtl = VideoController(redPlayer);
      final path = await _getVideoPath(redRec);
      await redPlayer.open(Media(path), play: false);
      redPlayer.setVolume(0);
    }
    if (blueRec != null) {
      bluePlayer = Player();
      blueCtl = VideoController(bluePlayer);
      final path = await _getVideoPath(blueRec);
      await bluePlayer.open(Media(path), play: false);
      bluePlayer.setVolume(0);
    }
    if (fullRec != null) {
      fullPlayer = Player();
      fullCtl = VideoController(fullPlayer);
      final path = await _getVideoPath(fullRec);
      await fullPlayer.open(Media(path), play: false);
      fullPlayer.setVolume(0);
    }

    final timeline = Timeline.fromRecordings(
      redRecording: redRec,
      redPlayer: redPlayer,
      redController: redCtl,
      blueRecording: blueRec,
      bluePlayer: bluePlayer,
      blueController: blueCtl,
      fullRecording: fullRec,
      fullPlayer: fullPlayer,
      fullController: fullCtl,
    );

    _subscriptions.add(timeline.unifiedPositionStream.listen((pos) {
      if (mounted && !_isScrubBarDragging && !_isFingerScrubbing) {
        setState(() => _position = pos);
      }
    }));
    _subscriptions.add(timeline.unifiedDurationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    }));
    _subscriptions.add(timeline.isPlayingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          _updateDrawingOpacity();
        });
      }
    }));
    _subscriptions.add(timeline.dimensionsStream.listen((role) {
      final w = timeline.widthFor(role);
      final h = timeline.heightFor(role);
      debugPrint('[VIDEO_DEBUG] $role media_kit reports: ${w}x$h '
          '(${(w ?? 0) > (h ?? 0) ? "landscape" : "portrait"})');
      _updateAutoRotation();
    }));

    if (mounted) setState(() => _timeline = timeline);

    // Autoplay
    await timeline.play();

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
    _timeline?.dispose();
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
    final t = _timeline;
    if (t == null) return;
    final redVol = _muteState == MuteState.redAudio ? 100.0 : 0.0;
    final blueVol = _muteState == MuteState.blueAudio ? 100.0 : 0.0;
    final fullVol = _muteState == MuteState.fullAudio ? 100.0 : 0.0;
    t.setVolumeFor(PlayerRole.red, redVol);
    t.setVolumeFor(PlayerRole.blue, blueVol);
    t.setVolumeFor(PlayerRole.full, fullVol);
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
    // Hacky workaround: see _resetGestureState declaration. Pressing play/pause
    // is a natural "I'm done with what I was doing" moment — proactively wipe
    // gesture state so any stuck flag from the unreproducible scrub-broken
    // bug gets healed before the next finger touch.
    _resetGestureState();
    final t = _timeline;
    if (t == null) return;
    if (t.isPlaying) {
      await t.pause();
    } else {
      await t.play();
    }
  }

  Future<void> _rewind10() async {
    await _seekTo(_position - const Duration(seconds: 10));
  }

  Future<void> _forward10() async {
    await _seekTo(_position + const Duration(seconds: 10));
  }

  Future<void> _restart() async {
    final wasPlaying = _isPlaying;
    final t = _timeline;
    if (t == null) return;
    await t.seek(Duration.zero);
    if (wasPlaying) await t.play();
  }

  Future<void> _seekTo(Duration target) async {
    await _timeline?.seek(target);
  }

  // --- Mark Start ---

  void _markStart() {
    final t = _timeline;
    if (t == null) return;
    setState(() => _markedStartPosition = t.unifiedPosition);
  }

  // --- Unified Pointer Handling (Scrub + Draw) ---

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);

    if (_activePointers.length == 1) {
      // First finger — start scrub or draw
      _primaryPointer = event.pointer;

      if (_drawButtonHeld) {
        // 1-finger with draw button held = draw
        _primaryPointerIsScrub = false;
        _drawingController.onPointerDown(event.position);
      } else {
        // 1-finger without draw button = scrub
        _primaryPointerIsScrub = true;
        _scrubStartX = event.position.dx;
        _wasPlayingBeforeScrub = _isPlaying;
        _isFingerScrubbing = true;
        _scrubBasePosition = _timeline?.unifiedPosition ?? _position;

        // Pause for scrub if currently playing
        if (_isPlaying) _timeline?.pause();

        // Start coalescing timer for smooth finger scrubbing
        _scrubController.startCoalescing(
          intervalMs: widget.dataStore.settings.scrubCoalescingIntervalMs,
          onTick: _onScrubCoalescingTick,
        );
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
      _isFingerScrubbing = false;
      _scrubController.stopCoalescing();
      _scrubController.reset();
      _scrubStartX = null;

      if (_wasPlayingBeforeScrub) {
        _wasPlayingBeforeScrub = false;
        _timeline?.play();
      }
    } else {
      _drawingController.cancelStroke();
    }

    _primaryPointer = null;
  }

  /// Called by the coalescing timer at fixed intervals. Fire-and-forget.
  void _onScrubCoalescingTick(Duration position) {
    _timeline?.seek(position);
  }

  // --- Drawing ---

  void _onDrawStart() {
    setState(() => _drawButtonHeld = true);
    _drawingController.setColor(DrawingColor.red);
    _updateDrawingOpacity();
  }

  void _onDrawEnd() {
    setState(() => _drawButtonHeld = false);
    _updateDrawingOpacity();
  }

  void _updateDrawingOpacity() {
    _drawingController.setOpacity((_isPlaying && !_drawButtonHeld) ? 0.4 : 1.0);
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

  /// Recomputes auto-rotation for all panes based on current view mode.
  /// In dual mode: wider dimension should be vertical (panes are tall/narrow).
  /// In single mode: wider dimension should be horizontal (fill landscape screen).
  /// Skips panes that the user has manually rotated.
  void _updateAutoRotation() {
    final t = _timeline;
    if (t == null) return;
    setState(() {
      final isSingleMode = _viewMode != ViewMode.both;
      debugPrint('[VIDEO_DEBUG] _updateAutoRotation: viewMode=$_viewMode, isSingleMode=$isSingleMode');

      _maybeAutoRotate(
        tag: 'RED',
        manuallyRotated: _redManuallyRotated,
        width: t.widthFor(PlayerRole.red),
        height: t.heightFor(PlayerRole.red),
        isSingleMode: isSingleMode,
        currentTurns: _redQuarterTurns,
        applyTurns: (q) => _redQuarterTurns = q,
      );
      _maybeAutoRotate(
        tag: 'BLUE',
        manuallyRotated: _blueManuallyRotated,
        width: t.widthFor(PlayerRole.blue),
        height: t.heightFor(PlayerRole.blue),
        isSingleMode: isSingleMode,
        currentTurns: _blueQuarterTurns,
        applyTurns: (q) => _blueQuarterTurns = q,
      );
      // Full is always single-mode-style (always full-screen)
      _maybeAutoRotate(
        tag: 'FULL',
        manuallyRotated: _fullManuallyRotated,
        width: t.widthFor(PlayerRole.full),
        height: t.heightFor(PlayerRole.full),
        isSingleMode: true,
        currentTurns: _fullQuarterTurns,
        applyTurns: (q) => _fullQuarterTurns = q,
      );
    });
  }

  void _maybeAutoRotate({
    required String tag,
    required bool manuallyRotated,
    required int? width,
    required int? height,
    required bool isSingleMode,
    required int currentTurns,
    required void Function(int) applyTurns,
  }) {
    if (manuallyRotated) {
      debugPrint('[VIDEO_DEBUG] $tag skipped (manually rotated), quarterTurns=$currentTurns');
      return;
    }
    if (width == null || height == null || width <= 0 || height <= 0) return;
    final isLandscape = width > height;
    final newTurns = isSingleMode ? (isLandscape ? 0 : 1) : (isLandscape ? 1 : 0);
    debugPrint('[VIDEO_DEBUG] $tag auto-rotate: ${width}x$height '
        'isLandscape=$isLandscape → quarterTurns=$newTurns (was $currentTurns)');
    applyTurns(newTurns);
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
              isDrawing: _drawButtonHeld,
              canUndo: _drawingController.canUndo,
              canRedo: _drawingController.canRedo,
              hasDrawings: _drawingController.hasNonEmptyStrokes,
              canToggleViewMode: _availableViewModes.length > 1,
              markedStartPosition: _markedStartPosition,
              currentPosition: _position,
              onBack: () => Navigator.of(context).pop(),
              onSwapSides: _swapSides,
              onToggleMute: _toggleMute,
              onToggleViewMode: _toggleViewMode,
              onPlayPause: _togglePlayPause,
              onMarkStart: _markStart,
              onRewind10: _rewind10,
              onForward10: _forward10,
              onRestart: _restart,
              onDrawStart: _onDrawStart,
              onDrawEnd: _onDrawEnd,
              onDrawTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hold the draw button and draw with your other hand'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
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
    final t = _timeline;
    if (t == null) {
      return const Center(
        child: Text('Loading...', style: TextStyle(color: Colors.white54)),
      );
    }
    final redCtl = t.controllerFor(PlayerRole.red);
    final blueCtl = t.controllerFor(PlayerRole.blue);
    final fullCtl = t.controllerFor(PlayerRole.full);

    // Full-only mode
    if (_viewMode == ViewMode.fullOnly) {
      if (fullCtl == null) {
        return const Center(
          child: Text('No video available', style: TextStyle(color: Colors.white54)),
        );
      }
      return _buildZoomablePane(
        paneKey: _singlePaneKey,
        zoomController: _fullZoomController,
        videoController: fullCtl,
        quarterTurns: _fullQuarterTurns,
        fit: BoxFit.contain,
      );
    }

    // Single red/blue mode
    if (_viewMode != ViewMode.both) {
      VideoController? controller;
      bool isRed = true;

      if (_viewMode == ViewMode.redOnly || (redCtl != null && blueCtl == null)) {
        controller = redCtl;
        isRed = true;
      } else {
        controller = blueCtl;
        isRed = false;
      }

      if (controller == null) {
        return const Center(
          child: Text('No video available', style: TextStyle(color: Colors.white54)),
        );
      }

      return _buildZoomablePane(
        paneKey: _singlePaneKey,
        zoomController: isRed ? _redZoomController : _blueZoomController,
        videoController: controller,
        quarterTurns: isRed ? _redQuarterTurns : _blueQuarterTurns,
        fit: BoxFit.contain,
      );
    }

    // Dual video mode — red on left, blue on right (or swapped)
    if (redCtl == null || blueCtl == null) {
      return const Center(
        child: Text('Loading...', style: TextStyle(color: Colors.white54)),
      );
    }
    final leftController = _sidesSwapped ? blueCtl : redCtl;
    final rightController = _sidesSwapped ? redCtl : blueCtl;
    final leftIsRed = !_sidesSwapped;
    final rightIsRed = _sidesSwapped;

    return Row(
      children: [
        Expanded(
          child: _buildZoomablePane(
            paneKey: _leftPaneKey,
            zoomController: leftIsRed ? _redZoomController : _blueZoomController,
            videoController: leftController,
            quarterTurns: leftIsRed ? _redQuarterTurns : _blueQuarterTurns,
            fit: BoxFit.fitWidth,
          ),
        ),
        Expanded(
          child: _buildZoomablePane(
            paneKey: _rightPaneKey,
            zoomController: rightIsRed ? _redZoomController : _blueZoomController,
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
          videoController: videoController,
          fit: fit,
        ),
      ),
    );
  }

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
    final t = _timeline;
    if (t == null) return const SizedBox.shrink();

    final children = <Widget>[];

    if (_viewMode == ViewMode.both) {
      final leftIsRed = !_sidesSwapped;
      final rightIsRed = _sidesSwapped;
      final leftRole = leftIsRed ? PlayerRole.red : PlayerRole.blue;
      final rightRole = rightIsRed ? PlayerRole.red : PlayerRole.blue;
      final leftColor = leftIsRed ? AppColors.redAlliance : AppColors.blueAlliance;
      final rightColor = rightIsRed ? AppColors.redAlliance : AppColors.blueAlliance;
      final leftRec = _sidesSwapped
          ? widget.matchWithVideos.blueRecording
          : widget.matchWithVideos.redRecording;
      final rightRec = _sidesSwapped
          ? widget.matchWithVideos.redRecording
          : widget.matchWithVideos.blueRecording;

      children.add(_buildPaneChrome(
        paneKey: _leftPaneKey,
        allianceColor: leftColor,
        containsUserTeam: _containsUserTeam(leftRec),
        onRotate: () => _rotatePane(isRed: leftIsRed),
        onEdit: _openEditMetadata,
        isWaiting: t.isWaitingFor(leftRole),
        countdownRemaining: t.countdownFor(leftRole),
        hasEnded: t.hasEnded(leftRole),
        endedAgo: t.endedAgoFor(leftRole),
      ));
      children.add(_buildPaneChrome(
        paneKey: _rightPaneKey,
        allianceColor: rightColor,
        containsUserTeam: _containsUserTeam(rightRec),
        onRotate: () => _rotatePane(isRed: rightIsRed),
        onEdit: _openEditMetadata,
        isWaiting: t.isWaitingFor(rightRole),
        countdownRemaining: t.countdownFor(rightRole),
        hasEnded: t.hasEnded(rightRole),
        endedAgo: t.endedAgoFor(rightRole),
      ));
    } else if (_viewMode == ViewMode.fullOnly) {
      children.add(_buildPaneChrome(
        paneKey: _singlePaneKey,
        allianceColor: AppColors.fullAlliance,
        containsUserTeam: _containsUserTeam(widget.matchWithVideos.fullRecording),
        onRotate: () => _rotatePane(isFull: true),
        onEdit: _openEditMetadata,
        isWaiting: t.isWaitingFor(PlayerRole.full),
        countdownRemaining: t.countdownFor(PlayerRole.full),
        hasEnded: t.hasEnded(PlayerRole.full),
        endedAgo: t.endedAgoFor(PlayerRole.full),
      ));
    } else {
      final isRed = _viewMode == ViewMode.redOnly;
      final role = isRed ? PlayerRole.red : PlayerRole.blue;
      final color = isRed ? AppColors.redAlliance : AppColors.blueAlliance;
      final recording = isRed
          ? widget.matchWithVideos.redRecording
          : widget.matchWithVideos.blueRecording;
      children.add(_buildPaneChrome(
        paneKey: _singlePaneKey,
        allianceColor: color,
        containsUserTeam: _containsUserTeam(recording),
        onRotate: () => _rotatePane(isRed: isRed),
        onEdit: _openEditMetadata,
        isWaiting: t.isWaitingFor(role),
        countdownRemaining: t.countdownFor(role),
        hasEnded: t.hasEnded(role),
        endedAgo: t.endedAgoFor(role),
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
                      'Starting in ${formatStopwatch(countdownRemaining)}',
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
                      'Video ended ${formatStopwatch(endedAgo)} ago',
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
