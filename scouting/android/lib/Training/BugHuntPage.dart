// lib/Training/BugHuntPage.dart
//
// LESSON 8: BUG HUNT
// -----------------------------------------------------------
// This page RUNS, but it has 5 bugs. Use the debug checklist
// to find them. Do not go looking for an answer key.
// -----------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:scout_ops_android/components/CheckBox.dart';
import 'package:scout_ops_android/components/CounterShelf.dart';

class BugHuntPage extends StatefulWidget {
  const BugHuntPage({super.key});

  @override
  State<BugHuntPage> createState() => _BugHuntPageState();
}

class _BugHuntPageState extends State<BugHuntPage> {
  int cycles = 0;
  int fouls = 0;
  bool climbed = false;
  final int cycleGoal = 5;

  // Each cycle is worth 4 points. A climb is worth 10 points.
  // Each foul costs 2 points.
  int totalScore() {
    int climbPoints = 0;
    if (climbed) {
      climbPoints = 10;
    }
    return cycles * 4 + climbPoints + fouls * 2;
  }

  String goalMessage() {
    if (cycles > cycleGoal) {
      return 'Goal reached!';
    } else {
      return 'Keep going...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bug Hunt')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            buildCounterFull('Cycles', cycles, (int value) {
              cycles = value;
            }, color: Colors.amber),
            const SizedBox(height: 8),
            buildCounterFull('Fouls', fouls, (int value) {
              setState(() {
                fouls = value;
              });
            }, color: Colors.red),
            const SizedBox(height: 8),
            buildCheckBoxFull('Climbed', climbed, (bool value) {
              setState(() {
                climbed = value;
              });
            }),
            const SizedBox(height: 16),
            const Text('Climbed: climbed', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Score: ${totalScore()}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(goalMessage(), style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}