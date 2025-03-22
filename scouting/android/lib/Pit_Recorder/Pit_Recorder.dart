import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/Pit_Recorder/Send_Pitdata.dart';
import 'package:scouting_app/services/DataBase.dart';

import 'CheckLists.dart';

class PitRecorder extends StatefulWidget {
  const PitRecorder({super.key});

  @override
  PitRecorderState createState() => PitRecorderState();
}

class PitRecorderState extends State<PitRecorder> {
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  List<int> _recorded_team = [];

  @override
  void initState() {
    _recorded_team = PitDataBase.GetRecorderTeam();
    super.initState();
    _fetchTeams();
    Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        _recorded_team = PitDataBase.GetRecorderTeam();
      });
    });
  }

  void _filterTeams(String query) {
    setState(() {
      _filteredTeams = _teams
          .where((team) =>
              team.nickname.toLowerCase().contains(query.toLowerCase()) ||
              team.teamNumber.toString().contains(query))
          .toList();
    });
  }

  void _selectTeam(BuildContext context, Team team) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Record(team: team), fullscreenDialog: true),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Error',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'An error occurred while loading teams: $errorMessage\n\n'
              'To resolve this issue, please navigate to Settings > Load Match, '
              'enter the event key, and press Load Event. If the indicator turns green, '
              'you can return to the home screen and try again.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchTeams();
              },
              child: Text(
                'Retry',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _fetchTeams() async {
    try {
      List<Team> teams = await fetchTeams();
      setState(() {
        _teams = teams;
        _filteredTeams = teams;
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: PitDataBase.LoadAll,
          ),
          IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SharePITDataScreen(),
                  ),
                );
              }),
        ],
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'Pit Recorder',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterTeams,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTeams.length,
              itemBuilder: (context, index) {
                final team = _filteredTeams[index];
                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isScouted(team.teamNumber, _recorded_team)
                            ? [Colors.red, Colors.blue]
                            : [Colors.grey, Colors.grey],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        'Team ${team.teamNumber}: ${team.nickname}',
                        style: GoogleFonts.museoModerno(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      subtitle: Text(
                        '${team.city}, ${team.stateProv}, ${team.country}',
                        style: GoogleFonts.museoModerno(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(134, 255, 255, 255),
                          letterSpacing: 1.2,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white),
                      onTap: () => _selectTeam(context, team),
                    ),
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () async {
              int tapCount = 0;
              bool confirmed = false;
              while (tapCount < 5) {
                confirmed = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text(
                          'Are you sure you want to delete all data? Tap ${5 - tapCount} more times to confirm.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('Yes'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text('No'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed) {
                  tapCount++;
                } else {
                  break;
                }
              }
              if (tapCount == 5) {
                // Perform delete operation
                PitDataBase.ClearData();
              }
            },
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 255, 1, 1),
                      const Color.fromARGB(255, 0, 38, 255)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: const Text(
                    'Delete All Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  trailing: const Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<Team>> fetchTeams() async {
  var dd =
      '[{"team_number": 201, "nickname": "Team 1", "city": "City 1", "state_prov": "State 1", "country": "Country 1", "website": "Website 1"}, {"team_number": 2, "nickname": "Team 2", "city": "City 2", "state_prov": "State 2", "country": "Country 2", "website": "Website 2"}]';
  dd = await Hive.box('pitData').get('teams');
  List<dynamic> teamsJson = json.decode(dd);
  return teamsJson.map((json) => Team.fromJson(json)).toList();
}

bool isScouted(int teamNumber, List<int> recorderTeam) {
  return recorderTeam.contains(teamNumber);
}
