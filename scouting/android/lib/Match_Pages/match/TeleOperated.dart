import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:scouting_app/components/CheckBox.dart';
// import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/components/gameSpecifics/timer.dart';

// import 'package:scouting_app/main.dart';
import '../../components/CheckBox.dart';
import '../../components/TeamInfo.dart';
import '../../components/gameSpecifics/PhaseSelection.dart';
import '../../services/DataBase.dart';

class TeleOperated extends StatefulWidget {
  final MatchRecord matchRecord;
  const TeleOperated({super.key, required this.matchRecord});

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  late int coralScoreL1;
  late int coralScoreL2;
  late int coralScoreL3;
  late int coralScoreL4;
  late int algaePickUp;
  late int algaeScoringProcessor;
  late int algaeScoringBarge;
  late double shootingTime1;
  late double shootingTimeA1;
  late double shootingTimeA2;
  late double shootingTimeI1;
  late double shootingTimeI2;
  late int amount = 0;
  late int amountA1 = 0;
  late int amountA2 = 0;
  late int amountI1 = 0;
  late int amountI2 = 0;
  late int tripAmount1 = 0;
  late bool defense;
  late bool defenseA1;
  late bool defenseA2;
  late bool defenseI1;
  late bool defenseI2;
  late int neutralTrips = 0;
  late int neutralTripsA1 = 0;
  late int neutralTripsA2 = 0;
  late int neutralTripsI1 = 0;
  late int neutralTripsI2 = 0;
  late bool feedtoHPStation,
      feedtoHPStationA1,
      feedtoHPStationA2,
      feedtoHPStationI1,
      feedtoHPStationI2;
  late bool passing, passingA1, passingA2, passingI1, passingI2;
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
    shootingTimeA1 = widget.matchRecord.teleOpPoints.TotalShootingTimeA1;
    shootingTimeA2 = widget.matchRecord.teleOpPoints.TotalShootingTimeA2;
    shootingTimeI1 = widget.matchRecord.teleOpPoints.TotalShootingTimeI1;
    shootingTimeI2 = widget.matchRecord.teleOpPoints.TotalShootingTimeI2;
    amount = widget.matchRecord.teleOpPoints.TotalAmount1;
    amountA1 = widget.matchRecord.teleOpPoints.TotalAmountA1;
    amountA2 = widget.matchRecord.teleOpPoints.TotalAmountA2;
    amountI1 = widget.matchRecord.teleOpPoints.TotalAmountI1;
    amountI2 = widget.matchRecord.teleOpPoints.TotalAmountI2;
    tripAmount1 = widget.matchRecord.teleOpPoints.TripAmount1;
    defense = widget.matchRecord.teleOpPoints.Defense;
    defenseA1 = widget.matchRecord.teleOpPoints.DefenseA1;
    defenseA2 = widget.matchRecord.teleOpPoints.DefenseA2;
    defenseI1 = widget.matchRecord.teleOpPoints.DefenseI1;
    defenseI2 = widget.matchRecord.teleOpPoints.DefenseI2;
    neutralTrips = widget.matchRecord.teleOpPoints.NeutralTrips;
    neutralTripsA1 = widget.matchRecord.teleOpPoints.NeutralTripsA1;
    neutralTripsA2 = widget.matchRecord.teleOpPoints.NeutralTripsA2;
    neutralTripsI1 = widget.matchRecord.teleOpPoints.NeutralTripsI1;
    neutralTripsI2 = widget.matchRecord.teleOpPoints.NeutralTripsI2;
    feedtoHPStation = widget.matchRecord.teleOpPoints.FeedToHPStation;
    feedtoHPStationA1 = widget.matchRecord.teleOpPoints.FeedToHPStationA1;
    feedtoHPStationA2 = widget.matchRecord.teleOpPoints.FeedToHPStationA2;
    feedtoHPStationI1 = widget.matchRecord.teleOpPoints.FeedToHPStationI1;
    feedtoHPStationI2 = widget.matchRecord.teleOpPoints.FeedToHPStationI2;
    passing = widget.matchRecord.teleOpPoints.passing;
    passingA1 = widget.matchRecord.teleOpPoints.passingA1;
    passingA2 = widget.matchRecord.teleOpPoints.passingA2;
    passingI1 = widget.matchRecord.teleOpPoints.passingI1;
    passingI2 = widget.matchRecord.teleOpPoints.passingI2;

