import 'dart:math';

import 'package:fit_curve/fit_curve.dart' show CubicCurve;
import 'package:flutter/material.dart';

import '../models/bot_path_config.dart';
import '../models/bot_path_data.dart';
import '../painters/path_painter.dart';
import '../utils/bezier_math.dart';

/// Widget for viewing and playing back a recorded robot path on a field image.
///
/// Takes a serialized path string (from [BotPathDrawer]) and displays it
/// on a field image with playback controls. Users can play, stop, and
/// adjust the speed of the path animation.
///
/// ## Usage
/// ```dart
/// BotPathViewer(
///   config: BotPathConfig(
///     backgroundImage: AssetImage('assets/field.png'),
///   ),
///   pathData: 'M0.083,0.573C0.098,0.559 0.241,0.397 0.390,0.317|0.00:0,1.57:450',
/// )
/// ```
class BotPathViewer extends StatefulWidget {
  /// Configuration for appearance and behavior.
  final BotPathConfig config;

  /// The serialized path string to display and play back.
  ///
  /// This should be a string produced by [BotPathDrawer] via the [onSave]
  /// callback. If the string is invalid, the widget shows just the field
  /// image with no path overlay.
  final String pathData;

  /// Creates a [BotPathViewer] widget.
  const BotPathViewer({
    super.key,
    required this.config,
    required this.pathData,
  });

  @override
  State<BotPathViewer> createState() => _BotPathViewerState();
}

