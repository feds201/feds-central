import 'dart:convert';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/components/CameraComposit.dart';
import 'package:scouting_app/components/TextBox.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';
import 'package:scouting_app/services/DataBase.dart';

class Checklist_record extends StatefulWidget {
  final PitChecklistItem list_item;
  const Checklist_record({super.key, required this.list_item});

  @override
  State<StatefulWidget> createState() => _Checklist_recordState();
}

class _Checklist_recordState extends State<Checklist_record> {
  int _pressCount = 0;
  final int _requiredPresses = 1;

  late ConfettiController _confettiController;

  late String matchkey;

  //drive train
  late bool drive_motors, drive_wheels, drive_gearboxes, drive_wires, drive_steer_motors, drive_encoders, drive_lime_lights, drive_nuts_and_bolts;
  late List<String> drivetrain;

  //structure
  late bool structure_frame, structure_hopper_panels, structure_brain_pan, structure_belly_pan, structure_nuts_and_bolts;
  late List<String> structure;

  //intake
  late bool intake_rack, intake_pinion, intake_belts, intake_rollers, intake_motors, intake_limit_switches, intake_lime_lights, intake_nuts_and_bolts, intake_wires;
  late List<String> intake;

  //spindexer
  late bool spindexer_panel, spindexer_churros, spindexer_motor, spindexer_wheels, spindexer_nuts_and_bolts;
  late List<String> spindexer;

  //kicker
  late bool kicker_plates, kicker_rollers, kicker_belts, kicker_gears, kicker_motor, kicker_radio, kicker_ethernet_switch, kicker_nuts_and_bolts, kicker_wires;
  late List<String> kicker;

  //shooter
  late bool shooter_flywheels, shooter_hood, shooter_hood_gears, shooter_gears, shooter_motors, shooter_nuts_and_bolts, shooter_wires;
  late List<String> shooter;



  late double outgoing_number;
  late double outgoing_battery_voltage;
  late double outgoing_battery_cca;
  late double returning_number;
  late double returning_battery_voltage;
  late double returning_battery_cca;
  late bool returning_battery_replacd;
  late bool outgoing_battery_replaced;

  late String alliance_color;

  late TextEditingController notes;

  late bool isPlayoffMatch;
  late String manualPlayoffMatchType; // "Quarterfinal", "Semifinal", "Final"
  late int manualAllianceNumber;
  late String manualAlliancePosition;

  late String image1;
  late String image2;
  late String image3;
  late String image4;
  late String image5;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    notes = TextEditingController();
    // Initialize with empty values
    matchkey = widget.list_item.matchkey;
    isPlayoffMatch = widget.list_item.matchkey.contains('_qf') ||
        widget.list_item.matchkey.contains('_sf') ||
        widget.list_item.matchkey.contains('_f');

    // If this is a manual playoff entry from TBA with alliance selection data
    if (widget.list_item.alliance_selection_data != null) {
      manualAllianceNumber =
          widget.list_item.alliance_selection_data!['alliance_number'] ?? 1;
      manualAlliancePosition =
          widget.list_item.alliance_selection_data!['position'] ?? 'Captain';

      if (widget.list_item.matchkey.contains('_qf')) {
        manualPlayoffMatchType = "Quarterfinal";
      } else if (widget.list_item.matchkey.contains('_sf')) {
        manualPlayoffMatchType = "Semifinal";
      } else {
        manualPlayoffMatchType = "Final";
      }
    } else {
      manualPlayoffMatchType = "Quarterfinal";
      manualAllianceNumber = 1;
      manualAlliancePosition = "Captain";
    }

    // Set alliance color if passed from the match
    if (widget.list_item.alliance_color.isNotEmpty) {
      alliance_color = widget.list_item.alliance_color;
    }
    alliance_color = "";

    //drive train
    drive_motors = false;
    drive_wheels = false;
    drive_gearboxes = false;
    drive_wires = false;
    drive_encoders = false;
    drive_lime_lights = false;
    drive_nuts_and_bolts = false;
    drive_steer_motors = false;
    drivetrain = [];

    //structure
    structure_frame = false;
    structure_hopper_panels = false;
    structure_brain_pan = false;
    structure_belly_pan = false;
    structure_nuts_and_bolts = false;
    structure = [];

