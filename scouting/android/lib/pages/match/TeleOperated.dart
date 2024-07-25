import 'package:flutter/material.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/RatingsBox.dart';

import '../../components/ratings.dart';

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
        buildComments(
            "Pick Up",
            [
              buildComments(
                  "Pick Up",
                  [
                    buildRating(
                        "Pick Up", Icons.ice_skating, 1, 3, Colors.cyan),
                  ],
                  const Icon(Icons.precision_manufacturing_outlined)),
            ],
            const Icon(Icons.precision_manufacturing_outlined)),
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
