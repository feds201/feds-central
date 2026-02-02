import 'package:flutter/material.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/main.dart';
import '../../components/gameSpecifics/PhaseSelection.dart';

import '../../services/DataBase.dart';

class TeleOperated extends StatefulWidget {
  final MatchRecord matchRecord;
  const TeleOperated({super.key, required this.matchRecord});

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  late int coralScoreL1;
  late int coralScoreL2;
  late int coralScoreL3;
  late int coralScoreL4;
  late int algaePickUp;
  late int algaeScoringProcessor;
  late int algaeScoringBarge;
  late bool defense;

  late TeleOpPoints teleOpPoints;

  @override
  void initState() {
    super.initState();
    // log(widget.matchRecord.toString());

    coralScoreL1 = widget.matchRecord.teleOpPoints.CoralScoringLevel1;
    coralScoreL2 = widget.matchRecord.teleOpPoints.CoralScoringLevel2;
    coralScoreL3 = widget.matchRecord.teleOpPoints.CoralScoringLevel3;
    coralScoreL4 = widget.matchRecord.teleOpPoints.CoralScoringLevel4;
    algaeScoringProcessor =
        widget.matchRecord.teleOpPoints.AlgaeScoringProcessor;
    algaeScoringBarge = widget.matchRecord.teleOpPoints.AlgaeScoringBarge;
    defense = widget.matchRecord.teleOpPoints.Defense;
    algaePickUp = widget.matchRecord.teleOpPoints.AlgaePickUp;

    teleOpPoints = TeleOpPoints(
      coralScoreL1,
      coralScoreL2,
      coralScoreL3,
      coralScoreL4,
      algaeScoringBarge,
      algaeScoringProcessor,
      algaePickUp,
      defense,
    );
    // log('TeleOp initialized: $teleOpPoints');
  }

  void UpdateData() {
    teleOpPoints = TeleOpPoints(
      coralScoreL1,
      coralScoreL2,
      coralScoreL3,
      coralScoreL4,
      algaeScoringBarge,
      algaeScoringProcessor,
      algaePickUp,
      defense,
    );
    widget.matchRecord.teleOpPoints.CoralScoringLevel1 = coralScoreL1;
    widget.matchRecord.teleOpPoints.CoralScoringLevel2 = coralScoreL2;
    widget.matchRecord.teleOpPoints.CoralScoringLevel3 = coralScoreL3;
    widget.matchRecord.teleOpPoints.CoralScoringLevel4 = coralScoreL4;
    widget.matchRecord.teleOpPoints.AlgaeScoringProcessor =
        algaeScoringProcessor;
    widget.matchRecord.teleOpPoints.AlgaeScoringBarge = algaeScoringBarge;
    widget.matchRecord.teleOpPoints.AlgaePickUp = algaePickUp;
    widget.matchRecord.teleOpPoints.Defense = defense;

    saveState();
  }

  void saveState() {
    LocalDataBase.putData('TeleOp', teleOpPoints.toJson());

    // log('TeleOp state saved: $teleOpPoints');
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
    // print(LocalDataBase.getData('Settings.apiKey'));
    return SingleChildScrollView(

      child: Column(
        children: [
          buildPhaseSele(context, (int shift) {

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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              // Add crossAxisAlignment to align items properly
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Wrap first child with Expanded to make it responsive
                Expanded(
                  flex: 3,
                  child:
                      buildCounter("Algae Retrieval", algaePickUp, (int value) {
                    setState(() {
                      algaePickUp = value;
                    });
                  }, color: Colors.green),
                ),
                const SizedBox(width: 8), // Add spacing between widgets
                // Wrap second child with Expanded
                Expanded(
                  flex: 2,
                  child: buildCheckBox("Defense", defense, (bool value) {
                    setState(() {
                      defense = value;
                    });
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
