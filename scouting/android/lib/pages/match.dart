import 'package:flutter/material.dart';

class Match extends StatefulWidget {
  final String eventKey;
  final String matchKey;
  final String? allianceColor;
  final String? station;
  final Map<String, dynamic> matchData;

  const Match(
      {super.key,
      required this.eventKey,
      required this.matchKey,
      required this.allianceColor,
      required this.station,
      required this.matchData});

  @override
  MatchState createState() => MatchState();
}

class MatchState extends State<Match> {
  int _selectedIndex = 0;
  Offset? _circlePosition;

  // Auto
  int _ampPlacementAuton = 0;
  int _speakerAuton = 0;

  // Teleop
  int allianceWing = 0;
  int centerField = 0;
  int farWing = 0;
  int unamplified = 0;
  int amplified = 0;
  int amp = 0;
  int trap = 0;
  int passed = 0;
  int missed = 0;

  // End Game

  // Functions for Auto
  void _incrementCounterAuton(String type) {
    setState(() {
      switch (type) {
        case 'ampPlacement':
          _ampPlacementAuton++;
          break;
        case 'speaker':
          _speakerAuton++;
          break;
      }
    });
  }

  void _decrementCounterAuton(String type) {
    setState(() {
      switch (type) {
        case 'ampPlacement':
          if (_ampPlacementAuton > 0) _ampPlacementAuton--;
          break;
        case 'speaker':
          if (_speakerAuton > 0) _speakerAuton--;
          break;
      }
    });
  }

  // Functions for Teleop
  void _incrementCounterTeleop(String type) {
    setState(() {
      switch (type) {
        case 'allianceWing':
          allianceWing++;
          break;
        case 'centerField':
          centerField++;
          break;
        case 'farWing':
          farWing++;
          break;
        case 'unamplified':
          unamplified++;
          break;
        case 'amplified':
          amplified++;
          break;
        case 'amp':
          amp++;
          break;
        case 'trap':
          trap++;
          break;
        case 'passed':
          passed++;
          break;
        case 'missed':
          missed++;
          break;
      }
    });
  }

  void _decrementCounterTeleop(String type) {
    setState(() {
      switch (type) {
        case 'allianceWing':
          if (allianceWing > 0) allianceWing--;
          break;
        case 'centerField':
          if (centerField > 0) centerField--;
          break;
        case 'farWing':
          if (farWing > 0) farWing--;
          break;
        case 'unamplified':
          if (unamplified > 0) unamplified--;
          break;
        case 'amplified':
          if (amplified > 0) amplified--;
          break;
        case 'amp':
          if (amp > 0) amp--;
          break;
        case 'trap':
          if (trap > 0) trap--;
          break;
        case 'passed':
          if (passed > 0) passed--;
          break;
        case 'missed':
          if (missed > 0) missed--;
          break;
      }
    });
  }

  // Functions for End Game

  //----------------------------------------------
  void _updatePosition(TapUpDetails details) {
    setState(() {
      _circlePosition = details.localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Page'),
        actions: <Widget>[
          Text("${widget.station}",
              style: const TextStyle(
                fontSize: 20,
              )),
          const SizedBox(width: 10),
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
            widget.allianceColor == "Red" ? Colors.red : Colors.blue,
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
        return Center(child: _auto(context));
      case 1:
        return SingleChildScrollView(child: Row(children: _teleop(context)));
      case 2:
        return Row(children: _endGame(context));
    }
  }

  Widget _auto(BuildContext context) {
    switch (widget.allianceColor) {
      case "Red":
        return SingleChildScrollView(
          child: Column(
            children: _autoBuilder(context, widget.allianceColor,
                widget.matchData, widget.station),
          ),
        );
      case "Blue":
        return SingleChildScrollView(
          child: Column(
            children: _autoBuilder(context, widget.allianceColor,
                widget.matchData, widget.station),
          ),
        );
      default:
        return const Text("Error: Invalid Alliance Color");
    }
  }

  List<Widget> _endGame(BuildContext context) {
    return [];
  }

  List<Widget> _autoBuilder(BuildContext context, String? alliancecolor,
      Map<String, dynamic> matchData, String? station) {
    return [
      Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(children: [
            Text(
                "Assigned Team: ${(matchData["alliances"][alliancecolor?.toLowerCase()]["team_keys"][int.parse(station![1]) - 1]).substring(3)}",
                style: const TextStyle(fontSize: 30, color: Colors.black45)),
          ]),
        ),
      ),
      Container(
          margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            const Text(
              "Starting Position",
              style: TextStyle(fontSize: 30, color: Colors.black45),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTapUp: _updatePosition,
              child: Stack(
                children: [
                  Image.asset(
                      'assets/${alliancecolor}Alliance_StartPosition.png'),
                  if (_circlePosition != null)
                    Positioned(
                      left: _circlePosition!.dx - 10, // Center the circle
                      top: _circlePosition!.dy - 10, // Center the circle
                      child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Image.asset(
                            'assets/Swerve.png',
                          )),
                    ),
                ],
              ),
            ),
          ])),
      Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(children: [
          Row(
            children: [
              Column(
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(180, 180),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                    ),
                    onPressed: () => _incrementCounterAuton('ampPlacement'),
                    child: const Icon(
                      Icons.add,
                      size: 50,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(180, 180),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                    ),
                    onPressed: () => _decrementCounterAuton('ampPlacement'),
                    child: const Icon(
                      Icons.remove,
                      size: 50,
                    ),
                  ),
                  Text('Amp Placement: $_ampPlacementAuton'),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(180, 180),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                    ),
                    onPressed: () => _incrementCounterAuton('speaker'),
                    child: const Icon(
                      Icons.add,
                      size: 50,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(180, 180),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                    ),
                    onPressed: () => _decrementCounterAuton('speaker'),
                    child: const Icon(
                      Icons.remove,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Speaker: $_speakerAuton',
                  ),
                ],
              )
            ],
          ),
        ]),
      ),
    ];
  }

  List<Widget> _teleop(BuildContext context) {
    return [
      Text("data")
    ];
  }

  Widget _SwitchBuilder(String type, String title, int value) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(70, 70),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
          onPressed: () => _incrementCounterTeleop(type),
          child: const Icon(
            Icons.add,
          ),
        ),
        const SizedBox(height: 5),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(70, 70),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
          onPressed: () => _decrementCounterTeleop(type),
          child: const Icon(
            Icons.remove,
          ),
        ),
        const SizedBox(height: 0),
        Text(
          '$title: $value',
        ),
      ],
    );
  }
}

class Results {
  late String matchKey;
  late String eventKey;
  late String allianceColor;
  late String station;
  late String teamKey;
  late String startingPosition;
}
