import 'dart:async';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

class TklKeyboard extends StatefulWidget {
  final Function(double) onChange;
  final Function() doChange;
  final Function() doChangeNoIncrement;
  final Function() doChangeResetter;
  double currentTime;

  TklKeyboard(
      {super.key,
      required this.onChange,
      required this.currentTime,
      required this.doChange,
      required this.doChangeNoIncrement,
      required this.doChangeResetter});

  @override
  State<TklKeyboard> createState() => _TklKeyboardState();
}

class _TklKeyboardState extends State<TklKeyboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  double _localTime = 0.0;
  double _holdBase = 0.0;

  @override
  void initState() {
    super.initState();
    _localTime = widget.currentTime;
  }

  @override
  void didUpdateWidget(TklKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != _localTime) {
      _localTime = widget.currentTime;
    }
  }

  void _startStopwatch() {
    if (_stopwatch.isRunning) return;
    _timer?.cancel();
    _holdBase = _localTime;
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      double newValue = _holdBase + (_stopwatch.elapsedMilliseconds / 1000.0);
      setState(() {
        _localTime = newValue;
      });
      widget.onChange(newValue);
    });
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _timer?.cancel();
    widget.doChange();
  }

  void _resetStopwatch() {
    setState(() {
      _timer?.cancel();
      _stopwatch.stop();
      _stopwatch.reset();
      _holdBase = 0.0;
      widget.doChangeResetter();
      _localTime = 0.0;
      widget.onChange(0.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Fixed height prevents unbounded constraints while allowing full width.
    const double designHeight = 500;

    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: designHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: islightmode()
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromRGBO(34, 34, 34, 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: DottedBorder(
                color: const Color(0xBF254EEA),
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                dashPattern: const [10, 4],
                strokeWidth: 3,
                child: Stack(
                  children: [
                    // Main content column
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Timer Display
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: islightmode()
                                    ? Colors.grey.withOpacity(0.1)
                                    : const Color(0xFF181818),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _localTime.toStringAsFixed(2),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: islightmode()
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "monospace",
                                ),
                              ),
                            ),
                            // Control Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Minus button
                                _buildRoundButton(
                                  "-0.30",
                                  const Color.fromARGB(255, 76, 175, 80),
                                  60,
                                  () {
                                    setState(() {
                                      _localTime -= 0.30;
                                    });
                                    widget.onChange(_localTime);
                                    widget.doChangeNoIncrement();
                                  },
                                ),
                                // HOLD button
                                GestureDetector(
                                  onTapDown: (_) => _startStopwatch(),
                                  onTapCancel: () {
                                    if (_stopwatch.isRunning) _stopStopwatch();
                                  },
                                  onTapUp: (_) {
                                    if (_stopwatch.isRunning) _stopStopwatch();
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 37, 211, 43),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          spreadRadius: 2,
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      "HOLD",
                                      style: TextStyle(
                                        color: Colors.black26,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                // Plus button
                                _buildRoundButton(
                                  "+0.30",
                                  const Color.fromARGB(255, 229, 57, 53),
                                  60,
                                  () {
                                    setState(() {
                                      _localTime += 0.30;
                                    });
                                    widget.onChange(_localTime);
                                    widget.doChangeNoIncrement();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Reset button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _resetStopwatch,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 152, 0),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundButton(
      String label, Color color, double size, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black26,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
