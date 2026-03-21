import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scout_ops_android/components/CheckBox.dart';
import 'package:scout_ops_android/components/CounterShelf.dart';
import 'package:scout_ops_android/components/ScoutersList.dart';

import '../../components/TeamInfo.dart';
import '../../components/gameSpecifics/heatmap.dart';
import '../../components/gameSpecifics/timer.dart';
import '../../services/DataBase.dart';

class Auton extends StatefulWidget {
  final MatchRecord matchRecord;
  const Auton({super.key, required this.matchRecord});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<Auton> {
  late bool autoClimb;
  late double shootingTime;
  late AutonPoints autonPoints;
  late int amount;
  late String assignedTeam;
  late int assignedStation;
  late String matchKey;
  late String allianceColor;
  late int matchNumber;
  late int passing;
  late Alliance mapcolor;
  final GlobalKey<SinglePointSelectorState> _tapSelectorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    //   log(widget.matchRecord.toString());
    autoClimb = false;
    assignedTeam = widget.matchRecord.teamNumber;
    assignedStation = widget.matchRecord.station;
    matchKey = widget.matchRecord.matchKey;
    allianceColor = widget.matchRecord.allianceColor;
    if (allianceColor == "Blue") {
      mapcolor = Alliance.blue;
    } else if (allianceColor == "Red") {
      mapcolor = Alliance.red;
    }
    matchNumber = widget.matchRecord.matchNumber;
    // Fallback if needed (BotLocation handles defaults in fromJson however)
    // If saving/loading logic is robust, this is fine.
    shootingTime = widget.matchRecord.autonPoints.total_shooting_time;
    amount = widget.matchRecord.autonPoints.amountOfShooting;
    passing = widget.matchRecord.autonPoints.passing;
    autonPoints = AutonPoints(
        shootingTime,
        amount,
        autoClimb,

        passing);
  }

  void UpdateData() {
    autonPoints = AutonPoints(
      shootingTime,
      amount,
      autoClimb,
      passing,
    );

    widget.matchRecord.autonPoints = autonPoints;
    widget.matchRecord.autonPoints.total_shooting_time = shootingTime;
    widget.matchRecord.autonPoints.amountOfShooting = amount;
    widget.matchRecord.autonPoints.climb = autoClimb;
    widget.matchRecord.autonPoints.passing = passing;
    widget.matchRecord.scouterName =
        Hive.box('settings').get('deviceName', defaultValue: '');

    saveState();
  }

  void saveState() {
    LocalDataBase.putData('Auton', autonPoints.toJson());

    log('Auton state saved: ${autonPoints.toCsv()}');
  }

  @override
  void dispose() {
    // Make sure data is saved when navigating away
    UpdateData();
    saveState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: _buildAuto(context));
  }

  Widget _buildAuto(BuildContext context) {
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
          SizedBox(
            height: 8,
          ),
          ScouterList(),
          SizedBox(
            height: 8,
          ),
          TklKeyboard(
            currentTime: shootingTime,
            onChange: (double time) {
              shootingTime = time;
            },
            doChange: () {
              setState(() {
                amount++;
              });

              UpdateData();
            },
            doChangeResetter: () {
              setState(() {
                amount = 0;
                shootingTime = 0.0;
              });
              UpdateData();
            },
            doChangeNoIncrement: () {
              UpdateData();
            },
          ),
          SizedBox(
            height: 8,
          ),

// Total Shooting Cycles counter
          buildCounterFull(
            "Total Shooting Cycles",
            amount,
            (int value) {
              setState(() {
                amount = value;
              });
              UpdateData();
            },
            color: Colors.amber,
          ),
          SizedBox(
            height: 8,
          ),
          buildCounterFull("Passing", passing, (int value) {
            setState(() {
              passing = value;
            });
            UpdateData();
          }, color: Colors.amber),
          SizedBox(
            height: 8,
          ),
          buildCheckBoxFull("Climb", autoClimb, (bool value) {
            setState(() {
              autoClimb = value;
            });
            UpdateData();
          }),
          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}
