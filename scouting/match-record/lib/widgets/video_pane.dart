import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// One side of the dual-video viewer.
///
/// Displays a video with countdown overlay when waiting for sync, and touch
/// scrub support. Alliance color bar and star icon are rendered outside the
/// RotatedBox in _buildZoomablePane so they don't rotate with the video.
class VideoPane extends StatelessWidget {
  final Player player;
  final VideoController videoController;
  final bool isDrawingMode;

  /// Whether this pane is waiting for the other side to catch up (countdown).
  final bool isWaiting;

  /// Countdown text to display while waiting.
  final Duration countdownRemaining;

  /// Whether the video has ended (earlier position past later's duration).
  final bool hasEnded;

  /// Callback when touch scrub gesture starts (pauses playback).
  final VoidCallback? onScrubStart;

  /// Callback during touch scrub with the horizontal delta from touch origin.
  final void Function(double deltaX, double paneWidth)? onScrubUpdate;

  /// Callback when touch scrub gesture ends.
  final VoidCallback? onScrubEnd;

  const VideoPane({
    super.key,
    required this.player,
    required this.videoController,
    this.isDrawingMode = false,
    this.isWaiting = false,
    this.countdownRemaining = Duration.zero,
    this.hasEnded = false,
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Video display (rotation is handled by the parent RotatedBox
            // in _buildZoomablePane, so no RotatedBox here)
            Positioned.fill(
              child: Video(
                controller: videoController,
                controls: NoVideoControls,
              ),
            ),
            // Touch scrub gesture detector (not shown during drawing mode
            // since drawing is handled by a screen-wide overlay in VideoViewer).
            // Placed before buttons/overlays so they receive taps on top of it.
            if (!isDrawingMode)
              Positioned.fill(
                child: _ScrubGestureDetector(
                  paneWidth: constraints.maxWidth,
                  onScrubStart: onScrubStart,
                  onScrubUpdate: onScrubUpdate,
                  onScrubEnd: onScrubEnd,
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
      },
    );
  }
}

/// Handles the touch-scrub gesture: pan down = pause, pan horizontally = scrub.
class _ScrubGestureDetector extends StatefulWidget {
  final double paneWidth;
  final VoidCallback? onScrubStart;
  final void Function(double deltaX, double paneWidth)? onScrubUpdate;
  final VoidCallback? onScrubEnd;

  const _ScrubGestureDetector({
    required this.paneWidth,
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,
  });

  @override
  State<_ScrubGestureDetector> createState() => _ScrubGestureDetectorState();
}

class _ScrubGestureDetectorState extends State<_ScrubGestureDetector> {
  double? _startX;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _startX = details.localPosition.dx;
        widget.onScrubStart?.call();
      },
      onPanUpdate: (details) {
        if (_startX != null) {
          final deltaX = details.localPosition.dx - _startX!;
          widget.onScrubUpdate?.call(deltaX, widget.paneWidth);
        }
      },
      onPanEnd: (_) {
        _startX = null;
        widget.onScrubEnd?.call();
      },
      onPanCancel: () {
        _startX = null;
      },
      child: const SizedBox.expand(),
    );
  }
}
