import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Auton extends StatefulWidget {
  const Auton({super.key});

  @override
  AutonState createState() => AutonState();
}

class AutonState extends State<Auton> {
  DataMaster dataMaster = DataMaster();
  Offset? _circlePosition;
  String ampPlacementValue = '0';
  String speakerValue = '0';

  @override
  Widget build(BuildContext context) {
    return Container(child: _auto(context));
  }

  void _updatePosition(TapUpDetails details) {
    setState(() {
      _circlePosition = details.localPosition;
      ampPlacementValue = dataMaster.fetchScoutData(AutoType.AmpPlacement);
      speakerValue = dataMaster.fetchScoutData(AutoType.Speaker);
    });
  }

  Widget _auto(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: _autoBuilder(context),
      ),
    );
  }

  List<Widget> _autoBuilder(BuildContext context) {
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
                // "Assigned Team: ${(matchData["alliances"][alliancecolor?.toLowerCase()]["team_keys"][int.parse(station![1]) - 1]).substring(3)}",
                "Assigned Team: ${
                    (dataMaster.readMatchData(Types.matchFile))['alliances'][(dataMaster.readMatchData(Types.allianceColor).toString().toLowerCase())]
                            ['team_keys'][int.parse((dataMaster.readMatchData(Types.selectedStation)[1])) - 1].substring(3)
                }",
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
                      'assets/${dataMaster.readMatchData(Types.allianceColor)}Alliance_StartPosition.png'),
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
                    onPressed: () => {
                      dataMaster.incrementCounter(AutoType.AmpPlacement, 1),
                      setState(() {
                        ampPlacementValue =
                            dataMaster.fetchScoutData(AutoType.AmpPlacement);
                        speakerValue =
                            dataMaster.fetchScoutData(AutoType.Speaker);
                      }),
                    },
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
                    onPressed: () => {
                      dataMaster.incrementCounter(AutoType.AmpPlacement, -1),
                      setState(() {
                        ampPlacementValue =
                            dataMaster.fetchScoutData(AutoType.AmpPlacement);
                        speakerValue =
                            dataMaster.fetchScoutData(AutoType.Speaker);
                      }),
                    },
                    child: const Icon(
                      Icons.remove,
                      size: 50,
                    ),
                  ),
                  Text(
                      'Amp Placement: ${dataMaster.fetchScoutData(AutoType.AmpPlacement)}'),
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
                    onPressed: () => {
                      dataMaster.incrementCounter(AutoType.Speaker, 1),
                      setState(() {
                        ampPlacementValue =
                            dataMaster.fetchScoutData(AutoType.AmpPlacement);
                        speakerValue =
                            dataMaster.fetchScoutData(AutoType.Speaker);
                      }),
                    },
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
                    onPressed: () => {
                      dataMaster.incrementCounter(AutoType.Speaker, -1),
                      setState(() {
                        ampPlacementValue =
                            dataMaster.fetchScoutData(AutoType.AmpPlacement);
                        speakerValue =
                            dataMaster.fetchScoutData(AutoType.Speaker);
                      }),
                    },
                    child: const Icon(
                      Icons.remove,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Speaker: ${dataMaster.fetchScoutData(AutoType.Speaker)}',
                  ),
                ],
              )
            ],
          ),
        ]),
      ),
    ];
  }
}

enum MatchType { Auto, Teleop, EndGame }

enum AutoType { AmpPlacement, Speaker }

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

  fetchScoutData(AutoType type) {
    if (kDebugMode) {
      print(
          'Fetching $type and returning ${storageAgent.get(type.toString())}');
    }
    return storageAgent.get(type.toString());
  }

  postScoutData(AutoType type, String value) {
    if (kDebugMode) {
      print('Posting $type with value $value');
    }
    storageAgent.put(type.toString(), value);
  }

  getScoutData() {
    if (kDebugMode) {
      print('Getting all scout data');
    }
    return storageAgent.get('AmpPlacement');
  }

  incrementCounter(AutoType type, int incrementBy) {
    int value = int.parse(storageAgent.get(type.toString()) ?? 0);
    value += incrementBy;
    storageAgent.put(type.toString(), value.toString());
    if (kDebugMode) {
      print('Incrementing $type by $incrementBy to $value');
    }
  }

  readMatchData(Types type) {
    return matchData.get(type.toString());
  }
}
