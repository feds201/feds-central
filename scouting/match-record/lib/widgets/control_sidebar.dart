import 'package:flutter/material.dart';

import '../viewer/drawing_controller.dart';

/// Mute state for the video viewer audio.
enum MuteState { muted, redAudio, blueAudio, fullAudio }

/// View mode for the video viewer layout.
enum ViewMode { both, redOnly, blueOnly, fullOnly }

/// Sidebar control panel for the video viewer.
///
/// In dual-video (both) mode: ~180px wide with text labels next to icons.
/// In single-video mode: ~72px wide with icons only.
/// Scrollable if controls overflow the available height.
class ControlSidebar extends StatelessWidget {
  final bool isPlaying;
  final MuteState muteState;
  final ViewMode viewMode;
  /// Current drawing color, or null if drawing mode is off.
  final DrawingColor? drawingColor;
  final bool canUndo;
  final bool canRedo;
  final bool hasDrawings;
  /// Whether the view mode toggle button is active (more than one view mode available).
  final bool canToggleViewMode;
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
    required this.drawingColor,
    required this.canUndo,
    required this.canRedo,
    required this.hasDrawings,
    required this.canToggleViewMode,
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
    // Collect button widgets — each gets wrapped in Expanded to fill height.
    // Dividers stay fixed-height between groups.
    final buttons = <Widget>[
      _buildItem(
        icon: Icons.arrow_back,
        label: 'Back',
        onPressed: onBack,
      ),
    ];

    if (canToggleViewMode) {
      buttons.addAll([
        _buildItem(
          icon: Icons.swap_horiz,
          label: 'Swap',
          onPressed: viewMode == ViewMode.both ? onSwapSides : null,
        ),
        _buildMuteItem(),
        _buildViewModeItem(),
      ]);
    }

    buttons.addAll([
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
    ]);

    buttons.addAll([
      _buildDrawItem(),
      _buildItem(
        icon: Icons.undo,
        label: 'Undo',
        onPressed: drawingColor != null && canUndo ? onUndo : null,
      ),
      _buildItem(
        icon: Icons.redo,
        label: 'Redo',
        onPressed: drawingColor != null && canRedo ? onRedo : null,
      ),
      _buildItem(
        icon: Icons.cleaning_services,
        label: 'Clear',
        onPressed: drawingColor != null && hasDrawings ? onClearDrawing : null,
      ),
    ]);

    // Build column children: wrap each button in Expanded, insert dividers
    // between groups at fixed height.
    final children = <Widget>[];
    final navCount = canToggleViewMode ? 4 : 1; // back + (swap, mute, view)
    final playbackStart = navCount;
    final playbackEnd = playbackStart + 4; // play, -10s, +10s, restart

    for (int i = 0; i < buttons.length; i++) {
      // Insert dividers between groups
      if (i == navCount || i == playbackEnd) {
        children.add(const Divider(indent: 8, endIndent: 8, height: 8));
      }
      children.add(Expanded(child: buttons[i]));
    }

    return SizedBox(
      width: _expanded ? 160 : 72,
      height: double.infinity,
      child: ColoredBox(
        color: const Color(0xFF1E1E1E),
        child: SafeArea(
          left: false,
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
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
      return IconButton(
        icon: Icon(icon),
        tooltip: label,
        onPressed: onPressed,
        color: isActive ? Colors.blue : Colors.white,
        disabledColor: Colors.white38,
        iconSize: 28,
        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
      );
    }

    final color = onPressed == null
        ? Colors.white38
        : isActive
            ? Colors.blue
            : Colors.white;

    return InkWell(
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
      case MuteState.fullAudio:
        icon = Icons.volume_up;
        circleColor = Colors.purple;
        label = 'Full audio';
    }

    if (!_expanded) {
      return Tooltip(
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
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onToggleMute,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeItem() {
    IconData icon;
    String label;
    Color? circleColor;

    switch (viewMode) {
      case ViewMode.both:
        icon = Icons.splitscreen;
        label = 'Both sides';
        circleColor = null;
      case ViewMode.redOnly:
        icon = Icons.crop_square;
        label = 'Red only';
        circleColor = Colors.red;
      case ViewMode.blueOnly:
        icon = Icons.crop_square;
        label = 'Blue only';
        circleColor = Colors.blue;
      case ViewMode.fullOnly:
        icon = Icons.crop_square;
        label = 'Full field';
        circleColor = Colors.purple;
    }

    // Use colored circle indicator (like mute button) when showing a single source
    if (circleColor != null) {
      if (!_expanded) {
        return Tooltip(
          message: label,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: circleColor,
                width: 2,
              ),
            ),
            child: IconButton(
              icon: Icon(icon),
              onPressed: canToggleViewMode ? onToggleViewMode : null,
              color: Colors.white,
              disabledColor: Colors.white38,
              iconSize: 28,
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            ),
          ),
        );
      }

      return InkWell(
        onTap: canToggleViewMode ? onToggleViewMode : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: circleColor,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildItem(
      icon: icon,
      label: label,
      onPressed: canToggleViewMode ? onToggleViewMode : null,
    );
  }

  Widget _buildDrawItem() {
    IconData icon;
    String label;
    Color? activeColor;

    switch (drawingColor) {
      case null:
        icon = Icons.edit_off;
        label = 'Draw';
        activeColor = null;
      case DrawingColor.red:
        icon = Icons.edit;
        label = 'Red draw';
        activeColor = Colors.red;
      case DrawingColor.blue:
        icon = Icons.edit;
        label = 'Blue draw';
        activeColor = Colors.blue;
    }

    final isEnabled = isPaused;
    final isActive = drawingColor != null;

    if (!_expanded) {
      return IconButton(
        icon: Icon(icon),
        tooltip: label,
        onPressed: isEnabled ? onToggleDrawing : null,
        color: activeColor ?? Colors.white,
        disabledColor: Colors.white38,
        iconSize: 28,
        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
      );
    }

    final color = !isEnabled
        ? Colors.white38
        : isActive
            ? (activeColor ?? Colors.white)
            : Colors.white;

    return InkWell(
      onTap: isEnabled ? onToggleDrawing : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
