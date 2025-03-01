import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scouting_app/components/CameraComposit.dart';
import 'package:scouting_app/services/DataBase.dart';
import 'package:scouting_app/components/TextBox.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

class Record extends StatefulWidget {
  final Team team;
  const Record({super.key, required this.team});

  @override
  State<StatefulWidget> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  int _pressCount = 0;
  final int _requiredPresses = 5;

  late ConfettiController _confettiController;
  late TextEditingController KeyStrengthsController;
  late TextEditingController ChallengesController;
  late TextEditingController DefensiveStrategiesController;
  late TextEditingController DefensePlanController;

  @override
  void initState() {
    super.initState();
    PitDataBase.PrintAll();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    KeyStrengthsController = TextEditingController();
    ChallengesController = TextEditingController();
    DefensiveStrategiesController = TextEditingController();
    DefensePlanController = TextEditingController();

    try {
      print(PitDataBase.GetData(widget.team.teamNumber)["teamNumber"]);
      KeyStrengthsController.text =
          PitDataBase.GetData(widget.team.teamNumber)["keyStrengths"];
      ChallengesController.text =
          PitDataBase.GetData(widget.team.teamNumber)["keyWeaknesses"];
      DefensiveStrategiesController.text =
          PitDataBase.GetData(widget.team.teamNumber)["defensiveStratigiy"];
      DefensePlanController.text =
          PitDataBase.GetData(widget.team.teamNumber)["defensePlan"];
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [],
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              widget.team.nickname,
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
        centerTitle: true,
      ),
      body: _buildQuestions(),
    );
  }

  Widget _buildQuestions() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          buildTextBoxs(
              "Qualitative questions",
              [
                buildTextBox(
                    "What are the key strengths of your robot?",
                    "Describe the main features and capabilities that make your robot stand out.",
                    Icon(
                      Icons.abc,
                      size: 30,
                    ),
                    KeyStrengthsController),
                buildTextBox(
                    "Have you faced any significant challenges with your robot, and how did you overcome them?",
                    "Mention any major issues encountered and the solutions implemented.",
                    Icon(
                      Icons.abc,
                      size: 30,
                    ),
                    ChallengesController),
                buildTextBox(
                    "What defensive strategies are they employing?",
                    "Explain the tactics used to defend against opponents.",
                    Icon(
                      Icons.abc,
                      size: 30,
                    ),
                    DefensiveStrategiesController),
                buildTextBox(
                    "How are they executing their defense plan?",
                    "Describe the methods and actions taken to implement the defense strategy.",
                    Icon(
                      Icons.abc,
                      size: 30,
                    ),
                    DefensePlanController),
              ],
              Icon(Icons.question_answer)),
          buildCameraBox(),
          const SizedBox(height: 20),
          _buildFunButton(),
        ],
      ),
    );
  }

  Widget _buildFunButton() {
    return Column(
      children: [
        Stack(alignment: Alignment.center, children: [
          // Confetti Widget
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2, // Shoot upwards
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            gravity: 0.3,
          ),

          // The fun button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact(); // Vibration feedback
                setState(() {
                  _pressCount++;
                  if (_pressCount >= _requiredPresses) {
                    _recordData();
                    _confettiController.play(); // 🎉 Play confetti
                    _pressCount = 0; // Reset count after saving
                    PopBoard(context);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50), // Smooth, pill shape
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  _pressCount < _requiredPresses
                      ? 'Press ${_requiredPresses - _pressCount} more times to record'
                      : 'Recording Data...',
                  style: GoogleFonts.museoModerno(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  void _recordData() {
    PitRecord record = PitRecord(
      teamNumber: widget.team.teamNumber,
      scouterName: 'Scouter Name',
      eventKey: "test",
      keyStrengths: KeyStrengthsController.text,
      keyWeaknesses: ChallengesController.text,
      defensiveStratigiy: DefensiveStrategiesController.text,
      defensePlan: DefensePlanController.text,
    );

    print('Recording data: $record');
    PitDataBase.PutData(widget.team.teamNumber, record);
    PitDataBase.SaveAll();
    PitDataBase.PrintAll();
  }

  void PopBoard(BuildContext context) {
    Navigator.pop(context);
  }
}
