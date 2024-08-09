import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
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

  void _selectTeam(Team team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistPage(team: team),
      ),
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
                  onTap: () => _selectTeam(team),
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
  final response = await http.get(
    Uri.parse('https://www.thebluealliance.com/api/v3/event/2024miket/teams'),
    headers: {'X-TBA-Auth-Key': '2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W'},
  );

  if (response.statusCode == 200) {
    List<dynamic> teamsJson = json.decode(response.body);
    return teamsJson.map((json) => Team.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load teams');
  }
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

class ChecklistPage extends StatefulWidget {
  final Team team;

  const ChecklistPage({super.key, required this.team});

  @override
  _ChecklistPageState createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  late Box<String> _generalTasksBox;
  late Box<String> _teamStatesBox;
  List<TaskState> _taskStates = [];

  @override
  void initState() {
    super.initState();
    _generalTasksBox = Hive.box<String>('generalTasks');
    _openTeamBox();
    _loadChecklist();
  }

  Future<void> _openTeamBox() async {
    String boxName = 'team_${widget.team.teamNumber}_states';
    if (!Hive.isBoxOpen(boxName)) {
      _teamStatesBox = await Hive.openBox<String>(boxName);
    } else {
      _teamStatesBox = Hive.box<String>(boxName);
    }
  }

  void _loadChecklist() {
    final generalTasksJson = _generalTasksBox.get('tasks');
    if (generalTasksJson != null) {
      final checklist = Checklist.fromJson(generalTasksJson);
      _taskStates = checklist.tasks.map((task) {
        final taskJson = _teamStatesBox.get(task);
        if (taskJson != null) {
          return TaskState.fromJson(json.decode(taskJson));
        }
        return TaskState(task: task);
      }).toList();
      setState(() {});
    }
  }

  void _toggleTaskState(int index) {
    setState(() {
      _taskStates[index].isCompleted = !_taskStates[index].isCompleted;
      _teamStatesBox.put(_taskStates[index].task, json.encode(_taskStates[index].toJson()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist for Team ${widget.team.teamNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Add task editing logic here
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _taskStates.length,
        itemBuilder: (context, index) {
          return CheckboxListTile(
            title: Text(_taskStates[index].task),
            value: _taskStates[index].isCompleted,
            onChanged: (bool? value) {
              _toggleTaskState(index);
            },
          );
        },
      ),
    );
  }
}
