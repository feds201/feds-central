import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class Plugins extends StatefulWidget {
  const Plugins({super.key});

  @override
  _PluginsState createState() => _PluginsState();
}

class _PluginsState extends State<Plugins> {
  bool _isExpanded = false;
  final TextEditingController _controllerIp = TextEditingController();
  final TextEditingController _controllerDeviceName = TextEditingController();
  Color _testButtonColor = Colors.blue;
  Map<String, bool> _pluginSwitchStates = {
    'Pyintel Scoutz': false,
    'Gemini Nano': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    var box = Hive.box('settings');
    String ipAddress = box.get('ipAddress', defaultValue: '');
    String deviceName = box.get('deviceName', defaultValue: '');
    _controllerIp.text = ipAddress;
    _controllerDeviceName.text = deviceName;

    // Load switch states
    _pluginSwitchStates['Pyintel Scoutz'] =
        box.get('Pyintel Scoutz', defaultValue: false);
    _pluginSwitchStates['Gemini Nano'] =
        box.get('Gemini Nano', defaultValue: false);
  }

  void _saveSettings() {
    var box = Hive.box('settings');
    box.put('ipAddress', _controllerIp.text);
    box.put('deviceName', _controllerDeviceName.text);

    // Save switch states
    box.put('Pyintel Scoutz', _pluginSwitchStates['Pyintel Scoutz']);
    box.put('Gemini Nano', _pluginSwitchStates['Gemini Nano']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plugins'),
      ),
      body: ListView(
        children: <Widget>[
          _buildPluginTile(
            context,
            title: 'Integrate with Pyintel Scoutz',
            icon: Icons.integration_instructions,
            pluginKey: 'Pyintel Scoutz',
            controllerIp: _controllerIp,
            controllerDeviceName: _controllerDeviceName,
            testButtonColor: _testButtonColor,
          ),
          _buildPluginTile(
            context,
            title: 'Use Gemini Nano (Coming Soon)',
            icon: Icons.new_releases,
            pluginKey: 'Gemini Nano',
            controllerIp: null,
            controllerDeviceName: null,
            testButtonColor: _testButtonColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPluginTile(BuildContext context,
      {required String title,
      required IconData icon,
      required String pluginKey,
      TextEditingController? controllerIp,
      TextEditingController? controllerDeviceName,
      required Color testButtonColor}) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
      highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(icon, color: Theme.of(context).primaryColor),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Switch(
                value: _pluginSwitchStates[pluginKey]!,
                onChanged: (bool value) {
                  setState(() {
                    _pluginSwitchStates[pluginKey] = value;
                    _saveSettings(); // Save state when changed
                  });
                },
              ),
            ),
            if (_isExpanded && _pluginSwitchStates[pluginKey]!)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    if (controllerIp != null)
                      TextField(
                        controller: controllerIp,
                        decoration: const InputDecoration(
                          labelText: 'Enter Pyintel Scoutz Server IP Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (controllerDeviceName != null) ...[
                      SizedBox(height: 8),
                      TextField(
                        controller: controllerDeviceName,
                        decoration: const InputDecoration(
                          labelText: 'Enter a Unique Device Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            String ipAddress = controllerIp!.text;
                            String url = 'http://$ipAddress:5000/alive';
                            try {
                              final response = await http.get(Uri.parse(url));
                              print('Response status: ${response.statusCode}');
                              print('Response body: ${response.body}');
                              if (response.statusCode == 200) {
                                setState(() {
                                  _testButtonColor = Colors.green;
                                });
                              } else {
                                setState(() {
                                  _testButtonColor = Colors.red;
                                });
                              }
                            } catch (e) {
                              print('Error: $e');
                              setState(() {
                                _testButtonColor = Colors.red;
                              });
                            }
                          },
                          icon: const Icon(Icons.wifi),
                          label: const Text(
                            'Test Connection',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: testButtonColor,
                            // Dynamically set the color
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            textStyle: TextStyle(
                                fontSize: 16, color: _testButtonColor),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            _saveSettings();
                            String ipAddress = controllerIp!.text;
                            String deviceName = controllerDeviceName!.text;
                            print('IP Address: $ipAddress');
                            print('Device Name: $deviceName');
                            String url = 'http://$ipAddress:5000/register';

                            try {
                              final response = await http.post(
                                Uri.parse(url),
                                headers: {
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({'device_name': deviceName}),
                              );
                              print('Response status: ${response.statusCode}');
                              print('Response body: ${response.body}');

                              if (response.statusCode == 200) {
                                final responseBody = jsonDecode(response.body);
                                if (responseBody['message'] != null &&
                                    responseBody['message']
                                        .contains('already registered')) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            Text('Device Already Registered'),
                                        content: Text(responseBody['message']),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            } catch (e) {
                              print('Error: $e');
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Register Device'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> fetchPyintelScoutzServerStatus() async {
  var box = Hive.box('settings');
  bool pyintelScoutzState = box.get('Pyintel Scoutz', defaultValue: false);
  return pyintelScoutzState;
}