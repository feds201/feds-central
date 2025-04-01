import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';

import '../Experiment/ExpStateManager.dart';
import '../services/DataBase.dart';
import '../components/QrGenerator.dart';
import 'match/Auton.dart';
import 'match/EndGame.dart';
import 'match/TeleOperated.dart';

class Match extends StatefulWidget {
  final MatchRecord matchRecord;
  const Match({super.key, required this.matchRecord});

  @override
  MatchState createState() => MatchState();
}

class MatchState extends State<Match> {
  int _selectedIndex = 0;
  String _allianceColor = "";
  String _selectedStation = "";
  bool isExperimentBoxOpen = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkExperimentBox() async {
    bool isOpen = await isExperimentBoxOpenFunc();
    setState(() {
      isExperimentBoxOpen = isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(widget.matchRecord);
    return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor:
                islightmode() ? Colors.white : darkColors.goodblack,
            leading: Container(
                margin: const EdgeInsets.only(left: 20, top: 15),
                child: Text(_selectedStation,
                    style: const TextStyle(
                      fontSize: 20,
                    ))),
            title: ShaderMask(
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
                              builder: (context) =>
                                  Qrgenerator(matchRecord: widget.matchRecord),
                              fullscreenDialog: true),
                        ).then((value) => _checkExperimentBox()),
                      },
                  child: const Icon(
                    Icons.check_rounded,
                    size: 30,
                  )),
            ],
          ),
          body: _match(context, _selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor:
                islightmode() ? Colors.white : darkColors.goodblack,
            unselectedItemColor: islightmode() ? Colors.black : Colors.white,
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
        ));
  }

  _match(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return SingleChildScrollView(
            child: Auton(
          matchRecord: widget.matchRecord,
        ));
      case 1:
        return SingleChildScrollView(
            child: TeleOperated(
          matchRecord: widget.matchRecord,
        ));
      case 2:
        return SingleChildScrollView(
            child: EndGame(
          matchRecord: widget.matchRecord,
        ));
      default:
        return Container();
    }
  }

  @override
  void dispose() {
    super.dispose();
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
  final ExpStateManager stateManager = ExpStateManager();
  Map<String, bool> states = await stateManager.loadAllPluginStates([
    'templateStudioEnabled',
  ]);
  return states['templateStudioEnabled'];
}
