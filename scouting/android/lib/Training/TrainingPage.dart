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
import 'package:scout_ops_android/components/FoulsCounter.dart';
import 'package:scout_ops_android/components/YesNoToggle.dart';

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
  int count = 0;
  int cycles = 0;
  int passing = 0;
  int fouls = 0;
  final int cycleGoal = 5;
  int totalPoints() {
    return (cycles * 4) + passing + (-fouls * 2);
  }
  bool cyclescheck = false;
  bool climbedcheck = false;
  bool counterscheck = false;
  bool foulcheck = false;
  bool goalcheck = false;
  bool capstoneZone = false;
  int morefouls = 0;
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
                countYes();
              });
            }),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize:
            Size(MediaQuery.of(context).size.width, 50),
            foregroundColor: Colors.white,
            backgroundColor: defense ? Colors.green : Colors.redAccent,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Colors.blue,
                width: 3,
              ),
            ),
          ),
          onPressed: () => setState(() {
            defense = !defense;
            countYes();
          }),
          child: Text(defense ? 'Defense: YES' : 'Defense: NO'),
        ),

            buildCheckBoxFull('leftZone?????', leftZone, (bool value) {
              setState(() {
                leftZone = value;
                countYes();
              });
            }),

            Text('Yes answers: ${count}'),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize:
                Size(MediaQuery.of(context).size.width / 2, 50),
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Colors.blue,
                    width: 3,
                  ),
                ),
              ),
              onPressed: () => setState(() {
                climbed = false;
                defense = false;
                leftZone = false;
              }),
              child: Text('RESET'),
            ),
            // ===== LESSON 7: COUNTERS =====
            buildCounterFull('Cycles', cycles, (int value) {
              setState(() {
                if (value >= 0 && value <= 10) {
                  cycles = value;
                }
              });
            }, color: Colors.amber),
            Text((cycles >= cycleGoal) ? 'Goal reached!'  : '${cycleGoal - cycles} to go', style: (cycles >= cycleGoal) ? TextStyle(color: Colors.green) : TextStyle(color: Colors.orange) ),
            buildCounterFull('Passing', passing, (int value) {
              setState(() {
                if (value >= 0 && value <= 20) {
                  passing = value;
                }
              });
            }, color: Colors.blue),
            buildCounterFull('Fouls', fouls, (int value) {
              setState(() {
                if (value >= 0 && value <= 6) {
                  fouls = value;
                }
              });
            }, color: Colors.red),
            Text('Yes answers: ${totalPoints()}'),
            // ===== LESSON 8: CHECKLIST =====
            buildCheckBox('cycles work', cyclescheck, (bool value) {
              setState(() {
                cyclescheck = value;
              });
            }),
            buildCheckBox('climbed work', climbedcheck, (bool value) {
              setState(() {
                climbedcheck = value;
              });
            }),
            buildCheckBox('counters work', counterscheck, (bool value) {
              setState(() {
                counterscheck = value;
              });
            }),
            buildCheckBox('foul work', foulcheck, (bool value) {
              setState(() {
                foulcheck = value;
              });
            }),
            buildCheckBox('goal work', goalcheck, (bool value) {
              setState(() {
                goalcheck = value;
              });
            }),
            Text((stepsLeft() <= 0) ? 'All steps done!'  : '${stepsLeft()} to go', style: (stepsLeft() <= 0) ? TextStyle(color: Colors.green) : TextStyle(color: Colors.orange) ),
            // ===== LESSON 9: CAPSTONE =====
            buildYesNoToggle('Left zone', capstoneZone, (bool value) {
              setState(() {
                capstoneZone = value;
              });
            }),
            buildFoulsCounter("epic foul title",morefouls, (int value){
              setState(() {
                if(value >= 0 && value <= 10) {
                  morefouls = value;
                }
              });
            }),
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

  int countYes() {
    if (defense)
      count++;
    if (climbed)
      count++;
    if (leftZone)
      count++;
    return count;
  }

  int stepsLeft() {
    int left = 0;
    if (!cyclescheck) {
      left++;
    }
    if (!climbedcheck) {
      left++;
    }
    if (!counterscheck) {
      left++;
    }
    if (!foulcheck) {
      left++;
    }
    if (!goalcheck) {
      left++;
    }
    // one more "if" for each of your other steps
    return left;
  }
}