import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/components/plugin-tile.dart';

import '../main.dart';
import 'plugin_state_manager.dart'; // Import the state manager
import 'ScoutOpsServer.dart';

class Plugins extends StatefulWidget {
  const Plugins({super.key});

  @override
  _PluginsState createState() => _PluginsState();
}

class _PluginsState extends State<Plugins> {
  final PluginStateManager _stateManager = PluginStateManager();
  bool integrateWithScoutOps = false;
  bool integrateWithScoutOps_expanded = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    Map<String, bool> states = await _stateManager.loadAllPluginStates([
      'integrateWithScoutOps',
    ]);
    setState(() {
      integrateWithScoutOps = states['integrateWithScoutOps'] ?? false;
    });
  }

  Future<void> _saveStates() async {
    await _stateManager.saveAllPluginStates({
      'integrateWithScoutOps': integrateWithScoutOps,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(context),
      body: ListView(
        children: <Widget>[
          PluginTile(
            title: "Scout Ops Server",
            description:
                "Integrate with the local Scout Ops Server for device registration and match synchronization",
            icon_Widget: Icons.cloud_sync,
            expanded_Widget: integrateWithScoutOps_expanded,
            value_trailing: integrateWithScoutOps,
            enabled_trailing: true,
            onToggle_Trailing: (bool value) {
              setState(() {
                integrateWithScoutOps = value;
              });
              _saveStates();
            },
            onTap_Widget: () {
              setState(() {
                integrateWithScoutOps_expanded = !integrateWithScoutOps_expanded;
              });
            },
            Expanded_Widget: const ScoutOpsServerWidget(),
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
