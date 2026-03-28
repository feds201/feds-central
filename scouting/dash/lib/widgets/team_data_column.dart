import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// One column of team data: OPR, EPA, then all pit scouting fields.
class TeamDataColumn extends StatelessWidget {
  const TeamDataColumn({
    super.key,
    required this.teamNumber,
    required this.slotIndex,
  });

  final int teamNumber;
  final int slotIndex;

  // Columns to hide from the data display.
  static const _hideCols = {
    'pathdraw', 'id', 'created_at', 'team', 'eventkey',
    'botimage1', 'botimage2', 'botimage3',
  };

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final color = AppTheme.slotColors[slotIndex];
    final opr = svc.oprByTeam[teamNumber];
    final epa = svc.epaByTeam[teamNumber];
    final rows = svc.scoutingByTeam[teamNumber] ?? [];
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};

    final displayEntries = row.entries
        .where((e) => !_hideCols.contains(e.key.toLowerCase()))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('$teamNumber',
                    style: AppTheme.mono(16, color: color)),
              ],
            ),
            const SizedBox(height: 10),

            // ── OPR / EPA ────────────────────────────────────────────
            Row(
              children: [
                _MetricBadge(label: 'OPR', value: opr, color: AppTheme.accent),
                const SizedBox(width: 8),
                _MetricBadge(label: 'EPA', value: epa, color: AppTheme.gold),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Scouting fields ──────────────────────────────────────
            if (displayEntries.isEmpty)
              Text('No scouting data',
                  style: TextStyle(color: AppTheme.muted, fontSize: 11))
            else
              ...displayEntries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            _formatCol(e.key),
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _displayVal(e.value),
                              style: AppTheme.mono(11),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  static String _formatCol(String col) {
    return col
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _displayVal(dynamic v) {
    if (v == null) return '—';
    if (v is double) return v.toStringAsFixed(2);
    final str = v.toString();
    // Truncate long JSON arrays / objects.
    if (str.length > 30) return '${str.substring(0, 27)}…';
    return str;
  }
}

// ═════════════════════════════════════════════════════════════════════

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              value != null ? value!.toStringAsFixed(1) : '—',
              style: AppTheme.mono(13, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
