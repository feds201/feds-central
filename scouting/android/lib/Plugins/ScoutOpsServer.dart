import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_app/components/qr_code_scanner_page.dart';

class ScoutOpsServerWidget extends StatefulWidget {
  const ScoutOpsServerWidget({super.key});

  @override
  _ScoutOpsServerWidgetState createState() => _ScoutOpsServerWidgetState();
}

class _ScoutOpsServerWidgetState extends State<ScoutOpsServerWidget> {
  final TextEditingController _controllerIp = TextEditingController();
  final TextEditingController _controllerDeviceName = TextEditingController();
  Color _testButtonColor = Colors.blue;

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
  }

  void _saveSettings() {
    var box = Hive.box('settings');
    box.put('ipAddress', _controllerIp.text);
    box.put('deviceName', _controllerDeviceName.text);
  }

  Future<void> _testConnection() async {
    String ipAddress = _controllerIp.text;
    String url = 'http://$ipAddress/alive';
    try {
      final response = await http.get(Uri.parse(url));
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
      setState(() {
        _testButtonColor = Colors.red;
      });
    }
  }

  Future<void> _registerDevice() async {
    _saveSettings();
    String ipAddress = _controllerIp.text;
    String deviceName = _controllerDeviceName.text;
    String url = 'http://$ipAddress/register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_name': deviceName}),
      );
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String message = responseBody['message'] ?? 'Device registered';
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Device Registered'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _syncMatchFileFromServer() async {
    String ipAddress = _controllerIp.text.isNotEmpty
        ? _controllerIp.text
        : Hive.box('settings').get('ipAddress', defaultValue: '');
    if (ipAddress == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server IP not configured')),
      );
      return;
    }

    final url = Uri.parse('http://$ipAddress/api/get_event_file.csv');
    print('Attempting to sync match CSV from $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final csvText = utf8.decode(response.bodyBytes);
        Hive.box('matchData').put('matches_csv', csvText);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match CSV synced from server')),
        );
      } else if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No CSV data available on server')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to download CSV: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = dark ? Colors.grey[850] : Colors.grey[200];
    final labelColor = dark ? Colors.white70 : Colors.black87;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: _controllerIp,
                decoration: InputDecoration(
                  labelText: 'Server IP',
                  hintText: 'Enter server IP',
                  filled: true,
                  fillColor: fillColor,
                  labelStyle: TextStyle(color: labelColor),
                  hintStyle: TextStyle(color: labelColor.withOpacity(0.7)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: labelColor),
                    onPressed: () async {
                      final qrCode = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const QRCodeScannerPage(),
                            fullscreenDialog: true),
                      );
                      if (qrCode != null) {
                        setState(() {
                          Hive.box('settings').put('ipAddress', qrCode);
                          _controllerIp.text = qrCode;
                        });
                      }
                    },
                  ),
                ),
                onSubmitted: (String value) {
                  Hive.box('settings').put('ipAddress', value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controllerDeviceName,
                decoration: InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'Enter device name',
                  filled: true,
                  fillColor: fillColor,
                  labelStyle: TextStyle(color: labelColor),
                  hintStyle: TextStyle(color: labelColor.withOpacity(0.7)),
                ),
                onSubmitted: (String value) {
                  Hive.box('settings').put('deviceName', value);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _testButtonColor,
                foregroundColor: dark ? Colors.black : Colors.white,
              ),
              child: const Text('Test'),
            ),
            ElevatedButton(
              onPressed: _registerDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    dark ? Colors.tealAccent.shade700 : Colors.green,
                foregroundColor: dark ? Colors.black : Colors.white,
              ),
              child: const Text('Register Device'),
            ),
            ElevatedButton(
              onPressed: _syncMatchFileFromServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: dark
                    ? Colors.deepOrangeAccent.shade200
                    : Colors.orangeAccent,
                foregroundColor: dark ? Colors.black : Colors.white,
              ),
              child: const Text('Sync Match File'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
