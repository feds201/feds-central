import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// One side of the dual-video viewer.
///
/// A dumb renderer: displays a video with countdown/ended overlays.
/// All gesture handling (scrub, draw, zoom) is managed by the parent widget tree.
class VideoPane extends StatelessWidget {
  final Player player;
  final VideoController videoController;

  /// Whether this pane is waiting for the other side to catch up (countdown).
  final bool isWaiting;

  /// Countdown text to display while waiting.
  final Duration countdownRemaining;

  /// Whether the video has ended (earlier position past later's duration).
  final bool hasEnded;

  /// How the video should be fitted within the pane.
  final BoxFit fit;

  const VideoPane({
    super.key,
    required this.player,
    required this.videoController,
    this.isWaiting = false,
    this.countdownRemaining = Duration.zero,
    this.hasEnded = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Video(
            controller: videoController,
            controls: NoVideoControls,
            fit: fit,
          ),
        ),
        // Countdown overlay when waiting for sync
        if (isWaiting)
          Positioned.fill(
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
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'Video ended',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
