import 'package:flutter/material.dart';

/// Mute state for the video viewer audio.
enum MuteState { muted, redAudio, blueAudio }

/// View mode for the video viewer layout.
enum ViewMode { both, redOnly, blueOnly }

/// Sidebar control panel for the video viewer.
///
/// In dual-video (both) mode: ~180px wide with text labels next to icons.
/// In single-video mode: ~72px wide with icons only.
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

  /// Show expanded labels when both panes are visible (more horizontal space available).
  bool get _expanded => viewMode == ViewMode.both;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _expanded ? 160 : 72,
      color: const Color(0xFF1E1E1E),
      child: SafeArea(
        left: false,
        right: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildItem(
                icon: Icons.arrow_back,
                label: 'Back',
                onPressed: onBack,
              ),
              if (hasDualVideo) ...[
                const Divider(indent: 8, endIndent: 8),
                _buildItem(
                  icon: Icons.swap_horiz,
                  label: 'Swap',
                  onPressed: onSwapSides,
                ),
                _buildMuteItem(),
                _buildViewModeItem(),
              ],
              const Divider(indent: 8, endIndent: 8),
              _buildItem(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                label: isPlaying ? 'Pause' : 'Play',
                onPressed: onPlayPause,
              ),
              _buildItem(
                icon: Icons.replay_10,
                label: '-10s',
                onPressed: onRewind10,
              ),
              _buildItem(
                icon: Icons.forward_10,
                label: '+10s',
                onPressed: onForward10,
              ),
              _buildItem(
                icon: Icons.restart_alt,
                label: 'Restart',
                onPressed: onRestart,
              ),
              if (isPaused) ...[
                const Divider(indent: 8, endIndent: 8),
                _buildItem(
                  icon: Icons.edit,
                  label: isDrawingMode ? 'Exit draw' : 'Draw',
                  onPressed: onToggleDrawing,
                  isActive: isDrawingMode,
                ),
                if (isDrawingMode) ...[
                  _buildItem(
                    icon: Icons.undo,
                    label: 'Undo',
                    onPressed: canUndo ? onUndo : null,
                  ),
                  _buildItem(
                    icon: Icons.redo,
                    label: 'Redo',
                    onPressed: canRedo ? onRedo : null,
                  ),
                  _buildItem(
                    icon: Icons.ink_eraser,
                    label: 'Clear',
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

  /// Build a button row: icon-only in compact mode, icon+label in expanded mode.
  Widget _buildItem({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isActive = false,
  }) {
    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: IconButton(
          icon: Icon(icon),
          tooltip: label,
          onPressed: onPressed,
          color: isActive ? Colors.blue : Colors.white,
          disabledColor: Colors.white38,
          iconSize: 24,
        ),
      );
    }

    final color = onPressed == null
        ? Colors.white38
        : isActive
            ? Colors.blue
            : Colors.white;

    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuteItem() {
    IconData icon;
    Color? circleColor;
    String label;

    switch (muteState) {
      case MuteState.muted:
        icon = Icons.volume_off;
        circleColor = null;
        label = 'Muted';
      case MuteState.redAudio:
        icon = Icons.volume_up;
        circleColor = Colors.red;
        label = 'Red audio';
      case MuteState.blueAudio:
        icon = Icons.volume_up;
        circleColor = Colors.blue;
        label = 'Blue audio';
    }

    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Tooltip(
          message: label,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: circleColor ?? Colors.transparent,
                width: 2,
              ),
            ),
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

    return InkWell(
      onTap: onToggleMute,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: circleColor ?? Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeItem() {
    IconData icon;
    String label;

    switch (viewMode) {
      case ViewMode.both:
        icon = Icons.splitscreen;
        label = 'Both sides';
      case ViewMode.redOnly:
        icon = Icons.crop_square;
        label = 'Red only';
      case ViewMode.blueOnly:
        icon = Icons.crop_square;
        label = 'Blue only';
    }

    return _buildItem(
      icon: icon,
      label: label,
      onPressed: hasDualVideo ? onToggleViewMode : null,
    );
  }
}
