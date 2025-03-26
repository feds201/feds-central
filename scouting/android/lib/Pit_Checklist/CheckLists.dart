import 'dart:convert';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scouting_app/components/CameraComposit.dart';
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

  late String matchkey;

  late bool chassis_drive_motors;
  late bool chassis_steer_motors;
  late bool chassis_gearboxes;
  late bool chassis_tread_conditions;
  late bool chassis_wires;
  late bool chassis_bumpers;
  late bool chassis_limelight_protectors;
  late List<String> chassis;

  late bool ethernet_front_left_limelight;
  late bool ethernet_front_right_limelight;
  late bool ethernet_back_left_limelight;
  late bool ethernet_switch;
  late bool ethernet_radio;
  late List<String> ethernet;

  late bool climber_number;
  late bool climber_clips;
  late bool climber_string;
  late bool climber_springs;
  late bool climber_hooks;
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
  late bool elevator_belts;
  late bool elevator_gearbox;
  late bool elevator_motors;
  late bool elevator_wires;
  late bool elevator_nuts_and_bolts;
  late List<String> elevator;

  late bool trapdoor_panels;
  late bool trapdoor_supports;
  late bool trapdoor_hinges;
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
  late bool gooseneck_gears;
  late bool gooseneck_nuts_and_bolts;
  late List<String> gooseneck;

  late double outgoing_number;
  late double outgoing_battery_voltage;
  late double outgoing_battery_cca;
  late double returning_number;
  late double returning_battery_voltage;
  late double returning_battery_cca;
  late bool returning_battery_replacd;

  late String alliance_color;
  late String image;
  List<String> images =
      []; // New list to store multiple images as base64 strings
  late TextEditingController notes;

  late bool isPlayoffMatch;
  late String manualPlayoffMatchType; // "Quarterfinal", "Semifinal", "Final"
  late int manualAllianceNumber;
  late String manualAlliancePosition;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    image = "";
    images = []; // Initialize empty list for multiple images
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

    chassis_drive_motors = false;
    chassis_steer_motors = false;
    chassis_gearboxes = false;
    chassis_tread_conditions = false;
    chassis_wires = false;
    chassis_bumpers = false;
    chassis_limelight_protectors = false;
    chassis = [];

    alliance_color = "";

    climber_number = false;
    climber_clips = false;
    climber_hooks = false;
    climber_string = false;
    climber_springs = false;
    climber_gearbox = false;
    climber_motors = false;
    climber_wires = false;
    climber_nuts_and_bolts = false;
    climber_reset = false;
    climber = [];

    ethernet_front_left_limelight = false;
    ethernet_front_right_limelight = false;
    ethernet_switch = false;
    ethernet_radio = false;
    ethernet = [];

    elevator_rod_of_doom = false;
    elevator_stage_0 = false;
    elevator_stage_1 = false;
    elevator_stage_2 = false;
    elevator_chain = false;
    elevator_belts = false;
    elevator_gearbox = false;
    elevator_motors = false;
    elevator_wires = false;
    elevator_nuts_and_bolts = false;
    elevator_belts = false;

    elevator = [];

    trapdoor_panels = false;
    trapdoor_supports = false;
    trapdoor_hinges = false;
    trapdoor_tensioners = false;
    trapdoor_nuts_and_bolts = false;
    trapdoor_reset = false;
    trapdoor = [];

    carriage_carriage = false;
    carriage_gearbox = false;
    carriage_beltbox = false;
    carriage_motors = false;
    carriage_coral_slide = false;
    carriage_wires = false;
    carriage_nuts_and_bolts = false;
    carriage = [];

    gooseneck_panels = false;
    gooseneck_wheels = false;
    gooseneck_belts = false;
    gooseneck_nuts_and_bolts = false;
    gooseneck_gears = false;
    gooseneck = [];

    returning_battery_voltage = 0;
    returning_battery_cca = 0;
    returning_number = 0;
    outgoing_battery_voltage = 0;
    outgoing_battery_cca = 0;
    outgoing_number = 0;
    returning_battery_replacd = false;

    // Load database and try to get existing data for this team
    PitCheckListDatabase.LoadAll();

    try {
      PitChecklistItem? existingRecord =
          PitCheckListDatabase.GetData(widget.list_item.matchkey);
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
          ethernet_front_right_limelight =
              existingRecord.ethernet_front_right_limlight;
          ethernet_switch = existingRecord.ethernet_swtich;
          ethernet_radio = existingRecord.ethernet_radio;

          climber_number = existingRecord.climber_number;
          climber_clips = existingRecord.climber_clips;
          climber_string = existingRecord.climber_string;
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
          elevator_gearbox = existingRecord.elevator_gearbox;
          elevator_motors = existingRecord.elevator_motors;
          elevator_wires = existingRecord.elevator_wires;
          elevator_nuts_and_bolts = existingRecord.elevator_nuts_and_bolts;
          elevator_belts = existingRecord.elevator_belts;

          trapdoor_panels = existingRecord.trapdoor_panels;
          trapdoor_supports = existingRecord.trapdoor_supports;
          trapdoor_hinges = existingRecord.trapdoor_hinges;
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
          gooseneck_nuts_and_bolts = existingRecord.gooseneck_nuts_and_bolts;
          gooseneck_gears = existingRecord.gooseneck_gears;

          returning_battery_voltage = existingRecord.returning_battery_voltage;
          returning_battery_cca = existingRecord.returning_battery_cca;
          returning_number = existingRecord.returning_number;

          outgoing_battery_voltage = existingRecord.outgoing_battery_voltage;
          outgoing_battery_cca = existingRecord.outgoing_battery_cca;
          outgoing_number = existingRecord.outgoing_number;
          returning_battery_replacd = existingRecord.outgoing_battery_replacd;

          alliance_color = existingRecord.alliance_color;
          image = existingRecord.broken_part_image;
          // Handle loading multiple images if they exist
          if (existingRecord.broken_part_images != null &&
              existingRecord.broken_part_images!.isNotEmpty) {
            images = existingRecord.broken_part_images!;
          } else if (image.isNotEmpty) {
            // For backward compatibility, add the single image to the images list
            images = [image];
          }
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
          if (ethernet_front_right_limelight) ethernet.add("FR Limelight");
          if (ethernet_switch) ethernet.add("Ethernet Switch");
          if (ethernet_radio) ethernet.add("Radio");

          // Climber list
          climber = [];

          if (climber_string) climber.add("Number");
          if (climber_string) climber.add("Clips");
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
          if (elevator_belts) elevator.add("Belts");
          if (elevator_gearbox) elevator.add("Gearbox");
          if (elevator_motors) elevator.add("Motors");
          if (elevator_wires) elevator.add("Wires");
          if (elevator_nuts_and_bolts) elevator.add("Nuts and Bolts");

          // Trapdoor list
          trapdoor = [];
          if (trapdoor_panels) trapdoor.add("Panels");
          if (trapdoor_supports) trapdoor.add("Supports");
          if (trapdoor_hinges) trapdoor.add("Hinges");
          if (trapdoor_wires) climber.add("Wires");
          if (trapdoor_tensioners) trapdoor.add("Tensioners");
          if (trapdoor_nuts_and_bolts) trapdoor.add("Nuts and Bolts");
          if (trapdoor_reset) trapdoor.add("Reset");

          // Carriage list
          carriage = [];
          if (carriage_gearbox) carriage.add("Gearbox");
          if (carriage_beltbox) carriage.add("Beltbox");
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
          if (gooseneck_gears) gooseneck.add("Gears");
          if (gooseneck_nuts_and_bolts) gooseneck.add("Nuts and Bolts");

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

  // Add a method to convert base64 strings to File objects
  Future<List<File>> _getImagesFromBase64Strings(
      List<String> base64Images) async {
    List<File> imageFiles = [];
    final tempDir = await Directory.systemTemp.createTemp('images');

    for (int i = 0; i < base64Images.length; i++) {
      if (base64Images[i].isEmpty) continue;

      try {
        final bytes = base64Decode(base64Images[i]);
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
              widget.list_item.matchkey,
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
                "Number",
                "Clips",
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
                "Belts",
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
                "Tensioners",
                "Wires",
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
                "Carriage",
                "Gearbox",
                "Beltbox",
                "Motors",
                "Coral Slide",
                "Wires",
                "Nuts and Bolts",
                "Reset"
                
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
                "Belts",
                "Gears",
                "Wires",
                "Nuts and Bolts",
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
                    outgoing_battery_replacd == true ? "Good" : "Replace",
                    (value) {
                  setState(() {
                    print(value);
                    if (value.isNotEmpty) {
                      outgoing_battery_replacd = !outgoing_battery_replacd;
                    }
                  });
                }),
              ],
              Icon(Icons.add_ic_call_outlined)),
          buildTextBox("Notes", "", Icon(Icons.note), notes),

          // Use FutureBuilder to load previously saved images
          FutureBuilder<List<File>>(
            future: _getImagesFromBase64Strings(images),
            builder: (context, snapshot) {
              List<File> existingFiles = snapshot.data ?? [];

              return CameraPhotoCapture(
                title: "Robot Images",
                description: "Take photos of robot issues",
                maxPhotos: 5, // Allow up to 5 photos
                initialImages: existingFiles.isNotEmpty ? existingFiles : [], // Ensure it's a valid list
                onPhotosTaken: (photos) {
                  // Convert all photos to base64 strings and store them
                  List<String> base64Images = [];
                  for (var photo in photos) {
                    base64Images.add(base64Encode(photo.readAsBytesSync()));
                  }

                  setState(() {
                    images = base64Images;
                    // For backward compatibility, update the single image variable with the latest photo
                    image = base64Images.isNotEmpty ? base64Images.last : "";
                  });

                  print('Photos captured: ${photos.length}');
                },
              );
            },
          ),

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
      chassis_drive_motors: chassis.contains("Drive motors"),
      chassis_steer_motors: chassis.contains("Steer motors"),
      chassis_gearboxes: chassis.contains("Gearboxes"),
      chassis_tread_conditions: chassis.contains("Tread condition"),
      chassis_wires: chassis.contains("Wires"),
      chassis_bumpers: chassis.contains("Bumpers"),
      chassis_limelight_protectors: chassis.contains("LL Protectors"),
      ethernet_front_left_limelight: ethernet.contains("FL Limelight"),
      ethernet_front_right_limlight: ethernet.contains("FR Limelight")
      ethernet_switch: ethernet.contains("Ethernet Switch"),
      ethernet_radio: ethernet.contains("Radio"),
      climber_number: climber.contains("Number"),
      climber_clips: climber.contains("Clips"),
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
      elevator_belts: elevator.contains("Belts"),
      elevator_gearbox: elevator.contains("Gearbox"),
      elevator_motors: elevator.contains("Motors"),
      elevator_wires: elevator.contains("Wires"),
      elevator_nuts_and_bolts: elevator.contains("Nuts and Bolts"),
      trapdoor_panels: trapdoor.contains("Panels"),
      trapdoor_supports: trapdoor.contains("Supports"),
      trapdoor_hinges: trapdoor.contains("Hinges"),
      trapdoor_tensioners: trapdoor.contains("Tensioners"),
      trapdoor_nuts_and_bolts: trapdoor.contains("Nuts and Bolts"),
      trapdoor_reset: trapdoor.contains("Reset"),
      carriage_gearbox: carriage.contains("Gearbox"),
      carriage_beltbox: carriage.contains("Beltbox"),
      carriage_motors: carriage.contains("Motors"),
      carriage_wires: carriage.contains("Wires"),
      carriage_nuts_and_bolts: carriage.contains("Nuts and Bolts"),
      carriage_coral_slide: carriage.contains("Coral Slide"),
      carriage_carriage: carriage.contains("Carriage"),
      gooseneck_panels: gooseneck.contains("Panels"),
      gooseneck_wheels: gooseneck.contains("Wheels"),
      gooseneck_belts: gooseneck.contains("Belts"),
      gooseneck_gears: gooseneck.contains("Gears"),
      gooseneck_nuts_and_bolts: gooseneck.contains("Nuts and Bolts"),
      returning_battery_voltage: returning_battery_voltage,
      returning_battery_cca: returning_battery_cca,
      returning_number: returning_number,
      outgoing_battery_voltage: outgoing_battery_voltage,
      outgoing_battery_cca: outgoing_battery_cca,
      outgoing_number: outgoing_number,
      outgoing_battery_replacd: returning_battery_replacd,
      broken_part_image: image,
      broken_part_images: images, // Add the new list of images
      alliance_color: alliance_color,
      note: notes.text,
    );

    print('Recording data: $record');
    print("Hiv ${record.toJson()}");
    print(widget.list_item.matchkey.toString());
    print("Data recorded for match key: ${record.matchkey}");

    PitCheckListDatabase.PutData(widget.list_item.matchkey, record);
    PitCheckListDatabase.SaveAll();

    PitCheckListDatabase.PrintAll();
  }

  void PopBoard(BuildContext context) {
    Navigator.pop(context);
  }
}
