import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playoff_alliance.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Dropdown for picking a playoff alliance. Only useful at elims events.
/// Reads alliance list from [DataService.playoffAlliances].
class AllianceSelector extends StatefulWidget {
  const AllianceSelector({
    super.key,
    required this.label,
    required this.accent,
    required this.value,
    required this.onSelected,
    required this.onCleared,
  });

  final String label;
  final Color accent;
  final PlayoffAlliance? value;
  final ValueChanged<PlayoffAlliance> onSelected;
  final VoidCallback onCleared;

  @override
  State<AllianceSelector> createState() => _AllianceSelectorState();
}

class _AllianceSelectorState extends State<AllianceSelector> {
  OverlayEntry? _overlay;
  final _linkKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggle() {
    if (_overlay != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = _linkKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlay = OverlayEntry(builder: (_) {
      final entries = context.read<DataService>().playoffAlliances;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: Material(
              color: AppTheme.surfaceHi,
              borderRadius: BorderRadius.circular(8),
              elevation: 8,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: entries.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No alliances',
                            style:
                                TextStyle(color: AppTheme.muted, fontSize: 12)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: entries.length,
                        itemBuilder: (_, i) => _buildItem(entries[i]),
                      ),
              ),
            ),
          ),
        ],
      );
    });

    Overlay.of(context).insert(_overlay!);
  }

  Widget _buildItem(PlayoffAlliance entry) {
    final isSelected = widget.value?.name == entry.name;
    return InkWell(
      onTap: () {
        widget.onSelected(entry);
        _removeOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected ? widget.accent.withOpacity(0.10) : null,
        child: Text(
          _formatLabel(entry),
          style: AppTheme.mono(
            11,
            color: isSelected ? widget.accent : AppTheme.text,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _formatLabel(PlayoffAlliance entry) {
    final hasOurTeam = entry.teams.contains(201);
    final star = hasOurTeam ? '⭐ ' : '';
    return '$star[${entry.name}] (${entry.teams.join(', ')})';
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final hasAlliances = context
        .select<DataService, bool>((s) => s.playoffAlliances.isNotEmpty);
    final label =
        widget.value != null ? _formatLabel(widget.value!) : widget.label;

    return GestureDetector(
      onTap: hasAlliances ? _toggle : null,
      child: Container(
        key: _linkKey,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.value != null
                ? widget.accent.withOpacity(0.6)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.groups_rounded,
                size: 14,
                color: hasAlliances ? widget.accent : AppTheme.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTheme.mono(
                  11,
                  color: widget.value != null ? widget.accent : AppTheme.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.value != null)
              GestureDetector(
                onTap: widget.onCleared,
                child: const Icon(Icons.close_rounded,
                    size: 14, color: AppTheme.muted),
              )
            else
              Icon(Icons.expand_more_rounded,
                  size: 16,
                  color: hasAlliances ? AppTheme.muted : AppTheme.border),
          ],
        ),
      ),
    );
  }
}
