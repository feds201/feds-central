import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/neon_service.dart';

class ChartPanel extends StatefulWidget {
  final NeonQueryResult data;
  final String tableName;

  const ChartPanel({
    super.key,
    required this.data,
    required this.tableName,
  });

  @override
  State<ChartPanel> createState() => _ChartPanelState();
}

class _ChartPanelState extends State<ChartPanel> {
  late List<String> _numericColumns;
  late List<String> _labelColumns;
  String? _selectedNumericCol;
  String? _selectedLabelCol;

  @override
  void initState() {
    super.initState();
    _analyzeColumns();
  }

  @override
  void didUpdateWidget(ChartPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _analyzeColumns();
    }
  }

  void _analyzeColumns() {
    _numericColumns = [];
    _labelColumns = [];

    for (final col in widget.data.columns) {
      int numericCount = 0;
      for (final row in widget.data.rows.take(50)) {
        final val = row[col];
        if (val != null && num.tryParse(val.toString()) != null) {
          numericCount++;
        }
      }
      final sampleSize = min(50, widget.data.rows.length);
      if (sampleSize > 0 && numericCount / sampleSize > 0.6) {
        _numericColumns.add(col);
      } else {
        _labelColumns.add(col);
      }
    }

    _selectedNumericCol =
        _numericColumns.isNotEmpty ? _numericColumns.first : null;
    _selectedLabelCol = _labelColumns.isNotEmpty ? _labelColumns.first : null;
  }

  List<double> _getNumericValues(String col) {
    return widget.data.rows
        .map((r) => double.tryParse(r[col]?.toString() ?? '') ?? 0)
        .toList();
  }

  List<String> _getLabelValues(String col) {
    return widget.data.rows.map((r) => r[col]?.toString() ?? '').toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_numericColumns.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 48, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              Text(
                'No Numeric Data Found',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Charts require at least one numeric column. Switch to Table view to see your data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumnSelectors(colors),
          const SizedBox(height: 24),
          _buildSummaryCards(colors),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 700;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBarChart(colors)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildLineChart(colors)),
                ],
              );
            }
            return Column(
              children: [
                _buildBarChart(colors),
                const SizedBox(height: 20),
                _buildLineChart(colors),
              ],
            );
          }),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 700;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildHistogram(colors)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _selectedLabelCol != null
                        ? _buildPieChart(colors)
                        : _buildScatterChart(colors),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildHistogram(colors),
                const SizedBox(height: 20),
                _selectedLabelCol != null
                    ? _buildPieChart(colors)
                    : _buildScatterChart(colors),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildColumnSelectors(ColorScheme colors) {
    return Row(
      children: [
        if (_numericColumns.isNotEmpty) ...[
          _dropdownSelector(
            label: 'Numeric Column',
            value: _selectedNumericCol,
            items: _numericColumns,
            onChanged: (v) => setState(() => _selectedNumericCol = v),
            colors: colors,
          ),
          const SizedBox(width: 16),
        ],
        if (_labelColumns.isNotEmpty)
          _dropdownSelector(
            label: 'Label Column',
            value: _selectedLabelCol,
            items: _labelColumns,
            onChanged: (v) => setState(() => _selectedLabelCol = v),
            colors: colors,
          ),
      ],
    );
  }

  Widget _dropdownSelector({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.3),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF1A1A24),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: Colors.white60,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: const Color(0xFF1A1A24),
              iconEnabledColor: Colors.white30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ColorScheme colors) {
    if (_selectedNumericCol == null) return const SizedBox.shrink();
    final values = _getNumericValues(_selectedNumericCol!);
    if (values.isEmpty) return const SizedBox.shrink();

    final sum = values.fold(0.0, (a, b) => a + b);
    final avg = sum / values.length;
    final sorted = List<double>.from(values)..sort();
    final minVal = sorted.first;
    final maxVal = sorted.last;
    final median = sorted.length.isOdd
        ? sorted[sorted.length ~/ 2]
        : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;

    return Row(
      children: [
        _statCard('Sum', _formatNum(sum), Icons.functions, colors),
        const SizedBox(width: 12),
        _statCard('Average', _formatNum(avg), Icons.trending_flat, colors),
        const SizedBox(width: 12),
        _statCard('Min', _formatNum(minVal), Icons.arrow_downward, colors),
        const SizedBox(width: 12),
        _statCard('Max', _formatNum(maxVal), Icons.arrow_upward, colors),
        const SizedBox(width: 12),
        _statCard('Median', _formatNum(median), Icons.align_vertical_center,
            colors),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, ColorScheme colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF12121A),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: colors.primary.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required Widget child,
    required ColorScheme colors,
    double height = 300,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF12121A),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart(ColorScheme colors) {
    if (_selectedNumericCol == null) return const SizedBox.shrink();
    final values = _getNumericValues(_selectedNumericCol!);
    final labels = _selectedLabelCol != null
        ? _getLabelValues(_selectedLabelCol!)
        : List.generate(values.length, (i) => '${i + 1}');

    final count = min(20, values.length);
    final maxVal = values.take(count).fold(0.0, (a, b) => max(a, b.abs()));

    return _chartCard(
      title: 'Bar Chart — $_selectedNumericCol',
      colors: colors,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label =
                    groupIndex < labels.length ? labels[groupIndex] : '';
                return BarTooltipItem(
                  '$label\n${_formatNum(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i >= 0 && i < count) {
                    final text = labels[i].length > 8
                        ? '${labels[i].substring(0, 7)}…'
                        : labels[i];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        text,
                        style:
                            const TextStyle(fontSize: 9, color: Colors.white24),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, meta) {
                  return Text(
                    _formatNum(val),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
            getDrawingHorizontalLine: (val) => FlLine(
              color: Colors.white.withOpacity(0.04),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(count, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].abs(),
                  width: max(4, (200 / count).toDouble()),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      colors.primary.withOpacity(0.3),
                      colors.primary,
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLineChart(ColorScheme colors) {
    if (_selectedNumericCol == null) return const SizedBox.shrink();
    final values = _getNumericValues(_selectedNumericCol!);
    final count = min(50, values.length);
    final maxVal = values.take(count).fold(0.0, (a, b) => max(a, b.abs()));
    final minVal =
        values.take(count).fold(double.infinity, (a, b) => min(a, b));

    return _chartCard(
      title: 'Line Chart — $_selectedNumericCol',
      colors: colors,
      child: LineChart(
        LineChartData(
          minY: minVal < 0 ? minVal * 1.1 : 0,
          maxY: maxVal * 1.15,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    _formatNum(spot.y),
                    TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: max(1, count / 5).toDouble(),
                getTitlesWidget: (val, meta) {
                  return Text(
                    val.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, meta) {
                  return Text(
                    _formatNum(val),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
            getDrawingHorizontalLine: (val) => FlLine(
              color: Colors.white.withOpacity(0.04),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(count, (i) {
                return FlSpot(i.toDouble(), values[i]);
              }),
              isCurved: true,
              curveSmoothness: 0.2,
              color: colors.primary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withOpacity(0.2),
                    colors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistogram(ColorScheme colors) {
    if (_selectedNumericCol == null) return const SizedBox.shrink();
    final values = _getNumericValues(_selectedNumericCol!);
    if (values.isEmpty) return const SizedBox.shrink();

    final sorted = List<double>.from(values)..sort();
    final minVal = sorted.first;
    final maxVal = sorted.last;
    final range = maxVal - minVal;

    if (range == 0) {
      return _chartCard(
        title: 'Distribution — $_selectedNumericCol',
        colors: colors,
        child: const Center(
          child: Text('All values are identical',
              style: TextStyle(color: Colors.white30)),
        ),
      );
    }

    const bucketCount = 12;
    final bucketSize = range / bucketCount;
    final buckets = List.filled(bucketCount, 0);

    for (final v in values) {
      var idx = ((v - minVal) / bucketSize).floor();
      if (idx >= bucketCount) idx = bucketCount - 1;
      buckets[idx]++;
    }

    final maxBucket = buckets.fold(0, (a, b) => max(a, b));

    return _chartCard(
      title: 'Distribution — $_selectedNumericCol',
      colors: colors,
      child: BarChart(
        BarChartData(
          maxY: maxBucket * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final lo = minVal + groupIndex * bucketSize;
                final hi = lo + bucketSize;
                return BarTooltipItem(
                  '${_formatNum(lo)} — ${_formatNum(hi)}\nCount: ${rod.toY.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i % 2 == 0 && i < bucketCount) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatNum(minVal + i * bucketSize),
                        style: const TextStyle(
                            fontSize: 9, color: Colors.white24),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (val, meta) {
                  return Text(
                    val.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (val) => FlLine(
              color: Colors.white.withOpacity(0.04),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(bucketCount, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].toDouble(),
                  width: max(8, (200 / bucketCount).toDouble()),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                  color: colors.primary.withOpacity(0.6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPieChart(ColorScheme colors) {
    if (_selectedLabelCol == null || _selectedNumericCol == null) {
      return const SizedBox.shrink();
    }

    final labels = _getLabelValues(_selectedLabelCol!);
    final values = _getNumericValues(_selectedNumericCol!);

    final aggregated = <String, double>{};
    for (var i = 0; i < min(labels.length, values.length); i++) {
      aggregated[labels[i]] = (aggregated[labels[i]] ?? 0) + values[i].abs();
    }

    final sorted = aggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sorted.take(8).toList();
    final otherSum = sorted.skip(8).fold(0.0, (a, b) => a + b.value);
    if (otherSum > 0) {
      topEntries.add(MapEntry('Other', otherSum));
    }

    final total = topEntries.fold(0.0, (a, b) => a + b.value);
    if (total == 0) {
      return _chartCard(
        title: 'Breakdown by $_selectedLabelCol',
        colors: colors,
        child: const Center(
          child: Text('No data to display',
              style: TextStyle(color: Colors.white30)),
        ),
      );
    }

    final chartColors = [
      colors.primary,
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
      const Color(0xFFEC4899),
      Colors.white24,
    ];

    return _chartCard(
      title: 'Breakdown by $_selectedLabelCol',
      colors: colors,
      height: 340,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: topEntries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final pct = (e.value / total * 100).toStringAsFixed(1);
                  return PieChartSectionData(
                    value: e.value,
                    color: chartColors[i % chartColors.length],
                    radius: 60,
                    title: '$pct%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: topEntries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: chartColors[i % chartColors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key.length > 16
                              ? '${e.key.substring(0, 15)}…'
                              : e.key,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScatterChart(ColorScheme colors) {
    if (_numericColumns.length < 2) {
      return _chartCard(
        title: 'Scatter Plot',
        colors: colors,
        child: const Center(
          child: Text(
            'Need 2+ numeric columns for scatter plot',
            style: TextStyle(color: Colors.white30, fontSize: 13),
          ),
        ),
      );
    }

    final xCol = _numericColumns[0];
    final yCol = _numericColumns.length > 1 ? _numericColumns[1] : xCol;
    final xVals = _getNumericValues(xCol);
    final yVals = _getNumericValues(yCol);
    final count = min(100, min(xVals.length, yVals.length));

    return _chartCard(
      title: 'Scatter — $xCol vs $yCol',
      colors: colors,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: List.generate(count, (i) {
            return ScatterSpot(
              xVals[i],
              yVals[i],
              dotPainter: FlDotCirclePainter(
                radius: 4,
                color: colors.primary.withOpacity(0.6),
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            );
          }),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                xCol,
                style: const TextStyle(fontSize: 11, color: Colors.white30),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) => Text(
                  _formatNum(val),
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                yCol,
                style: const TextStyle(fontSize: 11, color: Colors.white30),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, meta) => Text(
                  _formatNum(val),
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (val) => FlLine(
              color: Colors.white.withOpacity(0.04),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (val) => FlLine(
              color: Colors.white.withOpacity(0.04),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  String _formatNum(double val) {
    if (val.abs() >= 1e9) return '${(val / 1e9).toStringAsFixed(1)}B';
    if (val.abs() >= 1e6) return '${(val / 1e6).toStringAsFixed(1)}M';
    if (val.abs() >= 1e3) return '${(val / 1e3).toStringAsFixed(1)}K';
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(2);
  }
}
