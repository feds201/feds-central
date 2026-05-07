import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_entry.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Dropdown for picking a match/alliance from TBA schedule.
/// When an entry is selected, calls [onSelected] with the 3 team numbers.
class MatchSelector extends StatefulWidget {
  const MatchSelector({super.key, required this.onSelected});

  final void Function(List<int> teams) onSelected;

  @override
  State<MatchSelector> createState() => _MatchSelectorState();
}

class _MatchSelectorState extends State<MatchSelector> {
  OverlayEntry? _overlay;
  final _linkKey = GlobalKey();
  MatchEntry? _selected;

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
          // Dismiss on tap outside.
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
                constraints: const BoxConstraints(maxHeight: 300),
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
    final isSelected = _selected?.matchKey == entry.matchKey &&
        _selected?.alliance == entry.alliance;
    final isRed = entry.alliance == 'red';

    return InkWell(
      onTap: () {
        setState(() => _selected = entry);
        widget.onSelected(entry.teamNumbers);
        _removeOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected
            ? AppTheme.gold.withOpacity(0.10)
            : isRed
                ? AppTheme.red.withOpacity(0.04)
                : const Color(0xFF3B82F6).withOpacity(0.04),
        child: Text(
          entry.label,
          style: AppTheme.mono(
            11,
            color: isSelected ? AppTheme.gold : AppTheme.text,
          ),
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    // Watch so we rebuild when matchEntries loads.
    final hasMatches =
        context.select<DataService, bool>((s) => s.matchEntries.isNotEmpty);

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
            color: _selected != null
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
                _selected?.label ?? 'Match',
                style: AppTheme.mono(
                  11,
                  color: _selected != null ? AppTheme.gold : AppTheme.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selected != null)
              GestureDetector(
                onTap: () => setState(() => _selected = null),
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
