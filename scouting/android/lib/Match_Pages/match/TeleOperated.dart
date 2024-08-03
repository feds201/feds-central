import 'package:flutter/material.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';

import '../../components/DataBase.dart';

class TeleOperated extends StatefulWidget {
  const TeleOperated({super.key});

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  final LocalDataBase dataMaster = LocalDataBase();
  late int groundPickUp;
  late int sourcePickUp;
  late int speakerNotes;
  late int ampPlacement;
  late int trapPlacement;
  late int amplifiedSpeakerNotes;
  late bool coOpBonus;
  late int assists;

  @override
  void initState() {
    super.initState();
    groundPickUp = LocalDataBase.getData(TeleType.GroundPickUp) ?? 0;
    sourcePickUp = LocalDataBase.getData(TeleType.SourcePickUp) ?? 0;
    speakerNotes = LocalDataBase.getData(TeleType.SpeakerNotes) ?? 0;
    ampPlacement = LocalDataBase.getData(TeleType.AmpPlacement) ?? 0;
    trapPlacement = LocalDataBase.getData(TeleType.TrapPlacement) ?? 0;
    amplifiedSpeakerNotes =
        LocalDataBase.getData(TeleType.AmplifiedSpeakerNotes) ?? 0;
    coOpBonus = LocalDataBase.getData(TeleType.CoOpBonus) ?? false;
    assists = LocalDataBase.getData(TeleType.Assists) ?? 0;
  }

  void UpdateData() {
    LocalDataBase.putData(TeleType.GroundPickUp, groundPickUp);
    LocalDataBase.putData(TeleType.SourcePickUp, sourcePickUp);
    LocalDataBase.putData(TeleType.SpeakerNotes, speakerNotes);
    LocalDataBase.putData(TeleType.AmpPlacement, ampPlacement);
    LocalDataBase.putData(TeleType.TrapPlacement, trapPlacement);
    LocalDataBase.putData(
        TeleType.AmplifiedSpeakerNotes, amplifiedSpeakerNotes);
    LocalDataBase.putData(TeleType.CoOpBonus, coOpBonus);
    LocalDataBase.putData(TeleType.Assists, assists);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildComments(
              "Pick Up",
              [
                CounterSettings((int value) {
                  value++;
                  setState(() {
                    groundPickUp = value;
                  });
                  UpdateData();
                }, (int value) {
                  value--;
                  setState(() {
                    groundPickUp = value;
                  });
                  UpdateData();
                },
                    icon: Icons.grass_outlined,
                    number: groundPickUp,
                    counterText: "Ground",
                    color: Colors.green),
                CounterSettings((int value) {
                  value++;
                  setState(() {
                    sourcePickUp = value;
                  });
                  UpdateData();
                }, (int value) {
                  value--;
                  setState(() {
                    sourcePickUp = value;
                  });
                  UpdateData();
                },
                    icon: Icons.shopping_basket_outlined,
                    number: sourcePickUp,
                    counterText: "Source",
                    color: Colors.blue),
              ],
              const Icon(Icons.add_comment)),
          buildComments(
              "Scoring",
              [
                CounterSettings((int value) {
                  value++;
                  setState(() {
                    speakerNotes = value;
                  });
                  UpdateData();
                }, (int value) {
                  value--;
                  setState(() {
                    speakerNotes = value;
                  });
                  UpdateData();
                },
                    icon: Icons.grass_outlined,
                    number: speakerNotes,
                    counterText: "Speaker Notes",
                    color: Colors.green),
                CounterSettings((int value) {
                  value++;
                  setState(() {
                    ampPlacement = value;
                  });
                  UpdateData();
                }, (int value) {
                  value--;
                  setState(() {
                    ampPlacement = value;
                  });
                  UpdateData();
                },
                    icon: Icons.hub_outlined,
                    number: ampPlacement,
                    counterText: "Amp Placement",
                    color: Colors.blue),
                CounterSettings((int value) {
                  value++;
                  setState(() {
                    trapPlacement = value;
                  });
                  UpdateData();
                }, (int value) {
                  value--;
                  setState(() {
                    trapPlacement = value;
                  });
                  UpdateData();
                },
                    icon: Icons.shopping_basket_outlined,
                    number: trapPlacement,
                    counterText: "Trap Placement",
                    color: Colors.blue)
              ],
              const Icon(Icons.add_comment)),
          buildCounterShelf([
            CounterSettings((int value) {
              value++;
              setState(() {
                amplifiedSpeakerNotes = value;
              });
              UpdateData();
            }, (int value) {
              value--;
              setState(() {
                amplifiedSpeakerNotes = value;
              });
              UpdateData();
            },
                icon: Icons.grass_outlined,
                number: amplifiedSpeakerNotes,
                counterText: "Amplified Speaker Notes",
                color: Colors.green),
          ]),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              buildCheckBox("Co-Op Bonus", coOpBonus, (bool value) {
                setState(() {
                  coOpBonus = value;
                });
                UpdateData();
              }),
              buildCounter("Assists", assists, (int value) {
                setState(() {
                  assists = value;
                });
                UpdateData();
              }),
            ]),
          )
        ],
      ),
    );
  }
}
