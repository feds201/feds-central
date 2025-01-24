import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Experiment/ExpStateManager.dart';
import '../components/DataBase.dart';
import '../components/QrGenerator.dart';
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
  bool isExperimentBoxOpen = false;

  @override
  void initState() {
    super.initState();
    print(LocalDataBase.getData(Types.allianceColor));
    _allianceColor = LocalDataBase.getData(Types.allianceColor);
    _selectedStation = LocalDataBase.getData(Types.selectedStation);
    _team = (LocalDataBase.getData(Types.matchFile))['alliances']
                [_allianceColor.toLowerCase()]['team_keys']
            [int.parse(_selectedStation.substring(1)) - 1]
        .substring(3)
        .toString();
    _checkExperimentBox();
  }

  Future<void> _checkExperimentBox() async {
    bool isOpen = await isExperimentBoxOpenFunc();
    setState(() {
      isExperimentBoxOpen = isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    LocalDataBase.putData(Types.team, _team);

    return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
        leading:  Container(
          margin: const EdgeInsets.only(left: 20, top: 15),
            child: Text(_selectedStation,
            style: const TextStyle(
              fontSize: 20,

            ))),
        title:
        ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.red, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              _selectedIndex == 0
                  ? 'Autonomous'
                  : _selectedIndex == 1
                      ? 'Tele Operated'
                      : 'End Game',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),

            )),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: <Widget>[

          const SizedBox(width: 10),
          MaterialButton(
              onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                              builder: (context) => const Qrgenerator(),
                              fullscreenDialog: true),
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
        selectedItemColor: _allianceColor == "Red" ? Colors.red : Colors.blue,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
        ));
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

isExperimentBoxOpenFunc() async {
  final ExpStateManager _stateManager = ExpStateManager();
  Map<String, bool> states = await _stateManager.loadAllPluginStates([
    'templateStudioEnabled',
  ]);
  return states['templateStudioEnabled'];
}
