import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/pages/components/DataBase.dart';

class TeleOperated extends StatefulWidget {
  const TeleOperated({Key? key}) : super(key: key);

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

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


