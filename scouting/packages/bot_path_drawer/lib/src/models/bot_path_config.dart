import 'package:flutter/material.dart';

/// Configuration for [BotPathDrawer] and [BotPathViewer] widgets.
///
/// Controls the appearance and behavior of the path drawing/viewing canvas.
/// All optional parameters have sensible defaults for FRC robot path drawing.
class BotPathConfig {
  /// Background image displayed under the canvas (e.g. a field map).
  ///
  /// The image's aspect ratio is used to size the canvas. The larger
  /// pixel dimension is treated as width, the smaller as height.
  final ImageProvider backgroundImage;

  /// Fraction of the background image to display, cropped from the left.
  ///
  /// For example, 0.70 shows the left 70% of the image. Useful for
  /// showing only the relevant portion of a field (e.g. the autonomous
  /// zone). Range: (0.0, 1.0]. Defaults to 0.70.
  final double cropFraction;

  /// Robot size as a fraction of the displayed canvas width.
  ///
  /// The robot is drawn as a square with this fraction of the canvas
  /// width as its side length. Range: (0.0, 1.0). Defaults to approximately
  /// 0.056, which corresponds to a 27.5-inch FRC robot on a standard FRC
  /// field cropped to 75%.
  final double robotSizeFraction;

  /// Initial playback speed multiplier.
  ///
  /// At 1x speed, playback takes 20 seconds regardless of how long
  /// the original drawing took. At 4x, it takes 5 seconds. Must be
  /// positive. Defaults to 4.0.
  final double defaultPlaybackSpeed;

  /// Maximum allowed playback speed.
  ///
  /// Must be greater than or equal to [defaultPlaybackSpeed].
  /// Defaults to 10.0.
  final double maxPlaybackSpeed;

  /// Base duration of playback at 1x speed, in milliseconds.
  ///
  /// Defaults to 20000 (20 seconds), matching the FRC autonomous period.
  /// The actual playback duration is `playbackDurationMs / playbackSpeed`.
  ///
  /// Set to `null` to use the path's actual recorded duration — the
  /// animation will play back at real-time speed (1x = original speed,
  /// 2x = twice as fast, etc.) with no time normalization.
  ///
  /// Must be > 0 if non-null.
  final int? playbackDurationMs;

  /// Color used for the path line, intake edge, rotation dial indicator,
  /// and touch highlight circle (at reduced opacity).
  ///
  /// Defaults to [Colors.yellow].
  final Color pathColor;

  /// Fill color for the robot body rectangle.
  ///
  /// Defaults to semi-transparent blue: Color(0x332196F3).
  final Color robotColor;

  /// Color for the start-of-path indicator circle. Defaults to [Colors.green].
  final Color startColor;

  /// Color for the end-of-path indicator circle. Defaults to [Colors.red].
  final Color endColor;

  /// Multiplier for the touch highlight circle radius, relative to robot size.
  ///
  /// A value of 5.0 means the highlight circle has 5x the radius of the
  /// robot. Helps with visibility when drawing on a small screen.
  /// Must be positive. Defaults to 5.0.
  final double highlightSizeMultiplier;

  /// Error tolerance for Schneider curve simplification.
  ///
  /// Lower values produce more curves (tighter fit to the drawn path).
  /// Higher values produce fewer curves (more simplified).
  /// Must be positive. Defaults to 50.
  final double simplificationError;

  /// Minimum pixel distance between consecutive recorded points.
  ///
  /// Points closer than this are filtered out to reduce noise from
  /// a stationary or slow-moving finger. Must be non-negative.
  /// Defaults to 2.0.
  final double pointFilterDistance;

  /// Brightness override for UI elements (instructions, buttons).
  ///
  /// If null, the system/theme brightness is used. Set explicitly to
  /// override the system setting.
  final Brightness? brightness;

  /// Creates a new [BotPathConfig].
  ///
  /// Only [backgroundImage] is required. All other parameters have sensible
  /// defaults for FRC robot path drawing on a standard field image.
  BotPathConfig({
    required this.backgroundImage,
    this.cropFraction = 0.70,
    this.robotSizeFraction = 27.5 / (651.2 * 0.70),
    this.defaultPlaybackSpeed = 4.0,
    this.maxPlaybackSpeed = 10.0,
    this.playbackDurationMs = 20000,
    this.pathColor = Colors.yellow,
    this.robotColor = const Color(0x332196F3),
    this.startColor = Colors.green,
    this.endColor = Colors.red,
    this.highlightSizeMultiplier = 5.0,
    this.simplificationError = 50,
    this.pointFilterDistance = 2.0,
    this.brightness,
  })  : assert(cropFraction > 0 && cropFraction <= 1,
            'cropFraction must be in (0, 1]'),
        assert(robotSizeFraction > 0 && robotSizeFraction < 1,
            'robotSizeFraction must be in (0, 1)'),
        assert(defaultPlaybackSpeed > 0, 'defaultPlaybackSpeed must be > 0'),
        assert(maxPlaybackSpeed >= defaultPlaybackSpeed,
            'maxPlaybackSpeed must be >= defaultPlaybackSpeed'),
        assert(playbackDurationMs == null || playbackDurationMs > 0,
            'playbackDurationMs must be > 0 if non-null'),
        assert(highlightSizeMultiplier > 0,
            'highlightSizeMultiplier must be > 0'),
        assert(simplificationError > 0, 'simplificationError must be > 0'),
        assert(pointFilterDistance >= 0, 'pointFilterDistance must be >= 0');

  /// Returns a copy of this config with the given fields replaced.
  ///
  /// Any parameter that is not provided (or null) retains its current value.
  BotPathConfig copyWith({
    ImageProvider? backgroundImage,
    double? cropFraction,
    double? robotSizeFraction,
    double? defaultPlaybackSpeed,
    double? maxPlaybackSpeed,
    int? Function()? playbackDurationMs,
    Color? pathColor,
    Color? robotColor,
    Color? startColor,
    Color? endColor,
    double? highlightSizeMultiplier,
    double? simplificationError,
    double? pointFilterDistance,
    Brightness? brightness,
  }) {
    return BotPathConfig(
      backgroundImage: backgroundImage ?? this.backgroundImage,
      cropFraction: cropFraction ?? this.cropFraction,
      robotSizeFraction: robotSizeFraction ?? this.robotSizeFraction,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      maxPlaybackSpeed: maxPlaybackSpeed ?? this.maxPlaybackSpeed,
      playbackDurationMs: playbackDurationMs != null
          ? playbackDurationMs()
          : this.playbackDurationMs,
      pathColor: pathColor ?? this.pathColor,
      robotColor: robotColor ?? this.robotColor,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
      highlightSizeMultiplier:
          highlightSizeMultiplier ?? this.highlightSizeMultiplier,
      simplificationError: simplificationError ?? this.simplificationError,
      pointFilterDistance: pointFilterDistance ?? this.pointFilterDistance,
      brightness: brightness ?? this.brightness,
    );
  }
}
