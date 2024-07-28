import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/components/Map.dart';
import 'package:scouting_app/pages/components/DataBase.dart';
import 'package:scouting_app/components/CheckBox.dart';

import '../match.dart';

class EndGame extends StatefulWidget {
  const EndGame({super.key});

  @override
  _EndGameState createState() => _EndGameState();
}

class _EndGameState extends State<EndGame> {
  final LocalDataBase dataMaster = LocalDataBase();
  late Offset endLocation;
  late bool climbed;
  late int trapNotePosition;
  late bool harmony;
  late String comments;
  late String allianceColor;


  @override
  void initState() {
    super.initState();
    endLocation = LocalDataBase.getData(EndgameType.endLocation) ?? Offset.zero;
    climbed = LocalDataBase.getData(EndgameType.climbed) ?? false;
    trapNotePosition = LocalDataBase.getData(EndgameType.trapNotePosition) ?? 0;
    harmony = LocalDataBase.getData(EndgameType.harmony) ?? false;
    comments = LocalDataBase.getData(EndgameType.comments) ?? "";
    allianceColor = LocalDataBase.getData(Types.allianceColor) ?? "Null";
  }

  void UpdateData() {
    LocalDataBase.putData(EndgameType.endLocation, endLocation);
    LocalDataBase.putData(EndgameType.climbed, climbed);
    LocalDataBase.putData(EndgameType.trapNotePosition, trapNotePosition);
    LocalDataBase.putData(EndgameType.harmony, harmony);
    LocalDataBase.putData(EndgameType.comments, comments);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildMap(context, endLocation, Size(30, 30), allianceColor, onTap: (details) {
            setState(() {
              endLocation = details.localPosition;
            });
            UpdateData();
          }, image: Image.asset("Areana.png", fit: BoxFit.fill, width: 100, height: 100)),
        ],
      ),
    );
  }
}

enum EndgameType{
  endLocation,
  climbed,
  trapNotePosition,
  harmony,
  comments
}
