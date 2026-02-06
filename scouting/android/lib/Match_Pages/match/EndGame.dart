import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/components/QrGenerator.dart';
import 'package:scouting_app/components/gameSpecifics/climb.dart';
// import 'package:scouting_app/components/gameSpecifics/climb.dart';
import 'package:scouting_app/main.dart';

import '../../components/TeamInfo.dart';
import '../../components/gameSpecifics/timer.dart';
import '../../components/slider.dart';
import '../../services/DataBase.dart';

class EndGame extends StatefulWidget {
  final MatchRecord matchRecord;
  const EndGame({super.key, required this.matchRecord});

  @override
  EndGameState createState() => EndGameState();
}

class EndGameState extends State<EndGame> {
  // late bool feed;
  // late bool defense;
  late bool park;
  late bool feedToHP;
  late bool passing;
  int? selectedLevel; // Now maps to ClimbStatus: 0=None, 1-9=IDs

  late EndPoints endPoints;

  late String assignedTeam;
  late int assignedStation;
  late String matchKey;
  late String allianceColor;
  late int matchNumber;
  late int neutralTrips;
  //timer
  double endgameTime = 0.0;
  int endgameActions = 0;

  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    assignedTeam = widget.matchRecord.teamNumber;
    assignedStation = widget.matchRecord.station;
    matchKey = widget.matchRecord.matchKey;
    allianceColor = widget.matchRecord.allianceColor;

    // Load values from endPoints
    // ClimbStatus stores the specific ID (1-9) or 0 for none
    int status = widget.matchRecord.endPoints.ClimbStatus;
    selectedLevel = status == 0 ? null : status;
    park = widget.matchRecord.endPoints.Park;
    feedToHP = widget.matchRecord.endPoints.FeedToHP;
    passing = widget.matchRecord.endPoints.Passing;

    commentController.text = widget.matchRecord.endPoints.Comments;
    neutralTrips = 0;
    endgameTime = widget.matchRecord.endPoints.endgameTime;
    endgameActions = widget.matchRecord.endPoints.endgameActions;
  }

  void UpdateData() {
    // Save selectedLevel to ClimbStatus (0 if null)
    widget.matchRecord.endPoints.ClimbStatus = selectedLevel ?? 0;

    // Park is explicitly tracked, usually triggered if level is null and user leaves blank
    widget.matchRecord.endPoints.Park = park;
    widget.matchRecord.endPoints.FeedToHP = feedToHP;
    widget.matchRecord.endPoints.Passing = passing;

    widget.matchRecord.endPoints.Comments = commentController.text;

    // Timer and endgame actions
    widget.matchRecord.endPoints.endgameTime = endgameTime;
    widget.matchRecord.endPoints.endgameActions = endgameActions;

    endPoints = widget.matchRecord.endPoints;
    saveState();
  }

  void saveState() {
    LocalDataBase.putData('endPoints', endPoints.toJson());
    log('EndGame state saved: ${endPoints.toCsv()}');
  }

  @override
  void dispose() {
    // Make sure data is saved when navigating away
    UpdateData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print(LocalDataBase.getData('Settings.apiKey'));
    // print(endPoints.Comments);
    return SingleChildScrollView(
      child: Column(
        children: [
          MatchInfo(
            assignedTeam: assignedTeam,
            assignedStation: assignedStation,
            allianceColor: allianceColor,
            onPressed: () {
              // print('Team Info START button pressed');
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: buildCounter("Shooting Cycle", endgameActions,
                      (int value) {
                    setState(() {
                      endgameActions = value;
                    });
                    UpdateData();
                  }, color: Colors.yellow),
                ),
                Expanded(
                  child:
                      buildCounter("Neutral Trips", neutralTrips, (int value) {
                    setState(() {
                      neutralTrips = value;
                    });
                    UpdateData();
                  }, color: Colors.yellow),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child:
                      buildCheckBoxHalf("Feed to HP", feedToHP, (bool value) {
                    setState(() {
                      feedToHP = value;
                    });
                    UpdateData();
                  }),
                ),
                Expanded(
                  child: buildCheckBoxHalf("Passing", passing, (bool value) {
                    setState(() {
                      passing = value;
                    });
                    UpdateData();
                  }),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 9,
          ),
          TklKeyboard(
            currentTime: endgameTime,
            onChange: (double time) {
              setState(() {
                endgameTime = time;
              });
            },
            doChange: () {
              setState(() {
                endgameActions++;
              });
              UpdateData(); // Saves the updated endgame values
            },
            doChangeResetter: () {
              setState(() {
                endgameActions = 0;
                endgameTime = 0.0;
              });
              UpdateData(); // Resets the values in your matchRecord
            },
            doChangeNoIncrement: () {
              UpdateData(); // Updates without changing values
            },
          ),

          const SizedBox(height: 12), // spacing

// Total

          buildClimbImage(
            selectedLevel,
            park,
            (int? newLevel) {
              setState(() {
                selectedLevel = newLevel;
              });
              park = newLevel == null;
            },
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: islightmode()
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(255, 34, 34, 34),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Comments",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: !islightmode()
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : const Color.fromARGB(255, 34, 34, 34),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: TextField(
                    controller: commentController,
                    maxLines: 4,
                    style: TextStyle(
                      fontSize: 16,
                      color: islightmode()
                          ? const Color.fromARGB(
                              255, 0, 0, 0) // Black for light mode
                          : const Color.fromARGB(
                              255, 255, 255, 255), // White for dark mode
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: islightmode()
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(255, 34, 34, 34),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                      hintText:
                          'Add any relevant notes about the team\'s performance...',
                      hintStyle: TextStyle(
                        color: !islightmode()
                            ? const Color.fromARGB(255, 255, 255, 255)
                            : const Color.fromARGB(255, 34, 34, 34),
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 6),
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
                  backgroundColor: islightmode()
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : const Color.fromARGB(255, 34, 34, 34),
                  highlightedColor: Colors.green,
                  dismissThresholds: 0.97,
                  vibrationFlag: true,
                  width: MediaQuery.of(context).size.width - 16,
                  action: () async {
                    UpdateData();
                    MatchDataBase.PutData(
                        widget.matchRecord.matchKey, widget.matchRecord);
                    MatchDataBase.SaveAll();
                    // MatchDataBase.PrintAll();
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Qrgenerator(matchRecord: widget.matchRecord),
                            fullscreenDialog: true));
                    return null;
                  },
                  label: Text("Slide to Complete Event",
                      style: TextStyle(
                          color: islightmode() ? Colors.black : Colors.white,
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
