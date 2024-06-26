import 'package:flutter/material.dart';

class Match extends StatefulWidget {
  final String eventKey;
  final String matchKey;
  final String? allianceColor;
  final String? station;

  const Match({super.key, required this.eventKey, required this.matchKey, required this.allianceColor, required this.station});

  @override
  _MatchState createState() => _MatchState();
}

class _MatchState extends State<Match> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Page'),
      ),
      body: match(context, _selectedIndex),
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
        selectedItemColor: Colors.red,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  match(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return Row( children: auto(context));
      case 1:
        return Row( children: teleop(context));
      case 2:
        return Row( children: endGame(context));
    }
  }

  List<Widget> auto(BuildContext context) {
    return [
        Text("Event Key: ${widget.eventKey} \n"),
        const SizedBox(height: 10,),
        Text("Match Key: ${widget.matchKey} \n"),
        const SizedBox(height: 10,),
        Text("Alliance Color: ${widget.allianceColor} \n"),
        const SizedBox(height: 10,),
        Text("Station: ${widget.station} \n "),
    ];
  }

  List<Widget> teleop(BuildContext context) {
    return [

    ];
  }

  List<Widget> endGame(BuildContext context) {
    return [

    ];
  }



}