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
  bool climbed = false;
  bool defense = false;
  bool leftZone = false;
  int yesCount = 0;
  bool isTrue = false;

  int countYes() {
    int isClimbed = climbed ? 1 : 0;
    int isDefense = defense ? 1 : 0;
    int isLeft = leftZone ? 1 : 0;
    yesCount = isClimbed + isDefense + isLeft;
    if(yesCount == 3){
     isTrue = true;
    }
    else{
      isTrue = false;
    }
    return yesCount;
  }
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
            buildCheckBoxFull('Climbed?', climbed, (bool value) {
              setState(() {
                climbed = value;
              });
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: defense ? Colors.green : Colors.red,
              ),
              onPressed: () {
                setState(() {
                  defense = !defense;
                });
              },
              child: Text(defense ? 'Defense: YES' : 'Defense: NO'),
            ),
            const SizedBox(height: 16),
            buildCheckBoxFull('Left starting zone??', leftZone, (bool value) {
              setState(() {
                leftZone = value;
              });
            }),
            const SizedBox(height: 16),
            Text('Yes answers: '+ countYes().toString()),
            const SizedBox(height: 10),
            isTrue ? Text('ya hoo lets gooo u got All three!') : Text(''),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: defense ? Colors.red.shade300 : Colors.red,
              ),
              onPressed: () {
                setState(() {
                  climbed = false;
                  defense = false;
                  leftZone = false;
                });
              },
              child: Text('Reset'),
            ),
            // ===== LESSON 7: COUNTERS =====


            // ===== LESSON 8: CHECKLIST =====

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
              child: const Text('Open Bug Hunt (Lesson 8)'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}