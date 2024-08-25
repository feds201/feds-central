import 'package:flutter/material.dart';
import 'package:scouting_app/components/plugin-tile.dart';

import 'Pyintel_Soutz.dart';
import 'plugin_state_manager.dart'; // Import the state manager

class Plugins extends StatefulWidget {
  const Plugins({super.key});

  @override
  _PluginsState createState() => _PluginsState();
}

class _PluginsState extends State<Plugins> {
  final PluginStateManager _stateManager = PluginStateManager();
  bool intergrateWithPyintelScoutz = false;
  bool geminiIntergerations = false;
  bool auth0Intergerations = false;

  bool intergrateWithPyintelScoutz_expanded = false;
  bool geminiIntergerations_expanded = false;
  bool auth0Intergerations_expanded = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    Map<String, bool> states = await _stateManager.loadAllPluginStates([
      'intergrateWithPyintelScoutz',
      'geminiIntergerations',
      'auth0Intergerations',
    ]);
    setState(() {
      intergrateWithPyintelScoutz = states['intergrateWithPyintelScoutz']!;
      geminiIntergerations = states['geminiIntergerations']!;
      auth0Intergerations = states['auth0Intergerations']!;
    });
  }

  Future<void> _saveStates() async {
    await _stateManager.saveAllPluginStates({
      'intergrateWithPyintelScoutz': intergrateWithPyintelScoutz,
      'geminiIntergerations': geminiIntergerations,
      'auth0Intergerations': auth0Intergerations,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugins'),
      ),
      body: ListView(
        children: <Widget>[
          PluginTile(
            title: "Integrate with Pyintel Scoutz",
            description: "description",
            icon_Widget: Icons.integration_instructions,
            expanded_Widget: intergrateWithPyintelScoutz_expanded,
            value_trailing: intergrateWithPyintelScoutz,
            enabled_trailing: true,
            onToggle_Trailing: (bool value) {
              setState(() {
                intergrateWithPyintelScoutz = value;
              });
              _saveStates();
            },
            onTap_Widget: () {
              setState(() {
                intergrateWithPyintelScoutz_expanded =
                    !intergrateWithPyintelScoutz_expanded;
                auth0Intergerations_expanded = false;
                geminiIntergerations_expanded = false;
              });
            },
            Expanded_Widget: PyintelScoutzWidget(),
          ),
          PluginTile(
            title: "Authentication",
            description: "Enables in app authentications",
            icon_Widget: Icons.connected_tv_sharp,
            expanded_Widget: auth0Intergerations_expanded,
            value_trailing: auth0Intergerations,
            enabled_trailing: false,
            onToggle_Trailing: (bool value) {
              setState(() {
                auth0Intergerations = value;
              });
              _saveStates();
            },
            onTap_Widget: () {
              setState(() {
                auth0Intergerations_expanded = !auth0Intergerations_expanded;
                geminiIntergerations_expanded = false;
                intergrateWithPyintelScoutz_expanded = false;
              });
            },
            Expanded_Widget: Container(),
          ),
          PluginTile(
            title: "Integrate with Gemini (Soon)",
            description: "description",
            icon_Widget: Icons.webhook,
            expanded_Widget: geminiIntergerations_expanded,
            value_trailing: geminiIntergerations,
            enabled_trailing: false,
            onToggle_Trailing: (bool value) {
              setState(() {
                geminiIntergerations = value;
              });
            },
            onTap_Widget: () {
              setState(() {
                geminiIntergerations_expanded = !geminiIntergerations_expanded;
                auth0Intergerations_expanded = false;
                intergrateWithPyintelScoutz_expanded = false;
              });
            },
            Expanded_Widget: Container(),
          ),
        ],
      ),
    );
  }
}
