import 'dart:math';

import 'package:fit_curve/fit_curve.dart' show CubicCurve;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bot_path_config.dart';
import '../models/bot_path_data.dart';
import '../painters/path_painter.dart';
import '../utils/bezier_math.dart';
import '../utils/curve_fitting.dart';
import '../widgets/rotation_dial.dart';

/// Widget for drawing robot autonomous paths on a field image.
///
/// Provides a canvas showing a cropped field image where users can draw
/// paths with finger or mouse. Includes playback controls (Play/Stop),
/// a speed slider, a Clear button, and a Save button. On touch devices,
/// a rotation dial is shown for controlling robot heading.
///
/// ## Usage
/// ```dart
/// BotPathDrawer(
///   config: BotPathConfig(
///     backgroundImage: AssetImage('assets/field.png'),
///   ),
///   onSave: (pathData) {
///     // pathData is the serialized path string, or null if no path
///     print('Saved: $pathData');
///   },
/// )
/// ```
class BotPathDrawer extends StatefulWidget {
  /// Configuration for appearance and behavior.
  final BotPathConfig config;

  /// Called when the user presses the Save button.
  ///
  /// Receives the serialized path string if a path has been drawn,
  /// or null if the canvas is empty. The parent can use this to
  /// store the path data and dismiss the drawing UI.
  final ValueChanged<String?> onSave;

  /// Creates a [BotPathDrawer] widget.
  const BotPathDrawer({super.key, required this.config, required this.onSave});

  @override
  State<BotPathDrawer> createState() => _BotPathDrawerState();
}

