import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Dropdown search box for picking a team number.
/// Shows the slot color as an accent.
class TeamSelector extends StatefulWidget {
  const TeamSelector({
    super.key,
    required this.slotIndex,
    required this.value,
    required this.onChanged,
  });

  final int slotIndex;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<TeamSelector> createState() => _TeamSelectorState();
}

class _TeamSelectorState extends State<TeamSelector> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  OverlayEntry? _overlay;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = '${widget.value}';
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(TeamSelector old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _controller.text = widget.value != null ? '${widget.value}' : '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlay = OverlayEntry(builder: (ctx) {
      final svc = context.read<DataService>();
      final teams = svc.teamNumbers;
      final filtered = _filter.isEmpty
          ? teams
          : teams
              .where((t) => t.toString().contains(_filter))
              .toList();

      return Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          color: AppTheme.surfaceHi,
          borderRadius: BorderRadius.circular(8),
          elevation: 8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No teams',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      final isSelected = t == widget.value;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(t);
                          _controller.text = '$t';
                          _focusNode.unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color: isSelected
                              ? AppTheme.slotColors[widget.slotIndex]
                                  .withOpacity(0.10)
                              : null,
                          child: Text(
                            '$t',
                            style: AppTheme.mono(12,
                                color: isSelected
                                    ? AppTheme
                                        .slotColors[widget.slotIndex]
                                    : AppTheme.text),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      );
    });

    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.slotColors[widget.slotIndex];
    final slotLabel = 'Team ${widget.slotIndex + 1}';

    return SizedBox(
      height: 38,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: AppTheme.mono(12, color: color),
        decoration: InputDecoration(
          hintText: slotLabel,
          hintStyle: AppTheme.mono(11, color: AppTheme.muted),
          prefixIcon: Container(
            width: 32,
            alignment: Alignment.center,
            child: Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 0),
          suffixIcon: widget.value != null
              ? GestureDetector(
                  onTap: () {
                    widget.onChanged(null);
                    _controller.clear();
                    setState(() => _filter = '');
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: AppTheme.muted),
                )
              : const Icon(Icons.expand_more_rounded,
                  size: 16, color: AppTheme.muted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: color.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
        ),
        onChanged: (v) {
          setState(() => _filter = v);
          _removeOverlay();
          _showOverlay();
        },
        keyboardType: TextInputType.number,
      ),
    );
  }
}
