
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/pages/components/DataBase.dart';


class EndGame extends StatefulWidget {
  const EndGame({Key? key}) : super(key: key);

  @override
  _EndGameState createState() => _EndGameState();
}

class _EndGameState extends State<EndGame> {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _endGame(context),
    );
  }

  void _incrementCounter(MatchType type, dynamic subType, int incrementBy) {
    // Construct the key as a combination of the match type and the specific subtype
    String key = '${type.toString()}_${subType.toString()}';
    LocalDataBase.incrementCounter(key, incrementBy);
  }

  void _updatePosition(TapUpDetails details) {
    setState(() {
    });
  }

  Widget _endGame(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          width: MediaQuery
              .of(context)
              .size
              .width - 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              children: [
                const Text("Is the robot in the blue stage area?",
                    style: TextStyle(fontSize: 20, color: Colors.black45)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(50),
                              bottomLeft: Radius.circular(50),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Parked'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(50),
                              bottomRight: Radius.circular(50),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('On Stage'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(
                  color: Colors.grey,
                  height: 20,
                  thickness: 2,
                  indent: 50,
                  endIndent: 50,
                ),
                const SizedBox(height: 10),
                const Text("If not On-Stage",
                    style: TextStyle(fontSize: 20, color: Colors.black45)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child:
                        const Text('Robot attempted to climb, but failed'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          width: MediaQuery
              .of(context)
              .size
              .width - 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              children: [
                const Text("How did the team handle notes?",
                    style: TextStyle(fontSize: 20, color: Colors.black45)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Picked up notes from floor'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Fed the note to source'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Passed notes to teammates'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Stashed notes for later use'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          width: MediaQuery
              .of(context)
              .size
              .width - 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              children: [
                const Text("During the match:",
                    style: TextStyle(fontSize: 20, color: Colors.black45)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Robot played defense'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Note got stuck in the robot'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          // Handle button press
                        },
                        child: const Text('Robot broke or was disabled'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}


enum MatchType { Auto, Teleop, EndGame }

enum AutoType { AmpPlacement, Speaker }

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

