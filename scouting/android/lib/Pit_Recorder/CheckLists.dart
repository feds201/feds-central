import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
  final int _requiredPresses = 1;

  late ConfettiController _confettiController;

  late String DrivetrainController;
  late String AutonController;
  late List<String> ScoreTypeController;
  late String IntakeController;
  late List<String> ClimbTypeController;
  late List<String> ScoreObjectController;
  late bool? hello;
  late String selectedChoice;
  late String ImageBlob1;
  late String ImageBlob2;
  late String ImageBlob3;
  late String ImageBlob; // Add this variable to store combined images

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Initialize with empty values
    DrivetrainController = "";
    AutonController = "";
    ScoreTypeController = [];
    IntakeController = "";
    ClimbTypeController = [];
    ScoreObjectController = [];
    hello = null;
    selectedChoice = '';
    ImageBlob1 = "";
    ImageBlob2 = "";
    ImageBlob3 = "";
    ImageBlob = ""; // Initialize the combined blob

    // Load database and try to get existing data for this team
    PitDataBase.LoadAll();
    try {
      PitRecord? existingRecord = PitDataBase.GetData(widget.team.teamNumber);
      if (existingRecord != null) {
        // Populate UI state variables with existing data
        setState(() {
          DrivetrainController = existingRecord.driveTrainType;
          AutonController = existingRecord.autonType;
          ScoreTypeController = existingRecord.scoreType;
          IntakeController = existingRecord.intake;
          ClimbTypeController = existingRecord.climbType;
          ScoreObjectController = existingRecord.scoreObject;
          ImageBlob1 = existingRecord.botImage1;
          ImageBlob2 = existingRecord.botImage2;
          ImageBlob3 = existingRecord.botImage3;

          // Combine the existing images into ImageBlob
          // Filter out empty images and join with comma
          List<String> images = [ImageBlob1, ImageBlob2, ImageBlob3]
              .where((img) => img.isNotEmpty)
              .toList();
          ImageBlob = images.join(',');
        });
        print("Loaded existing data for team ${widget.team.teamNumber}");
      } else {
        print("No existing record found for team ${widget.team.teamNumber}");
      }
    } catch (e) {
      print("Error retrieving team data: $e");
    } finally {}
  }

  // Helper method to convert base64 strings to File objects
  Future<List<File>> _getImagesFromBase64Strings(String base64Images) async {
    List<File> imageFiles = [];
    if (base64Images.isEmpty) return imageFiles;

    // Split the base64 string by comma to get individual images
    List<String> images = base64Images.split(',');

    for (int i = 0; i < images.length; i++) {
      try {
        final tempDir = await Directory.systemTemp.createTemp('images');
        final bytes = base64Decode(images[i]);
        final file = File('${tempDir.path}/image_$i.jpg');
        await file.writeAsBytes(bytes);
        imageFiles.add(file);
      } catch (e) {
        print('Error converting base64 to file: $e');
      }
    }

    return imageFiles;
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
        child: Column(children: [
          buildTextBoxs(
            "PIT Questions",
            [
              buildChoiceBox(
                  "What type of drive train do they have?",
                  Icon(Icons.car_crash_outlined,
                      size: 30, color: Colors.purple),
                  ["Tank drive", "Swerve drive", "Others"],
                  DrivetrainController, (value) {
                setState(() {
                  DrivetrainController = value;
                });
              }),
              buildChoiceBox(
                  "Auton?",
                  Icon(Icons.computer_outlined,
                      size: 30, color: const Color.fromARGB(255, 69, 84, 169)),
                  ["No Auto", "Leave", "Leave + Auto."],
                  AutonController, (value) {
                setState(() {
                  AutonController = value;
                });
              }),
              buildMultiChoiceBox(
                  "What can they score??",
                  Icon(Icons.star_outline, size: 30, color: Colors.blue),
                  ["Coral", "Algae"],
                  ScoreObjectController, (value) {
                setState(() {
                  ScoreObjectController = value;
                });
              }),
              buildMultiChoiceBox(
                  "Where can they score?",
                  Icon(Icons.star_outline, size: 30, color: Colors.blue),
                  ["L1", "L2", "L3", "L4", "Barge"],
                  ScoreTypeController, (value) {
                setState(() {
                  ScoreTypeController = value;
                });
              }),
              buildChoiceBox(
                  "How do they INTAKE Coral",
                  Icon(Icons.shopping_cart_checkout_outlined,
                      size: 30, color: Colors.green),
                  ["Ground", "Coral Station"],
                  IntakeController, (value) {
                setState(() {
                  IntakeController = value;
                });
              }),
              buildMultiChoiceBox(
                  "Can they climb?",
                  Icon(Icons.elevator,
                      size: 30, color: const Color.fromARGB(255, 200, 186, 34)),
                  ["Deep", "Shallow", "Doesn't Climb"],
                  ClimbTypeController, (value) {
                setState(() {
                  ClimbTypeController = value;
                });
              }),
              Icon(Icons.question_answer),

              // Camera component with previously captured images
              CameraPhotoCapture(
                title: "Robot Photos",
                description: "Take photos of the robot",
                maxPhotos: 3,
                initialImages: [ImageBlob1, ImageBlob2, ImageBlob3]
                    .where((img) => img.isNotEmpty)
                    .toList(),
                onPhotosTaken: (photos) {
                  // Convert all photos to base64 strings
                  List<String> base64Images = [];
                  for (var photo in photos) {
                    base64Images.add(base64Encode(photo.readAsBytesSync()));
                  }

                  setState(() {
                    // Store the combined base64 strings
                    ImageBlob = base64Images.join(',');

                    // Also update individual image blobs if needed
                    if (base64Images.isNotEmpty && base64Images.length >= 1) {
                      ImageBlob1 = base64Images[0];
                    } else {
                      ImageBlob1 = "";
                    }
                    if (base64Images.isNotEmpty && base64Images.length >= 2) {
                      ImageBlob2 = base64Images[1];
                    } else {
                      ImageBlob2 = "";
                    }
                    if (base64Images.isNotEmpty && base64Images.length >= 3) {
                      ImageBlob3 = base64Images[2];
                    } else {
                      ImageBlob3 = "";
                    }
                  });

                  print('Photos captured: ${photos.length}');
                },
              ),
              const SizedBox(height: 20),
              _buildFunButton(),
            ],
            Icon(Icons.question_answer),
          ),
        ]));
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
    String deviceName = Hive.box('settings')
        .get('deviceName', defaultValue: 'Ritesh Raj Arul Selvan');
    String eventKey =
        Hive.box('userData').get('eventKey', defaultValue: 'test');
    PitRecord record = PitRecord(
        teamNumber: widget.team.teamNumber,
        scouterName: deviceName,
        eventKey: eventKey,
        driveTrainType: DrivetrainController,
        autonType: AutonController,
        scoreType: ScoreTypeController,
        intake: IntakeController,
        climbType: ClimbTypeController,
        scoreObject: ScoreObjectController.cast<String>().toList(),
        botImage1: ImageBlob1,
        botImage2: ImageBlob2,
        botImage3: ImageBlob3);

    print('Recording data: $record');
    print("Hiv ${record.toJson()}");

    _showConfirmationDialog(record);
    PitDataBase.PutData(widget.team.teamNumber, record);
    PitDataBase.SaveAll();

    PitDataBase.PrintAll();
  }

  void _showConfirmationDialog(PitRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text(
              "Data recorded successfully. \n\nTeam: ${record.teamNumber}\nScouter: ${record.scouterName}"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                PopBoard(context);
              },
            ),
          ],
        );
      },
    );
  }

  void PopBoard(BuildContext context) {
    Navigator.pop(context);
  }
}
