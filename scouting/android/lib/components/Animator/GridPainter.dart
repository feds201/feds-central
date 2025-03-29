import 'dart:math';
import 'package:flutter/material.dart';

import '../../main.dart';

class WaveGrid extends StatefulWidget {
  const WaveGrid({super.key});

  @override
  _WaveGridState createState() => _WaveGridState();
}

class _WaveGridState extends State<WaveGrid> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Initializing animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(); // Repeating the animation
  }

  @override
  void dispose() {
    _controller.dispose(); // Disposing the animation controller
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Using MediaQuery to get the screen size
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WaveGridPainter(
              waveAnimation:
                  _controller.drive(Tween(begin: 1 * pi, end: 5 * pi)),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WaveGridPainter extends CustomPainter {
  final Animation<double> waveAnimation;

  _WaveGridPainter({
    required this.waveAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = islightmode() ? const Color(0x15040404) : invertColor(const Color(0x15040404))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0x00ffffff)
      ..strokeWidth = 3 // Line width
      ..style = PaintingStyle.stroke;

    const cols = 15;
    const rows = 25;
    const loc = 50;
    final grid = List.generate(cols, (i) {
      return List.generate(rows, (j) {
        return Cell(
          colSize: size.width / cols,
          rowSize: size.height / rows,
          x0: size.width / cols * i,
          y0: size.height / rows * j,
          r: (size.width / cols) / 10,
          // Adjust point size here
          angle: (size.width / cols) * loc / 100 * i + loc * j,
        );
      });
    });

    for (var i = 0; i < grid.length; i++) {
      for (var j = 0; j < grid[i].length; j++) {
        grid[i][j].update(waveAnimation.value);
        canvas.drawCircle(
          Offset(grid[i][j].x0 * 1.2 + grid[i][j].x,
              grid[i][j].y0 * 1.2 + grid[i][j].y),
          grid[i][j].r,
          paint,
        );

        // Drawing lines to neighboring points
        if (i > 0) {
          canvas.drawLine(
            Offset(grid[i][j].x0 * 1.2 + grid[i][j].x,
                grid[i][j].y0 * 1.2 + grid[i][j].y),
            Offset(grid[i - 1][j].x0 * 1.2 + grid[i - 1][j].x,
                grid[i - 1][j].y0 * 1.2 + grid[i - 1][j].y),
            linePaint,
          );
        }
        if (j > 0) {
          canvas.drawLine(
            Offset(grid[i][j].x0 * 1.2 + grid[i][j].x,
                grid[i][j].y0 * 1.2 + grid[i][j].y),
            Offset(grid[i][j - 1].x0 * 1.2 + grid[i][j - 1].x,
                grid[i][j - 1].y0 * 1.2 + grid[i][j - 1].y),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WaveGridPainter oldDelegate) => true;

}

class Cell {
  final double r;
  final double angle;
  final double x0;
  final double y0;
  late double x;
  late double y;

  Cell({
    required double colSize,
    required double rowSize,
    required this.x0,
    required this.y0,
    required this.r,
    required this.angle,
  }) {
    x = r * cos(angle);
    y = r * sin(angle);
  }

  void update(double waveAnimation) {
    x = r * cos(angle + waveAnimation);
    y = r * sin(angle + waveAnimation);
  }
}
