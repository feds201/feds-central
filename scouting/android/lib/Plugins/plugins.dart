import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/Plugins/FEDScout.dart';
import 'package:scouting_app/components/plugin-tile.dart';

import '../main.dart';
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
  bool intergrateWithFEDSScoutz = false;
  bool intergrateWithPyintelScoutz_expanded = false;
  bool intergrateWithFEDSScoutz_expanded = false;

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
      'intergrateWithRitesh',
    ]);
    setState(() {
      intergrateWithPyintelScoutz = states['intergrateWithPyintelScoutz']!;

      intergrateWithFEDSScoutz = states['intergrateWithFEDSScoutz']!;
    });
  }

  Future<void> _saveStates() async {
    await _stateManager.saveAllPluginStates({
      'intergrateWithPyintelScoutz': intergrateWithPyintelScoutz,
      'intergrateWithFEDSScoutz': intergrateWithFEDSScoutz,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(context),
      body: ListView(
        children: <Widget>[
          PluginTile(
            title: "Integrate with Pyintel Scoutz",
            description:
                "Allows the device to communicate with Pyintel Servers and Scout Ops Server",
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
              });
            },
            Expanded_Widget: const PyintelScoutzWidget(),
          ),
          PluginTile(
            title: "Integrate with FEDS Scoutz",
            description:
                "Allows the device to communicate with FEDS Scouting Servers for Ai training and Scouting Analysis",
            icon_Widget: Icons.wifi,
            expanded_Widget: intergrateWithFEDSScoutz_expanded,
            value_trailing: intergrateWithFEDSScoutz,
            enabled_trailing: true,
            onToggle_Trailing: (bool value) {
              setState(() {
                intergrateWithFEDSScoutz = value;
              });
              _saveStates();
            },
            onTap_Widget: () {
              setState(() {
                intergrateWithFEDSScoutz_expanded =
                    !intergrateWithFEDSScoutz_expanded;
              });
            },
            Expanded_Widget: const FEDSScoutzWidget(),
          ),
        ],
      ),
    );
  }

  AppBar _buildCustomAppBar(BuildContext context) {
    return AppBar(
      leading: Builder(builder: (context) {
        return IconButton(
            icon: const Icon(Icons.arrow_back),
            color: !islightmode()
                ? const Color.fromARGB(193, 255, 255, 255)
                : const Color.fromARGB(105, 36, 33, 33),
            onPressed: () => Navigator.pop(context));
      }),

      backgroundColor: Colors.transparent, // Transparent to show the animation
      title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.red, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: Text(
            'Plugins',
            style: GoogleFonts.museoModerno(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          )),

      elevation: 0, // Remove shadow for a cleaner look
      centerTitle: true,
    );
  }
}
