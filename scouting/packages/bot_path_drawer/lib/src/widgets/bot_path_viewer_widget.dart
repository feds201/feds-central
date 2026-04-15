import 'dart:math';

import 'package:fit_curve/fit_curve.dart' show CubicCurve;
import 'package:flutter/material.dart';

import '../models/bot_path_config.dart';
import '../models/bot_path_data.dart';
import '../models/bot_viewer_path.dart';
import '../painters/path_painter.dart';
import '../utils/bezier_math.dart';

/// Widget for viewing and playing back recorded robot paths on a field image.
///
/// Supports displaying multiple paths simultaneously, each with its own color.
/// Users can play, stop, and adjust the speed of the path animation.
///
/// ## Single-path usage (legacy)
/// ```dart
/// BotPathViewer(
///   config: BotPathConfig(
///     backgroundImage: AssetImage('assets/field.png'),
///   ),
///   pathData: 'M0.083,0.573C0.098,0.559 0.241,0.397 0.390,0.317|0.00:0,1.57:450',
/// )
/// ```
///
/// ## Multi-path usage
/// ```dart
/// BotPathViewer(
///   config: BotPathConfig(
///     backgroundImage: AssetImage('assets/field.png'),
///   ),
///   paths: [
///     BotViewerPath(pathData: '...', color: Colors.red),
///     BotViewerPath(pathData: '...', color: Colors.blue),
///   ],
/// )
/// ```
class BotPathViewer extends StatefulWidget {
  /// Configuration for appearance and behavior.
  final BotPathConfig config;

  /// The serialized path string to display and play back (legacy single-path API).
  ///
  /// Uses [BotPathConfig.pathColor] and [BotPathConfig.robotColor] for colors.
  /// If [paths] is also provided, [paths] takes precedence and this is ignored.
  final String? pathData;

  /// Multiple paths to display simultaneously, each with its own color.
  ///
  /// When provided, [pathData] is ignored. Each [BotViewerPath.color] is used
  /// for that path's line, robot fill (at 30% opacity), intake edge, and
  /// start/end dot outlines.
  final List<BotViewerPath>? paths;

  /// Creates a [BotPathViewer] widget.
  ///
  /// Either [pathData] or [paths] must be provided. If both are given,
  /// [paths] takes precedence.
  const BotPathViewer({
    super.key,
    required this.config,
    this.pathData,
    this.paths,
  });

  @override
  State<BotPathViewer> createState() => _BotPathViewerState();
}

