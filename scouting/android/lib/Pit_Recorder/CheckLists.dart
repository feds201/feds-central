import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/CameraComposit.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';
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
  late List<String> IntakeController;
  late List<String> ClimbTypeController;
  late List<String> ScoreObjectController;
  late bool? hello;
  late String selectedChoice;
  late String ImageBlob1;
  late String ImageBlob2;
  late String ImageBlob3;
  late String ImageBlob; // Add this variable to store combined images

  // New FRC 2026 State Variables
  late List<String> AutoRoutesController;
  late int AutoFuelController;
  late String GameDataController; // "Yes" or "No"
  late double WeightController;
  late double SpeedController;
  late TextEditingController DriveMotorTypeController;
  late double GroundClearanceController;
  late int MaxFuelCapacityController;
  late double AvgCycleTimeController;
  late double ClimbSuccessProbController;
  late int BatteriesController;
  late TextEditingController FramePerimeterController;
  late double ShootingRateController;

  // Unit selectors
  String weightUnit = 'lbs';
  String speedUnit = 'ft/s';
  String clearanceUnit = 'in';
  String shootingRateUnit = 'balls/sec';

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Initialize with empty values
    DrivetrainController = "";
    AutonController = "";
    ScoreTypeController = [];
    IntakeController = [];
    ClimbTypeController = [];
    ScoreObjectController = [];
    hello = null;
    selectedChoice = '';
    ImageBlob1 = "";
    ImageBlob2 = "";
    ImageBlob3 = "";
    ImageBlob = ""; // Initialize the combined blob

    // New Fields Init
    AutoRoutesController = [];
    AutoFuelController = 0;
    GameDataController = "No";
    WeightController = 0.0;
    SpeedController = 0.0;
    DriveMotorTypeController = TextEditingController();
    GroundClearanceController = 0.0;
    MaxFuelCapacityController = 0;
    AvgCycleTimeController = 0.0;
    ClimbSuccessProbController = 0.0;
    BatteriesController = 0;
    FramePerimeterController = TextEditingController();
    ShootingRateController = 0.0;

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

          // New Fields Populate
          AutoRoutesController = existingRecord.autoRoutes;
          AutoFuelController = existingRecord.autoFuel;
          GameDataController = existingRecord.gameData ? "Yes" : "No";
          WeightController = existingRecord.weight;
          SpeedController = existingRecord.speed;
          DriveMotorTypeController.text = existingRecord.driveMotorType;
          GroundClearanceController = existingRecord.groundClearance;
          MaxFuelCapacityController = existingRecord.maxFuelCapacity;
          AvgCycleTimeController = existingRecord.avgCycleTime;
          ClimbSuccessProbController = existingRecord.climbSuccessProb;
          BatteriesController = existingRecord.batteries;
          FramePerimeterController.text = existingRecord.framePerimeter;
          ShootingRateController = existingRecord.shootingRate;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [],
        backgroundColor:
            islightmode() ? lightColors.white : darkColors.goodblack,
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
            "Autonomous & Game Data",
            [
              buildMultiChoiceBox(
                  "Auto Starting Positions",
                  Icon(Icons.start, size: 30, color: Colors.green),
                  ["Left", "Center", "Right"],
                  AutoRoutesController, (value) {
                setState(() {
                  AutoRoutesController = value;
                });
              }),
              buildNumberBox(
                  "Auto Fuel Scored (Avg)",
                  AutoFuelController.toDouble(),
                  Icon(Icons.numbers, size: 30, color: Colors.blue), (value) {
                setState(() {
                  AutoFuelController = int.tryParse(value) ?? 0;
                });
              }),
              buildChoiceBox(
                  "Game Data Processing?",
                  Icon(Icons.data_object, size: 30, color: Colors.orange),
                  ["Yes", "No"],
                  GameDataController, (value) {
                setState(() {
                  GameDataController = value;
                });
              }),
            ],
            Icon(Icons.auto_mode),
          ),
          buildTextBoxs(
            "Physical & Drive Stats",
            [
              buildNumberWithUnitBox(
                  "Total Weight",
                  WeightController,
                  Icon(Icons.monitor_weight, size: 30, color: Colors.grey),
                  ['lbs', 'kg'],
                  weightUnit,
                  (value) {
                    setState(() {
                      WeightController = double.tryParse(value) ?? 0.0;
                    });
                  },
                  (unit) {
                    setState(() {
                      weightUnit = unit;
                    });
                  }),
              buildNumberWithUnitBox(
                  "Top Speed",
                  SpeedController,
                  Icon(Icons.speed, size: 30, color: Colors.red),
                  ['ft/s', 'm/s', 'mph'],
                  speedUnit,
                  (value) {
                    setState(() {
                      SpeedController = double.tryParse(value) ?? 0.0;
                    });
                  },
                  (unit) {
                    setState(() {
                      speedUnit = unit;
                    });
                  }),
              buildTextBox(
                  "Drive Motors",
                  "e.g. 4x Kraken",
                  Icon(Icons.motorcycle, size: 30, color: Colors.black),
                  DriveMotorTypeController),
              buildNumberWithUnitBox(
                  "Ground Clearance",
                  GroundClearanceController,
                  Icon(Icons.height, size: 30, color: Colors.brown),
                  ['in', 'cm', 'mm'],
                  clearanceUnit,
                  (value) {
                    setState(() {
                      GroundClearanceController = double.tryParse(value) ?? 0.0;
                    });
                  },
                  (unit) {
                    setState(() {
                      clearanceUnit = unit;
                    });
                  }),
              buildChoiceBox(
                  "Drive Train Type",
                  Icon(Icons.car_crash_outlined,
                      size: 30, color: Colors.purple),
                  ["Tank", "Swerve", "Mecanum", "Other"],
                  DrivetrainController, (value) {
                setState(() {
                  DrivetrainController = value;
                });
              }),
            ],
            Icon(Icons.engineering),
          ),
          buildTextBoxs(
            "Scoring & Intake",
            [
              buildNumberBox(
                  "Max Fuel Capacity",
                  MaxFuelCapacityController.toDouble(),
                  Icon(Icons.battery_full, size: 30, color: Colors.green),
                  (value) {
                setState(() {
                  MaxFuelCapacityController = int.tryParse(value) ?? 0;
                });
              }),
              buildNumberBox("Avg Cycle Time (sec)", AvgCycleTimeController,
                  Icon(Icons.timer, size: 30, color: Colors.blue), (value) {
                setState(() {
                  AvgCycleTimeController = double.tryParse(value) ?? 0.0;
                });
              }),
              buildNumberWithUnitBox(
                  "Shooting Rate",
                  ShootingRateController,
                  Icon(Icons.rocket_launch, size: 30, color: Colors.deepOrange),
                  ['balls/sec', 'balls/min'],
                  shootingRateUnit,
                  (value) {
                    setState(() {
                      ShootingRateController = double.tryParse(value) ?? 0.0;
                    });
                  },
                  (unit) {
                    setState(() {
                      shootingRateUnit = unit;
                    });
                  }),
              buildMultiChoiceBox(
                  "Intake Type",
                  Icon(Icons.shopping_cart_checkout_outlined,
                      size: 30, color: Colors.green),
                  ["Ground", "Source"],
                  IntakeController, (value) {
                setState(() {
                  IntakeController = value;
                });
              }),
              buildMultiChoiceBox(
                  "Score Locations",
                  Icon(Icons.star_outline, size: 30, color: Colors.blue),
                  ["Low Goal", "High Goal", "Cross Obstacles"],
                  ScoreTypeController, (value) {
                setState(() {
                  ScoreTypeController = value;
                });
              }),
            ],
            Icon(Icons.sports_score),
          ),
          buildTextBoxs(
            "Strategic Checklist",
            [
              buildNumberBox("Climb Success %", ClimbSuccessProbController,
                  Icon(Icons.elevator, size: 30, color: Colors.amber), (value) {
                setState(() {
                  ClimbSuccessProbController = double.tryParse(value) ?? 0.0;
                });
              }),
              buildMultiChoiceBox(
                  "Climb Type",
                  Icon(Icons.elevator,
                      size: 30, color: const Color.fromARGB(255, 200, 186, 34)),
                  ["Climb", "Park", "None"],
                  ClimbTypeController, (value) {
                setState(() {
                  ClimbTypeController = value;
                });
              }),
              buildNumberBox(
                  "Batteries On-Site",
                  BatteriesController.toDouble(),
                  Icon(Icons.battery_charging_full,
                      size: 30, color: Colors.yellow), (value) {
                setState(() {
                  BatteriesController = int.tryParse(value) ?? 0;
                });
              }),
              buildTextBox(
                  "Frame Perimeter",
                  "Dimensions",
                  Icon(Icons.square_foot, size: 30, color: Colors.grey),
                  FramePerimeterController),
            ],
            Icon(Icons.check_box),
          ),
          buildTextBoxs(
            "Photos",
            [
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
            Icon(Icons.camera_alt),
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

    // Ensure lists are specialized
    List<String> finalScoreObject = ["Fuel"]; // Default for 2026

    // Convert weight to lbs for storage
    double storedWeight = WeightController;
    if (weightUnit == 'kg') storedWeight = WeightController * 2.20462;

    // Convert speed to ft/s for storage
    double storedSpeed = SpeedController;
    if (speedUnit == 'm/s') storedSpeed = SpeedController * 3.28084;
    if (speedUnit == 'mph') storedSpeed = SpeedController * 1.46667;

    // Convert ground clearance to inches for storage
    double storedClearance = GroundClearanceController;
    if (clearanceUnit == 'cm') storedClearance = GroundClearanceController / 2.54;
    if (clearanceUnit == 'mm') storedClearance = GroundClearanceController / 25.4;

    // Convert shooting rate to balls/sec for storage
    double storedShootingRate = ShootingRateController;
    if (shootingRateUnit == 'balls/min') storedShootingRate = ShootingRateController / 60.0;

    PitRecord record = PitRecord(
        teamNumber: widget.team.teamNumber,
        scouterName: deviceName,
        eventKey: eventKey,
        driveTrainType: DrivetrainController,
        autonType: AutonController,
        scoreType: ScoreTypeController,
        intake: IntakeController,
        climbType: ClimbTypeController,
        scoreObject: finalScoreObject,
        botImage1: ImageBlob1,
        botImage2: ImageBlob2,
        botImage3: ImageBlob3,

        // New Fields
        autoRoutes: AutoRoutesController,
        autoFuel: AutoFuelController,
        gameData: GameDataController == "Yes",
        weight: storedWeight,
        speed: storedSpeed,
        driveMotorType: DriveMotorTypeController.text,
        groundClearance: storedClearance,
        maxFuelCapacity: MaxFuelCapacityController,
        avgCycleTime: AvgCycleTimeController,
        climbSuccessProb: ClimbSuccessProbController,
        batteries: BatteriesController,
        framePerimeter: FramePerimeterController.text,
        shootingRate: storedShootingRate);

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
