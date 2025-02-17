import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_app/components/ScoutersList';

class PyintelScoutzWidget extends StatefulWidget {
  const PyintelScoutzWidget({super.key});

  @override
  _PyintelScoutzWidgetState createState() => _PyintelScoutzWidgetState();
}

class _PyintelScoutzWidgetState extends State<PyintelScoutzWidget> {
  final TextEditingController _controllerIp = TextEditingController();
  final TextEditingController _controllerDeviceName = TextEditingController();
  Color _testButtonColor = Colors.blue;

  @override
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
      ipAddress = ipAddress;
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
            const SizedBox(height: 8),
            ScouterList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _testConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: _testButtonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Test Connection',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _registerDevice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.2),
            ).copyWith(
              overlayColor:
                  MaterialStateProperty.all(Colors.greenAccent.shade400),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Register Device',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ]);
  }
}