class _BotPathViewerState extends State<BotPathViewer>
    with SingleTickerProviderStateMixin {
  /// Effective list of paths to render (resolved from props).
  List<BotViewerPath> _effectivePaths = const [];

  /// Parsed path data for each effective path (null if invalid).
  List<BotPathData?> _parsedPaths = const [];

  /// Animation controller driving the playback animation.
  late final AnimationController _playbackController;

  /// Per-path playback robot position during animation (normalized coords).
  List<Offset?> _playbackPositions = const [];

  /// Per-path playback robot rotation during animation.
  List<double> _playbackRotations = const [];

  /// Current playback speed multiplier.
  late double _playbackSpeed;

  /// Resolved background image width in pixels.
  int? _imageWidth;

  /// Resolved background image height in pixels.
  int? _imageHeight;

  /// Whether the image failed to load.
  bool _imageError = false;

  /// The image stream subscription used for resolving image dimensions.
  ImageStream? _imageStream;

  /// The listener attached to [_imageStream].
  ImageStreamListener? _imageStreamListener;

  /// Per-path cached scaled curves for stable shouldRepaint comparisons.
  List<List<CubicCurve>> _cachedScaledCurves = const [];

  /// Canvas size used when [_cachedScaledCurves] was last computed.
  Size _lastScaledSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.config.defaultPlaybackSpeed;
    _playbackController = AnimationController(vsync: this);
    _playbackController.addListener(_onPlaybackTick);
    _playbackController.addStatusListener(_onPlaybackStatus);
    _resolvePaths();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(BotPathViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathData != widget.pathData ||
        oldWidget.paths != widget.paths) {
      _stopPlayback();
      _resolvePaths();
    }
    if (oldWidget.config.backgroundImage != widget.config.backgroundImage) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _playbackController.removeListener(_onPlaybackTick);
    _playbackController.removeStatusListener(_onPlaybackStatus);
    _playbackController.dispose();
    _removeImageListener();
    super.dispose();
  }

  /// Resolves [_effectivePaths] and [_parsedPaths] from widget props.
  void _resolvePaths() {
    if (widget.paths != null) {
      _effectivePaths = widget.paths!;
    } else if (widget.pathData != null) {
      _effectivePaths = [
        BotViewerPath(
          pathData: widget.pathData!,
          color: widget.config.pathColor,
        ),
      ];
    } else {
      _effectivePaths = const [];
    }

    _parsedPaths =
        _effectivePaths.map((p) => BotPathData.tryParse(p.pathData)).toList();
    _playbackPositions = List.filled(_effectivePaths.length, null);
    _playbackRotations = List.filled(_effectivePaths.length, 0.0);
    _cachedScaledCurves = List.filled(_effectivePaths.length, const []);
    _lastScaledSize = Size.zero;
  }

  /// Resolves the background image to obtain its pixel dimensions.
  void _resolveImage() {
    _removeImageListener();
    final provider = widget.config.backgroundImage;
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) return;
        setState(() {
          _imageWidth = info.image.width;
          _imageHeight = info.image.height;
          _imageError = false;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!mounted) return;
        setState(() {
          _imageError = true;
        });
      },
    );
    stream.addListener(listener);
    _imageStream = stream;
    _imageStreamListener = listener;
  }

  /// Removes the current image stream listener if one exists.
  void _removeImageListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  /// Called on each animation frame during playback.
  void _onPlaybackTick() {
    final t = _playbackController.value;

    var changed = false;

    for (var i = 0; i < _parsedPaths.length; i++) {
      final data = _parsedPaths[i];
      if (data == null || data.curves.isEmpty) continue;

      final pathDuration = data.timestamps.last;
      // Every path is normalized to the full animation duration
      final pathT = t;

      if (pathT >= 1.0) {
        // This path has finished — park robot at end
        if (_playbackPositions[i] != null) {
          // Was still animating, now done — show end position
          final lastCurve = data.curves.last;
          _playbackPositions[i] =
              Offset(lastCurve.point2.x, lastCurve.point2.y);
          _playbackRotations[i] = data.rotations.last;
          changed = true;
        }
        continue;
      }

      final currentMs = pathT * pathDuration;

      // Find the curve segment that contains the current time
      var curveIndex = 0;
      for (var ci = 0; ci < data.curves.length; ci++) {
        if (currentMs <= data.timestamps[ci + 1]) {
          curveIndex = ci;
          break;
        }
        curveIndex = ci;
      }

      final segStart = data.timestamps[curveIndex].toDouble();
      final segEnd = data.timestamps[curveIndex + 1].toDouble();
      final segDuration = segEnd - segStart;

      final localT = segDuration > 0
          ? ((currentMs - segStart) / segDuration).clamp(0.0, 1.0)
          : 1.0;

      final pos = evalBezier(data.curves[curveIndex], localT);
      final rot = lerpAngle(
        data.rotations[curveIndex],
        data.rotations[curveIndex + 1],
        localT,
      );

      _playbackPositions[i] = pos;
      _playbackRotations[i] = rot;
      changed = true;
    }

    if (changed) setState(() {});
  }

  /// Called when the playback animation status changes.
  void _onPlaybackStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _playbackPositions = List.filled(_effectivePaths.length, null);
        _playbackRotations = List.filled(_effectivePaths.length, 0.0);
      });
    }
  }

  /// Base playback duration at 1x speed, in milliseconds.
  ///
  /// Uses the configured [BotPathConfig.playbackDurationMs] if set,
  /// otherwise falls back to the longest path's actual recorded duration.
  int get _baseDurationMs {
    if (widget.config.playbackDurationMs != null) {
      return widget.config.playbackDurationMs!;
    }
    var maxDuration = 0;
    for (final data in _parsedPaths) {
      if (data != null && data.timestamps.isNotEmpty) {
        maxDuration = max(maxDuration, data.timestamps.last);
      }
    }
    return maxDuration > 0 ? maxDuration : 1;
  }

  /// Whether any paths have valid data.
  bool get _hasValidPaths => _parsedPaths.any((p) => p != null);

  /// Starts playback of the path animation.
  void _startPlayback() {
    if (!_hasValidPaths) return;

    final durationMs = (_baseDurationMs / _playbackSpeed).round();
    _playbackController.duration = Duration(milliseconds: durationMs);

    _playbackController.forward(from: 0);
  }

  /// Stops playback and resets to the initial state.
  void _stopPlayback() {
    _playbackController.stop();
    _playbackController.reset();
    setState(() {
      _playbackPositions = List.filled(_effectivePaths.length, null);
      _playbackRotations = List.filled(_effectivePaths.length, 0.0);
    });
  }

  /// Updates playback speed. If currently playing, adjusts duration and
  /// continues from the current progress.
  void _updatePlaybackSpeed(double newSpeed) {
    setState(() {
      _playbackSpeed = newSpeed;
    });

    if (_playbackController.isAnimating) {
      final currentValue = _playbackController.value;
      final durationMs = (_baseDurationMs / _playbackSpeed).round();
      _playbackController.duration = Duration(milliseconds: durationMs);
      _playbackController.forward(from: currentValue);
    }
  }

  // ---------------------------------------------------------------------------
  // Discrete speed steps
  // ---------------------------------------------------------------------------

  static const _speedSteps = [0.5, 1.0, 2.0, 4.0, 5.0, 10.0];

  bool get _canDecrementSpeed =>
      _speedSteps.any((s) => s < _playbackSpeed);

  bool get _canIncrementSpeed =>
      _speedSteps.any(
          (s) => s > _playbackSpeed && s <= widget.config.maxPlaybackSpeed);

  void _incrementSpeed() {
    final nextIdx = _speedSteps.indexWhere((s) => s > _playbackSpeed);
    if (nextIdx != -1 &&
        _speedSteps[nextIdx] <= widget.config.maxPlaybackSpeed) {
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

  /// Returns cached scaled curves for path at [index], recomputing only
  /// when the canvas size changes.
  List<CubicCurve> _getScaledCurves(int index, Size canvasSize) {
    final data = _parsedPaths[index];
    if (data == null) return const [];
    if (_lastScaledSize == canvasSize &&
        _cachedScaledCurves[index].isNotEmpty) {
      return _cachedScaledCurves[index];
    }
    // If canvas size changed, invalidate all caches
    if (_lastScaledSize != canvasSize) {
      _cachedScaledCurves = List.filled(_effectivePaths.length, const []);
      _lastScaledSize = canvasSize;
    }
    _cachedScaledCurves[index] = data.scaledCurves(canvasSize, cropFraction: widget.config.cropFraction);
    return _cachedScaledCurves[index];
  }

  /// Computes the end-of-path robot position for path at [index].
  Offset? _endRobotPos(int index, Size canvasSize) {
    final data = _parsedPaths[index];
    if (data == null || data.curves.isEmpty) return null;
    final endpoints = data.scaledEndpoints(canvasSize, cropFraction: widget.config.cropFraction);
    return endpoints.last;
  }

  /// Computes the end-of-path robot rotation for path at [index].
  double _endRobotRot(int index) {
    final data = _parsedPaths[index];
    if (data == null || data.rotations.isEmpty) return 0;
    return data.rotations.last;
  }

  /// Scales a normalized playback position to pixel coordinates for path at [index].
  Offset? _scaledPlaybackPos(int index, Size canvasSize) {
    final pos = _playbackPositions[index];
    if (pos == null) return null;
    final data = _parsedPaths[index];
    if (data == null) return null;
    final scale = BotPathData.scaleFactor(
      data.formatVersion, canvasSize, widget.config.cropFraction,
    );
    return Offset(pos.dx * scale, pos.dy * scale);
  }

  /// Builds the per-path config with color overrides.
  BotPathConfig _configForPath(int index) {
    final color = _effectivePaths[index].color;
    return widget.config.copyWith(
      pathColor: color,
      robotColor: color.withAlpha(0x4D),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if image failed to load
    if (_imageError) {
      return const Center(
        child: Text('Failed to load background image'),
      );
    }

    // While the image is still resolving, show a loading indicator
    if (_imageWidth == null || _imageHeight == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Compute aspect ratio: larger dimension is width, smaller is height
    final largerDim = max(_imageWidth!, _imageHeight!);
    final smallerDim = min(_imageWidth!, _imageHeight!);
    final cropFraction = widget.config.cropFraction;
    final displayedAspectRatio = (largerDim * cropFraction) / smallerDim;

    // Determine brightness for button styling
    final brightness = widget.config.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final buttonTextColor = isDark ? Colors.white : Colors.black;
    final buttonBgColor =
        isDark ? Colors.white12 : Colors.black.withAlpha(15);

    final isPlaying = _playbackController.isAnimating;

    return Column(
      children: [
        // Field canvas — takes remaining vertical space, respects aspect ratio
        Expanded(
          child: LayoutBuilder(
              builder: (context, constraints) {
                var canvasWidth = constraints.maxWidth;
                var canvasHeight = canvasWidth / displayedAspectRatio;

                if (canvasHeight > constraints.maxHeight) {
                  canvasHeight = constraints.maxHeight;
                  canvasWidth = canvasHeight * displayedAspectRatio;
                }

                final canvasSize = Size(canvasWidth, canvasHeight);

                return Center(
                  child: SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: Stack(
                      children: [
                        // Cropped background image
                        Positioned.fill(
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              maxWidth: canvasWidth / cropFraction,
                              child: Image(
                                image: widget.config.backgroundImage,
                                fit: BoxFit.fill,
                                width: canvasWidth / cropFraction,
                                height: canvasHeight,
                              ),
                            ),
                          ),
                        ),
                        // Path overlays — one painter per path
                        for (var i = 0; i < _effectivePaths.length; i++)
                          if (_parsedPaths[i] != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: PathPainter(
                                  config: _configForPath(i),
                                  rawPath: const [],
                                  fittedCurves:
                                      _getScaledCurves(i, canvasSize),
                                  robotPosition: null,
                                  robotRotation: 0,
                                  endRobotPos: _playbackPositions[i] == null
                                      ? _endRobotPos(i, canvasSize)
                                      : null,
                                  endRobotRot: _endRobotRot(i),
                                  playbackRobotPos:
                                      _scaledPlaybackPos(i, canvasSize),
                                  playbackRobotRot: _playbackRotations[i],
                                  showHighlight: false,
                                  alliance: _effectivePaths[i].alliance,
                                  mirrored: _effectivePaths[i].mirrored,
                                ),
                              ),
                            ),
                        // Play/Stop toggle + speed controls
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ControlButton(
                                icon: isPlaying
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                label: isPlaying ? 'Stop' : 'Play',
                                onPressed: _hasValidPaths
                                    ? (isPlaying
                                        ? _stopPlayback
                                        : _startPlayback)
                                    : null,
                                textColor: buttonTextColor,
                                bgColor: buttonBgColor,
                              ),
                              const SizedBox(height: 4),
                              _SpeedControl(
                                speedLabel: _speedLabel,
                                canDecrement: _canDecrementSpeed,
                                canIncrement: _canIncrementSpeed,
                                onDecrement: _decrementSpeed,
                                onIncrement: _incrementSpeed,
                                textColor: buttonTextColor,
                                bgColor: buttonBgColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// A small labeled icon button used for playback controls.
class _ControlButton extends StatelessWidget {
  /// The icon to display in the button.
  final IconData icon;

  /// The text label displayed next to the icon.
  final String label;

  /// Called when the button is pressed, or null if the button is disabled.
  final VoidCallback? onPressed;

  /// Text and icon color when enabled.
  final Color textColor;

  /// Button background color.
  final Color bgColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final effectiveColor = isDisabled
        ? Theme.of(context).disabledColor
        : textColor;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: effectiveColor, size: 18),
      label: Text(
        label,
        style: TextStyle(color: effectiveColor, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Speed control row: [−] speed [+], styled to match [_ControlButton].
class _SpeedControl extends StatelessWidget {
  final String speedLabel;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color textColor;
  final Color bgColor;

  const _SpeedControl({
    required this.speedLabel,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = textColor.withAlpha(77);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: canDecrement ? onDecrement : null,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.remove,
              size: 18,
              color: canDecrement ? textColor : disabledColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              speedLabel,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          InkWell(
            onTap: canIncrement ? onIncrement : null,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.add,
              size: 18,
              color: canIncrement ? textColor : disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