class _BotPathDrawerState extends State<BotPathDrawer>
    with SingleTickerProviderStateMixin {
  // Button padding constants
  static const _buttonHorizontalPadding = 8.0;
  static const _buttonVerticalPaddingTouch = 4.0;
  static const _buttonVerticalPaddingDesktop = 8.0;

  // Touch tracking
  int? _pointer1Id;
  Offset? _pointer1Pos;

  // Help toast visibility (touch devices)
  bool _showingHelp = false;

  // Drawing state
  bool _isRecording = false;
  double _currentRotation = 0;
  final Stopwatch _stopwatch = Stopwatch();

  // Timestamp offset used when continuing a path after an idle gap.
  // When the user lifts their finger and later taps near the endpoint
  // to continue, we reset the stopwatch and set this to the timestamp
  // of the last recorded point so that _elapsed() returns a value
  // continuous with the existing path (no idle gap baked in).
  int _timeOffset = 0;

  // Raw recorded points
  final List<RawPathPoint> _rawPath = [];

  // Fitted path after finalization
  BotPathData? _pathData;
  String _serializedData = '';

  // Playback
  late final AnimationController _playbackController;
  bool _playbackComplete = false;
  // Playback robot position in normalized coordinates (scale in build)
  Offset? _playbackRobotPos;
  double _playbackRobotRot = 0;
  late double _playbackSpeed;

  // Canvas size from LayoutBuilder
  Size _canvasSize = Size.zero;

  // Cached lists for stable references in shouldRepaint comparisons
  List<Offset> _cachedRawPositions = const [];
  List<CubicCurve> _cachedScaledCurves = const [];
  Size _lastScaledSize = Size.zero;

  // Keyboard state for WASD initial direction
  final Set<LogicalKeyboardKey> _heldKeys = {};

  // Focus node for scoped keyboard handling
  final FocusNode _focusNode = FocusNode();

  // Resolved image dimensions
  int? _imageWidth;
  int? _imageHeight;

  // Image loading error message, if any
  String? _imageError;

  // Image stream subscription handle for cleanup
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.config.defaultPlaybackSpeed;
    _playbackController = AnimationController(vsync: this);
    _playbackController.addListener(_onPlaybackTick);
    _playbackController.addStatusListener(_onPlaybackStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disposeImageStream();
    _resolveImage();
  }

  @override
  void didUpdateWidget(BotPathDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.backgroundImage != widget.config.backgroundImage) {
      _disposeImageStream();
      _imageWidth = null;
      _imageHeight = null;
      _imageError = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _playbackController.removeListener(_onPlaybackTick);
    _playbackController.removeStatusListener(_onPlaybackStatus);
    _playbackController.dispose();
    _disposeImageStream();
    super.dispose();
  }

  /// Resolves the background image to obtain its pixel dimensions.
  void _resolveImage() {
    final config = widget.config;
    final provider = config.backgroundImage;
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) return;
        setState(() {
          _imageWidth = info.image.width;
          _imageHeight = info.image.height;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!mounted) return;
        setState(() {
          _imageError = 'Failed to load background image: $error';
        });
      },
    );
    stream.addListener(listener);
    _imageStream = stream;
    _imageStreamListener = listener;
  }

  /// Removes the image stream listener to avoid leaks.
  void _disposeImageStream() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  // ---------------------------------------------------------------------------
  // Keyboard handling
  // ---------------------------------------------------------------------------

  /// Handles keyboard events scoped to this widget's focus.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _heldKeys.add(key);

      // Q = rotate CCW, E = rotate CW
      if (key == LogicalKeyboardKey.keyQ) {
        setState(() {
          _currentRotation -= pi / 16; // 11.25 degrees, 8 presses = 90
          _addRotationPointIfRecording();
        });
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyE) {
        setState(() {
          _currentRotation += pi / 16;
          _addRotationPointIfRecording();
        });
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      _heldKeys.remove(key);
    }
    return KeyEventResult.ignored;
  }

  /// Adds a rotation-only point if currently recording and pointer is down.
  void _addRotationPointIfRecording() {
    if (_isRecording && _pointer1Pos != null) {
      _rawPath.add(
        RawPathPoint(_pointer1Pos!, _currentRotation, _elapsed()),
      );
    }
  }

  /// Returns the initial rotation based on currently held WASD keys.
  double _initialRotationFromKeys() {
    if (_heldKeys.contains(LogicalKeyboardKey.keyW)) return -pi / 2;
    if (_heldKeys.contains(LogicalKeyboardKey.keyA)) return pi;
    if (_heldKeys.contains(LogicalKeyboardKey.keyS)) return pi / 2;
    if (_heldKeys.contains(LogicalKeyboardKey.keyD)) return 0;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Pointer handling
  // ---------------------------------------------------------------------------

  /// Handles pointer down to start or continue path drawing.
  void _onPointerDown(PointerDownEvent event) {
    if (_pointer1Id != null) return; // already tracking a pointer

    final pos = event.localPosition;

    setState(() {
      _pointer1Id = event.pointer;
      _pointer1Pos = pos;

      if (_rawPath.isNotEmpty) {
        // Path already exists — check if tap is close enough to continue
        final lastPoint = _rawPath.last.position;
        final distance = (pos - lastPoint).distance;
        final threshold = _canvasSize.width * 0.1;

        if (distance <= threshold) {
          // Continue the existing path — adjust timing so no idle gap
          final lastTimestamp = _rawPath.last.timestamp;
          _timeOffset = lastTimestamp;
          _stopwatch.reset();

          _currentRotation = _rawPath.last.rotation;
          _isRecording = true;
          _stopwatch.start();
          _pathData = null;
          _serializedData = '';
          _stopPlayback();
          _rawPath.add(RawPathPoint(pos, _currentRotation, _elapsed()));
        }
        // If far away, ignore — user must press Clear
      } else {
        // No existing path — start fresh
        _currentRotation = _initialRotationFromKeys();
        _isRecording = true;
        _timeOffset = 0;
        _stopwatch.reset();
        _stopwatch.start();
        _rawPath.add(RawPathPoint(pos, _currentRotation, 0));
      }
    });
  }

  /// Handles pointer move to record path points while drawing.
  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer1Id || !_isRecording) return;

    setState(() {
      _pointer1Pos = event.localPosition;
      _rawPath.add(
        RawPathPoint(event.localPosition, _currentRotation, _elapsed()),
      );
    });
  }

  /// Handles pointer up to finalize the current drawing stroke.
  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer1Id) return;

    setState(() {
      _pointer1Id = null;
      _pointer1Pos = null;
      _isRecording = false;
      _stopwatch.stop();
      _finalizePath();
    });
  }

  /// Handles scroll wheel events to adjust rotation.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {
        _currentRotation += event.scrollDelta.dy * 0.005;
        _addRotationPointIfRecording();
      });
    }
  }

  /// Returns elapsed milliseconds since recording started, including any
  /// time offset from path continuation.
  int _elapsed() => _stopwatch.elapsedMilliseconds + _timeOffset;

  /// Returns cached raw positions, rebuilding only when the list length changes.
  ///
  /// During active drawing the length changes every frame (we want repaints).
  /// During idle the length is stable so the same reference is reused,
  /// allowing [PathPainter.shouldRepaint] to skip redundant paints.
  List<Offset> _getRawPositions() {
    if (_rawPath.length != _cachedRawPositions.length) {
      _cachedRawPositions = _rawPath.map((p) => p.position).toList();
    }
    return _cachedRawPositions;
  }

  /// Returns cached scaled curves, recomputing only when the canvas size
  /// changes or the cache has been invalidated.
  List<CubicCurve> _getScaledCurves(Size canvasSize) {
    if (_pathData == null) return const [];
    if (_lastScaledSize == canvasSize && _cachedScaledCurves.isNotEmpty) {
      return _cachedScaledCurves;
    }
    _cachedScaledCurves = _pathData!.scaledCurves(canvasSize, cropFraction: widget.config.cropFraction);
    _lastScaledSize = canvasSize;
    return _cachedScaledCurves;
  }

  /// Fits the raw path points into Bezier curves and serializes the result.
  void _finalizePath() {
    if (_rawPath.length < 2) return;

    final result = fitPath(
      _rawPath,
      maxError: widget.config.simplificationError,
      minPointDistance: widget.config.pointFilterDistance,
    );
    if (result == null) return;

    _pathData = BotPathData.fromPixelCurves(
      curves: result.curves,
      rotations: result.rotations,
      timestamps: result.timestamps,
      canvasSize: _canvasSize,
      cropFraction: widget.config.cropFraction,
    );
    _cachedScaledCurves = const [];
    _serializedData = _pathData!.serialize();
  }

  // ---------------------------------------------------------------------------
  // Rotation dial callback
  // ---------------------------------------------------------------------------

  /// Called when the rotation dial value changes.
  void _onDialRotation(double newRotation) {
    setState(() {
      _currentRotation = newRotation;
      if (_isRecording && _pointer1Pos != null) {
        _rawPath.add(
          RawPathPoint(_pointer1Pos!, _currentRotation, _elapsed()),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Base playback duration at 1x speed, in milliseconds.
  ///
  /// Uses the configured [BotPathConfig.playbackDurationMs] if set,
  /// otherwise falls back to the path's actual recorded duration.
  int get _baseDurationMs =>
      widget.config.playbackDurationMs ?? _pathData!.timestamps.last;

  /// Starts path playback from the beginning.
  void _startPlayback() {
    if (_pathData == null || _pathData!.curves.isEmpty) return;

    setState(() {
      _playbackComplete = false;
      _playbackRobotPos = null;
      _playbackRobotRot = 0;
    });

    final durationMs = (_baseDurationMs / _playbackSpeed).round();
    _playbackController.duration = Duration(milliseconds: durationMs);
    _playbackController.forward(from: 0);
  }

  /// Stops playback and resets the playback robot.
  void _stopPlayback() {
    _playbackController.reset();
    _playbackComplete = false;
    _playbackRobotPos = null;
    _playbackRobotRot = 0;
  }

  /// Called on each animation frame during playback.
  void _onPlaybackTick() {
    if (_pathData == null || _pathData!.curves.isEmpty) return;

    final t = _playbackController.value;
    final curves = _pathData!.curves; // normalized
    final rotations = _pathData!.rotations;
    final timestamps = _pathData!.timestamps;
    final totalTime = timestamps.last;

    if (totalTime <= 0) return;

    // Map animation progress to the path's time domain
    final currentTime = t * totalTime;

    // Find which curve segment we're in by timestamp
    var curveIndex = 0;
    for (var i = 0; i < curves.length; i++) {
      if (currentTime <= timestamps[i + 1]) {
        curveIndex = i;
        break;
      }
      curveIndex = i;
    }

    // Interpolation parameter within this curve segment
    final segStart = timestamps[curveIndex].toDouble();
    final segEnd = timestamps[curveIndex + 1].toDouble();
    final segDuration = segEnd - segStart;
    final localT =
        segDuration > 0 ? ((currentTime - segStart) / segDuration).clamp(0.0, 1.0) : 1.0;

    // Evaluate on normalized curves — scaling to pixels happens in build
    final pos = evalBezier(curves[curveIndex], localT);
    final rot = lerpAngle(rotations[curveIndex], rotations[curveIndex + 1], localT);

    setState(() {
      _playbackRobotPos = pos;
      _playbackRobotRot = rot;
    });
  }

  /// Called when the playback animation status changes.
  void _onPlaybackStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _playbackComplete = true;
        // Show robot at final position (normalized coords, scaled in build)
        if (_pathData != null && _pathData!.curves.isNotEmpty) {
          final lastPt = _pathData!.curves.last.point2;
          _playbackRobotPos = Offset(lastPt.x, lastPt.y);
          _playbackRobotRot = _pathData!.rotations.last;
        }
      });
    }
  }

  /// Updates playback speed. If currently playing, adjusts duration and
  /// continues from the current progress.
  void _updatePlaybackSpeed(double newSpeed) {
    setState(() {
      _playbackSpeed = newSpeed;
    });

    if (_playbackController.isAnimating) {
      final currentProgress = _playbackController.value;
      final durationMs = (_baseDurationMs / _playbackSpeed).round();
      _playbackController.duration = Duration(milliseconds: durationMs);
      _playbackController.forward(from: currentProgress);
    }
  }

  // ---------------------------------------------------------------------------
  // Discrete speed steps (touch devices)
  // ---------------------------------------------------------------------------

  static const _speedSteps = [0.5, 1.0, 2.0, 4.0, 5.0, 10.0];

  bool get _canDecrementSpeed =>
      _speedSteps.any((s) => s < _playbackSpeed);

  bool get _canIncrementSpeed =>
      _speedSteps.any((s) => s > _playbackSpeed && s <= widget.config.maxPlaybackSpeed);

  void _incrementSpeed() {
    final nextIdx = _speedSteps.indexWhere((s) => s > _playbackSpeed);
    if (nextIdx != -1 && _speedSteps[nextIdx] <= widget.config.maxPlaybackSpeed) {
      _updatePlaybackSpeed(_speedSteps[nextIdx]);
    }
  }

  void _decrementSpeed() {
    final prevIdx = _speedSteps.lastIndexWhere((s) => s < _playbackSpeed);
    if (prevIdx != -1) {
      _updatePlaybackSpeed(_speedSteps[prevIdx]);
    }
  }

  String get _speedLabel {
    if (_playbackSpeed % 1 == 0) return '${_playbackSpeed.toInt()}x';
    return '${_playbackSpeed.toStringAsFixed(1)}x';
  }

  // ---------------------------------------------------------------------------
  // Clear and Save
  // ---------------------------------------------------------------------------

  /// Resets all state to initial values.
  void _clear() {
    setState(() {
      _stopPlayback();
      _rawPath.clear();
      _pathData = null;
      _serializedData = '';
      _cachedRawPositions = const [];
      _cachedScaledCurves = const [];
      _stopwatch.reset();
      _timeOffset = 0;
      _currentRotation = 0;
      _isRecording = false;
      _pointer1Id = null;
      _pointer1Pos = null;
    });
  }

  /// Passes the serialized path data (or null) to the parent via [onSave].
  void _save() {
    widget.onSave(_serializedData.isNotEmpty ? _serializedData : null);
  }

  // ---------------------------------------------------------------------------
  // Platform detection
  // ---------------------------------------------------------------------------

  /// Returns true if the current platform is a touch device (Android or iOS).
  bool _isTouchDevice(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Show an error message if the image failed to load
    if (_imageError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _imageError!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Show a loading indicator while the image dimensions are being resolved
    if (_imageWidth == null || _imageHeight == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Compute the displayed aspect ratio from image dimensions and crop
    final naturalWidth = max(_imageWidth!, _imageHeight!);
    final naturalHeight = min(_imageWidth!, _imageHeight!);
    final displayedAspectRatio =
        (naturalWidth * widget.config.cropFraction) / naturalHeight;

    final brightness = widget.config.brightness ??
        MediaQuery.platformBrightnessOf(context);

    final isTouch = _isTouchDevice(context);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Field canvas — takes all remaining vertical space,
            // maintains aspect ratio within those bounds.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fit canvas within available space, respecting aspect ratio
                  var canvasWidth = constraints.maxWidth;
                  var canvasHeight = canvasWidth / displayedAspectRatio;

                  if (canvasHeight > constraints.maxHeight) {
                    canvasHeight = constraints.maxHeight;
                    canvasWidth = canvasHeight * displayedAspectRatio;
                  }

                  _canvasSize = Size(canvasWidth, canvasHeight);

                  return Center(
                    child: _buildFieldCanvas(canvasWidth, canvasHeight, isTouch: isTouch),
                  );
                },
              ),
            ),

            // Controls row
            _buildTouchControlsRow(brightness, isTouch: isTouch),
          ],
        ),
      ),
    );
  }

  /// Toggles the help toast overlay on the canvas.
  void _toggleHelp() {
    setState(() => _showingHelp = !_showingHelp);
    if (_showingHelp) {
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _showingHelp) setState(() => _showingHelp = false);
      });
    }
  }

  /// Computes the end-of-path robot position scaled to [canvasSize].
  Offset? _endRobotPos(Size canvasSize) {
    final data = _pathData;
    if (data == null || data.curves.isEmpty) return null;
    final endpoints = data.scaledEndpoints(canvasSize, cropFraction: widget.config.cropFraction);
    return endpoints.last;
  }

  /// Computes the end-of-path robot rotation.
  double get _endRobotRot {
    final data = _pathData;
    if (data == null || data.rotations.isEmpty) return 0;
    return data.rotations.last;
  }

  /// Scales the normalized playback position to pixel coordinates.
  Offset? _scaledPlaybackPos(Size canvasSize) {
    final pos = _playbackRobotPos;
    if (pos == null) return null;
    final scale = BotPathData.scaleFactor(
      BotPathData.version, canvasSize, widget.config.cropFraction,
    );
    return Offset(pos.dx * scale, pos.dy * scale);
  }

  /// Builds the field canvas with background image, path overlay, and
  /// optional rotation dial overlay on touch devices.
  Widget _buildFieldCanvas(double canvasWidth, double canvasHeight, {required bool isTouch}) {
    final canvasSize = Size(canvasWidth, canvasHeight);

    // Drawing surface with pointer handling
    final drawingSurface = Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerSignal: _onPointerSignal,
      child: Stack(
        children: [
          // Background image, cropped from the left
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: canvasWidth / widget.config.cropFraction,
                child: Image(
                  image: widget.config.backgroundImage,
                  width: canvasWidth / widget.config.cropFraction,
                  height: canvasHeight,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // Path overlay
          // Only show raw trail while recording (before curve fitting).
          // Once fitted curves exist, show only those — otherwise both
          // the raw trail and fitted path render simultaneously, producing
          // a "ghost" double-path since they don't perfectly overlap.
          Positioned.fill(
            child: CustomPaint(
              painter: PathPainter(
                config: widget.config,
                rawPath: _pathData != null ? const [] : _getRawPositions(),
                fittedCurves: _getScaledCurves(canvasSize),
                robotPosition: _isRecording ? _pointer1Pos : null,
                robotRotation: _currentRotation,
                endRobotPos: _playbackRobotPos == null
                    ? _endRobotPos(canvasSize)
                    : null,
                endRobotRot: _endRobotRot,
                playbackRobotPos: _scaledPlaybackPos(canvasSize),
                playbackRobotRot: _playbackRobotRot,
                showHighlight: isTouch,
              ),
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        children: [
          // Drawing canvas (Listener handles all pointer events here)
          Positioned.fill(child: drawingSurface),

          // Rotation dial overlay on touch devices — positioned outside
          // the Listener so dial touches don't trigger path drawing.
          if (isTouch)
            Positioned(
              right: 8,
              bottom: 8,
              child: Opacity(
                opacity: 0.8,
                child: RotationDial(
                  size: min(MediaQuery.sizeOf(context).width * 0.2, 100.0),
                  rotation: _currentRotation,
                  onChanged: _onDialRotation,
                  color: widget.config.pathColor,
                ),
              ),
            ),

          // Help toast (touch devices, toggled by info button)
          if (_showingHelp)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isTouch
                        ? 'Draw a path with your finger. '
                            'Use the dial in the corner to set robot heading.'
                        : 'Hold WASD to set initial direction before clicking. '
                            'Click and drag to draw. Q/E rotates. '
                            'Scroll wheel for fine rotation.',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the controls row: info + action buttons + speed +/-.
  Widget _buildTouchControlsRow(Brightness brightness, {required bool isTouch}) {
    final buttonTextColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    final vPad = isTouch
        ? _buttonVerticalPaddingTouch
        : _buttonVerticalPaddingDesktop;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Info button → shows instructions toast
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: _toggleHelp,
            color: buttonTextColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),

          // Action buttons
          Expanded(
            child: Builder(builder: (context) {
              final isPlayingOrComplete =
                  _playbackController.isAnimating || _playbackComplete;
              return _buildControlButton(
                label: isPlayingOrComplete ? 'Stop' : 'Play',
                icon: isPlayingOrComplete ? Icons.stop : Icons.play_arrow,
                onPressed: _pathData != null
                    ? (isPlayingOrComplete
                        ? () => setState(_stopPlayback)
                        : _startPlayback)
                    : null,
                textColor: buttonTextColor,
                verticalPadding: vPad,
              );
            }),
          ),

          // Speed -/+ controls
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: _canDecrementSpeed ? _decrementSpeed : null,
            color: buttonTextColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              _speedLabel,
              style: TextStyle(color: buttonTextColor, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: _canIncrementSpeed ? _incrementSpeed : null,
            color: buttonTextColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _buildControlButton(
              label: 'Clear',
              icon: Icons.delete_outline,
              onPressed: _rawPath.isNotEmpty ? _clear : null,
              textColor: buttonTextColor,
              verticalPadding: vPad,
            ),
          ),
          Expanded(
            child: _buildControlButton(
              label: 'Save',
              icon: Icons.check,
              onPressed: _save,
              textColor: buttonTextColor,
              verticalPadding: vPad,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single control button with an icon and label.
  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color textColor,
    required double verticalPadding,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(
          horizontal: _buttonHorizontalPadding,
          vertical: verticalPadding,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

}
