import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

enum Alliance { blue, red }

class MultiPointSelector extends StatefulWidget {
  final String blueAllianceImagePath;
  final String redAllianceImagePath;
  final Alliance alliance;
  final List<int>? initialData;
  final void Function(List<int> data)? onDataChanged;
  final void Function(bool isLocked)? onLockStateChanged;

  const MultiPointSelector({
    Key? key,
    required this.blueAllianceImagePath,
    required this.redAllianceImagePath,
    required this.alliance,
    this.initialData,
    this.onDataChanged,
    this.onLockStateChanged,
  }) : super(key: key);

  @override
  State<MultiPointSelector> createState() => MultiPointSelectorState();
}

class MultiPointSelectorState extends State<MultiPointSelector> {
  Set<int> _selectedCells = {};
  bool _isLocked = true;
  bool _isErasing = false;
  final GlobalKey _imageKey = GlobalKey();

  static const int _rows = 33;
  static const int _cols = 58;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedCells = Set.from(widget.initialData!);
    }
  }

  String get _currentImagePath => widget.alliance == Alliance.blue
      ? widget.blueAllianceImagePath
      : widget.redAllianceImagePath;

  Color get _allianceColor =>
      widget.alliance == Alliance.blue ? Colors.blue : Colors.red;

  @override
  void didUpdateWidget(covariant MultiPointSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alliance != widget.alliance) {
      setState(() {
        _selectedCells.clear();
      });
    }
  }

  void _clear() {
    setState(() {
      _selectedCells.clear();
      _notifyChanged();
    });
  }

  int _calculateCellId(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return -1;
    double dx = localPosition.dx.clamp(0.0, size.width - 0.1);
    double dy = localPosition.dy.clamp(0.0, size.height - 0.1);

    double cellWidth = size.width / _cols;
    double cellHeight = size.height / _rows;

    int col = (dx / cellWidth).floor();
    int row = (dy / cellHeight).floor();

    return (row * _cols) + col + 1;
  }

  void _handleGesture(Offset localPosition) {
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    Size size = renderBox.size;

    double dx = localPosition.dx.clamp(0.0, size.width - 0.1);
    double dy = localPosition.dy.clamp(0.0, size.height - 0.1);

    double cellWidth = size.width / _cols;
    double cellHeight = size.height / _rows;

    int centerCol = (dx / cellWidth).floor();
    int centerRow = (dy / cellHeight).floor();

    // Radius 2 = 5x5 block.
    int radius = 2;

    Set<int> cellsMod = {};

    for (int r = centerRow - radius; r <= centerRow + radius; r++) {
      for (int c = centerCol - radius; c <= centerCol + radius; c++) {
        if (r >= 0 && r < _rows && c >= 0 && c < _cols) {
          int id = (r * _cols) + c + 1;
          cellsMod.add(id);
        }
      }
    }

    setState(() {
      if (_isErasing) {
        _selectedCells.removeAll(cellsMod);
      } else {
        _selectedCells.addAll(cellsMod);
      }
    });
  }

  void _notifyChanged() {
    widget.onDataChanged?.call(_selectedCells.toList());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = MediaQuery.of(context).size.width;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Container(
                width: screenWidth,
                decoration: BoxDecoration(
                  color: islightmode()
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : const Color.fromARGB(255, 34, 34, 34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    color: const Color(0xBF254EEA),
                    child: GestureDetector(
                      onPanStart: _isLocked
                          ? null
                          : (details) {
                              final RenderBox? renderBox =
                                  _imageKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (renderBox == null) return;
                              Size size = renderBox.size;
                              int startId =
                                  _calculateCellId(details.localPosition, size);
                              _isErasing = _selectedCells.contains(startId);
                              _handleGesture(details.localPosition);
                            },
                      onPanUpdate: _isLocked
                          ? null
                          : (details) {
                              _handleGesture(details.localPosition);
                            },
                      onPanEnd: _isLocked ? null : (_) => _notifyChanged(),
                      onTapUp: _isLocked
                          ? null
                          : (details) {
                              final RenderBox? renderBox =
                                  _imageKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (renderBox == null) return;
                              Size size = renderBox.size;
                              int cellId =
                                  _calculateCellId(details.localPosition, size);
                              if (cellId == -1) return;
                              setState(() {
                                if (_selectedCells.contains(cellId)) {
                                  _selectedCells.remove(cellId);
                                } else {
                                  _selectedCells.add(cellId);
                                }
                                _notifyChanged();
                              });
                            },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          key: _imageKey,
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              _currentImagePath,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _GridPainter(
                                  selectedCells: _selectedCells,
                                  color: _allianceColor,
                                  rows: _rows,
                                  cols: _cols,
                                ),
                              ),
                            ),
                            if (_isLocked)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.black.withOpacity(0.5),
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLocked = !_isLocked;
                      });
                      widget.onLockStateChanged?.call(_isLocked);
                    },
                    icon:
                        Icon(_isLocked ? Icons.lock_outline : Icons.lock_open),
                    label: Text(_isLocked ? "Unlock" : "Lock"),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          islightmode() ? Colors.black : Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _Clearable ? _clear : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Clear"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      disabledForegroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _Clearable => _selectedCells.isNotEmpty;
}

class _GridPainter extends CustomPainter {
  final Set<int> selectedCells;
  final Color color;
  final int rows;
  final int cols;

  _GridPainter({
    required this.selectedCells,
    required this.color,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedCells.isEmpty) return;

    double cellWidth = size.width / cols;
    double cellHeight = size.height / rows;

    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int id in selectedCells) {
      if (id < 1) continue;
      // 1-based ID -> 0-based index
      int index = id - 1;
      int r = index ~/ cols;
      int c = index % cols;

      Rect rect = Rect.fromLTWH(
        c * cellWidth,
        r * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.selectedCells != selectedCells ||
        oldDelegate.color != color;
  }
}
