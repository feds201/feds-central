import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// One side of the dual-video viewer.
///
/// Displays a video with alliance color bar at top, star icon if the user's
/// team is present, countdown overlay when waiting for sync, and touch scrub
/// support.
class VideoPane extends StatelessWidget {
  final Player player;
  final VideoController videoController;
  final Color allianceColor;
  final bool containsUserTeam;
  final bool isDrawingMode;

  /// Number of 90-degree clockwise rotations to apply to the video (0-3).
  final int quarterTurns;

  /// Callback to rotate this video pane 90 degrees.
  final VoidCallback? onRotate;

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

  /// Callback to open metadata editing for this pane's recording.
  final VoidCallback? onEdit;

  const VideoPane({
    super.key,
    required this.player,
    required this.videoController,
    required this.allianceColor,
    this.containsUserTeam = false,
    this.isDrawingMode = false,
    this.quarterTurns = 0,
    this.onRotate,
    this.isWaiting = false,
    this.countdownRemaining = Duration.zero,
    this.hasEnded = false,
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Video display (rotated if quarterTurns != 0)
            Positioned.fill(
              child: RotatedBox(
                quarterTurns: quarterTurns,
                child: Video(
                  controller: videoController,
                  controls: NoVideoControls,
                ),
              ),
            ),
            // Alliance color bar at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                color: allianceColor,
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
            // Star icon for user's team
            if (containsUserTeam)
              Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.star,
                  color: Colors.yellow.shade600,
                  size: 20,
                ),
              ),
            // Rotate and edit buttons in top-right corner
            Positioned(
              top: 2,
              right: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRotate != null)
                    _PaneButton(
                      icon: Icons.rotate_90_degrees_cw,
                      onTap: onRotate!,
                    ),
                  if (onRotate != null && onEdit != null)
                    const SizedBox(width: 2),
                  if (onEdit != null)
                    _PaneButton(
                      icon: Icons.edit,
                      onTap: onEdit!,
                    ),
                ],
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

/// A small button overlaid on the video pane with adequate touch target (40x40).
class _PaneButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PaneButton({required this.icon, required this.onTap});

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
