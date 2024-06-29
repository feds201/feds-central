import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/pages/match/EndGame.dart';
import 'package:scouting_app/pages/match/TeleOperated.dart';
import 'actions/QrGenerator.dart';
import 'Match/Auton.dart';
class Match extends StatefulWidget {
  const Match({super.key});

  @override
  MatchState createState() => MatchState();
}

class MatchState extends State<Match> {
  int _selectedIndex = 0;
  DataMaster dataMaster = DataMaster();





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Page'),
        actions: <Widget>[
          Text("${dataMaster.readMatchData(Types.selectedStation)}",
              style: const TextStyle(
                fontSize: 20,
              )),
          const SizedBox(width: 10),
          MaterialButton(
              onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Qrgenerator(ScoutData: {}),
                      ),
                    ).then((value) => print('Returned to Match Page'))
                  },
              child: const Icon(
                Icons.check_rounded,
                size: 30,
              )),
        ],
      ),
      body: _match(context, _selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Auto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Teleop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: 'End Game',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            dataMaster.readMatchData(Types.allianceColor) == "Red" ? Colors.red : Colors.blue,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
  _match(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return const Center(child: Auton());
      case 1:
        return const SingleChildScrollView(child: TeleOperated());
      case 2:
        return const SingleChildScrollView(child: EndGame());
    }
  }
}

enum MatchType { Auto, Teleop, EndGame }



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