    teleOpPoints = TeleOpPoints(
      shootingTime1,
      shootingTimeA1,
      shootingTimeA2,
      shootingTimeI1,
      shootingTimeI2,
      amount,
      amountA1,
      amountA2,
      amountI1,
      amountI2,
      tripAmount1,
      defense,
      defenseA1,
      defenseA2,
      defenseI1,
      defenseI2,
      neutralTrips,
      neutralTripsA1,
      neutralTripsA2,
      neutralTripsI1,
      neutralTripsI2,
      feedtoHPStation,
      feedtoHPStationA1,
      feedtoHPStationA2,
      feedtoHPStationI1,
      feedtoHPStationI2,
      passing,
      passingA1,
      passingA2,
      passingI1,
      passingI2,
    );
    // log('TeleOp initialized: $teleOpPoints');
  }

  void UpdateData() {
    teleOpPoints = TeleOpPoints(
      shootingTime1,
      shootingTimeA1,
      shootingTimeA2,
      shootingTimeI1,
      shootingTimeI2,
      amount,
      amountA1,
      amountA2,
      amountI1,
      amountI2,
      tripAmount1,
      defense,
      defenseA1,
      defenseA2,
      defenseI1,
      defenseI2,
      neutralTrips,
      neutralTripsA1,
      neutralTripsA2,
      neutralTripsI1,
      neutralTripsI2,
      feedtoHPStation,
      feedtoHPStationA1,
      feedtoHPStationA2,
      feedtoHPStationI1,
      feedtoHPStationI2,
      passing,
      passingA1,
      passingA2,
      passingI1,
      passingI2,
    );

    widget.matchRecord.teleOpPoints.Defense = defense;
    widget.matchRecord.teleOpPoints.TotalShootingTime1 = shootingTime1;
    widget.matchRecord.teleOpPoints.TotalShootingTimeA1 = shootingTimeA1;
    widget.matchRecord.teleOpPoints.TotalShootingTimeA2 = shootingTimeA2;
    widget.matchRecord.teleOpPoints.TotalShootingTimeI1 = shootingTimeI1;
    widget.matchRecord.teleOpPoints.TotalShootingTimeI2 = shootingTimeI2;
    widget.matchRecord.teleOpPoints.TotalAmount1 = amount;
    widget.matchRecord.teleOpPoints.TotalAmountA1 = amountA1;
    widget.matchRecord.teleOpPoints.TotalAmountA2 = amountA2;
    widget.matchRecord.teleOpPoints.TotalAmountI1 = amountI1;
    widget.matchRecord.teleOpPoints.TotalAmountI2 = amountI2;
    widget.matchRecord.teleOpPoints.NeutralTrips = neutralTrips;
    widget.matchRecord.teleOpPoints.NeutralTripsA1 = neutralTripsA1;
    widget.matchRecord.teleOpPoints.NeutralTripsA2 = neutralTripsA2;
    widget.matchRecord.teleOpPoints.NeutralTripsI1 = neutralTripsI1;
    widget.matchRecord.teleOpPoints.NeutralTripsI2 = neutralTripsI2;
    widget.matchRecord.teleOpPoints.FeedToHPStation = feedtoHPStation;
    widget.matchRecord.teleOpPoints.FeedToHPStationA1 = feedtoHPStationA1;
    widget.matchRecord.teleOpPoints.FeedToHPStationA2 = feedtoHPStationA2;
    widget.matchRecord.teleOpPoints.FeedToHPStationI1 = feedtoHPStationI1;
    widget.matchRecord.teleOpPoints.FeedToHPStationI2 = feedtoHPStationI2;
    widget.matchRecord.teleOpPoints.passing = passing;
    widget.matchRecord.teleOpPoints.passingA1 = passingA1;
    widget.matchRecord.teleOpPoints.passingA2 = passingA2;
    widget.matchRecord.teleOpPoints.passingI1 = passingI1;
    widget.matchRecord.teleOpPoints.passingI2 = passingI2;
    widget.matchRecord.teleOpPoints.TripAmount1 = tripAmount1;

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
      buildPhaseSelection(context, (int shift) {
        setState(() {
          _selectedPhase = shift;
        });
      }, _selectedPhase),
      IndexedStack(
        index: _selectedPhase,
        children: [
          _buildTransitionPhase(),
          _buildActive1Phase(),
          _buildActive2Phase(),
          _buildInactive1Phase(),
          _buildInactive2Phase(),
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
                child: buildCheckBoxHalf("Feed to HP", feedtoHPStation,
                    (bool value) {
                  setState(() {
                    feedtoHPStation = value;
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

  Widget _buildActive1Phase() {
    return Column(
      children: [
        TklKeyboard(
          currentTime: shootingTimeA1,
          onChange: (double time) {
            shootingTimeA1 = time;
          },
          doChange: () {
            setState(() {
              amountA1++;
            });
            UpdateData();
          },
          doChangeResetter: () {
            setState(() {
              amountA1 = 0;
              shootingTimeA1 = 0.0;
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
                child: buildCounter("Shooting Cycle", amountA1, (int value) {
                  setState(() {
                    amountA1 = value;
                  });
                  UpdateData();
                }, color: Colors.yellow),
              ),
              Expanded(
                child:
                    buildCounter("Neutral Trips", neutralTripsA1, (int value) {
                  setState(() {
                    neutralTripsA1 = value;
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
                child: buildCheckBoxHalf("Feed to HP", feedtoHPStationA1,
                    (bool value) {
                  setState(() {
                    feedtoHPStationA1 = value;
                  });
                  UpdateData();
                }),
              ),
              Expanded(
                child: buildCheckBoxHalf("Passing", passingA1, (bool value) {
                  setState(() {
                    passingA1 = value;
                  });
                  UpdateData();
                }),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        buildCheckBoxFull("Defense", defenseA1, (bool value) {
          setState(() {
            defenseA1 = value;
          });
          UpdateData();
        }),
      ],
    );
  }

  Widget _buildActive2Phase() {
    return Column(
      children: [
        TklKeyboard(
          currentTime: shootingTimeA2,
          onChange: (double time) {
            shootingTimeA2 = time;
          },
          doChange: () {
            setState(() {
              amountA2++;
            });
            UpdateData();
          },
          doChangeResetter: () {
            setState(() {
              amountA2 = 0;
              shootingTimeA2 = 0.0;
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
                child: buildCounter("Shooting Cycle", amountA2, (int value) {
                  setState(() {
                    amountA2 = value;
                  });
                  UpdateData();
                }, color: Colors.yellow),
              ),
              Expanded(
                child:
                    buildCounter("Neutral Trips", neutralTripsA2, (int value) {
                  setState(() {
                    neutralTripsA2 = value;
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
                child: buildCheckBoxHalf("Feed to HP", feedtoHPStationA2,
                    (bool value) {
                  setState(() {
                    feedtoHPStationA2 = value;
                  });
                  UpdateData();
                }),
              ),
              Expanded(
                child: buildCheckBoxHalf("Passing", passingA2, (bool value) {
                  setState(() {
                    passingA2 = value;
                  });
                  UpdateData();
                }),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        buildCheckBoxFull("Defense", defenseA2, (bool value) {
          setState(() {
            defenseA2 = value;
          });
          UpdateData();
        }),
      ],
    );
  }

  Widget _buildInactive1Phase() {
    return Column(
      children: [
        TklKeyboard(
          currentTime: shootingTimeI1,
          onChange: (double time) {
            shootingTimeI1 = time;
          },
          doChange: () {
            setState(() {
              amountI1++;
            });
            UpdateData();
          },
          doChangeResetter: () {
            setState(() {
              amountI1 = 0;
              shootingTimeI1 = 0.0;
            });
            UpdateData();
          },
          doChangeNoIncrement: () {
            UpdateData();
          },
        ),
        SizedBox(height: 8),
        buildCounterFull("Neutral Trips", neutralTripsI1, (int value) {
          setState(() {
            neutralTripsI1 = value;
          });
          UpdateData();
        }, color: Colors.yellow),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: buildCheckBoxHalf("Feed to HP", feedtoHPStationI1,
                    (bool value) {
                  setState(() {
                    feedtoHPStationI1 = value;
                  });
                  UpdateData();
                }),
              ),
              Expanded(
                child: buildCheckBoxHalf("Passing", passingI1, (bool value) {
                  setState(() {
                    passingI1 = value;
                  });
                  UpdateData();
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        buildCheckBoxFull("Defense", defenseI1, (bool value) {
          setState(() {
            defenseI1 = value;
          });
          UpdateData();
        }),
      ],
    );
  }

  Widget _buildInactive2Phase() {
    return Column(
      children: [
        TklKeyboard(
          currentTime: shootingTimeI2,
          onChange: (double time) {
            shootingTimeI2 = time;
          },
          doChange: () {
            setState(() {
              amountI2++;
            });
            UpdateData();
          },
          doChangeResetter: () {
            setState(() {
              amountI2 = 0;
              shootingTimeI2 = 0.0;
            });
            UpdateData();
          },
          doChangeNoIncrement: () {
            UpdateData();
          },
        ),
        SizedBox(height: 8),
        buildCounterFull("Neutral Trips", neutralTripsI2, (int value) {
          setState(() {
            neutralTripsI2 = value;
          });
          UpdateData();
        }, color: Colors.yellow),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: buildCheckBoxHalf("Feed to HP", feedtoHPStationI2,
                    (bool value) {
                  setState(() {
                    feedtoHPStationI2 = value;
                  });
                  UpdateData();
                }),
              ),
              Expanded(
                child: buildCheckBoxHalf("Passing", passingI2, (bool value) {
                  setState(() {
                    passingI2 = value;
                  });
                  UpdateData();
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        buildCheckBoxFull("Defense", defenseI2, (bool value) {
          setState(() {
            defenseI2 = value;
          });
          UpdateData();
        }),
      ],
    );
  }
}
