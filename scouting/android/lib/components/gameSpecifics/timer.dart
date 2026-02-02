import 'dart:async';

import 'package:flutter/material.dart';

class TklKeyboard extends StatefulWidget {
  final Function(double) onChange;
  final Function() doChange;
  final Function() doChangenakedversion;
  double currentTime;

  TklKeyboard(
      {super.key,
      required this.onChange,
      required this.currentTime,
      required this.doChange,
      required this.doChangenakedversion});

  @override
  State<TklKeyboard> createState() => _TklKeyboardState();
}

class _TklKeyboardState extends State<TklKeyboard> with AutomaticKeepAliveClientMixin {
  // Store these in the State class so they persist across rebuilds
  @override
  bool get wantKeepAlive => true;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  void _startStopwatch() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      widget.onChange(_stopwatch.elapsed.inMilliseconds / 1000);
    });
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _timer?.cancel();
    widget.doChange();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always clean up timers to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 450,
        width: 400,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(34, 34, 34, 1),
          borderRadius: BorderRadius.circular(25), // Outer rounded edges
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Grey margin before the line
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(34, 34, 34, 1), // Inner grey
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0032FB), // Blue line
                width: 2,
              ),
            ),
            child: Column(children: [
              const SizedBox(
                height: 20,
              ),
              Text(widget.currentTime.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 70)),
              const SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      widget.onChange(widget.currentTime -= 0.30);
                      widget.doChangenakedversion();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Text("-0.3",
                          style: TextStyle(color: Colors.black, fontSize: 16)),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) {
                      _startStopwatch(); // Start timer here
                    },
                    onTapUp: (_) {
                      // Cancel timer here
                      if (_stopwatch.isRunning) {
                        _stopStopwatch();
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                      child: const Text("HOLD",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 40,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {
                      widget.onChange(widget.currentTime += 0.30);
                      widget.doChangenakedversion();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          color: Colors.lightGreenAccent,
                          shape: BoxShape.circle),
                      child: const Text("+0.3",
                          style: TextStyle(color: Colors.black, fontSize: 16)),
                    ),
                  ),
                ],
              )
            ]),
          ),
        ),
      ),
    );
  }
}
