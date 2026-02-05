import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/components/ScoutersList.dart';
import 'package:scouting_app/components/gameSpecifics/winAfterAuton.dart';

import '../../components/TeamInfo.dart';
import '../../components/gameSpecifics/timer.dart';
import '../../services/DataBase.dart';
import '../../components/gameSpecifics/heatmap.dart';

class Auton extends StatefulWidget {
  final MatchRecord matchRecord;
  const Auton({super.key, required this.matchRecord});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<Auton> {
  late bool left_startingLocation;
  late bool depot;
  late bool outPost;
  late bool zone;
  late bool autoClimb;
  // late BotLocation startingBotLocations;
  late String winAfterAuton;
  late double shootingTime;
  late AutonPoints autonPoints;
  late int amount = 0;
  late String assignedTeam;
  late int assignedStation;
  late String matchKey;
  late String allianceColor;
  late int matchNumber;
  late Alliance mapcolor;
  final GlobalKey<SinglePointSelectorState> _tapSelectorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    //   log(widget.matchRecord.toString());
    depot = false;
    outPost = false;
    zone = false;
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
    // startingBotLocations = BotLocation(Offset(200, 200), Size(2000, 2000), 45);
    left_startingLocation =
        widget.matchRecord.autonPoints.left_starting_position;
    depot = widget.matchRecord.autonPoints.fuel_pickup_from_Depot;
    outPost = widget.matchRecord.autonPoints.fuel_pickup_from_Outpost;
    zone = widget.matchRecord.autonPoints.fuel_pickup_from_Neutral_Zone;
    autoClimb = widget.matchRecord.autonPoints.climb;
    winAfterAuton = widget.matchRecord.autonPoints.winAfterAuton;
    shootingTime = widget.matchRecord.autonPoints.total_shooting_time;
    amount = widget.matchRecord.autonPoints.amountOfShooting;
    left_startingLocation = false;

    autonPoints = AutonPoints(depot, outPost, zone, shootingTime, amount,
        autoClimb, winAfterAuton, left_startingLocation);
  }

  // startingBotLocations,
  // left_startingLocation,
  void UpdateData() {
    autonPoints = AutonPoints(
      depot,
      outPost,
      zone,
      shootingTime,
      amount,
      autoClimb,
      winAfterAuton,
      left_startingLocation,
      // startingBotLocations,
    );

    widget.matchRecord.autonPoints = autonPoints;
    widget.matchRecord.autonPoints.left_starting_position =
        left_startingLocation;
    widget.matchRecord.autonPoints.fuel_pickup_from_Depot = depot;
    widget.matchRecord.autonPoints.fuel_pickup_from_Outpost = outPost;
    widget.matchRecord.autonPoints.fuel_pickup_from_Neutral_Zone = zone;
    widget.matchRecord.autonPoints.total_shooting_time = shootingTime;
    widget.matchRecord.autonPoints.amountOfShooting = amount;
    widget.matchRecord.autonPoints.winAfterAuton = winAfterAuton;
    widget.matchRecord.autonPoints.climb = autoClimb;
    // widget.matchRecord.autonPoints.starting_location = startingBotLocations;
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
          ScouterList(),
          SinglePointSelector(
            key: _tapSelectorKey,
            blueAllianceImagePath: 'assets/2026/BlueAlliance_StartPosition.png',
            redAllianceImagePath: 'assets/2026/RedAlliance_StartPosition.png',
            alliance: mapcolor,
            onPointSelected: (imageSize, point) {
              log('Tap at x=${point.dx}, y=${point.dy} on image width=${imageSize.width}, height=${imageSize.height}');
            },
          ),
          buildCheckBoxFull("Leave", left_startingLocation, (bool value) {
            setState(() {
              left_startingLocation = value;
            });
            UpdateData();
          }),
          Row(
            children: [
              buildCheckBox("Depot", depot, (bool value) {
                setState(() {
                  depot = value;
                });
                UpdateData();
              }),
              buildCheckBox("Outpost", outPost, (bool value) {
                setState(() {
                  outPost = value;
                });
                UpdateData();
              }),
            ],
          ),
          TklKeyboard(
            currentTime: shootingTime,
            onChange: (double time) {
              setState(() {
                shootingTime = time;
              });
            },
            doChange: () {
              amount++;
              UpdateData();
            },
            doChangeResetter: () {
              amount = 0;
              shootingTime = 0.0;
              UpdateData();
            },
            doChangenakedversion: () {
              UpdateData();
            },
          ),
          buildCounterShelf([
            CounterSettings((number) {
              setState(() {
                amount++;
                UpdateData();
              });
            }, (number) {
              setState(() {
                amount--;
                UpdateData();
              });
            },
                icon: Icons.import_contacts,
                number: amount,
                counterText: 'Total Shooting Cycles',
                color: Colors.black12)
          ]),
          buildCheckBoxFull("Grabbed Balls From Neutral Zone", zone,
              (bool value) {
            setState(() {
              zone = value;
            });
            UpdateData();
          }),
          buildCheckBoxFull("Climb", autoClimb, (bool value) {
            setState(() {
              autoClimb = value;
            });
            UpdateData();
          }),
          buildWinner(context, (String winner) {
            setState(() {
              winAfterAuton = winner;
            });
            UpdateData();
          }, winAfterAuton),
        ],
      ),
    );
  }
}
