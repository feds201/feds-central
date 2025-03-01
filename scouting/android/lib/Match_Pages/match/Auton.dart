import 'package:flutter/material.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';

import '../../services/DataBase.dart';
import '../../components/TeamInfo.dart';
import '../match.dart';

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

  late AutonPoints autonPoints;

  late String assignedTeam;
  late String assignedStation;
  late String matchKey;
  late String allianceColor;

  @override
  void initState() {
    super.initState();

    autonPoints = LocalDataBase.getData('TEMP-Data') ??
        AutonPoints(0, 0, 0, 0, false, 0, 0);
    assignedTeam = widget.matchRecord.teamNumber;
    assignedStation = widget.matchRecord.station;
    matchKey = widget.matchRecord.matchKey;
    allianceColor = widget.matchRecord.allianceColor;
    left_barge = autonPoints.LeftBarge;

    coralScoreL1 = autonPoints.CoralScoringLevel1;
    coralScoreL2 = autonPoints.CoralScoringLevel2;
    coralScoreL3 = autonPoints.CoralScoringLevel3;
    coralScoreL4 = autonPoints.CoralScoringLevel4;
    algaeScoringProcessor = autonPoints.AlgaeScoringProcessor;
    algaeScoringBarge = autonPoints.AlgaeScoringBarge;
    left_barge = autonPoints.LeftBarge;

    UpdateData();
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
    );
    saveState();
  }

  void saveState() {
    LocalDataBase.putData('autonPoints', autonPoints);
  }

  void revertState() {
    var savedData = LocalDataBase.getData('autonPoints');
    if (savedData != null) {
      setState(() {
        coralScoreL1 = savedData['CoralScoringLevel1'];
        coralScoreL2 = savedData['CoralScoringLevel2'];
        coralScoreL3 = savedData['CoralScoringLevel3'];
        coralScoreL4 = savedData['CoralScoringLevel4'];
        algaeScoringProcessor = savedData['AlgaeScoringProcessor'];
        algaeScoringBarge = savedData['AlgaeScoringBarge'];
        left_barge = savedData['LeftBarge'];
      });
    }
    print(savedData);
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
              print('Team Info START button pressed');
            },
          ),
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
                    UpdateData();
                  },
                  (int value) {
                    setState(() {
                      coralScoreL4--;
                    });
                    UpdateData();
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
                    UpdateData();
                  },
                  (int value) {
                    setState(() {
                      coralScoreL3--;
                    });
                    UpdateData();
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
                    UpdateData();
                  },
                  (int value) {
                    setState(() {
                      coralScoreL2--;
                    });
                    UpdateData();
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
                    UpdateData();
                  },
                  (int value) {
                    setState(() {
                      coralScoreL1--;
                    });
                    UpdateData();
                  },
                  icon: Icons.cyclone,
                  number: coralScoreL1,
                  counterText: "Level 1",
                  color: Colors.green,
                ),
              ],
              const Icon(Icons.emoji_nature_outlined)),
          buildComments(
              "Algae Scoring",
              [
                CounterSettings(
                  (int value) {
                    setState(() {
                      algaeScoringProcessor++;
                    });
                    UpdateData();
                  },
                  (int value) {
                    setState(() {
                      algaeScoringProcessor--;
                    });
                    UpdateData();
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
                    UpdateData();
                  },
                  (int value) {
                    setState(() {
                      algaeScoringBarge--;
                    });
                    UpdateData();
                  },
                  icon: Icons.rice_bowl_outlined,
                  number: algaeScoringBarge,
                  counterText: "Barge",
                  color: Colors.green,
                ),
              ],
              const Icon(Icons.add_comment)),
        ],
      ),
    );
  }
}

class AutonPoints {
  final int CoralScoringLevel1;
  final int CoralScoringLevel2;
  final int CoralScoringLevel3;
  final int CoralScoringLevel4;
  final bool LeftBarge;
  final int AlgaeScoringProcessor;
  final int AlgaeScoringBarge;

  AutonPoints(
    this.CoralScoringLevel1,
    this.CoralScoringLevel2,
    this.CoralScoringLevel3,
    this.CoralScoringLevel4,
    this.LeftBarge,
    this.AlgaeScoringProcessor,
    this.AlgaeScoringBarge,
  );

  Map<String, dynamic> toJson() {
    return {
      'CoralScoringLevel1': CoralScoringLevel1,
      'CoralScoringLevel2': CoralScoringLevel2,
      'CoralScoringLevel3': CoralScoringLevel3,
      'CoralScoringLevel4': CoralScoringLevel4,
      'LeftBarge': LeftBarge,
      'AlgaeScoringProcessor': AlgaeScoringProcessor,
      'AlgaeScoringBarge': AlgaeScoringBarge,
    };
  }
}
