import 'package:slider_button/slider_button.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/components/Map.dart';
import 'package:scouting_app/pages/components/DataBase.dart';
import 'package:scouting_app/components/CheckBox.dart';

import '../actions/QrGenerator.dart';
import '../match.dart';

class EndGame extends StatefulWidget {
  const EndGame({super.key});

  @override
  _EndGameState createState() => _EndGameState();
}

class _EndGameState extends State<EndGame> {
  final LocalDataBase dataMaster = LocalDataBase();
  late Offset endLocation;

  late int trapNotePosition;
  late String comments;
  late String allianceColor;
  late bool harmony;
  late bool attempted;
  late bool climbed;
  late bool spotlight;

  @override
  void initState() {
    super.initState();
    endLocation =
        LocalDataBase.getData(EndgameType.endLocation) ?? Offset(10, 10);
    climbed = LocalDataBase.getData(EndgameType.climbed) ?? false;
    harmony = LocalDataBase.getData(EndgameType.harmony) ?? false;
    allianceColor = LocalDataBase.getData(Types.allianceColor) ?? "Null";
    attempted = LocalDataBase.getData(EndgameType.attempted) ?? false;
    spotlight = LocalDataBase.getData(EndgameType.spotlight) ?? false;
  }

  void UpdateData() {
    LocalDataBase.putData(EndgameType.endLocation, endLocation);
    LocalDataBase.putData(EndgameType.climbed, climbed);
    LocalDataBase.putData(EndgameType.harmony, harmony);
    LocalDataBase.putData(EndgameType.attempted, attempted);
    LocalDataBase.putData(EndgameType.spotlight, spotlight);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildMap(
            context,
            endLocation,
            const Size(35, 35),
            allianceColor,
            onTap: (TapUpDetails details) {
              _updatePosition(details);
            },
            image: Image.asset('assets/Areana.png'),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              buildCheckBox("Climbed?", climbed, (bool value) {
                setState(() {
                  climbed = value;
                });
                UpdateData();
              }, IconOveride: true),
              buildCheckBox("Failed", attempted, (bool value) {
                setState(() {
                  attempted = value;
                });
                UpdateData();
              }, IconOveride: true),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              buildCheckBox("Spotlight?", spotlight, (bool value) {
                setState(() {
                  spotlight = value;
                });
                UpdateData();
              }, IconOveride: true),
              buildCheckBox("Harmony?", harmony, (bool value) {
                setState(() {
                  harmony = value;
                });
                UpdateData();
              }, IconOveride: true),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
                width: MediaQuery.of(context).size.width - 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SliderButton(
                  buttonColor: Colors.yellow,
                  backgroundColor: Colors.white,
                  highlightedColor: Colors.green,
                  dismissThresholds: 0.97,
                  vibrationFlag: true,
                  width: MediaQuery.of(context).size.width-16,
                  action: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Qrgenerator()));

                  },
                  label: const Text("Slide to Complete Event",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 17),
                      textAlign: TextAlign.start),
                  icon: const Icon(Icons.send_outlined,
                      size: 30, color: Colors.black),
                )),
          )
        ],
      ),
    );
  }

  void _updatePosition(TapUpDetails details) {
    setState(() {
      endLocation = details.localPosition;
      LocalDataBase.putData(AutoType.StartPosition, endLocation);
    });
    UpdateData();
  }
}

enum EndgameType {
  endLocation,
  climbed,
  harmony,
  attempted,
  spotlight
}
