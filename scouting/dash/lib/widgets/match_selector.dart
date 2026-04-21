import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_entry.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Dropdown for picking a match from the TBA schedule.
/// Calls [onSelected] with the [MatchEntry] so the parent can grab both
/// red and blue team lists.
class MatchSelector extends StatefulWidget {
  const MatchSelector({
    super.key,
    required this.value,
    required this.onSelected,
    required this.onCleared,
  });

  final MatchEntry? value;
  final ValueChanged<MatchEntry> onSelected;
  final VoidCallback onCleared;

  @override
  State<MatchSelector> createState() => _MatchSelectorState();
}

class _MatchSelectorState extends State<MatchSelector> {
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
      final entries = context.read<DataService>().matchEntries;

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
                constraints: const BoxConstraints(maxHeight: 360),
                child: entries.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No matches',
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

  Widget _buildItem(MatchEntry entry) {
    final isSelected = widget.value?.matchKey == entry.matchKey;

    return InkWell(
      onTap: () {
        widget.onSelected(entry);
        _removeOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected ? AppTheme.gold.withOpacity(0.10) : null,
        child: Text(
          _formatLabel(entry),
          style: AppTheme.mono(
            11,
            color: isSelected ? AppTheme.gold : AppTheme.text,
          ),
        ),
      ),
    );
  }

  String _formatLabel(MatchEntry entry) {
    final star = entry.hasOurTeam ? '⭐ ' : '';
    final red = _formatTeamList(entry.redTeams);
    final blue = _formatTeamList(entry.blueTeams);
    return '$star[${entry.shortLabel}] $red vs $blue';
  }

  String _formatTeamList(List<int> teams) {
    if (teams.isEmpty) return '(—)';
    return '(${teams.join(', ')})';
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final hasMatches =
        context.select<DataService, bool>((s) => s.matchEntries.isNotEmpty);
    final label =
        widget.value != null ? _formatLabel(widget.value!) : 'Match';

    return GestureDetector(
      onTap: hasMatches ? _toggle : null,
      child: Container(
        key: _linkKey,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.value != null
                ? AppTheme.gold.withOpacity(0.5)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded,
                size: 14,
                color: hasMatches ? AppTheme.gold : AppTheme.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTheme.mono(
                  11,
                  color: widget.value != null ? AppTheme.gold : AppTheme.muted,
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
                  color: hasMatches ? AppTheme.muted : AppTheme.border),
          ],
        ),
      ),
    );
  }
}
