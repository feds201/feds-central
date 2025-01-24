import 'package:flutter/material.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';

import '../../components/DataBase.dart';
import '../../components/TeamInfo.dart';
import '../match.dart';

class Auton extends StatefulWidget {
  const Auton({super.key});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<Auton> {
  final LocalDataBase dataMaster = LocalDataBase();

  late bool left_barge;
  late int coralScoreL1;
  late int coralScoreL2;
  late int coralScoreL3;
  late int coralScoreL4;

  late String assignedTeam;
  late String assignedStation;
  late String matchKey;
  late String allianceColor;


  // Match Variables
  @override
  void initState() {
    super.initState();
    assignedTeam = LocalDataBase.getData(Types.team) ?? "Null";
    assignedStation = LocalDataBase.getData(Types.selectedStation) ?? "Null";

    left_barge = LocalDataBase.getData(AutoType.LeftBarge) ?? false;
    coralScoreL1 = LocalDataBase.getData(AutoType.CoralScoringLevel1) ?? 0;
    coralScoreL2 = LocalDataBase.getData(AutoType.CoralScoringLevel2) ?? 0;
    coralScoreL3 = LocalDataBase.getData(AutoType.CoralScoringLevel3) ?? 0;
    coralScoreL4 = LocalDataBase.getData(AutoType.CoralScoringLevel4) ?? 0;
  }

  void UpdateData() {
    LocalDataBase.putData(AutoType.LeftBarge, left_barge);
    LocalDataBase.putData(AutoType.CoralScoringLevel1, coralScoreL1);
    LocalDataBase.putData(AutoType.CoralScoringLevel2, coralScoreL2);
    LocalDataBase.putData(AutoType.CoralScoringLevel3, coralScoreL3);
    LocalDataBase.putData(AutoType.CoralScoringLevel4, coralScoreL4);
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      assignedTeam = LocalDataBase.getData(Types.team) ?? "Null";
      assignedStation = LocalDataBase.getData(Types.selectedStation) ?? "Null";
      matchKey = LocalDataBase.getData(Types.matchKey) ?? "Null";
      allianceColor = LocalDataBase.getData(Types.allianceColor) ?? "Null";
    });
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
          buildCheckBoxFull("Left Barge", left_barge, (bool value) {
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
              ],
              const Icon(Icons.emoji_nature_outlined))
        ],
      ),
    );
  }
}
