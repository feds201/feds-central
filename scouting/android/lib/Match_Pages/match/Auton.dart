import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/components/ScoutersList.dart';

import '../../main.dart';
import '../../services/DataBase.dart';
import '../../components/TeamInfo.dart';

class Auton extends StatefulWidget {
  final MatchRecord matchRecord;
  const Auton({super.key, required this.matchRecord});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<Auton> {
  late bool left_barge;
  late int coralScoreL1;
  late int coralScoreL2;
  late int coralScoreL3;
  late int coralScoreL4;
  late int algaeScoringProcessor;
  late int algaeScoringBarge;
  late BotLocation botLocations;

  late AutonPoints autonPoints;

  late String assignedTeam;
  late int assignedStation;
  late String matchKey;
  late String allianceColor;
  late int matchNumber;

  @override
  void initState() {
    super.initState();
    //   log(widget.matchRecord.toString());

    assignedTeam = widget.matchRecord.teamNumber;
    assignedStation = widget.matchRecord.station;
    matchKey = widget.matchRecord.matchKey;
    allianceColor = widget.matchRecord.allianceColor;
    matchNumber = widget.matchRecord.matchNumber;
    botLocations = BotLocation(Offset(200, 200), Size(2000, 2000), 45);
    left_barge = widget.matchRecord.autonPoints.LeftBarge;
    coralScoreL1 = widget.matchRecord.autonPoints.CoralScoringLevel1;
    coralScoreL2 = widget.matchRecord.autonPoints.CoralScoringLevel2;
    coralScoreL3 = widget.matchRecord.autonPoints.CoralScoringLevel3;
    coralScoreL4 = widget.matchRecord.autonPoints.CoralScoringLevel4;
    algaeScoringProcessor =
        widget.matchRecord.autonPoints.AlgaeScoringProcessor;
    algaeScoringBarge = widget.matchRecord.autonPoints.AlgaeScoringBarge;
    autonPoints = AutonPoints(
        coralScoreL1,
        coralScoreL2,
        coralScoreL3,
        coralScoreL4,
        left_barge,
        algaeScoringProcessor,
        algaeScoringBarge,
        botLocations);
    // log('Auton initialized: $autonPoints');
  }

  void UpdateData() {
    autonPoints = AutonPoints(
        coralScoreL1,
        coralScoreL2,
        coralScoreL3,
        coralScoreL4,
        left_barge,
        algaeScoringProcessor,
        algaeScoringBarge,
        botLocations);

    widget.matchRecord.autonPoints = autonPoints;
    widget.matchRecord.autonPoints.LeftBarge = left_barge;
    widget.matchRecord.autonPoints.CoralScoringLevel1 = coralScoreL1;
    widget.matchRecord.autonPoints.CoralScoringLevel2 = coralScoreL2;
    widget.matchRecord.autonPoints.CoralScoringLevel3 = coralScoreL3;
    widget.matchRecord.autonPoints.CoralScoringLevel4 = coralScoreL4;
    widget.matchRecord.autonPoints.AlgaeScoringProcessor =
        algaeScoringProcessor;
    widget.matchRecord.autonPoints.AlgaeScoringBarge = algaeScoringBarge;
    widget.matchRecord.scouterName =
        Hive.box('settings').get('deviceName', defaultValue: '');

    saveState();
  }

  void saveState() {
    LocalDataBase.putData('Auton', autonPoints.toJson());

    log('Auton state saved: ${autonPoints.toCsv()}');
  }

  @override
  void dispose() {
    // Make sure data is saved when navigating away
    UpdateData();
    saveState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: _buildAuto(context));
  }

  Widget _buildAuto(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          MatchInfo(
            assignedTeam: assignedTeam,
            assignedStation: assignedStation,
            allianceColor: allianceColor,
            onPressed: () {
              // print('Team Info START button pressed');
            },
          ),
          ScouterList(),
          buildCheckBoxFull("Leave", left_barge, (bool value) {
            setState(() {
              left_barge = value;
            });
            UpdateData();
          }),
          buildComments(
            "Coral Scoring",
            [
              CounterSettings(
                (int value) {
                  setState(() {
                    coralScoreL4++;
                  });
                },
                (int value) {
                  setState(() {
                    coralScoreL4--;
                  });
                },
                icon: Icons.cyclone,
                number: coralScoreL4,
                counterText: "Level 4",
                color: Colors.red,
              ),
              CounterSettings(
                (int value) {
                  setState(() {
                    coralScoreL3++;
                  });
                },
                (int value) {
                  setState(() {
                    coralScoreL3--;
                  });
                },
                icon: Icons.cyclone,
                number: coralScoreL3,
                counterText: "Level 3",
                color: Colors.orange,
              ),
              CounterSettings(
                (int value) {
                  setState(() {
                    coralScoreL2++;
                  });
                },
                (int value) {
                  setState(() {
                    coralScoreL2--;
                  });
                },
                icon: Icons.cyclone,
                number: coralScoreL2,
                counterText: "Level 2",
                color: Colors.yellow,
              ),
              CounterSettings(
                (int value) {
                  setState(() {
                    coralScoreL1++;
                  });
                },
                (int value) {
                  setState(() {
                    coralScoreL1--;
                  });
                },
                icon: Icons.cyclone,
                number: coralScoreL1,
                counterText: "Level 1",
                color: Colors.green,
              ),
            ],
            Icon(
              Icons.emoji_nature_outlined,
              color: !islightmode()
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(255, 34, 34, 34),
            ),
          ),
          buildComments(
              "Algae Scoring",
              [
                CounterSettings(
                  (int value) {
                    setState(() {
                      algaeScoringProcessor++;
                    });
                  },
                  (int value) {
                    setState(() {
                      algaeScoringProcessor--;
                    });
                  },
                  icon: Icons.wash,
                  number: algaeScoringProcessor,
                  counterText: "Processor",
                  color: Colors.green,
                ),
                CounterSettings(
                  (int value) {
                    setState(() {
                      algaeScoringBarge++;
                    });
                  },
                  (int value) {
                    setState(() {
                      algaeScoringBarge--;
                    });
                  },
                  icon: Icons.rice_bowl_outlined,
                  number: algaeScoringBarge,
                  counterText: "Barge",
                  color: Colors.green,
                ),
              ],
              Icon(
                Icons.add_comment,
                color: !islightmode()
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : const Color.fromARGB(255, 34, 34, 34),
              )),
        ],
      ),
    );
  }
}
