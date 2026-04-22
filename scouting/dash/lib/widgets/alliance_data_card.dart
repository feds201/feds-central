import 'package:bot_path_drawer/bot_path_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme.dart';

const _hideCols = {
  'pathdraw',
  'id',
  'created_at',
  'team',
  'eventkey',
  'botimage1',
  'botimage2',
  'botimage3',
};

/// A single card displaying scouting data for one alliance's 3 teams.
/// Layout: left column = field names, then 3 columns (one per team) of values.
class AllianceDataCard extends StatelessWidget {
  const AllianceDataCard({
    super.key,
    required this.alliance,
    required this.teams,
  });

  final Alliance alliance;
  final List<int?> teams;

  Color get _allianceColor =>
      AppTheme.allianceTeamColors[alliance]!.first;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();

    final fieldNames = svc.displayColumns
        .where((c) => !_hideCols.contains(c.toLowerCase()))
        .toList();

    final rowsByTeam = <int?, Map<String, dynamic>>{};
    for (final t in teams) {
      if (t == null) {
        rowsByTeam[t] = const {};
      } else {
        final r = svc.scoutingByTeam[t];
        rowsByTeam[t] = (r != null && r.isNotEmpty) ? r.first : const {};
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _allianceColor.withOpacity(0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(child: _buildColumnBackgrounds()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildOprRow(svc),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                if (fieldNames.isEmpty)
                  const Text(
                    'No scouting data',
                    style: TextStyle(color: AppTheme.muted, fontSize: 11),
                  )
                else
                  ...fieldNames.map(
                    (field) => _buildFieldRow(field, rowsByTeam),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnBackgrounds() {
    return Row(
      children: [
        const Expanded(flex: 5, child: SizedBox.shrink()),
        for (int i = 0; i < 3; i++) ...[
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.allianceTeamColors[alliance]![i]
                    .withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _allianceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  alliance == Alliance.red ? 'Red alliance' : 'Blue alliance',
                  style: AppTheme.mono(14, color: _allianceColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < 3; i++) ...[
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: _buildTeamHeader(i),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamHeader(int slot) {
    final team = slot < teams.length ? teams[slot] : null;
    final color = AppTheme.allianceTeamColors[alliance]![slot];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          team?.toString() ?? '—',
          style: AppTheme.mono(13, color: color)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildOprRow(DataService svc) {
    return Row(
      children: [
        const Expanded(flex: 5, child: SizedBox.shrink()),
        for (int i = 0; i < 3; i++) ...[
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: _buildOprCell(svc, i),
          ),
        ],
      ],
    );
  }

  Widget _buildOprCell(DataService svc, int slot) {
    final team = slot < teams.length ? teams[slot] : null;
    final opr = team == null ? null : svc.oprByTeam[team];
    final color = AppTheme.allianceTeamColors[alliance]![slot];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Text(
            'OPR',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            opr != null ? opr.toStringAsFixed(1) : '—',
            style: AppTheme.mono(11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(
    String field,
    Map<int?, Map<String, dynamic>> rowsByTeam,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              _formatCol(field),
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (int i = 0; i < 3; i++) ...[
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _cellValue(rowsByTeam, i, field),
                    style: AppTheme.mono(11),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _cellValue(
    Map<int?, Map<String, dynamic>> rowsByTeam,
    int slot,
    String field,
  ) {
    if (slot >= teams.length) return _displayVal(null);
    final team = teams[slot];
    final row = rowsByTeam[team];
    return _displayVal(row == null ? null : row[field]);
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
    if (str.length > 20) return '${str.substring(0, 17)}…';
    return str;
  }
}

