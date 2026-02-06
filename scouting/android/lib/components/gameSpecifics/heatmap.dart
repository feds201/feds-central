import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

enum Alliance { blue, red }

class SinglePointSelector extends StatefulWidget {
  final String blueAllianceImagePath;
  final String redAllianceImagePath;
  final Alliance alliance;
  final Offset? initialPoint;
  final void Function(Size imageSize, Offset point)? onPointSelected;

  const SinglePointSelector({
    Key? key,
    required this.blueAllianceImagePath,
    required this.redAllianceImagePath,
    required this.alliance,
    this.initialPoint,
    this.onPointSelected,
  }) : super(key: key);

  @override
  State<SinglePointSelector> createState() => SinglePointSelectorState();
}

class SinglePointSelectorState extends State<SinglePointSelector> {
  Offset? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  String get _currentImagePath => widget.alliance == Alliance.blue
      ? widget.blueAllianceImagePath
      : widget.redAllianceImagePath;

  Color get _allianceColor =>
      widget.alliance == Alliance.blue ? Colors.blue : Colors.red;

  @override
  void didUpdateWidget(covariant SinglePointSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alliance != widget.alliance) {
      setState(() => _selectedPoint = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = MediaQuery.of(context).size.width;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: islightmode()
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(255, 34, 34, 34),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                dashPattern: const [8, 4],
                strokeWidth: 2,
                color: const Color(0xBF254EEA),
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          setState(
                              () => _selectedPoint = details.localPosition);
                          final imageSize =
                              Size(constraints.maxWidth, constraints.maxHeight);
                          widget.onPointSelected
                              ?.call(imageSize, details.localPosition);
                        },
                        child: ClipRect(
                          // Changed ClipRect to ClipRRect to match border radius if needed, but ClipRect is fine for the image itself inside padding
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  _currentImagePath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _SelectionPainter(
                                      point: _selectedPoint,
                                      color: _allianceColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final Offset? point;
  final Color color;

  _SelectionPainter({required this.point, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (point == null) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point!, 19.0, paint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return oldDelegate.point != point || oldDelegate.color != color;
  }
}
