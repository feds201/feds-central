import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// One side of the dual-video viewer.
///
/// A dumb renderer: displays a video. Countdown/ended overlays are rendered
/// in the chrome overlay layer (outside InteractiveViewer) so they don't
/// zoom or pan with the video.
/// All gesture handling (scrub, draw, zoom) is managed by the parent widget tree.
class VideoPane extends StatelessWidget {
  final Player player;
  final VideoController videoController;

  /// How the video should be fitted within the pane.
  final BoxFit fit;

  const VideoPane({
    super.key,
    required this.player,
    required this.videoController,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: videoController,
      controls: NoVideoControls,
      fit: fit,
    );
  }
}
