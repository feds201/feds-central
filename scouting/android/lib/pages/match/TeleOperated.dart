
import 'package:flutter/material.dart';

class TeleOperated extends StatefulWidget {
  const TeleOperated({Key? key}) : super(key: key);

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {


  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
          Text("TeleOperated"),

      ],
    );
  }
}

enum MatchType { Auto, Teleop, EndGame }



enum TeleopType {
  AllianceWing,
  CenterField,
  FarWing,
  Unamplified,
  Amplified,
  Amp,
  Trap,
  Passed,
  Missed
}

enum AutoType { AmpPlacement, Speaker, StartPosition, AutonRating, Comments }

enum Types {
  eventKey,
  matchKey,
  allianceColor,
  selectedStation,
  eventFile,
  matchFile,
}