class _BotPathViewerState extends State<BotPathViewer>
    with SingleTickerProviderStateMixin {
  /// Parsed path data in normalized coordinates, null if invalid.
  BotPathData? _pathData;

  /// Animation controller driving the playback animation.
  late final AnimationController _playbackController;

  /// Current position of the playback robot during animation (pixel coords).
  Offset? _playbackRobotPos;

  /// Current rotation of the playback robot during animation.
  double _playbackRobotRot = 0;

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

  /// Cached scaled curves for stable references in shouldRepaint comparisons.
  List<CubicCurve> _cachedScaledCurves = const [];

  /// Canvas size used when [_cachedScaledCurves] was last computed.
  Size _lastScaledSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.config.defaultPlaybackSpeed;
    _playbackController = AnimationController(vsync: this);
    _playbackController.addListener(_onPlaybackTick);
    _playbackController.addStatusListener(_onPlaybackStatus);
    _pathData = BotPathData.tryParse(widget.pathData);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(BotPathViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathData != widget.pathData) {
      _stopPlayback();
      _pathData = BotPathData.tryParse(widget.pathData);
      _cachedScaledCurves = const [];
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
    final data = _pathData;
    if (data == null || data.curves.isEmpty) return;

    final t = _playbackController.value;
    final totalDuration = data.timestamps.last;
    final currentMs = t * totalDuration;

    // Find the curve segment that contains the current time
    var curveIndex = 0;
    for (var i = 0; i < data.curves.length; i++) {
      if (currentMs <= data.timestamps[i + 1]) {
        curveIndex = i;
        break;
      }
      curveIndex = i;
    }

    final segStart = data.timestamps[curveIndex].toDouble();
    final segEnd = data.timestamps[curveIndex + 1].toDouble();
    final segDuration = segEnd - segStart;

    final localT = segDuration > 0
        ? ((currentMs - segStart) / segDuration).clamp(0.0, 1.0)
        : 1.0;

    // Evaluate bezier on normalized curves, then scale to pixels
    final pos = evalBezier(data.curves[curveIndex], localT);
    final rot = lerpAngle(
      data.rotations[curveIndex],
      data.rotations[curveIndex + 1],
      localT,
    );

    setState(() {
      _playbackRobotPos = pos;
      _playbackRobotRot = rot;
    });
  }

  /// Called when the playback animation status changes.
  void _onPlaybackStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _playbackRobotPos = null;
        _playbackRobotRot = 0;
      });
    }
  }

  /// Base playback duration at 1x speed, in milliseconds.
  ///
  /// Uses the configured [BotPathConfig.playbackDurationMs] if set,
  /// otherwise falls back to the path's actual recorded duration.
  int get _baseDurationMs =>
      widget.config.playbackDurationMs ?? _pathData!.timestamps.last;

  /// Starts playback of the path animation.
  void _startPlayback() {
    final data = _pathData;
    if (data == null || data.curves.isEmpty) return;

    final durationMs = (_baseDurationMs / _playbackSpeed).round();
    _playbackController.duration = Duration(milliseconds: durationMs);

    _playbackController.forward(from: 0);
  }

  /// Stops playback and resets to the initial state.
  void _stopPlayback() {
    _playbackController.stop();
    _playbackController.reset();
    setState(() {
      _playbackRobotPos = null;
      _playbackRobotRot = 0;
    });
  }

  /// Updates the playback speed, adjusting the animation duration if playing.
  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });

    if (_playbackController.isAnimating) {
      final currentValue = _playbackController.value;
      final durationMs = (_baseDurationMs / _playbackSpeed).round();
      _playbackController.duration = Duration(milliseconds: durationMs);
      _playbackController.forward(from: currentValue);
    }
  }

  /// Returns cached scaled curves, recomputing only when the canvas size
  /// changes or the cache has been invalidated.
  List<CubicCurve> _getScaledCurves(Size canvasSize) {
    if (_pathData == null) return const [];
    if (_lastScaledSize == canvasSize && _cachedScaledCurves.isNotEmpty) {
      return _cachedScaledCurves;
    }
    _cachedScaledCurves = _pathData!.scaledCurves(canvasSize);
    _lastScaledSize = canvasSize;
    return _cachedScaledCurves;
  }

  /// Computes the end-of-path robot position from the parsed path data,
  /// scaled to the given [canvasSize].
  Offset? _endRobotPos(Size canvasSize) {
    final data = _pathData;
    if (data == null || data.curves.isEmpty) return null;
    final endpoints = data.scaledEndpoints(canvasSize);
    return endpoints.last;
  }

  /// Computes the end-of-path robot rotation from the parsed path data.
  double get _endRobotRot {
    final data = _pathData;
    if (data == null || data.rotations.isEmpty) return 0;
    return data.rotations.last;
  }

  /// Scales a normalized playback position to pixel coordinates.
  Offset? _scaledPlaybackPos(Size canvasSize) {
    final pos = _playbackRobotPos;
    if (pos == null) return null;
    final scale = max(canvasSize.width, canvasSize.height);
    return Offset(pos.dx * scale, pos.dy * scale);
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

    // Determine brightness for button/slider styling
    final brightness = widget.config.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final buttonTextColor = isDark ? Colors.white : Colors.black;
    final sliderActiveColor = isDark ? Colors.white : Colors.black;
    final sliderInactiveColor = isDark ? Colors.white38 : Colors.black38;
    final buttonBgColor =
        isDark ? Colors.white12 : Colors.black.withAlpha(15);

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
                        // Path overlay
                        if (_pathData != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PathPainter(
                                config: widget.config,
                                rawPath: const [],
                                fittedCurves:
                                    _getScaledCurves(canvasSize),
                                robotPosition: null,
                                robotRotation: 0,
                                endRobotPos: _playbackRobotPos == null
                                    ? _endRobotPos(canvasSize)
                                    : null,
                                endRobotRot: _endRobotRot,
                                playbackRobotPos:
                                    _scaledPlaybackPos(canvasSize),
                                playbackRobotRot: _playbackRobotRot,
                                showHighlight: false,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        // Playback controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Play / Stop buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ControlButton(
                            icon: Icons.play_arrow,
                            label: 'Play',
                            onPressed:
                                _pathData != null ? _startPlayback : null,
                            textColor: buttonTextColor,
                            bgColor: buttonBgColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ControlButton(
                            icon: Icons.stop,
                            label: 'Stop',
                            onPressed:
                                _pathData != null ? _stopPlayback : null,
                            textColor: buttonTextColor,
                            bgColor: buttonBgColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Speed slider
                    Row(
                      children: [
                        Text(
                          'Speed: ${_playbackSpeed.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: buttonTextColor,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _playbackSpeed,
                            min: 0.5,
                            max: widget.config.maxPlaybackSpeed,
                            onChanged: _setPlaybackSpeed,
                            activeColor: sliderActiveColor,
                            inactiveColor: sliderInactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
