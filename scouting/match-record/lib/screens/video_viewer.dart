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
import '../widgets/drawing_overlay.dart';
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
  VideoController? _redController;
  VideoController? _blueController;

  // Sync
  SyncEngine? _syncEngine;
  bool get _hasDualVideo =>
      widget.matchWithVideos.redRecording != null &&
      widget.matchWithVideos.blueRecording != null;

  // State
  MuteState _muteState = MuteState.muted;
  ViewMode _viewMode = ViewMode.both;
  late bool _sidesSwapped;
  bool _isPlaying = false;
  bool _isDrawingMode = false;
  bool _isScrubBarDragging = false;
  bool _isFingerScrubbing = false;
  bool _wasPlayingBeforeScrub = false;
  Duration _scrubBasePosition = Duration.zero;

  // Per-pane rotation (quarter turns, 0-3)
  int _redQuarterTurns = 0;
  int _blueQuarterTurns = 0;
  bool _redManuallyRotated = false;
  bool _blueManuallyRotated = false;

  // Position tracking
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _laterWaiting = false;
  Duration _countdownRemaining = Duration.zero;

  // Controllers
  final _drawingController = DrawingController();
  final _scrubController = ScrubController();

  // Subscriptions
  final _subscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _sidesSwapped = widget.dataStore.settings.sidesSwapped;
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

    // Set up sync engine for dual video
    if (_hasDualVideo && _redPlayer != null && _bluePlayer != null) {
      _syncEngine = SyncEngine.fromRecordings(
        redRecording: redRec!,
        blueRecording: blueRec!,
        redPlayer: _redPlayer!,
        bluePlayer: _bluePlayer!,
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
    _autoRotatePlayer(_redPlayer, isRed: true);
    _autoRotatePlayer(_bluePlayer, isRed: false);

    // Subscribe to position/duration streams from the primary player
    // (must subscribe before autoplay so we catch the playing state)
    final primaryPlayer = _syncEngine?.earlierPlayer ?? _redPlayer ?? _bluePlayer;
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
              _drawingController.setOpacity(playing ? 0.5 : 1.0);
              if (playing) _isDrawingMode = false;
            });
          }
        }),
      );
    }

    // Autoplay: start playback after initialization
    if (_syncEngine != null) {
      await _syncEngine!.startSyncedPlayback();
    } else {
      final player = _redPlayer ?? _bluePlayer;
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
    _drawingController.removeListener(_onDrawingChanged);
    _drawingController.dispose();

    // Restore orientation and UI
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();

    super.dispose();
  }

  // --- Audio ---

  void _toggleMute() {
    setState(() {
      switch (_muteState) {
        case MuteState.muted:
          _muteState = MuteState.redAudio;
        case MuteState.redAudio:
          _muteState = MuteState.blueAudio;
        case MuteState.blueAudio:
          _muteState = MuteState.muted;
      }
    });
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
      case MuteState.redAudio:
        redPlayer?.setVolume(100);
        bluePlayer?.setVolume(0);
      case MuteState.blueAudio:
        redPlayer?.setVolume(0);
        bluePlayer?.setVolume(100);
    }
  }

  // --- View Mode ---

  void _toggleViewMode() {
    if (!_hasDualVideo) return;
    setState(() {
      switch (_viewMode) {
        case ViewMode.both:
          _viewMode = ViewMode.redOnly;
        case ViewMode.redOnly:
          _viewMode = ViewMode.blueOnly;
        case ViewMode.blueOnly:
          _viewMode = ViewMode.both;
      }
    });
    _updateAutoRotation();
  }

  // --- Playback ---

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      if (_syncEngine != null) {
        await _syncEngine!.pauseBoth();
      } else {
        final player = _redPlayer ?? _bluePlayer;
        await player?.pause();
      }
    } else {
      if (_syncEngine != null) {
        await _syncEngine!.startSyncedPlayback();
      } else {
        final player = _redPlayer ?? _bluePlayer;
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
      final player = _redPlayer ?? _bluePlayer;
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
      final player = _redPlayer ?? _bluePlayer;
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
        (_redPlayer ?? _bluePlayer)?.pause();
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
      (_redPlayer ?? _bluePlayer)?.seek(position);
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
    setState(() => _isDrawingMode = !_isDrawingMode);
  }

  // --- Rotation ---

  void _rotatePane(bool isRed) {
    setState(() {
      if (isRed) {
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
      ),
    );
  }

  // --- Auto-rotation ---

  // Cached video dimensions for recomputing rotation on view mode change
  int? _redVideoWidth, _redVideoHeight;
  int? _blueVideoWidth, _blueVideoHeight;

  /// Auto-rotate a video pane based on its native dimensions.
  /// Listens to the player's width stream (fires when video opens).
  void _autoRotatePlayer(Player? player, {required bool isRed}) {
    if (player == null) return;
    _subscriptions.add(
      player.stream.width.listen((width) {
        final height = player.state.height;
        if (width != null && height != null && width > 0 && height > 0) {
          if (isRed) {
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
      final isSingleMode = !_hasDualVideo || _viewMode != ViewMode.both;

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
    });
  }

  // --- Helpers ---

  bool _containsUserTeam(Recording? recording) {
    final teamNum = widget.dataStore.settings.teamNumber;
    if (teamNum == null || recording == null) return false;
    return recording.team1 == teamNum ||
        recording.team2 == teamNum ||
        recording.team3 == teamNum;
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
              isDrawingMode: _isDrawingMode,
              canUndo: _drawingController.canUndo,
              canRedo: _drawingController.canRedo,
              hasDrawings: _drawingController.strokes.isNotEmpty,
              hasDualVideo: _hasDualVideo,
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
              onUndo: _drawingController.undo,
              onRedo: _drawingController.redo,
              onClearDrawing: _drawingController.clear,
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
        // Drawing overlay — covers all video panes but not the control sidebar
        if (_isDrawingMode)
          Positioned.fill(
            child: DrawingOverlay(controller: _drawingController),
          ),
        // Passive stroke display when not in drawing mode
        if (!_isDrawingMode && _drawingController.strokes.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: StrokePainter(
                  strokes: _drawingController.strokes,
                  currentStroke: _drawingController.currentStroke,
                  opacity: _drawingController.opacity,
                ),
                size: Size.infinite,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPanes() {
    final redRec = widget.matchWithVideos.redRecording;
    final blueRec = widget.matchWithVideos.blueRecording;

    // Single video mode
    if (!_hasDualVideo || _viewMode != ViewMode.both) {
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

      return VideoPane(
        player: player,
        videoController: controller,
        allianceColor: color,
        containsUserTeam: _containsUserTeam(recording),
        isDrawingMode: _isDrawingMode,
        quarterTurns: isRed ? _redQuarterTurns : _blueQuarterTurns,
        onRotate: () => _rotatePane(isRed),
        isWaiting: isWaiting,
        countdownRemaining: _countdownRemaining,
        onScrubStart: _onScrubStart,
        onScrubUpdate: _onScrubUpdate,
        onScrubEnd: _onScrubEnd,
        onEdit: _openEditMetadata,
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
          child: VideoPane(
            player: leftPlayer,
            videoController: leftController,
            allianceColor: leftColor,
            containsUserTeam: _containsUserTeam(leftRec),
            isDrawingMode: _isDrawingMode,
            quarterTurns: leftIsRed ? _redQuarterTurns : _blueQuarterTurns,
            onRotate: () => _rotatePane(leftIsRed),
            isWaiting: leftWaiting,
            countdownRemaining: _countdownRemaining,
            onScrubStart: _onScrubStart,
            onScrubUpdate: _onScrubUpdate,
            onScrubEnd: _onScrubEnd,
            onEdit: _openEditMetadata,
          ),
        ),
        Expanded(
          child: VideoPane(
            player: rightPlayer,
            videoController: rightController,
            allianceColor: rightColor,
            containsUserTeam: _containsUserTeam(rightRec),
            isDrawingMode: _isDrawingMode,
            quarterTurns: rightIsRed ? _redQuarterTurns : _blueQuarterTurns,
            onRotate: () => _rotatePane(rightIsRed),
            isWaiting: rightWaiting,
            countdownRemaining: _countdownRemaining,
            onScrubStart: _onScrubStart,
            onScrubUpdate: _onScrubUpdate,
            onScrubEnd: _onScrubEnd,
            onEdit: _openEditMetadata,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for editing recording metadata (match, alliance, teams).
class _EditMetadataSheet extends StatefulWidget {
  final MatchWithVideos matchWithVideos;
  final DataStore dataStore;

  const _EditMetadataSheet({
    required this.matchWithVideos,
    required this.dataStore,
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
  Recording? _editingRecording;

  @override
  void initState() {
    super.initState();
    // Default to editing the red recording, or blue if red doesn't exist
    _editingRecording = widget.matchWithVideos.redRecording ??
        widget.matchWithVideos.blueRecording;
    if (_editingRecording != null) {
      _selectedMatchKey = _editingRecording!.matchKey;
      _allianceSide = _editingRecording!.allianceSide;
      _team1Controller.text =
          _editingRecording!.team1 > 0 ? '${_editingRecording!.team1}' : '';
      _team2Controller.text =
          _editingRecording!.team2 > 0 ? '${_editingRecording!.team2}' : '';
      _team3Controller.text =
          _editingRecording!.team3 > 0 ? '${_editingRecording!.team3}' : '';
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
    );

    await widget.dataStore.updateRecording(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final eventKeys = widget.dataStore.settings.selectedEventKeys;
    final matches = widget.dataStore.getMatchesForEvents(eventKeys);

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
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _team1Controller,
                    decoration: const InputDecoration(labelText: 'Team 1'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _team2Controller,
                    decoration: const InputDecoration(labelText: 'Team 2'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _team3Controller,
                    decoration: const InputDecoration(labelText: 'Team 3'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
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
