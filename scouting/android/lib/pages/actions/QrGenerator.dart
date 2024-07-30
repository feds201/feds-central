import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scouting_app/pages/home_page.dart';
import 'package:slider_button/slider_button.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../components/DataBase.dart';

class Qrgenerator extends StatefulWidget {
  const Qrgenerator({Key? key}) : super(key: key);

  @override
  QrCoder createState() => QrCoder();
}

class QrCoder extends State<Qrgenerator> {
  final LocalDataBase dataMaster = LocalDataBase();

  @override
  Widget build(BuildContext context) {
    String qrData = LocalDataBase.getMatchData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 350,
              semanticsLabel: 'QR code',
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Colors.red,
              ),
              gapless: false,
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Colors.blue,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            const Text(
              'Scan the QR code to submit the data',
              style: TextStyle(fontSize: 20.0),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 8, right: 8),
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SliderButton(
                  buttonColor: Colors.yellow,
                  backgroundColor: Colors.white,
                  highlightedColor: Colors.green,
                  buttonSize: 70,
                  dismissThresholds: 0.97,
                  vibrationFlag: true,
                  width: MediaQuery.of(context).size.width - 40,
                  action: () async {
                    await InititiateTransactions(qrData);
                    MatchLogs.addLog(qrData);
                    LocalDataBase.clearData();
                    print("Data Cleared");
                    developer.log(qrData);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  label: const Text(
                    "Slide to Scout Next Match",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  icon: const Icon(
                    Icons.send_outlined,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> InititiateTransactions(String qrData) async {
    var box = Hive.box('settings');
    String? ipAddress = box.get('ipAddress');
    String? deviceName = box.get('deviceName');

    if (ipAddress != null) {
      String url = 'http://$ipAddress:5000/send_data';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'device_name': deviceName, 'data': qrData}),
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['message'] != null &&
              responseBody['message'].contains('already registered')) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Device Already Registered'),
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to communicate with the server.'),
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
    } else {
      print('IP address not found in Hive.');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('IP address not configured.'),
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
}
