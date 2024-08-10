import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

import 'CheckLists.dart';

class Pit_Recorder extends StatefulWidget {
  const Pit_Recorder({super.key});

  @override
  _Pit_RecorderState createState() => _Pit_RecorderState();
}

class _Pit_RecorderState extends State<Pit_Recorder> {
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  String _searchQuery = '';
  int _visibleCount = 7;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  void _fetchTeams() async {
    try {
      List<Team> teams = await fetchTeams();
      setState(() {
        _teams = teams;
        _filteredTeams = teams;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load teams: $e')),
      );
    }
  }

  void _filterTeams(String query) {
    setState(() {
      _searchQuery = query;
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
      MaterialPageRoute(builder: (context) => Checklists(team: team)),
    );
  }

  void _showMore() {
    setState(() {
      _visibleCount += 7;
    });
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
// Future<List<Team>> fetchTeams() async {
//   final response = await http.get(
//     Uri.parse('https://www.thebluealliance.com/api/v3/event/2022miroc/teams'),
//     headers: {'X-TBA-Auth-Key': '2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W'},
//   );
//
//
//   if (response.statusCode == 200) {
//     List<dynamic> teamsJson = json.decode(response.body);
//     return teamsJson.map((json) => Team.fromJson(json)).toList();
//   } else {
//     throw Exception('Failed to load teams');
//   }
// }

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
