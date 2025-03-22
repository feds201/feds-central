import 'dart:convert';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/CameraComposit.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/services/DataBase.dart';
import 'package:scouting_app/components/TextBox.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

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

  late int matchNumber;

  late bool chassis_drive_motors;
  late bool chassis_steer_motors;
  late bool chassis_gearboxes;
  late bool chassis_tread_conditions;
  late bool chassis_wires;
  late bool chassis_bumpers;
  late bool chassis_limelight_protectors;
  late List<String> chassis;

  late bool ethernet_front_left_limelight;
  late bool ethernet_front_right_limlight;
  late bool ethernet_back_right_limlight;
  late bool ethernet_back_left_limlight;
  late bool ethernet_swtich;
  late bool ethernet_radio;
  late List<String> ethernet;

  late bool climber_w_shape;
  late bool climber_w_clips;
  late bool climber_surgical_tubing;
  late bool climber_string;
  late bool climber_springs;
  late bool climber_gearbox;
  late bool climber_motors;
  late bool climber_wires;
  late bool climber_nuts_and_bolts;
  late bool climber_reset;
  late List<String> climber;

  late bool elevator_rod_of_doom;
  late bool elevator_stage_0;
  late bool elevator_stage_1;
  late bool elevator_stage_2;
  late bool elevator_chain;
  late bool elevator_string;
  late bool elevator_gearbox;
  late bool elevator_motors;
  late bool elevator_wires;
  late bool elevator_nuts_and_bolts;
  late List<String> elevator;

  late bool trapdoor_panels;
  late bool trapdoor_supports;
  late bool trapdoor_hinges;
  late bool trapdoor_release;
  late bool trapdoor_tensioners;
  late bool trapdoor_nuts_and_bolts;
  late bool trapdoor_reset;
  late List<String> trapdoor;

  late bool carriage_gearbox;
  late bool carriage_beltbox;
  late bool carriage_motors;
  late bool carriage_wires;
  late bool carriage_nuts_and_bolts;
  late bool carriage_coral_slide;
  late bool carriage_carriage;
  late List<String> carriage;

  late bool gooseneck_panels;
  late bool gooseneck_wheels;
  late bool gooseneck_belts;
  late bool gooseneck_surgical_tubing;
  late bool gooseneck_nuts_and_bolts;
  late List<String> gooseneck;

  late double returning_battery_voltage;
  late double returning_battery_cca;
  late double returning_number;
  late double outgoing_battery_voltage;
  late double outgoing_battery_cca;
  late double outgoing_number;
  late bool outgoing_battery_replacd;

  late String alliance_color;
  late String image;
  late TextEditingController notes;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    image = "";
    notes = TextEditingController();
    // Initialize with empty values
    matchNumber = 0;
    chassis_drive_motors = false;
    chassis_steer_motors = false;
    chassis_gearboxes = false;
    chassis_tread_conditions = false;
    chassis_wires = false;
    chassis_bumpers = false;
    chassis_limelight_protectors = false;
    chassis = [];

    alliance_color = "";

    climber_w_shape = false;
    climber_w_clips = false;
    climber_surgical_tubing = false;
    climber_string = false;
    climber_springs = false;
    climber_gearbox = false;
    climber_motors = false;
    climber_wires = false;
    climber_nuts_and_bolts = false;
    climber_reset = false;
    climber = [];

    ethernet_front_left_limelight = false;
    ethernet_front_right_limlight = false;
    ethernet_back_right_limlight = false;
    ethernet_back_left_limlight = false;
    ethernet_swtich = false;
    ethernet_radio = false;
    ethernet = [];

    elevator_rod_of_doom = false;
    elevator_stage_0 = false;
    elevator_stage_1 = false;
    elevator_stage_2 = false;
    elevator_chain = false;
    elevator_string = false;
    elevator_gearbox = false;
    elevator_motors = false;
    elevator_wires = false;
    elevator_nuts_and_bolts = false;
    elevator = [];

    trapdoor_panels = false;
    trapdoor_supports = false;
    trapdoor_hinges = false;
    trapdoor_release = false;
    trapdoor_tensioners = false;
    trapdoor_nuts_and_bolts = false;
    trapdoor_reset = false;
    trapdoor = [];

    carriage_gearbox = false;
    carriage_beltbox = false;
    carriage_motors = false;
    carriage_wires = false;
    carriage_nuts_and_bolts = false;
    carriage_coral_slide = false;
    carriage_carriage = false;
    carriage = [];

    gooseneck_panels = false;
    gooseneck_wheels = false;
    gooseneck_belts = false;
    gooseneck_surgical_tubing = false;
    gooseneck_nuts_and_bolts = false;
    gooseneck = [];

    returning_battery_voltage = 0;
    returning_battery_cca = 0;
    returning_number = 0;
    outgoing_battery_voltage = 0;
    outgoing_battery_cca = 0;
    outgoing_number = 0;
    outgoing_battery_replacd = false;

    // Load database and try to get existing data for this team
    PitCheckListDatabase.LoadAll();
    try {
      PitChecklistItem? existingRecord =
          PitCheckListDatabase.GetData(widget.list_item.matchNumber);
      if (existingRecord != null) {
        // Populate UI state variables with existing data
        setState(() {
          chassis_drive_motors = existingRecord.chassis_drive_motors;
          chassis_steer_motors = existingRecord.chassis_steer_motors;
          chassis_gearboxes = existingRecord.chassis_gearboxes;
          chassis_tread_conditions = existingRecord.chassis_tread_conditions;
          chassis_wires = existingRecord.chassis_wires;
          chassis_bumpers = existingRecord.chassis_bumpers;
          chassis_limelight_protectors =
              existingRecord.chassis_limelight_protectors;

          ethernet_front_left_limelight =
              existingRecord.ethernet_front_left_limelight;
          ethernet_front_right_limlight =
              existingRecord.ethernet_front_right_limlight;
          ethernet_back_right_limlight =
              existingRecord.ethernet_back_right_limlight;
          ethernet_back_left_limlight =
              existingRecord.ethernet_back_left_limlight;
          ethernet_swtich = existingRecord.ethernet_swtich;
          ethernet_radio = existingRecord.ethernet_radio;

          climber_w_shape = existingRecord.climber_w_shape;
          climber_w_clips = existingRecord.climber_w_clips;
          climber_surgical_tubing = existingRecord.climber_surgical_tubing;
          climber_string = existingRecord.climber_string;
          climber_springs = existingRecord.climber_springs;
          climber_gearbox = existingRecord.climber_gearbox;
          climber_motors = existingRecord.climber_motors;
          climber_wires = existingRecord.climber_wires;
          climber_nuts_and_bolts = existingRecord.climber_nuts_and_bolts;
          climber_reset = existingRecord.climber_reset;

          elevator_rod_of_doom = existingRecord.elevator_rod_of_doom;
          elevator_stage_0 = existingRecord.elevator_stage_0;
          elevator_stage_1 = existingRecord.elevator_stage_1;
          elevator_stage_2 = existingRecord.elevator_stage_2;
          elevator_chain = existingRecord.elevator_chain;
          elevator_string = existingRecord.elevator_string;
          elevator_gearbox = existingRecord.elevator_gearbox;
          elevator_motors = existingRecord.elevator_motors;
          elevator_wires = existingRecord.elevator_wires;
          elevator_nuts_and_bolts = existingRecord.elevator_nuts_and_bolts;

          trapdoor_panels = existingRecord.trapdoor_panels;
          trapdoor_supports = existingRecord.trapdoor_supports;
          trapdoor_hinges = existingRecord.trapdoor_hinges;
          trapdoor_release = existingRecord.trapdoor_release;
          trapdoor_tensioners = existingRecord.trapdoor_tensioners;
          trapdoor_nuts_and_bolts = existingRecord.trapdoor_nuts_and_bolts;
          trapdoor_reset = existingRecord.trapdoor_reset;

          carriage_gearbox = existingRecord.carriage_gearbox;
          carriage_beltbox = existingRecord.carriage_beltbox;
          carriage_motors = existingRecord.carriage_motors;
          carriage_wires = existingRecord.carriage_wires;
          carriage_nuts_and_bolts = existingRecord.carriage_nuts_and_bolts;
          carriage_coral_slide = existingRecord.carriage_coral_slide;
          carriage_carriage = existingRecord.carriage_carriage;

          gooseneck_panels = existingRecord.gooseneck_panels;
          gooseneck_wheels = existingRecord.gooseneck_wheels;
          gooseneck_belts = existingRecord.gooseneck_belts;
          gooseneck_surgical_tubing = existingRecord.gooseneck_surgical_tubing;
          gooseneck_nuts_and_bolts = existingRecord.gooseneck_nuts_and_bolts;

          returning_battery_voltage = existingRecord.returning_battery_voltage;
          returning_battery_cca = existingRecord.returning_battery_cca;
          returning_number = existingRecord.returning_number;

          outgoing_battery_voltage = existingRecord.outgoing_battery_voltage;
          outgoing_battery_cca = existingRecord.outgoing_battery_cca;
          outgoing_number = existingRecord.outgoing_number;
          outgoing_battery_replacd = existingRecord.outgoing_battery_replacd;

          alliance_color = existingRecord.alliance_color;
          image = existingRecord.broken_part_image;
          notes.text = existingRecord.note;

          // Populate lists from boolean values
          // Chassis list
          chassis = [];
          if (chassis_drive_motors) chassis.add("Drive motors");
          if (chassis_steer_motors) chassis.add("Steer motors");
          if (chassis_gearboxes) chassis.add("Gearboxes");
          if (chassis_tread_conditions) chassis.add("Tread condition");
          if (chassis_wires) chassis.add("Wires");
          if (chassis_bumpers) chassis.add("Bumpers");
          if (chassis_limelight_protectors) chassis.add("LL Protectors");

          // Ethernet list
          ethernet = [];
          if (ethernet_front_left_limelight) ethernet.add("FL Limelight");
          if (ethernet_front_right_limlight) ethernet.add("FR Limelight");
          if (ethernet_back_left_limlight) ethernet.add("BL Limelight");
          if (ethernet_back_right_limlight) ethernet.add("BR Limelight");
          if (ethernet_swtich) ethernet.add("Ethernet Switch");
          if (ethernet_radio) ethernet.add("Radio");

          // Climber list
          climber = [];
          if (climber_w_shape) climber.add("W Shape");
          if (climber_w_clips) climber.add("W Clips");
          if (climber_surgical_tubing) climber.add("Surgical Tubing");
          if (climber_string) climber.add("String");
          if (climber_springs) climber.add("Springs");
          if (climber_gearbox) climber.add("Gearbox");
          if (climber_motors) climber.add("Motors");
          if (climber_wires) climber.add("Wires");
          if (climber_nuts_and_bolts) climber.add("Nuts and Bolts");
          if (climber_reset) climber.add("Reset");

          // Elevator list
          elevator = [];
          if (elevator_rod_of_doom) elevator.add("Rod of Doom");
          if (elevator_stage_0) elevator.add("Stage 0");
          if (elevator_stage_1) elevator.add("Stage 1");
          if (elevator_stage_2) elevator.add("Stage 2");
          if (elevator_chain) elevator.add("Chain");
          if (elevator_string) elevator.add("String");
          if (elevator_gearbox) elevator.add("Gearbox");
          if (elevator_motors) elevator.add("Motors");
          if (elevator_wires) elevator.add("Wires");
          if (elevator_nuts_and_bolts) elevator.add("Nuts and Bolts");

          // Trapdoor list
          trapdoor = [];
          if (trapdoor_panels) trapdoor.add("Panels");
          if (trapdoor_supports) trapdoor.add("Supports");
          if (trapdoor_hinges) trapdoor.add("Hinges");
          if (trapdoor_release) trapdoor.add("Release");
          if (trapdoor_tensioners) trapdoor.add("Tensioners");
          if (trapdoor_nuts_and_bolts) trapdoor.add("Nuts and Bolts");
          if (trapdoor_reset) trapdoor.add("Reset");

          // Carriage list
          carriage = [];
          if (carriage_gearbox) carriage.add("Gearbox");
          if (carriage_beltbox) carriage.add("Beatbox");
          if (carriage_motors) carriage.add("Motors");
          if (carriage_wires) carriage.add("Wires");
          if (carriage_nuts_and_bolts) carriage.add("Nuts and Bolts");
          if (carriage_coral_slide) carriage.add("Coral Slide");
          if (carriage_carriage) carriage.add("Carriage");

          // Gooseneck list
          gooseneck = [];
          if (gooseneck_panels) gooseneck.add("Panels");
          if (gooseneck_wheels) gooseneck.add("Wheels");
          if (gooseneck_belts) gooseneck.add("Belts");
          if (gooseneck_surgical_tubing) gooseneck.add("Surgical Tubing");
          if (gooseneck_nuts_and_bolts) gooseneck.add("Nuts and Bolts");

          // Set matchNumber from existing record
          matchNumber = existingRecord.matchNumber;
        });
        print("Loaded existing data for match ${widget.list_item.matchNumber}");
      } else {
        print(
            "No existing record found for match ${widget.list_item.matchNumber}");
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
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              widget.list_item.matchNumber.toString(),
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
            "General Questions",
            [
              buildChoiceBox(
                  "What alliance is your robot?",
                  Icon(Icons.car_crash_outlined,
                      size: 30, color: Colors.purple),
                  ["Blue Alliance", "Red Alliance"],
                  alliance_color, (value) {
                setState(() {
                  alliance_color = value;
                });
              }),
            ],
            Icon(Icons.question_answer),
          ),
          buildMultiChoiceBox(
              "Chassis",
              Icon(Icons.mood_rounded, size: 30, color: Colors.blue),
              [
                "Drive motors",
                "Steer motors",
                "Gearboxes",
                "Tread condition",
                "Wires",
                "Bumpers",
                "LL Protectors"
              ],
              chassis, (value) {
            setState(() {
              chassis = value;
            });
          }),
          buildMultiChoiceBox(
              "Ethernet",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "FL Limelight",
                "FR Limelight",
                "BL Limelight",
                "BR Limelight",
                "Ethernet Switch",
                "Radio",
              ],
              ethernet, (value) {
            setState(() {
              ethernet = value;
            });
          }),
          buildMultiChoiceBox(
              "Climber",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "W Shape",
                "W Clips",
                "Surgical Tubing",
                "String",
                "Springs",
                "Gearbox",
                "Motors",
                "Wires",
                "Nuts and Bolts",
                "Reset",
              ],
              climber, (value) {
            setState(() {
              climber = value;
            });
          }),
          buildMultiChoiceBox(
              "Elevator",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Rod of Doom",
                "Stage 0",
                "Stage 1",
                "Stage 2",
                "Chain",
                "String",
                "Gearbox",
                "Motors",
                "Wires",
                "Nuts and Bolts",
              ],
              elevator, (value) {
            setState(() {
              elevator = value;
            });
          }),
          buildMultiChoiceBox(
              "Trapdoor",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Panels",
                "Supports",
                "Hinges",
                "Release",
                "Tensioners",
                "Nuts and Bolts",
                "Reset",
              ],
              trapdoor, (value) {
            setState(() {
              trapdoor = value;
            });
          }),
          buildMultiChoiceBox(
              "Carriage",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Gearbox",
                "Beatbox",
                "Motors",
                "Wires",
                "Nuts and Bolts",
                "Coral Slide",
              ],
              carriage, (value) {
            setState(() {
              carriage = value;
            });
          }),
          buildMultiChoiceBox(
              "Gooseneck",
              Icon(Icons.star_outline, size: 30, color: Colors.blue),
              [
                "Panels",
                "Wheels",
                "Motors",
                "Belts",
                "Nuts and Bolts",
                "Surgical Tubing",
              ],
              gooseneck, (value) {
            setState(() {
              gooseneck = value;
            });
          }),
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
          buildTextBoxs(
              "Ongoing Battery",
              [
                buildNumberBox("Battery Tag", outgoing_number, Icon(Icons.tag),
                    (value) {
                  setState(() {
                    outgoing_number = (double.tryParse(value) ?? 0);
                  });
                }),
                buildNumberBox("Battery Voltage", outgoing_battery_voltage,
                    Icon(Icons.tag), (value) {
                  setState(() {
                    outgoing_battery_voltage = (double.tryParse(value) ?? 0);
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
                    outgoing_battery_replacd == true ? "Replace" : "Good",
                    (value) {
                  setState(() {
                    if (value.isNotEmpty) {
                      outgoing_battery_replacd =
                          value == "Replace" ? true : false;
                    }
                  });
                }),
              ],
              Icon(Icons.add_ic_call_outlined)),
          buildTextBox("Notes", "", Icon(Icons.note), notes),
          CameraPhotoCapture(onPhotoTaken: (photo) {
            print('Photo captured: $photo');
            // Convert the captured photo to base64
            image = base64Encode(photo.readAsBytesSync());
            developer.log(image);
          }),
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
      matchNumber: matchNumber,
      chassis_drive_motors: chassis.contains("Drive motors"),
      chassis_steer_motors: chassis.contains("Steer motors"),
      chassis_gearboxes: chassis.contains("Gearboxes"),
      chassis_tread_conditions: chassis.contains("Tread condition"),
      chassis_wires: chassis.contains("Wires"),
      chassis_bumpers: chassis.contains("Bumpers"),
      chassis_limelight_protectors: chassis.contains("LL Protectors"),
      ethernet_front_left_limelight: ethernet.contains("FL Limelight"),
      ethernet_front_right_limlight: ethernet.contains("FR Limelight"),
      ethernet_back_right_limlight: ethernet.contains("BR Limelight"),
      ethernet_back_left_limlight: ethernet.contains("BL Limelight"),
      ethernet_swtich: ethernet.contains("Ethernet Switch"),
      ethernet_radio: ethernet.contains("Radio"),
      climber_w_shape: climber.contains("W Shape"),
      climber_w_clips: climber.contains("W Clips"),
      climber_surgical_tubing: climber.contains("Surgical Tubing"),
      climber_string: climber.contains("String"),
      climber_springs: climber.contains("Springs"),
      climber_gearbox: climber.contains("Gearbox"),
      climber_motors: climber.contains("Motors"),
      climber_wires: climber.contains("Wires"),
      climber_nuts_and_bolts: climber.contains("Nuts and Bolts"),
      climber_reset: climber.contains("Reset"),
      elevator_rod_of_doom: elevator.contains("Rod of Doom"),
      elevator_stage_0: elevator.contains("Stage 0"),
      elevator_stage_1: elevator.contains("Stage 1"),
      elevator_stage_2: elevator.contains("Stage 2"),
      elevator_chain: elevator.contains("Chain"),
      elevator_string: elevator.contains("String"),
      elevator_gearbox: elevator.contains("Gearbox"),
      elevator_motors: elevator.contains("Motors"),
      elevator_wires: elevator.contains("Wires"),
      elevator_nuts_and_bolts: elevator.contains("Nuts and Bolts"),
      trapdoor_panels: trapdoor.contains("Panels"),
      trapdoor_supports: trapdoor.contains("Supports"),
      trapdoor_hinges: trapdoor.contains("Hinges"),
      trapdoor_release: trapdoor.contains("Release"),
      trapdoor_tensioners: trapdoor.contains("Tensioners"),
      trapdoor_nuts_and_bolts: trapdoor.contains("Nuts and Bolts"),
      trapdoor_reset: trapdoor.contains("Reset"),
      carriage_gearbox: carriage.contains("Gearbox"),
      carriage_beltbox: carriage.contains("Beatbox"),
      carriage_motors: carriage.contains("Motors"),
      carriage_wires: carriage.contains("Wires"),
      carriage_nuts_and_bolts: carriage.contains("Nuts and Bolts"),
      carriage_coral_slide: carriage.contains("Coral Slide"),
      carriage_carriage: carriage.contains("Carriage"),
      gooseneck_panels: gooseneck.contains("Panels"),
      gooseneck_wheels: gooseneck.contains("Wheels"),
      gooseneck_belts: gooseneck.contains("Belts"),
      gooseneck_surgical_tubing: gooseneck.contains("Surgical Tubing"),
      gooseneck_nuts_and_bolts: gooseneck.contains("Nuts and Bolts"),
      returning_battery_voltage: returning_battery_voltage,
      returning_battery_cca: returning_battery_cca,
      returning_number: returning_number,
      outgoing_battery_voltage: outgoing_battery_voltage,
      outgoing_battery_cca: outgoing_battery_cca,
      outgoing_number: outgoing_number,
      outgoing_battery_replacd: outgoing_battery_replacd,
      broken_part_image: image,
      alliance_color: alliance_color,
      note: notes.text,
    );

    print('Recording data: $record');
    print("Hiv ${record.toJson()}");
    print(widget.list_item.matchNumber.toString());
    print("Data recorded for match number: ${record.matchNumber}");

    PitCheckListDatabase.PutData(widget.list_item.matchNumber, record);
    PitCheckListDatabase.SaveAll();

    PitCheckListDatabase.PrintAll();
  }

  void PopBoard(BuildContext context) {
    Navigator.pop(context);
  }
}