    //intake
    intake_rack = false;
    intake_pinion = false;
    intake_belts = false;
    intake_rollers = false;
    intake_motors = false;
    intake_limit_switches = false;
    intake_lime_lights = false;
    intake_nuts_and_bolts = false;
    intake_wires = false;
    intake = [];

    //spindexer
    spindexer_panel = false;
    spindexer_churros = false;
    spindexer_motor = false;
    spindexer_wheels = false;
    spindexer_nuts_and_bolts = false;
    spindexer = [];

    //kicker
    kicker_plates = false;
    kicker_rollers = false;
    kicker_belts = false;
    kicker_gears = false;
    kicker_motor = false;
    kicker_radio = false;
    kicker_ethernet_switch = false;
    kicker_nuts_and_bolts = false;
    kicker_wires = false;
    kicker = [];

    //shooter
    shooter_flywheels = false;
    shooter_hood = false;
    shooter_hood_gears = false;
    shooter_gears = false;
    shooter_motors = false;
    shooter_nuts_and_bolts = false;
    shooter_wires = false;
    shooter = [];

    returning_battery_voltage = 0;
    returning_battery_cca = 0;
    returning_number = 0;
    outgoing_battery_voltage = 0;
    outgoing_battery_cca = 0;
    outgoing_number = 0;
    returning_battery_replacd = false;
    outgoing_battery_replaced = false;

    image1 = "";
    image2 = "";
    image3 = "";
    image4 = "";
    image5 = "";

    // Load database and try to get existing data for this team
    PitCheckListDatabase.LoadAll();

