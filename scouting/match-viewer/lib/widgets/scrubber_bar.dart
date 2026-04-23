import 'package:flutter/material.dart';

/// Vertical scrubber bar for the video viewer.
///
/// Positioned between the video panes and the control sidebar.
/// 0:00 is at the bottom, duration at the top. Shows current position
/// and total duration labels above/below the slider.
/// During user drag, position stream updates are suppressed via [isDragging].
class ScrubberBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final bool isDragging;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<bool> onDragStateChanged;

  const ScrubberBar({
    super.key,
    required this.position,
    required this.duration,
    required this.isDragging,
    required this.onSeek,
    required this.onDragStateChanged,
  });

  @override
  State<ScrubberBar> createState() => _ScrubberBarState();
}

class _ScrubberBarState extends State<ScrubberBar> {
  double? _dragValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double get _maxMs => widget.duration.inMilliseconds.toDouble().clamp(1, double.infinity);
  double get _currentMs =>
      (_dragValue ?? widget.position.inMilliseconds.toDouble()).clamp(0, _maxMs);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Duration label at top
          Text(
            _formatDuration(widget.duration),
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          // Vertical slider (rotated from horizontal)
          Expanded(
            child: RotatedBox(
              quarterTurns: 3, // Rotate so bottom = 0, top = max
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                ),
                child: Slider(
                  value: _currentMs,
                  min: 0,
                  max: _maxMs,
                  onChangeStart: (_) {
                    widget.onDragStateChanged(true);
                  },
                  onChanged: (value) {
                    setState(() => _dragValue = value);
                  },
                  onChangeEnd: (value) {
                    final seekPos = Duration(milliseconds: value.round());
                    _dragValue = null;
                    widget.onDragStateChanged(false);
                    widget.onSeek(seekPos);
                  },
                ),
              ),
            ),
          ),
          // Current position label at bottom
          Text(
            _formatDuration(
              Duration(milliseconds: _currentMs.round()),
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
