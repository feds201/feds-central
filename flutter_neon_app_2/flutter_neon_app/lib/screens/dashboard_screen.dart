import 'package:flutter/material.dart';
import '../services/neon_service.dart';
import '../widgets/data_table_view.dart';
import '../widgets/chart_panel.dart';

class DashboardScreen extends StatefulWidget {
  final NeonService service;
  final List<String> tables;

  const DashboardScreen({
    super.key,
    required this.service,
    required this.tables,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedTable;
  NeonQueryResult? _tableData;
  List<ColumnInfo>? _columnInfo;
  bool _loading = false;
  String? _error;
  String? _customQuery;
  final _queryController = TextEditingController();
  bool _showCharts = true;

  @override
  void initState() {
    super.initState();
    if (widget.tables.isNotEmpty) {
      _selectTable(widget.tables.first);
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _selectTable(String table) async {
    setState(() {
      _selectedTable = table;
      _loading = true;
      _error = null;
      _customQuery = null;
    });

    try {
      final results = await Future.wait([
        widget.service.fetchTable(table),
        widget.service.describeTable(table),
      ]);

      if (!mounted) return;
      setState(() {
        _tableData = results[0] as NeonQueryResult;
        _columnInfo = results[1] as List<ColumnInfo>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _runQuery() async {
    final sql = _queryController.text.trim();
    if (sql.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _customQuery = sql;
      _selectedTable = null;
    });

    try {
      final result = await widget.service.query(sql);
      if (!mounted) return;
      setState(() {
        _tableData = result;
        _columnInfo = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──
          Container(
            width: isWide ? 260 : 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E16),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withOpacity(0.15),
                        ),
                        child: Icon(
                          Icons.storage_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Neon DB',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.white.withOpacity(0.06), height: 1),

                // Tables list
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'TABLES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                Expanded(
                  child: widget.tables.isEmpty
                      ? Center(
                          child: Text(
                            'No tables found',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: widget.tables.length,
                          itemBuilder: (context, i) {
                            final table = widget.tables[i];
                            final selected = table == _selectedTable;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _selectTable(table),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: selected
                                          ? colors.primary.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.table_chart_outlined,
                                          size: 16,
                                          color: selected
                                              ? colors.primary
                                              : Colors.white30,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            table,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: selected
                                                  ? colors.primary
                                                  : Colors.white60,
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Disconnect button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/'),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Disconnect'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main content ──
          Expanded(
            child: Column(
              children: [
                // Top bar with query input and toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E16),
                    border: Border(
                      bottom:
                          BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Custom query input
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF1A1A24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Icon(
                                  Icons.code,
                                  size: 16,
                                  color: Colors.white24,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _queryController,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Run custom SQL query...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onSubmitted: (_) => _runQuery(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: SizedBox(
                                  height: 30,
                                  child: FilledButton(
                                    onPressed: _runQuery,
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          colors.primary.withOpacity(0.2),
                                      foregroundColor: colors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'Run',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Toggle charts
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF1A1A24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _toggleButton(
                              icon: Icons.table_chart_outlined,
                              label: 'Table',
                              active: !_showCharts,
                              onTap: () =>
                                  setState(() => _showCharts = false),
                            ),
                            _toggleButton(
                              icon: Icons.bar_chart_rounded,
                              label: 'Charts',
                              active: _showCharts,
                              onTap: () =>
                                  setState(() => _showCharts = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats bar
                if (_tableData != null && !_loading)
                  _buildStatsBar(colors),

                // Content area
                Expanded(
                  child: _buildContent(colors),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: active ? colors.primary.withOpacity(0.15) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: active ? colors.primary : Colors.white30),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? colors.primary : Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(ColorScheme colors) {
    final data = _tableData!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          _statChip(Icons.grid_on, '${data.columns.length} columns', colors),
          const SizedBox(width: 16),
          _statChip(
              Icons.list_alt, '${data.rowCount} rows', colors),
          const Spacer(),
          if (_selectedTable != null)
            Text(
              _selectedTable!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: colors.primary.withOpacity(0.6),
              ),
            ),
          if (_customQuery != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colors.primary.withOpacity(0.1),
              ),
              child: Text(
                'Custom Query',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, ColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme colors) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fetching data...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colors.error.withOpacity(0.08),
            border: Border.all(color: colors.error.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 32, color: colors.error),
              const SizedBox(height: 12),
              Text(
                'Query Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.error.withOpacity(0.8),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tableData == null || _tableData!.isEmpty) {
      return Center(
        child: Text(
          'No data to display.\nSelect a table or run a query.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 14,
          ),
        ),
      );
    }

    if (_showCharts) {
      return ChartPanel(
        data: _tableData!,
        tableName: _selectedTable ?? 'Query Result',
      );
    }

    return DataTableView(
      data: _tableData!,
      columnInfo: _columnInfo,
    );
  }
}
