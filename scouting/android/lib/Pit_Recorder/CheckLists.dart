import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scout_ops_android/components/CameraComposit.dart';
import 'package:scout_ops_android/components/ScoutersList.dart';
import 'package:scout_ops_android/main.dart';
import 'package:scout_ops_android/services/Colors.dart';
import 'package:scout_ops_android/services/DataBase.dart';
import 'package:scout_ops_android/components/TextBox.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:bot_path_drawer/bot_path_drawer.dart';
import 'dart:async';


class Record extends StatefulWidget {
  final Team team;
  const Record({super.key, required this.team});

  @override
  State<StatefulWidget> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  int _pressCount = 0;
  Timer? _pathSavedTimer;
  final int _requiredPresses = 1;
  final config = BotPathConfig(
    backgroundImage: AssetImage('assets/2026/Aerna2026.png'),
    brightness: Brightness.dark
  );


  late ConfettiController _confettiController;

  late String DrivetrainController;
  late String AutonController;
  late List<String> ScoreTypeController;
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
  late String HopperStatusController;
  late String TrenchController;
  late String BumpController;
  late int DriverYearController;
  late TextEditingController InterviewerNameController;
  late TextEditingController InterviewerRoleController;
  late String AttitudeController;
  late String ScoutingAccuracyController;
  late TextEditingController NotCooperativeReasonController;
  late TextEditingController PathNameController;
  late List<Map<String, String?>> PathDataController;

  // Unit selectors
  String weightUnit = 'lbs';
  String speedUnit = 'ft/s';
  String clearanceUnit = 'in';
  String shootingRateUnit = 'balls/sec';
  bool _pathSaved = false;


  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Initialize with empty values
    DrivetrainController = "";
    AutonController = "";
    ScoreTypeController = [];
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
    HopperStatusController = "No";
    TrenchController = "Never";
    BumpController = "No";
    DriverYearController = 0;
    InterviewerNameController = TextEditingController();
    InterviewerRoleController = TextEditingController();
    AttitudeController = "Yes";
    ScoutingAccuracyController = "Accurate";
    NotCooperativeReasonController = TextEditingController();
    PathNameController = TextEditingController();
    PathDataController = [];
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
          HopperStatusController = existingRecord.hopperSealed ? "Yes" : "No";
          TrenchController = existingRecord.trenchUnder;
          BumpController = existingRecord.bumpOver ? "Yes" : "No";
          DriverYearController = existingRecord.driverYear;
          InterviewerNameController.text = existingRecord.interviewerName;
          InterviewerRoleController.text = existingRecord.interviewerRole;
          AttitudeController = existingRecord.attitude ? "Yes" : "No";
          ScoutingAccuracyController = existingRecord.scoutingAccuracy;
          NotCooperativeReasonController.text = existingRecord.notCooperativeReason;
          PathDataController = List<Map<String, String?>>.from(
              existingRecord.pathDraw.map((e) => Map<String, String?>.from(e))
          );
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

  @override
  void dispose() {
    _pathSavedTimer?.cancel();
    // ... rest of your existing dispose code
    super.dispose();
  }


