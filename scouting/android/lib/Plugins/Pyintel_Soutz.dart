import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class PyintelScoutzWidget extends StatefulWidget {
  @override
  _PyintelScoutzWidgetState createState() => _PyintelScoutzWidgetState();
}

class _PyintelScoutzWidgetState extends State<PyintelScoutzWidget> {
  final TextEditingController _controllerIp = TextEditingController();
  final TextEditingController _controllerDeviceName = TextEditingController();
  Color _testButtonColor = Colors.blue;

  void initState() {
    super.initState();
    _loadSettings();
  }

  void _testConnection() async {
    String ipAddress = _controllerIp.text;
    String url = 'http://$ipAddress/alive';
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
  }

  void _registerDevice() async {
    _saveSettings();
    String ipAddress = _controllerIp.text;
    RegExp websitePattern = RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!websitePattern.hasMatch(ipAddress)) {
      ipAddress = '$ipAddress';
    }

    String deviceName = _controllerDeviceName.text;
    print('IP Address: $ipAddress');
    print('Device Name: $deviceName');
    String url = 'http://$ipAddress/register';

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
            responseBody['message'].contains('already registered')) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Device Already Registered'),
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
        if (responseBody['status'].contains('success')) {
          String message =
              responseBody['message'] ?? 'Device registered successfully';
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Device Registered'),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
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
  }

  void _saveSettings() {
    var box = Hive.box('settings');
    box.put('ipAddress', _controllerIp.text);
    box.put('deviceName', _controllerDeviceName.text);
  }

  void _loadSettings() {
    var box = Hive.box('settings');
    String ipAddress = box.get('ipAddress', defaultValue: '');
    String deviceName = box.get('deviceName', defaultValue: '');
    _controllerIp.text = ipAddress;
    _controllerDeviceName.text = deviceName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            TextField(
              controller: _controllerIp,
              decoration: const InputDecoration(
                labelText: 'Enter Pyintel Scoutz Server IP Address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _controllerDeviceName,
              decoration: const InputDecoration(
                labelText: 'Enter a Unique Device Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.wifi),
            label: const Text('Test Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _testButtonColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: TextStyle(fontSize: 16, color: _testButtonColor),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _registerDevice,
            icon: const Icon(Icons.save),
            label: const Text('Register Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ]);
  }
}
