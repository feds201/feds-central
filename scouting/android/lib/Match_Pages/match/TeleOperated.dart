import 'package:flutter/material.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';

import '../../components/DataBase.dart';

class TeleOperated extends StatefulWidget {
  const TeleOperated({super.key});

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  late int coralScoreL1;
  late int coralScoreL2;
  late int coralScoreL3;
  late int coralScoreL4;
  late int algaeScoringProcessor;
  late int algaeScoringBarge;

  @override
  void initState() {
    super.initState();

    coralScoreL1 = LocalDataBase.getData(TeleType.CoralScoringLevel1) ?? 0;
    coralScoreL2 = LocalDataBase.getData(TeleType.CoralScoringLevel2) ?? 0;
    coralScoreL3 = LocalDataBase.getData(TeleType.CoralScoringLevel3) ?? 0;
    coralScoreL4 = LocalDataBase.getData(TeleType.CoralScoringLevel4) ?? 0;
    algaeScoringProcessor =
        LocalDataBase.getData(TeleType.AlgaeScoringProcessor) ?? 0;
    algaeScoringBarge = LocalDataBase.getData(TeleType.AlgaeScoringBarge) ?? 0;
  }

  void UpdateData() {
    LocalDataBase.putData(TeleType.CoralScoringLevel1, coralScoreL1);
    LocalDataBase.putData(TeleType.CoralScoringLevel2, coralScoreL2);
    LocalDataBase.putData(TeleType.CoralScoringLevel3, coralScoreL3);
    LocalDataBase.putData(TeleType.CoralScoringLevel4, coralScoreL4);
    LocalDataBase.putData(
        TeleType.AlgaeScoringProcessor, algaeScoringProcessor);
    LocalDataBase.putData(TeleType.AlgaeScoringBarge, algaeScoringBarge);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
