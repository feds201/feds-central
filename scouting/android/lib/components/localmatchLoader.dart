import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../home_page.dart';

class localmatchLoader extends StatefulWidget {
  const localmatchLoader({Key? key}) : super(key: key);

  @override
  _localmatchLoaderState createState() => _localmatchLoaderState();
}

class _localmatchLoaderState extends State<localmatchLoader> {
  final TextEditingController eventKeyController = TextEditingController();
  Future<List<dynamic>>? matches;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
      color: Colors.white,
      child: Column(
        children: modules(context),
      ),
      ));
  }

  List<Widget> modules(BuildContext context) {
    return [
      const SizedBox(height: 100),
      Material(
        color: Colors.white,
        child: TextField(
          controller: eventKeyController,
          decoration: InputDecoration(
            labelText: 'Match Event Key (e.g. 2023cmptx)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLoading ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width / 2, 50),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: () => {
                  getData(eventKeyController.text),
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                      ),
                      content: const Text('Done! Now go back to the home page to view the matches!'),
                      duration: const Duration(milliseconds: 1500),
                      width: 280.0, // Width of the SnackBar.
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, // Inner padding for SnackBar content.
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                },
                child: const Text('Load Event'),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  getData(String eventKey) async {
    var headers = {
      'X-TBA-Auth-Key':
          '2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W'
    };
    var responseForMatchData = await http.get(
        Uri.parse(
            'https://www.thebluealliance.com/api/v3/event/$eventKey/matches'),
        headers: headers);

    if (responseForMatchData.statusCode == 200) {
      if (kDebugMode) {
        print('Success');
      }
      setState(() {
        isLoading = true;
      });
      Hive.box('matchData').put('matches', jsonDecode(responseForMatchData.body));
    }
    var responseForPitData = await http.get(
        Uri.parse(
            'https://www.thebluealliance.com/api/v3/event/$eventKey/teams'),
        headers: headers);

    if (responseForPitData.statusCode == 200) {
      if (kDebugMode) {
        print('Success');
      }
      setState(() {
        isLoading = true;
      });
      Hive.box('pitData').put('teams', (responseForPitData.body));
    }
  }
}
