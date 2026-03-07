import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';
import 'ExpStateManager.dart';

class Experiment extends StatefulWidget {
  const Experiment({super.key});

  @override
  _ExperimentState createState() => _ExperimentState();
}

class _ExperimentState extends State<Experiment> {
  final ExpStateManager _stateManager = ExpStateManager();
  bool templateStudioEnabled = false;
  bool templateStudioExpanded = false;
  bool cardBuilderEnabled = false;
  bool cardBuilderExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    Map<String, bool> states = await _stateManager.loadAllPluginStates([
      'templateStudioEnabled',
      'templateStudioExpanded',
      'cardBuilderEnabled',
      'cardBuilderExpanded',
    ]);
    setState(() {
      templateStudioEnabled = states['templateStudioEnabled']!;
      templateStudioExpanded = states['templateStudioExpanded']!;
      cardBuilderEnabled = states['cardBuilderEnabled']!;
      cardBuilderExpanded = states['cardBuilderExpanded']!;
    });
  }

  Future<void> _saveStates() async {
    await _stateManager.saveAllPluginStates({
      'templateStudioEnabled': templateStudioEnabled,
      'templateStudioExpanded': templateStudioExpanded,
      'cardBuilderEnabled': cardBuilderEnabled,
      'cardBuilderExpanded': cardBuilderExpanded,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Template Studio'),
            textColor: islightmode()
                ? Colors.grey.withOpacity(0.4)
                : lightColors.white,
            trailing: Switch(
              value: templateStudioEnabled,
              onChanged: (bool value) {
                setState(() {
                  templateStudioEnabled = value;
                });
                _saveStates();
              },
            ),
            onTap: () {
              setState(() {
                templateStudioExpanded = !templateStudioExpanded;
              });
              _saveStates();
            },
          ),
          if (templateStudioExpanded)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.blueGrey[50],
              child: const Text(
                'Template Studio details go here. You can add more content or widgets based on the requirement.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ListTile(
            title: const Text('Card Builder'),
            textColor: islightmode()
                ? Colors.grey.withOpacity(0.4)
                : lightColors.white,
            trailing: Switch(
              value: cardBuilderEnabled,
              onChanged: (bool value) {
                setState(() {
                  cardBuilderEnabled = value;
                });
                _saveStates();
              },
            ),
            onTap: () {
              setState(() {
                cardBuilderExpanded = !cardBuilderExpanded;
              });
              _saveStates();
            },
          ),
          if (cardBuilderExpanded)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.blueGrey[50],
              child: const Text(
                'Card Builder details go here. You can add more content or widgets based on the requirement.',
                style: TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
