import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enum for alliance selection
enum Alliance { blue, red }

/// Field Heatmap Whiteboard controlled externally - no internal alliance toggle
class FieldHeatmapWidget extends StatefulWidget {
  final String blueAllianceImagePath;
  final String redAllianceImagePath;
  final Alliance alliance; // Controlled by parent
  final ValueChanged<int>? onPointsChanged; // Optional callback for point count
  final VoidCallback? onClear; // Optional callback when cleared

  const FieldHeatmapWidget({
    Key? key,
    required this.blueAllianceImagePath,
    required this.redAllianceImagePath,
    required this.alliance, // Must be provided by parent
    this.onPointsChanged,
    this.onClear,
  }) : super(key: key);

  @override
  State<FieldHeatmapWidget> createState() => FieldHeatmapWidgetState();
}

class FieldHeatmapWidgetState extends State<FieldHeatmapWidget> {
   List<Offset> _points = [];
  final double _brushSize = 60.0; // Fixed brush size
  final double _intensity = 0.5; // Fixed intensity

  String get _currentImagePath {
    return widget.alliance == Alliance.blue
        ? widget.blueAllianceImagePath
        : widget.redAllianceImagePath;
  }

  Color get _allianceColor {
    return widget.alliance == Alliance.blue ? Colors.blue : Colors.red;
  }

  // Public methods to control from parent
  void clearHeatmap() {
    setState(() {
      _points.clear();
    });
    widget.onClear?.call();
  }

  int get pointCount => _points.length;

  @override
  void didUpdateWidget(FieldHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear points when alliance changes
    if (oldWidget.alliance != widget.alliance) {
      _points.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Important!
      children: [
        Flexible(  // Changed from Expanded to Flexible
          child: _buildFieldCanvas(),
        ),
        _buildActionButtons(),
      ],
    );
  }



   Widget _buildFieldCanvas() {
     return AspectRatio(
       aspectRatio: 1.8,
       child: GestureDetector(
         // Ensure behavior is set to opaque so it catches hits in empty space
         behavior: HitTestBehavior.opaque,
         onPanStart: (details) => _addPoint(details.localPosition),
         onPanUpdate: (details) => _addPoint(details.localPosition),
         child: Stack(
           children: [
             // 1. Background Image
             Positioned.fill(
               child: Image.asset(
                 _currentImagePath,
                 fit: BoxFit.contain,
               ),
             ),
             // 2. Heatmap Overlay
             Positioned.fill(
               child: IgnorePointer( // <--- CRITICAL: Keeps touches going to the GestureDetector
                 child: ClipRect(
                   child: CustomPaint(
                     painter: HeatmapOverlayPainter(
                       points: List.from(_points), // Pass a copy to force a new reference
                       pointRadius: _brushSize,
                       intensity: _intensity,
                       allianceColor: _allianceColor,
                     ),
                   ),
                 ),
               ),
             ),
           ],
         ),
       ),
     );
   }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: clearHeatmap,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showStats,
            icon: const Icon(Icons.analytics),
            label: const Text('Stats'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _allianceColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

   void _addPoint(Offset position) {
     setState(() {
       // Creating a new list instance (List.from) is the
       // most reliable way to trigger a repaint in Flutter.
       _points = List.from(_points)..add(position);
     });
     widget.onPointsChanged?.call(_points.length);
   }

  void _showStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: _allianceColor),
            const SizedBox(width: 8),
            const Text('Heatmap Statistics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Alliance', widget.alliance.name.toUpperCase()),
            _buildStatRow('Touch points', '${_points.length}'),
            _buildStatRow('Brush size', '${_brushSize.toInt()}px'),
            _buildStatRow('Intensity', _intensity.toStringAsFixed(2)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'This heatmap visualizes robot activity on the field. '
                  'Warmer colors indicate higher activity areas.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}

/// Heatmap overlay painter
class HeatmapOverlayPainter extends CustomPainter {
  final List<Offset> points;
  final double pointRadius;
  final double intensity;
  final Color allianceColor;

  HeatmapOverlayPainter({
    required this.points,
    required this.pointRadius,
    required this.intensity,
    required this.allianceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridResolution = 50;
    final cellWidth = size.width / gridResolution;
    final cellHeight = size.height / gridResolution;

    final gradientColors = [
      Colors.transparent,
      allianceColor.withOpacity(0.15),
      allianceColor.withOpacity(0.35),
      Colors.yellow.withOpacity(0.5),
      Colors.orange.withOpacity(0.7),
      Colors.red.withOpacity(0.85),
    ];

    for (var i = 0; i < gridResolution; i++) {
      for (var j = 0; j < gridResolution; j++) {
        final x = i * cellWidth;
        final y = j * cellHeight;
        final cellCenter = Offset(x + cellWidth / 2, y + cellHeight / 2);

        double density = 0.0;

        for (var point in points) {
          final distance = (point - cellCenter).distance;
          if (distance < pointRadius) {
            final contribution = intensity * (1 - (distance / pointRadius));
            density += contribution;
          }
        }

        if (density > 0) {
          final normalizedDensity = math.min(density, 1.0);
          final color = _getGradientColor(normalizedDensity, gradientColors);

          final rect = Rect.fromLTWH(x, y, cellWidth, cellHeight);
          final paint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;

          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  Color _getGradientColor(double value, List<Color> colors) {
    if (value <= 0) return colors.first;
    if (value >= 1) return colors.last;

    final segmentSize = 1.0 / (colors.length - 1);
    final segmentIndex = (value / segmentSize).floor();
    final segmentValue = (value % segmentSize) / segmentSize;

    final startColor = colors[segmentIndex];
    final endColor = colors[math.min(segmentIndex + 1, colors.length - 1)];

    return Color.lerp(startColor, endColor, segmentValue)!;
  }

  @override
  @override
  @override
  bool shouldRepaint(HeatmapOverlayPainter oldDelegate) {
    // If the length is different, we MUST repaint.
    return points.length != oldDelegate.points.length;
  }
}
