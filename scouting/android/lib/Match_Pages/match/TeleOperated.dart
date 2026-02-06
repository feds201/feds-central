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
  late int amount1 = 0;
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

    coralScoreL1 = widget.matchRecord.teleOpPoints.CoralScoringLevel1;
    coralScoreL2 = widget.matchRecord.teleOpPoints.CoralScoringLevel2;
    coralScoreL3 = widget.matchRecord.teleOpPoints.CoralScoringLevel3;
    coralScoreL4 = widget.matchRecord.teleOpPoints.CoralScoringLevel4;
    algaeScoringProcessor =
        widget.matchRecord.teleOpPoints.AlgaeScoringProcessor;
    algaeScoringBarge = widget.matchRecord.teleOpPoints.AlgaeScoringBarge;
    shootingTime1 = widget.matchRecord.teleOpPoints.TotalShootingTime1;
    amount1 = widget.matchRecord.teleOpPoints.TotalAmount1;
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

    algaePickUp = widget.matchRecord.teleOpPoints.AlgaePickUp;

    teleOpPoints = TeleOpPoints(
      coralScoreL1,
      coralScoreL2,
      coralScoreL3,
      coralScoreL4,
      algaeScoringBarge,
      algaeScoringProcessor,
      algaePickUp,
      shootingTime1,
      amount1,
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
      coralScoreL1,
      coralScoreL2,
      coralScoreL3,
      coralScoreL4,
      algaeScoringBarge,
      algaeScoringProcessor,
      algaePickUp,
      shootingTime1,
      amount1,
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
    widget.matchRecord.teleOpPoints.CoralScoringLevel1 = coralScoreL1;
    widget.matchRecord.teleOpPoints.CoralScoringLevel2 = coralScoreL2;
    widget.matchRecord.teleOpPoints.CoralScoringLevel3 = coralScoreL3;
    widget.matchRecord.teleOpPoints.CoralScoringLevel4 = coralScoreL4;
    widget.matchRecord.teleOpPoints.AlgaeScoringProcessor =
        algaeScoringProcessor;
    widget.matchRecord.teleOpPoints.AlgaeScoringBarge = algaeScoringBarge;
    widget.matchRecord.teleOpPoints.AlgaePickUp = algaePickUp;
    widget.matchRecord.teleOpPoints.Defense = defense;
    widget.matchRecord.teleOpPoints.TotalShootingTime1 = shootingTime1;
    widget.matchRecord.teleOpPoints.TotalAmount1 = amount1;
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

    // log('TeleOp state saved: $teleOpPoints');
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
        _buildPhasePlaceholder("Transition"),
        TklKeyboard(
          currentTime: shootingTime1,
          onChange: (double time) {
            shootingTime1 = time;
          },
          doChange: () {
            amount1++;
            UpdateData();
          },
          doChangeResetter: () {
            amount1 = 0;
            shootingTime1 = 0.0;
            UpdateData();
          },
          doChangenakedversion: () {
            UpdateData();
          },
        ),
        buildCounterShelf([
          CounterSettings((number) {
            setState(() {
              amount1++;
              UpdateData();
            });
          }, (number) {
            setState(() {
              amount1--;
              UpdateData();
            });
          },
              icon: Icons.import_contacts,
              number: amount1,
              counterText: 'Total Shooting Cycles',
              color: Colors.black12)
        ]),
        buildCounter(
          "Trips to Neutral Zone",
          neutralTrips,
          (int value) {
            setState(() {
              neutralTrips = value;
            });
          },
          color: Colors.amber,
        ),
        Row(
          children: [
            Expanded(
              child: buildCheckBoxHalf("Feed to HP Station", feedtoHPStation,
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
        _buildPhasePlaceholder("Active 1"),
        TklKeyboard(
          currentTime: shootingTime1,
          onChange: (double time) {
            shootingTime1 = time;
          },
          doChange: () {
            amountA1++;
            UpdateData();
          },
          doChangeResetter: () {
            amountA1 = 0;
            shootingTime1 = 0.0;
            UpdateData();
          },
          doChangenakedversion: () {
            UpdateData();
          },
        ),
        buildCounterShelf([
          CounterSettings((number) {
            setState(() {
              amountA1++;
              UpdateData();
            });
          }, (number) {
            setState(() {
              amountA1--;
              UpdateData();
            });
          },
              icon: Icons.import_contacts,
              number: amountA1,
              counterText: 'Total Shooting Cycles',
              color: Colors.black12)
        ]),
        buildCounter(
          "Trips to Neutral Zone",
          neutralTripsA1,
          (int value) {
            setState(() {
              neutralTripsA1 = value;
            });
          },
          color: Colors.amber,
        ),
        Row(
          children: [
            Expanded(
              child: buildCheckBoxHalf("Feed to HP Station", feedtoHPStationA1,
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
        _buildPhasePlaceholder("Active 2"),
        TklKeyboard(
          currentTime: shootingTime1,
          onChange: (double time) {
            shootingTime1 = time;
          },
          doChange: () {
            amountA2++;
            UpdateData();
          },
          doChangeResetter: () {
            amountA2 = 0;
            shootingTime1 = 0.0;
            UpdateData();
          },
          doChangenakedversion: () {
            UpdateData();
          },
        ),
        buildCounterShelf([
          CounterSettings((number) {
            setState(() {
              amountA2++;
              UpdateData();
            });
          }, (number) {
            setState(() {
              amountA2--;
              UpdateData();
            });
          },
              icon: Icons.import_contacts,
              number: amountA2,
              counterText: 'Total Shooting Cycles',
              color: Colors.black12)
        ]),
        buildCounter(
          "Trips to Neutral Zone",
          neutralTripsA2,
          (int value) {
            setState(() {
              neutralTripsA2 = value;
            });
          },
          color: Colors.amber,
        ),
        Row(
          children: [
            Expanded(
              child: buildCheckBoxHalf("Feed to HP Station", feedtoHPStationA2,
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
        _buildPhasePlaceholder("Inactive 1"),
        buildCounter(
          "Trips to Neutral Zone",
          neutralTripsI1,
          (int value) {
            setState(() {
              neutralTripsI1 = value;
            });
          },
          color: Colors.amber,
        ),
        Row(
          children: [
            Expanded(
              child: buildCheckBoxHalf("Feed to HP Station", feedtoHPStationI1,
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
        _buildPhasePlaceholder("Inactive 2"),
        buildCounter(
          "Trips to Neutral Zone",
          neutralTripsI2,
          (int value) {
            setState(() {
              neutralTripsI2 = value;
            });
          },
          color: Colors.amber,
        ),
        Row(
          children: [
            Expanded(
              child: buildCheckBoxHalf("Feed to HP Station", feedtoHPStationI2,
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
        buildCheckBoxFull("Defense", defenseI2, (bool value) {
          setState(() {
            defenseI2 = value;
          });
          UpdateData();
        }),
      ],
    );
  }

  Widget _buildPhasePlaceholder(String label) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
