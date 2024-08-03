


import 'package:flutter/material.dart';

import '../components/DataBase.dart';
import 'actions/QrGenerator.dart';
import 'match/Auton.dart';
import 'match/EndGame.dart';
import 'match/TeleOperated.dart';

class Match extends StatefulWidget {
  const Match({super.key});

  @override
  MatchState createState() => MatchState();
}

class MatchState extends State<Match> {
  int _selectedIndex = 0;
  String _allianceColor = "";
  String _selectedStation = "";
  String _team = "";



  @override
  void initState() {
    super.initState();
    _allianceColor = LocalDataBase.getData(Types.allianceColor);
    // _allianceColor = "red";
    _selectedStation = LocalDataBase.getData(Types.selectedStation);
    // _selectedStation = "R1";
    _team = (LocalDataBase.getData(Types.matchFile))['alliances'][_allianceColor.toLowerCase()]['team_keys'][int.parse(_selectedStation.substring(1)) - 1].substring(3).toString();
  }


  @override
  Widget build(BuildContext context) {
    LocalDataBase.putData(Types.team, _team);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Page'),
        actions: <Widget>[
          Text(_selectedStation,
              style: const TextStyle(
                fontSize: 20,
              )),
          const SizedBox(width: 10),
          MaterialButton(
              onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Qrgenerator(),
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
            _allianceColor == "Red" ? Colors.red : Colors.blue,
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
        return const SingleChildScrollView(child: Auton());
      case 1:
        return const SingleChildScrollView(child: TeleOperated());
      case 2:
        return const SingleChildScrollView(child: EndGame());
    }
  }
}





enum Types {
  eventKey,
  matchKey,
  allianceColor,
  selectedStation,
  eventFile,
  matchFile,
  team
}

