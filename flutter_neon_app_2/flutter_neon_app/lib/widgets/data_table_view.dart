import 'package:flutter/material.dart';
import '../services/neon_service.dart';

class DataTableView extends StatefulWidget {
  final NeonQueryResult data;
  final List<ColumnInfo>? columnInfo;

  const DataTableView({
    super.key,
    required this.data,
    this.columnInfo,
  });

  @override
  State<DataTableView> createState() => _DataTableViewState();
}

class _DataTableViewState extends State<DataTableView> {
  int _sortColumnIndex = -1;
  bool _sortAscending = true;
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _rowsPerPage = 25;

  List<Map<String, dynamic>> get _filteredRows {
    var rows = widget.data.rows;
    if (_searchQuery.isNotEmpty) {
      rows = rows.where((row) {
        return row.values.any((v) =>
            v.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    if (_sortColumnIndex >= 0 && _sortColumnIndex < widget.data.columns.length) {
      final col = widget.data.columns[_sortColumnIndex];
      rows = List.from(rows)
        ..sort((a, b) {
          final aVal = a[col];
          final bVal = b[col];
          if (aVal == null && bVal == null) return 0;
          if (aVal == null) return _sortAscending ? -1 : 1;
          if (bVal == null) return _sortAscending ? 1 : -1;

          // Try numeric comparison
          final aNum = num.tryParse(aVal.toString());
          final bNum = num.tryParse(bVal.toString());
          if (aNum != null && bNum != null) {
            return _sortAscending
                ? aNum.compareTo(bNum)
                : bNum.compareTo(aNum);
          }
          return _sortAscending
              ? aVal.toString().compareTo(bVal.toString())
              : bVal.toString().compareTo(aVal.toString());
        });
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filtered = _filteredRows;
    final totalPages = (filtered.length / _rowsPerPage).ceil();
    final pageRows = filtered
        .skip(_currentPage * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();
    final columns = widget.data.columns;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF1A1A24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 0;
                    }),
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    decoration: const InputDecoration(
                      hintText: 'Search rows...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.white),
                      prefixIcon: Icon(Icons.search, size: 18, color: Colors.white24),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${filtered.length} rows',
                style: const TextStyle(fontSize: 12, color: Colors.white30),
              ),
            ],
          ),
        ),

        // Table
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.white.withOpacity(0.03),
                    ),
                    dataRowColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.hovered)) {
                        return colors.primary.withOpacity(0.04);
                      }
                      return Colors.transparent;
                    }),
                    headingRowHeight: 44,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 56,
                    columnSpacing: 32,
                    horizontalMargin: 16,
                    border: TableBorder(
                      horizontalInside:
                          BorderSide(color: Colors.white.withOpacity(0.04)),
                    ),
                    sortColumnIndex:
                        _sortColumnIndex >= 0 ? _sortColumnIndex : null,
                    sortAscending: _sortAscending,
                    columns: columns.asMap().entries.map((entry) {
                      final i = entry.key;
                      final col = entry.value;
                      final info = widget.columnInfo?.firstWhere(
                        (c) => c.name == col,
                        orElse: () => ColumnInfo(
                            name: col, dataType: 'text', isNullable: true),
                      );

                      return DataColumn(
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              col,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            if (info != null)
                              Text(
                                info.dataType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.primary.withOpacity(0.4),
                                  fontFamily: 'monospace',
                                ),
                              ),
                          ],
                        ),
                        onSort: (colIndex, ascending) {
                          setState(() {
                            _sortColumnIndex = colIndex;
                            _sortAscending = ascending;
                          });
                        },
                      );
                    }).toList(),
                    rows: pageRows.map((row) {
                      return DataRow(
                        cells: columns.map((col) {
                          final val = row[col];
                          return DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                val?.toString() ?? 'NULL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: val == null
                                      ? Colors.white
                                      : Colors.white60,
                                  fontStyle: val == null
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Pagination
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  color: Colors.white38,
                  disabledColor: Colors.white12,
                ),
                const SizedBox(width: 8),
                Text(
                  'Page ${_currentPage + 1} of $totalPages',
                  style: const TextStyle(fontSize: 13, color: Colors.white38),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 20),
                  color: Colors.white38,
                  disabledColor: Colors.white12,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
