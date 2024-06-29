import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class TeleOperated extends StatefulWidget {
  const TeleOperated({Key? key}) : super(key: key);

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  DataMaster dataMaster = DataMaster();
  Offset? _circlePosition;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _teleOp(context),
    );
  }

  void _incrementCounter(MatchType type, dynamic subType, int incrementBy) {
    // Construct the key as a combination of the match type and the specific subtype
    String key = '${type.toString()}_${subType.toString()}';
    dataMaster.incrementCounter(key, incrementBy);
  }

  void _updatePosition(TapUpDetails details) {
    setState(() {
      _circlePosition = details.localPosition;
    });
  }

  Widget _teleOp(BuildContext context) {
    switch (dataMaster.readMatchData(Types.allianceColor)) {
      case "Red":
        return SingleChildScrollView(
          child: Column(
            children: _teleOpBuilder(context),
          ),
        );
      case "Blue":
        return SingleChildScrollView(
          child: Column(
            children: _teleOpBuilder(context),
          ),
        );
      default:
        return const Text("Error: Invalid Alliance Color");
    }
  }

  List<Widget> _teleOpBuilder(BuildContext context) {
    return [
      Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Text(
              "TeleOp",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Power Cells"),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _incrementCounter(MatchType.Teleop, "PowerCells", 1);
                  },
                  child: const Text("+1"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _incrementCounter(MatchType.Teleop, "PowerCells", -1);
                  },
                  child: const Text("-1"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Climb"),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _incrementCounter(MatchType.Teleop, "Climb", 1);
                  },
                  child: const Text("+1"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _incrementCounter(MatchType.Teleop, "Climb", -1);
                  },
                  child: const Text("-1"),
                ),
              ],
            ),

          ],
        ),
      ),

    ];
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

enum Types {
  eventKey,
  matchKey,
  allianceColor,
  selectedStation,
  eventFile,
  matchFile,
}


class DataMaster {
  final storageAgent = Hive.box('ScoutData');
  final matchData = Hive.box('matchData');
  DataMaster();

  putScoutData(dynamic key, dynamic value) {
    if (kDebugMode) {
      print("DataMaster: ${key.toString()}: $value");
    }
    storageAgent.put(key.toString(), value);

  }

  String getScoutData(dynamic key) {
    if (kDebugMode) {
      print("DataMaster: ${key.toString()}");
    }
    return storageAgent.get(key.toString()).toString();
  }



  constructScoutData() {
    if (kDebugMode) {
      print("DataMaster: Constructing Data");
    }
  }

  void incrementCounter(String key, int incrementBy) {
    int currentCount = storageAgent.get(key) ?? 0;
    putScoutData(key, currentCount + incrementBy);
  }

  readMatchData(dynamic key) {
    if (kDebugMode) {
      print("DataMaster: ${key.toString()}");
    }
    return matchData.get(key.toString());

  }
}
