import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:scout_ops_android/components/CheckBox.dart';
// import 'package:scout_ops_android/components/CommentBox.dart';
import 'package:scout_ops_android/components/CounterShelf.dart';
import 'package:scout_ops_android/components/gameSpecifics/timer.dart';

// import 'package:scout_ops_android/main.dart';
import '../../components/CheckBox.dart';
import '../../components/TeamInfo.dart';
import '../../services/DataBase.dart';

class TeleOperated extends StatefulWidget {
  final MatchRecord matchRecord;
  const TeleOperated({super.key, required this.matchRecord});

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  late double shootingTime1;
  late int amount = 0;
  late bool defense;
  late int neutralTrips = 0;
  late int pushBalls = 0;
  late int passing;
  int _selectedPhase = 0;
  late String assignedTeam;
  late int assignedStation;
  late String matchKey;
  late String allianceColor;
  late int matchNumber;

  late TeleOpPoints teleOpPoints;

  @override
  void initState() {
    super.initState();
    // log(widget.matchRecord.toString());
    assignedTeam = widget.matchRecord.teamNumber;
    assignedStation = widget.matchRecord.station;
    matchKey = widget.matchRecord.matchKey;
    allianceColor = widget.matchRecord.allianceColor;
    shootingTime1 = widget.matchRecord.teleOpPoints.TotalShootingTime1;
    amount = widget.matchRecord.teleOpPoints.TotalAmount1;
    defense = widget.matchRecord.teleOpPoints.Defense;
    neutralTrips = widget.matchRecord.teleOpPoints.NeutralTrips;
    pushBalls = widget.matchRecord.teleOpPoints.PushBalls;
    passing = widget.matchRecord.teleOpPoints.passing;

    teleOpPoints = TeleOpPoints(
      shootingTime1,
      amount,
      defense,
      neutralTrips,
      pushBalls,
      passing,
    );
    // log('TeleOp initialized: $teleOpPoints');
  }

  void UpdateData() {
    teleOpPoints = TeleOpPoints(
      shootingTime1,
      amount,
      defense,
      neutralTrips,
      pushBalls,
      passing,
    );

    widget.matchRecord.teleOpPoints.Defense = defense;
    widget.matchRecord.teleOpPoints.TotalShootingTime1 = shootingTime1;
    widget.matchRecord.teleOpPoints.TotalAmount1 = amount;
    widget.matchRecord.teleOpPoints.NeutralTrips = neutralTrips;
    widget.matchRecord.teleOpPoints.PushBalls = pushBalls;
    widget.matchRecord.teleOpPoints.passing = passing;

    saveState();
  }

  void saveState() {
    LocalDataBase.putData('TeleOp', teleOpPoints.toJson());

    log('TeleOp state saved: ${teleOpPoints.toCsv()}');
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
    // print(LocalDataBase.getData('Settings.apiKey'));
    return Column(children: [
      MatchInfo(
        assignedTeam: assignedTeam,
        assignedStation: assignedStation,
        allianceColor: allianceColor,
        onPressed: () {
          // print('Team Info START button pressed');
        },
      ),
      IndexedStack(
        index: _selectedPhase,
        children: [
          _buildTransitionPhase(),
        ],
      ),
    ]);
  }

  Widget _buildTransitionPhase() {
    return Column(
      children: [
        TklKeyboard(
          currentTime: shootingTime1,
          onChange: (double time) {
            shootingTime1 = time;
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
              shootingTime1 = 0.0;
            });
            UpdateData();
          },
          doChangeNoIncrement: () {
            UpdateData();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: buildCounter("Shooting Cycle", amount, (int value) {
                  setState(() {
                    amount = value;
                  });
                  UpdateData();
                }, color: Colors.yellow),
              ),
              Expanded(
                child: buildCounter("Neutral Trips", neutralTrips, (int value) {
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
                child: buildCounter("Pushing Balls", pushBalls, (int value) {
                  setState(() {
                    pushBalls = value;
                  });
                  UpdateData();
                }, color: Colors.yellow),
              ),
              Expanded(
                child: buildCounter("Passing", passing, (int value) {
                  setState(() {
                    passing = value;
                  });
                  UpdateData();
                }, color: Colors.yellow),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        buildCheckBoxFull("Defense", defense, (bool value) {
          setState(() {
            defense = value;
          });
          UpdateData();
        }),
      ],
    );
  }
}
