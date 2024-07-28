import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/components/Map.dart';
import 'package:scouting_app/pages/components/DataBase.dart';
import '../../components/Chips.dart';
import '../../components/RatingsBox.dart';
import '../../components/TeamInfo.dart';
import '../../components/ratings.dart';
import '../match.dart';

class Auton extends StatefulWidget {
  const Auton({super.key});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<Auton> {
  final LocalDataBase dataMaster = LocalDataBase();
  late Offset? _circlePosition =
      LocalDataBase.getData(AutoType.StartPosition) ??
          const Offset(10, 10); // Default value;
  late int ampPlacementValue;
  late int speakerValue;
  late int trapValue;

  late int autonRating;
  late List<String> comments;

  late String assignedTeam;
  late String assignedStation;
  late String matchKey;
  late String allianceColor;

  bool isChip1Clicked = false;
  bool isChip2Clicked = false;
  bool isChip3Clicked = false;

  // Match Variables
  @override
  void initState() {
    super.initState();
    assignedTeam = LocalDataBase.getData(Types.team) ?? "Null";
    assignedStation = LocalDataBase.getData(Types.selectedStation) ?? "Null";
    autonRating = LocalDataBase.getData(AutoType.AutonRating) ?? 0;

    ampPlacementValue = LocalDataBase.getData(AutoType.AmpPlacement) ?? 0;
    speakerValue = LocalDataBase.getData(AutoType.Speaker) ?? 0;
    trapValue = LocalDataBase.getData(AutoType.Trap) ?? 0;
    autonRating = LocalDataBase.getData(AutoType.AutonRating) ?? 0;

    isChip1Clicked = LocalDataBase.getData(AutoType.Chip1) ?? false;
    isChip2Clicked = LocalDataBase.getData(AutoType.Chip2) ?? false;
    isChip3Clicked = LocalDataBase.getData(AutoType.Chip3) ?? false;
  }

  void UpdateData() {
    LocalDataBase.putData(AutoType.AmpPlacement, ampPlacementValue);
    LocalDataBase.putData(AutoType.Speaker, speakerValue);
    LocalDataBase.putData(AutoType.Trap, trapValue);
    LocalDataBase.putData(AutoType.StartPosition, _circlePosition);
    LocalDataBase.putData(AutoType.AutonRating, autonRating);
    LocalDataBase.putData(AutoType.Chip1, isChip1Clicked);
    LocalDataBase.putData(AutoType.Chip2, isChip2Clicked);
    LocalDataBase.putData(AutoType.Chip3, isChip3Clicked);
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
          buildTeamInfo(assignedTeam, assignedStation, allianceColor, () {}),
          buildMap(context, _circlePosition, const Size(35, 35), allianceColor,
              onTap: (TapUpDetails details) {_updatePosition(details);}),
          buildComments(
            "Scoring",
            [
              CounterSettings(
                (int value) {
                  value++;
                  setState(() {
                    ampPlacementValue = value;
                  });
                },
                (int value) {
                  value--;
                  setState(() {
                    ampPlacementValue = value;

                  });
                },
                icon: Icons.sledding,
                number: ampPlacementValue,
                counterText: "Amp Placement",
                color: Colors.blue,

              ),
              CounterSettings(
                (int value) {
                  value++;
                  setState(() {
                    speakerValue = value;

                  });
                },
                (int value) {
                  value--;
                  setState(() {
                    speakerValue = value;

                  });
                },
                icon: Icons.speaker,
                number: speakerValue,
                counterText: "Speaker Placement",
                color: Colors.green,
              ),
              CounterSettings(
                (int value) {
                  value++;
                  setState(() {
                    trapValue = value;
                    UpdateData();
                  });
                },
                (int value) {
                  value--;
                  setState(() {
                    trapValue = value;
                    UpdateData();
                  });
                },
                icon: Icons.hub_outlined,
                number: trapValue,
                counterText: "Trap Placement",
                color: Colors.red,
              ),
            ],
            const Icon(Icons.comment),
          ),
          buildComments(
            "React",
            [
              buildRatings([
                buildRating("Auton Rating", Icons.access_alarm_outlined, autonRating.toDouble(), 5,
                    Colors.yellow.shade600, onRatingUpdate: (double rating) {
                      setState(() {
                        autonRating = rating.toInt();
                        UpdateData();
                      });
                    }),
              ]),
              buildComments(
                "Auton Comments",
                [
                  buildChips([
                    "Encountered issues",
                    "Fast and efficient",
                    "No issues"
                  ], [
                    [Colors.red, Colors.white],
                    [Colors.green, Colors.white],
                    [Colors.blue, Colors.white]
                  ], [
                    isChip1Clicked,
                    isChip2Clicked,
                    isChip3Clicked,
                  ], onTapList: [
                    (String label) {
                      setState(() {
                        isChip1Clicked = !isChip1Clicked;
                        isChip2Clicked = isChip2Clicked;
                        isChip3Clicked = false;
                      });
                      UpdateData();
                    },
                    (String label) {
                      setState(() {
                        isChip1Clicked = isChip1Clicked;
                        isChip2Clicked = !isChip2Clicked;
                        isChip3Clicked = isChip3Clicked;
                      });
                      UpdateData();
                    },
                    (String label) {
                      setState(() {
                        isChip1Clicked = false;
                        isChip2Clicked = isChip2Clicked;
                        isChip3Clicked = !isChip3Clicked;
                      });
                      UpdateData();
                    },
                  ]),
                ],
                const Icon(Icons.comment_bank),
              ),
            ],
            const Icon(Icons.comment_bank),
          ),

        ],
      ),
    );
  }




  void _updatePosition(TapUpDetails details) {
    setState(() {
      _circlePosition = details.localPosition;
      LocalDataBase.putData(AutoType.StartPosition, _circlePosition);
    });
    UpdateData();
  }
}

enum AutoType {
  AmpPlacement,
  Speaker,
  Trap,
  StartPosition,
  AutonRating,
  Chip1,
  Chip2,
  Chip3
}
