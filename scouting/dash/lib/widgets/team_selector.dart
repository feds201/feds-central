import 'package:bot_path_drawer/bot_path_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Dropdown search box for picking a team number.
/// Tint is derived from (alliance, slot) to mirror the bot path drawer's
/// per-team colors in alliance mode.
class TeamSelector extends StatefulWidget {
  const TeamSelector({
    super.key,
    required this.alliance,
    required this.slot,
    required this.value,
    required this.onChanged,
  });

  final Alliance alliance;
  final int slot;
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

  Color get _color =>
      AppTheme.allianceTeamColors[widget.alliance]![widget.slot];

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
                      final name = svc.teamNames[t];
                      final label = (name == null || name.isEmpty)
                          ? '$t'
                          : '$t — $name';
                      return InkWell(
                        onTap: () {
                          widget.onChanged(t);
                          _controller.text = '$t';
                          _focusNode.unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color:
                              isSelected ? _color.withOpacity(0.10) : null,
                          child: Text(
                            label,
                            style: AppTheme.mono(12,
                                color: isSelected ? _color : AppTheme.text),
                            overflow: TextOverflow.ellipsis,
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
    final color = _color;
    final hint = widget.alliance == Alliance.red
        ? 'Red ${widget.slot + 1}'
        : 'Blue ${widget.slot + 1}';

    return SizedBox(
      height: 38,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: AppTheme.mono(12, color: color),
        decoration: InputDecoration(
          hintText: hint,
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
