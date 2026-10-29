// lib/Training/TrainingPage.dart
//
// YOUR TRAINING PAGE (Module 2)
// -----------------------------------------------------------
// This page already exists and is reachable from the home
// screen (orange "Training" button). You will fill it in
// lesson by lesson.
//
// Rules:
//  - Add your variables in the "YOUR VARIABLES" area.
//  - Add your widgets inside the children list, under the
//    heading for the lesson you are on.
//  - Do NOT delete the section headings.
// -----------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:scout_ops_android/components/CheckBox.dart';
import 'package:scout_ops_android/components/CounterShelf.dart';

import 'BugHuntPage.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  // ===== YOUR VARIABLES =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Page')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Hello, FEDS!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ===== LESSON 6: TRUE / FALSE =====

            // ===== LESSON 7: COUNTERS =====

            // ===== LESSON 9: CAPSTONE =====

            // ----- Lesson 8 button. Do not delete. -----
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BugHuntPage()),
                );
              },
              child: const Text('Open Bug Hunt (Lesson 10)'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}