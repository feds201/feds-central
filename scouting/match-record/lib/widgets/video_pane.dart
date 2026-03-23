import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../viewer/drawing_controller.dart';
import 'drawing_overlay.dart';

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
  final DrawingController? drawingController;

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
    this.drawingController,
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
            // Video display
            Positioned.fill(
              child: Video(
                controller: videoController,
                controls: NoVideoControls,
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
            // Edit (pencil) icon in corner
            if (onEdit != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
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
            // Drawing overlay (when drawing mode is active)
            if (isDrawingMode && drawingController != null)
              Positioned.fill(
                child: DrawingOverlay(controller: drawingController!),
              ),
            // Drawing display (when not in drawing mode but strokes exist)
            if (!isDrawingMode && drawingController != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: drawingController!,
                    builder: (context, _) {
                      if (drawingController!.strokes.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        painter: _PassiveStrokePainter(
                          strokes: drawingController!.strokes,
                          opacity: drawingController!.opacity,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),
            // Touch scrub gesture detector (below drawing overlay)
            if (!isDrawingMode)
              Positioned.fill(
                child: _ScrubGestureDetector(
                  paneWidth: constraints.maxWidth,
                  onScrubStart: onScrubStart,
                  onScrubUpdate: onScrubUpdate,
                  onScrubEnd: onScrubEnd,
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

/// Simplified stroke painter for passive (non-drawing-mode) display.
class _PassiveStrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double opacity;

  _PassiveStrokePainter({
    required this.strokes,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 1.75, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length - 1; i++) {
        final midX = (stroke[i].dx + stroke[i + 1].dx) / 2;
        final midY = (stroke[i].dy + stroke[i + 1].dy) / 2;
        path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, midX, midY);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PassiveStrokePainter oldDelegate) => true;
}
