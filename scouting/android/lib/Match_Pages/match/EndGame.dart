import 'package:flutter/material.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/slider.dart';

import '../../services/DataBase.dart';
import '../../components/QrGenerator.dart';

class EndGame extends StatefulWidget {
  final MatchRecord matchRecord;
  const EndGame({super.key, required this.matchRecord});

  @override
  _EndGameState createState() => _EndGameState();
}

class _EndGameState extends State<EndGame> {
  late bool DeepClimb = false;
  late bool ShallowClimb = false;
  late bool parked = false;
  late String scouterComments = '';

  @override
  void initState() {
    super.initState();
  }

  // @override
  // void dispose() {
  //   stopWatchTime.cancel();
  //   super.dispose();
  // }

  void UpdateData() {}

  @override
  Widget build(BuildContext context) {
    print(LocalDataBase.getData('Settings.apiKey'));
    return SingleChildScrollView(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              buildCheckBox("Deep Climb", DeepClimb, (bool value) {
                setState(() {
                  DeepClimb = value;
                });
                UpdateData();
              }),
              buildCheckBox("Shallow Climb", ShallowClimb, (bool value) {
                setState(() {
                  ShallowClimb = value;
                });
                UpdateData();
              }),
            ]),
          ),
          buildCheckBoxFull("Parked", parked, (bool value) {
            setState(() {
              parked = value;
            });
            UpdateData();
          }),
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
                  width: MediaQuery.of(context).size.width - 16,
                  action: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Qrgenerator(matchRecord: widget.matchRecord),
                            fullscreenDialog: true));
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
          ),
        ],
      ),
    );
  }
}

// Define your MapWidget separately if not defined
class MapWidget extends StatelessWidget {
  final Offset endLocation;
  final Size size;
  final Color allianceColor;
  final ImageProvider image;
  final Function(TapUpDetails) onTap;

  const MapWidget({
    super.key,
    required this.endLocation,
    required this.size,
    required this.allianceColor,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder
  }
}
