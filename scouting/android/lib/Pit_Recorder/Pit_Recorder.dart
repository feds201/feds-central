import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'CheckLists.dart';

class Pit_Recorder extends StatefulWidget {
  const Pit_Recorder({super.key});

  @override
  _Pit_RecorderState createState() => _Pit_RecorderState();
}

class _Pit_RecorderState extends State<Pit_Recorder> {
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  int _visibleCount = 7;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
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
    print("Selected team is : ${team.teamNumber}");
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Checklists(team: team), fullscreenDialog: true),
    );
  }

  void _showMore() {
    setState(() {
      _visibleCount += 7;
    });
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
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
              style: TextStyle(fontSize: 16),
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
              child: Text('Cancel'),
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
      _showErrorDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pit Recorder'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Teams',
                border: OutlineInputBorder(),
              ),
              onChanged: _filterTeams,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTeams.length < _visibleCount
                  ? _filteredTeams.length
                  : _visibleCount,
              itemBuilder: (context, index) {
                final team = _filteredTeams[index];
                return ListTile(
                  title: Text('Team ${team.teamNumber}: ${team.nickname}'),
                  onTap: () => _selectTeam(context, team),
                );
              },
            ),
          ),
          if (_filteredTeams.length > _visibleCount)
            TextButton(
              onPressed: _showMore,
              child: const Text('Show More'),
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

class Team {
  final int teamNumber;
  final String nickname;
  final String? city;
  final String? stateProv;
  final String? country;
  final String? website;

  Team({
    required this.teamNumber,
    required this.nickname,
    this.city,
    this.stateProv,
    this.country,
    this.website,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamNumber: json['team_number'],
      nickname: json['nickname'],
      city: json['city'],
      stateProv: json['state_prov'],
      country: json['country'],
      website: json['website'],
    );
  }
}