    try {
      PitChecklistItem? existingRecord =
          PitCheckListDatabase.GetData(widget.list_item.matchkey);
      if (existingRecord != null) {
        // Populate UI state variables with existing data

        setState(() {


          returning_battery_voltage = existingRecord.returning_battery_voltage;
          returning_battery_cca = existingRecord.returning_battery_cca;
          returning_number = existingRecord.returning_number;

          outgoing_battery_voltage = existingRecord.outgoing_battery_voltage;
          outgoing_battery_cca = existingRecord.outgoing_battery_cca;
          outgoing_number = existingRecord.outgoing_number;
          returning_battery_replacd = existingRecord.outgoing_battery_replaced;

          alliance_color = existingRecord.alliance_color;
          image1 = existingRecord.img1;
          image2 = existingRecord.img2;
          image3 = existingRecord.img3;
          image4 = existingRecord.img4;
          image5 = existingRecord.img5;

          //drivetrain
          drive_motors = existingRecord.drive_motors;
          drive_wheels = existingRecord.drive_wheels;
          drive_gearboxes = existingRecord.drive_gearboxes;
          drive_wires = existingRecord.drive_wires;
          drive_lime_lights = existingRecord.drive_lime_lights;
          drive_steer_motors = existingRecord.drive_steer_motors;
          drive_nuts_and_bolts = existingRecord.drive_nuts_and_bolts;
          drive_encoders = existingRecord.drive_encoders;

          //structure
          structure_frame = existingRecord.structure_frame;
          structure_hopper_panels = existingRecord.structure_hopper_panels;
          structure_brain_pan = existingRecord.structure_brain_pan;
          structure_belly_pan = existingRecord.structure_belly_pan;
          structure_nuts_and_bolts = existingRecord.structure_nuts_and_bolts;

          //intake
          intake_rack = existingRecord.intake_rack;
          intake_pinion = existingRecord.intake_pinion;
          intake_belts = existingRecord.intake_belts;
          intake_rollers = existingRecord.intake_roller;
          intake_motors = existingRecord.intake_motors;
          intake_limit_switches = existingRecord.intake_limit_switches;
          intake_lime_lights = existingRecord.intake_lime_lights;
          intake_nuts_and_bolts = existingRecord.intake_nuts_and_bolts;
          intake_wires = existingRecord.intake_wires;

          //spindexer
          spindexer_panel = existingRecord.spindexer_panel;
          spindexer_churros = existingRecord.spindexer_churros;
          spindexer_motor = existingRecord.spindexer_motor;
          spindexer_wheels = existingRecord.spindexer_wheels;
          spindexer_nuts_and_bolts = existingRecord.spindexer_nuts_and_bolts;

          //kicker
          kicker_plates = existingRecord.kicker_plates;
          kicker_rollers = existingRecord.kicker_roller;
          kicker_belts = existingRecord.kicker_belts;
          kicker_gears = existingRecord.kicker_gears;
          kicker_motor = existingRecord.kicker_motor;
          kicker_radio = existingRecord.kicker_radio;
          kicker_ethernet_switch = existingRecord.kicker_ethernet_switch;
          kicker_nuts_and_bolts = existingRecord.kicker_nuts_and_bolts;
          kicker_wires = existingRecord.kicker_wires;

          //shooter
          shooter_flywheels = existingRecord.shooter_flywheels;
          shooter_hood = existingRecord.shooter_hood;
          shooter_hood_gears = existingRecord.shooter_hood_gears;
          shooter_gears = existingRecord.shooter_gears;
          shooter_motors = existingRecord.shooter_motors;
          shooter_nuts_and_bolts = existingRecord.shooter_nuts_and_bolts;
          shooter_wires = existingRecord.shooter_wires;


          notes.text = existingRecord.note;

          // Populate lists from boolean values

          //drivetrain
          drivetrain = [];
          if (drive_motors) drivetrain.add("Drive Motors");
          if (drive_wheels) drivetrain.add("Wheels");
          if (drive_wires) drivetrain.add("Wires");
          if (drive_gearboxes) drivetrain.add("Gearboxes");
          if (drive_steer_motors) drivetrain.add("Steer Motors");
          if (drive_nuts_and_bolts) drivetrain.add("Nuts and Bolts");
          if (drive_lime_lights) drivetrain.add("Lime Lights");
          if (drive_encoders) drivetrain.add("Encoders");

          //structure
          structure = [];
          if (structure_frame) structure.add("Frame");
          if (structure_hopper_panels) structure.add("Hopper Panels");
          if (structure_brain_pan) structure.add("BrainPan");
          if (structure_belly_pan) structure.add("Belly Pan");
          if (structure_nuts_and_bolts) structure.add("Nuts and Bolts");

          //intake
          intake = [];
          if (intake_rack) intake.add("Rack");
          if (intake_pinion) intake.add("Pinion");
          if (intake_belts) intake.add("Belts");
          if (intake_rollers) intake.add("Rollers");
          if (intake_motors) intake.add("Motors");
          if (intake_limit_switches) intake.add("Limit Switches");
          if (intake_lime_lights) intake.add("Lime Lights");
          if (intake_nuts_and_bolts) intake.add("Nuts and Bolts");
          if (intake_wires) intake.add("Wires");

          //spindexer
          spindexer = [];
          if (spindexer_panel) spindexer.add("Panel");
          if (spindexer_churros) spindexer.add("Churros");
          if (spindexer_motor) spindexer.add("Motor");
          if (spindexer_wheels) spindexer.add("Wheels");
          if (spindexer_nuts_and_bolts) spindexer.add("Nuts and Bolts");

          //kicker
          kicker = [];
          if (kicker_plates) kicker.add("Plates");
          if (kicker_rollers) kicker.add("Rollers");
          if (kicker_belts) kicker.add("Belts");
          if (kicker_gears) kicker.add("Gears");
          if (kicker_motor) kicker.add("Motor");
          if (kicker_radio) kicker.add("Radio");
          if (kicker_ethernet_switch) kicker.add("Ethernet Switch");
          if (kicker_nuts_and_bolts) kicker.add("Nuts and Bolts");
          if (kicker_wires) kicker.add("Wires");

          //shooter
          shooter = [];
          if (shooter_flywheels) shooter.add("Flywheels");
          if (shooter_hood) shooter.add("Hood");
          if (shooter_hood_gears) shooter.add("Hood Gears");
          if (shooter_gears) shooter.add("Gears");
          if (shooter_motors) shooter.add("Motors");
          if (shooter_nuts_and_bolts) shooter.add("Nuts and Bolts");
          if (shooter_wires) shooter.add("Wires");

          // Set matchkey from existing record
          matchkey = existingRecord.matchkey;
        });
        print("Loaded existing data for match ${widget.list_item.matchkey}");
      } else {
        print(
            "No existing record found for match ${widget.list_item.matchkey}");
      }
    } catch (e) {
      print("Error retrieving team data: $e");
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return IconButton(
              icon: const Icon(Icons.menu),
              color: !islightmode() ? Colors.transparent : Colors.transparent,
              onPressed: () => {});
        }),
        backgroundColor: islightmode() ? Colors.white : darkColors.goodblack,
        centerTitle: true,
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              widget.list_item.matchkey,
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
      ),
      body: _buildQuestions(),
    );
  }

  Widget _buildQuestions() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(children: [
          // MatchInfo(
          //   assignedTeam: assignedTeam,
          //   assignedStation: assignedStation,
          //   allianceColor: alliance_color,
          //   onPressed: () {
          //     // print('Team Info START button pressed');
          //   },
          // ),
          CameraPhotoCapture(
              title: "Robot Photos",
              description: "Take photos of the robot",
              maxPhotos: 5,
              initialImages: [image1, image2, image3, image4, image5]
                  .where((img) => img.isNotEmpty)
                  .toList(),
              onPhotosTaken: (photos) {
                // Convert all photos to base64 strings
                List<String> base64Images = [];
                for (var photo in photos) {
                  base64Images.add(base64Encode(photo.readAsBytesSync()));
                }

                setState(() {
                  image1 = base64Images[0];
                  image2 = base64Images[1];
                  image3 = base64Images[2];
                  image4 = base64Images[3];
                  image5 = base64Images[4];
                });
              }),
          buildTextBox("Notes", "", Icon(Icons.note), notes),
          buildMultiChoiceBox(
              "DriveTrain",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Wheels",
                "Gearboxes",
                "Steer Motors",
                "Drive Motors",
                "Encoders",
                "Lime Lights",
                "Nuts and Bolts",
                "Wires",
              ],
              drivetrain, (value) {
            setState(() {
              drivetrain = value;
            });
          }),
          buildMultiChoiceBox(
              "Structure",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Frame",
                "Hopper Panels",
                "BrainPan",
                "Belly Pan",
                "Nuts and Bolts",
              ],
              structure, (value) {
            setState(() {
              structure = value;
            });
          }),
          buildMultiChoiceBox(
              "Intake",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Rack",
                "Pinion",
                "Belts",
                "Rollers",
                "Motors",
                "Limit Switches",
                "Lime Lights",
                "Nuts and Bolts",
                "Wires",
              ],
              intake, (value) {
            setState(() {
              intake = value;
            });
          }),
          buildMultiChoiceBox(
              "Spindexer",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Panel",
                "Churros",
                "Motor",
                "Wheels",
                "Nuts and Bolts",
              ],
              spindexer, (value) {
            setState(() {
              spindexer = value;
            });
          }),
          buildMultiChoiceBox(
              "Kicker",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Plates",
                "Rollers",
                "Belts",
                "Gears",
                "Motor",
                "Radio",
                "Ethernet Switch",
                "Nuts and Bolts",
                "Wires",
              ],
              kicker, (value) {
            setState(() {
              kicker = value;
            });
          }),
          buildMultiChoiceBox(
              "Shooter",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Flywheels",
                "Hood",
                "Hood Gears",
                "Gears",
                "Motors",
                "Nuts and Bolts",
                "Wires",
              ],
              shooter, (value) {
            setState(() {
              shooter = value;
            });
          }),
          buildTextBoxs(
              "Outgoing Battery",
              [
                buildNumberBox("Battery Voltage", outgoing_battery_voltage,
                    Icon(Icons.tag), (value) {
                  setState(() {
                    outgoing_battery_voltage = (double.tryParse(value) ?? 0);
                  });
                }),
                buildNumberBox("Battery Tag", outgoing_number, Icon(Icons.tag),
                    (value) {
                  setState(() {
                    outgoing_number = (double.tryParse(value) ?? 0);
                  });
                }),
                buildNumberBox(
                    "Battery CCA", outgoing_battery_cca, Icon(Icons.tag),
                    (value) {
                  setState(() {
                    outgoing_battery_cca = (double.tryParse(value) ?? 0);
                  });
                }),
                buildDualBox(
                    "Battery Status",
                    Icon(Icons.battery_full),
                    ["Good", "Replace"],
                    returning_battery_replacd == true ? "Good" : "Replace",
                    (value) {
                  setState(() {
                    print(value);
                    if (value.isNotEmpty) {
                      returning_battery_replacd = !returning_battery_replacd;
                    }
                  });
                }),
              ],
              Icon(Icons.add_ic_call_outlined)),
          buildTextBoxs(
              "Returning Battery",
              [
                buildNumberBox("Battery Tag", returning_number, Icon(Icons.tag),
                    (value) {
                  setState(() {
                    returning_number = (double.tryParse(value) ?? 0);
                  });
                }),
                buildNumberBox("Battery Voltage", returning_battery_voltage,
                    Icon(Icons.tag), (value) {
                  setState(() {
                    returning_battery_voltage = (double.tryParse(value) ?? 0);
                  });
                }),
                buildNumberBox(
                    "Battery CCA", returning_battery_cca, Icon(Icons.tag),
                    (value) {
                  setState(() {
                    returning_battery_cca = (double.tryParse(value) ?? 0);
                  });
                })
              ],
              Icon(Icons.add_ic_call_outlined)),
          buildTextBox("Notes", "", Icon(Icons.note), notes),
          const SizedBox(height: 20),
          _buildFunButton(),
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
    PitChecklistItem record = PitChecklistItem(

      matchkey: matchkey,

      returning_battery_voltage: returning_battery_voltage,
      returning_battery_cca: returning_battery_cca,
      returning_number: returning_number,
      outgoing_battery_voltage: outgoing_battery_voltage,
      outgoing_battery_cca: outgoing_battery_cca,
      outgoing_number: outgoing_number,
      outgoing_battery_replaced: outgoing_battery_replaced,
      //drivetrain
      drive_motors: drivetrain.contains("Drive Motors"),
      drive_wheels: drivetrain.contains("Wheels"),
      drive_gearboxes: drivetrain.contains("Gearboxes"),
      drive_wires: drivetrain.contains("Wires"),
      drive_lime_lights: drivetrain.contains("Lime Lights"),
      drive_steer_motors: drivetrain.contains("Steer Motors"),
      drive_nuts_and_bolts: drivetrain.contains("Nuts and Bolts"),
      drive_encoders: drivetrain.contains("Encoders"),
      //structure
      structure_frame: structure.contains("Frame"),
      structure_hopper_panels: structure.contains("Hopper Panels"),
      structure_brain_pan: structure.contains("BrainPan"),
      structure_belly_pan: structure.contains("Belly Pan"),
      structure_nuts_and_bolts: structure.contains("Nuts and Bolts"),
      //intake
      intake_rack: intake.contains("Rack"),
      intake_pinion: intake.contains("Pinion"),
      intake_belts: intake.contains("Belts"),
      intake_roller: intake.contains("Rollers"),
      intake_motors: intake.contains("Motors"),
      intake_limit_switches: intake.contains("Limit Switches"),
      intake_lime_lights: intake.contains("Lime Lights"),
      intake_nuts_and_bolts: intake.contains("Nuts and Bolts"),
      intake_wires: intake.contains("Wires"),
      //spindexer
      spindexer_panel: spindexer.contains("Panel"),
      spindexer_churros: spindexer.contains("Churros"),
      spindexer_motor: spindexer.contains("Motor"),
      spindexer_wheels: spindexer.contains("Wheels"),
      spindexer_nuts_and_bolts: spindexer.contains("Nuts and Bolts"),
      //kicker
      kicker_plates: kicker.contains("Plates"),
      kicker_roller: kicker.contains("Rollers"),
      kicker_belts: kicker.contains("Belts"),
      kicker_gears: kicker.contains("Gears"),
      kicker_motor: kicker.contains("Motor"),
      kicker_radio: kicker.contains("Radio"),
      kicker_ethernet_switch: kicker.contains("Ethernet Switch"),
      kicker_nuts_and_bolts: kicker.contains("Nuts and Bolts"),
      kicker_wires: kicker.contains("Wires"),
      //shooter
      shooter_flywheels: shooter.contains("Flywheels"),
      shooter_hood: shooter.contains("Hood"),
      shooter_hood_gears: shooter.contains("Hood Gears"),
      shooter_gears: shooter.contains("Gears"),
      shooter_motors: shooter.contains("Motors"),
      shooter_nuts_and_bolts: shooter.contains("Nuts and Bolts"),
      shooter_wires: shooter.contains("Wires"),

      alliance_color: alliance_color,
      note: notes.text,
      img1: image1,
      img2: image2,
      img3: image3,
      img4: image4,
      img5: image5,
    );

    print('Recording data: $record');
    print("Hiv ${record.toJson()}");
    print(widget.list_item.matchkey.toString());
    print("Data recorded for match key: ${record.matchkey}");
    developer.log(record.toJson().toString());

    PitCheckListDatabase.PutData(widget.list_item.matchkey, record);
    PitCheckListDatabase.SaveAll();
    PitCheckListDatabase.PrintAll();
  }

  void PopBoard(BuildContext context) {
    Navigator.pop(context);
  }
}