  Widget _buildQuestions() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(children: [
          buildTextBoxs(
            "Introductions and Names",
            [
              ScouterList(),
              SizedBox(
                height: 8,
              ),
              Container(
              padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF101010),
            borderRadius: BorderRadius.circular(10),
          ),
            child:
            Column(
              children: [
                Text("Script", textAlign: TextAlign.center,
                      style: GoogleFonts.museoModerno(fontSize: 30, fontWeight: FontWeight.bold,color: Colors.blue)),
                SizedBox(
                  height: 15,
                ),
                Text("Hi! Our names are [Your Name], [Partner Name], and we are from team 201 the FEDS. We just wanted to come by, introduce ourselves, and ask you a few questions about your robot. Could you first tell us your name and role in the team?"
                  ,textAlign: TextAlign.center,
                  style: GoogleFonts.museoModerno(fontSize: 20),
                ),
              ]

            ),

              ),
              buildTextBox(
                  "Interviewer Name",
                  "ex. John",
                  Icon(Icons.badge, size: 30, color: Colors.grey),
                  InterviewerNameController),
              buildTextBox(
                  "Interviewer Role",
                  "ex. Pit Lead",
                  Icon(Icons.handyman, size: 30, color: Colors.grey),
                  InterviewerRoleController),
            ],
            Icon(Icons.badge)
          ),
          buildTextBoxs(
            "Autonomous & Game Data",
            [
              Container(
                width: double.infinity,
                height: 560,
                child: Column(
                  children: [
                    Text("Auton Path", textAlign: TextAlign.center,
                        style: GoogleFonts.museoModerno(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: TextField(
                        controller: PathNameController,
                        decoration: InputDecoration(
                          labelText: "Path Name",
                          hintText: "ex. Left Side Rush",
                          prefixIcon: Icon(Icons.label_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 1600,
                      height: 450,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _pathSaved ? Colors.green : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: BotPathDrawer(
                          config: config,
                          onSave: (String? pathData) {
                            setState(() {
                              PathDataController.add({
                              'name': PathNameController.text,
                              'path': pathData,
                            });
                           _pathSaved = true;
                          });
                             _pathSavedTimer?.cancel();
                             _pathSavedTimer = Timer(const Duration(seconds: 5), () {
                             setState(() => _pathSaved = false);
                               });
                          },
                        ),
                      ),
                    ),

                  ],
                ),
              ),

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
                  weightUnit, (value) {
                setState(() {
                  WeightController = double.tryParse(value) ?? 0.0;
                });
              }, (unit) {
                setState(() {
                  weightUnit = unit;
                });
              }),
              buildNumberWithUnitBox(
                  "Top Speed",
                  SpeedController,
                  Icon(Icons.speed, size: 30, color: Colors.red),
                  ['ft/s', 'm/s', 'mph'],
                  speedUnit, (value) {
                setState(() {
                  SpeedController = double.tryParse(value) ?? 0.0;
                });
              }, (unit) {
                setState(() {
                  speedUnit = unit;
                });
              }),
              buildChoiceBox(
                  "Sealed Hopper?",
                  Icon(Icons.devices_fold,
                      size: 30, color: Colors.purple),
                  ["Yes", "No"],
                  HopperStatusController, (value) {
                setState(() {
                  HopperStatusController = value;
                });
              }),
              buildChoiceBox(
                  "Can go Under Trench?",
                  Icon(Icons.subdirectory_arrow_right,
                      size: 30, color: Colors.blue),
                  ["Always", "Sometimes", "Never"],
                  TrenchController, (value) {
                setState(() {
                  TrenchController = value;
                });
              }),
              buildChoiceBox(
                  "Can go over Bump?",
                  Icon(Icons.upgrade,
                      size: 30, color: Colors.red ),
                  ["Yes", "No"],
                  BumpController, (value) {
                setState(() {
                  BumpController = value;
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
              buildNumberBox("Avg Fuel Per Period", AvgCycleTimeController,
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
                  shootingRateUnit, (value) {
                setState(() {
                  ShootingRateController = double.tryParse(value) ?? 0.0;
                });
              }, (unit) {
                setState(() {
                  shootingRateUnit = unit;
                });
              }),
              buildMultiChoiceBox(
                  "Score Locations",
                  Icon(Icons.star_outline, size: 30, color: Colors.blue),
                  ["Hub", "Feeder"],
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
              buildNumberBox(
                  "Driver # Of Years Driving?",
                  DriverYearController.toDouble(),
                  Icon(Icons.directions_car,
                      size: 30, color: Colors.yellow), (value) {
                setState(() {
                  DriverYearController = int.tryParse(value) ?? 0;
                });
              }),
              buildMultiChoiceBox(
                  "Climb Type",
                  Icon(Icons.elevator,
                      size: 30, color: const Color.fromARGB(255, 200, 186, 34)),
                  ["L1", "L2", "L3"],
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
                  "Frame Perimeter With Bumpers",
                  "ex. 30 x 30",
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

            ],
            Icon(Icons.camera_alt),
          ),
          buildTextBoxs(
            "Final Feedbacks",
            [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF101010),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                Column(
                  children: [
                    Text("Script", textAlign: TextAlign.center,
                        style: GoogleFonts.museoModerno(fontSize: 30, fontWeight: FontWeight.bold,color: Colors.blue)),
                    SizedBox(
                      height: 15,
                    ),
                    Text("Thank you for taking the time to talk with us— We really appreciate it. Our pit is over there(Point to it), so feel free to stop by if you have any questions."

                      ,textAlign: TextAlign.center,
                      style: GoogleFonts.museoModerno(fontSize: 20),
                    ),

                  ],

                ),


              ),
              buildChoiceBox(
                  "Were the Interviewers Cooperative?",
                  Icon(Icons.volunteer_activism,
                      size: 30, color: Colors.pink[300] ),
                  ["Yes", "No"],
                  AttitudeController, (value) {
                setState(() {
                  AttitudeController = value;
                });
              }),
              buildTextBox(
                  "If Team was not Cooperative, Why?",
                  "explain why the team was not cooperative",
                  Icon(Icons.sentiment_dissatisfied, size: 30, color: Colors.red),
                  NotCooperativeReasonController),
              buildChoiceBox(
                  "Is Your data Accurate or is it Wishy Washy/Not sure?",
                  Icon(Icons.question_mark,
                      size: 30, color: Colors.purpleAccent[300] ),
                  ["Accurate", "Wishy Washy"],
                  ScoutingAccuracyController, (value) {
                setState(() {
                  ScoutingAccuracyController = value;
                });
              }),
              SizedBox(height: 20),
              _buildFunButton(),
        ],
            Icon(Icons.list_alt),
          ),
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
    if (clearanceUnit == 'cm')
      storedClearance = GroundClearanceController / 2.54;
    if (clearanceUnit == 'mm')
      storedClearance = GroundClearanceController / 25.4;

    // Convert shooting rate to balls/sec for storage
    double storedShootingRate = ShootingRateController;
    if (shootingRateUnit == 'balls/min')
      storedShootingRate = ShootingRateController / 60.0;

    PitRecord record = PitRecord(
        teamNumber: widget.team.teamNumber,
        scouterName: deviceName,
        eventKey: eventKey,
        driveTrainType: DrivetrainController,
        autonType: AutonController,
        scoreType: ScoreTypeController,
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
        shootingRate: storedShootingRate,
        hopperSealed: HopperStatusController == "Yes",
        trenchUnder: TrenchController,
        bumpOver: BumpController == "Yes",
        driverYear: DriverYearController,
        interviewerName: InterviewerNameController.text,
        interviewerRole: InterviewerRoleController.text,
        attitude: AttitudeController == "Yes",
        scoutingAccuracy: ScoutingAccuracyController,
        notCooperativeReason: NotCooperativeReasonController.text,
        pathDraw: PathDataController);

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
