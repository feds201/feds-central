import 'package:flutter/material.dart';

/// Mute state for the video viewer audio.
enum MuteState { muted, redAudio, blueAudio }

/// View mode for the video viewer layout.
enum ViewMode { both, redOnly, blueOnly }

/// Sidebar control panel for the video viewer.
///
/// ~72px wide, dark background, contains all playback and drawing controls.
/// Scrollable if controls overflow the available height.
class ControlSidebar extends StatelessWidget {
  final bool isPlaying;
  final MuteState muteState;
  final ViewMode viewMode;
  final bool isDrawingMode;
  final bool canUndo;
  final bool canRedo;
  final bool hasDualVideo;
  final bool isPaused;

  final VoidCallback onBack;
  final VoidCallback onSwapSides;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleViewMode;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind10;
  final VoidCallback onForward10;
  final VoidCallback onRestart;
  final VoidCallback onToggleDrawing;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClearDrawing;

  const ControlSidebar({
    super.key,
    required this.isPlaying,
    required this.muteState,
    required this.viewMode,
    required this.isDrawingMode,
    required this.canUndo,
    required this.canRedo,
    required this.hasDualVideo,
    required this.isPaused,
    required this.onBack,
    required this.onSwapSides,
    required this.onToggleMute,
    required this.onToggleViewMode,
    required this.onPlayPause,
    required this.onRewind10,
    required this.onForward10,
    required this.onRestart,
    required this.onToggleDrawing,
    required this.onUndo,
    required this.onRedo,
    required this.onClearDrawing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: const Color(0xFF1E1E1E),
      child: SafeArea(
        left: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onPressed: onBack,
              ),
              if (hasDualVideo) ...[
                const Divider(indent: 8, endIndent: 8),
                _buildButton(
                  icon: Icons.swap_horiz,
                  tooltip: 'Swap sides',
                  onPressed: onSwapSides,
                ),
                _buildMuteButton(),
                _buildViewModeButton(),
              ],
              const Divider(indent: 8, endIndent: 8),
              _buildButton(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: onPlayPause,
              ),
              _buildButton(
                icon: Icons.replay_10,
                tooltip: 'Rewind 10s',
                onPressed: onRewind10,
              ),
              _buildButton(
                icon: Icons.forward_10,
                tooltip: 'Forward 10s',
                onPressed: onForward10,
              ),
              _buildButton(
                icon: Icons.restart_alt,
                tooltip: 'Restart',
                onPressed: onRestart,
              ),
              if (isPaused) ...[
                const Divider(indent: 8, endIndent: 8),
                _buildButton(
                  icon: Icons.edit,
                  tooltip: isDrawingMode ? 'Exit drawing' : 'Draw',
                  onPressed: onToggleDrawing,
                  isActive: isDrawingMode,
                ),
                if (isDrawingMode) ...[
                  _buildButton(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                    onPressed: canUndo ? onUndo : null,
                  ),
                  _buildButton(
                    icon: Icons.redo,
                    tooltip: 'Redo',
                    onPressed: canRedo ? onRedo : null,
                  ),
                  _buildButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Clear drawings',
                    onPressed: onClearDrawing,
                  ),
                ],
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        color: isActive ? Colors.blue : Colors.white,
        disabledColor: Colors.white38,
        iconSize: 24,
      ),
    );
  }

  Widget _buildMuteButton() {
    IconData icon;
    Color? circleColor;

    switch (muteState) {
      case MuteState.muted:
        icon = Icons.volume_off;
        circleColor = null;
      case MuteState.redAudio:
        icon = Icons.volume_up;
        circleColor = Colors.red;
      case MuteState.blueAudio:
        icon = Icons.volume_up;
        circleColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: _muteTooltip,
        child: Container(
          decoration: circleColor != null
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: circleColor, width: 2),
                )
              : null,
          child: IconButton(
            icon: Icon(icon),
            onPressed: onToggleMute,
            color: Colors.white,
            iconSize: 24,
          ),
        ),
      ),
    );
  }

  String get _muteTooltip {
    switch (muteState) {
      case MuteState.muted:
        return 'Muted';
      case MuteState.redAudio:
        return 'Red audio';
      case MuteState.blueAudio:
        return 'Blue audio';
    }
  }

  Widget _buildViewModeButton() {
    IconData icon;
    String tooltip;

    switch (viewMode) {
      case ViewMode.both:
        icon = Icons.view_column;
        tooltip = 'Viewing both';
      case ViewMode.redOnly:
        icon = Icons.crop_square;
        tooltip = 'Red only';
      case ViewMode.blueOnly:
        icon = Icons.crop_square;
        tooltip = 'Blue only';
    }

    return _buildButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: hasDualVideo ? onToggleViewMode : null,
    );
  }
}
