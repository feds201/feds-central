import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_app/components/DataBase.dart';

import '../Match_Pages/match_page.dart';
import '../home_page.dart';

class localmatchLoader extends StatefulWidget {
  const localmatchLoader({super.key});

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
        appBar: AppBar(
          title: const Text('Local Match Loader'),
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            children: modules(context),
          ),
        ));
  }

  List<Widget> modules(BuildContext context) {
    return [
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        child: TextField(
          controller: eventKeyController,
          decoration: InputDecoration(
            labelText: 'Match Event Key (e.g. 2022miket)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLoading ? Colors.green[300] : Colors.redAccent,
                  border: Border.all(
                    color: isLoading ? Colors.green : Colors.red,
                    width: 3,
                  ),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width / 2, 50),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: Colors.blue,
                      width: 3,
                    ),
                  ),
                ),
                onPressed: () {
                  getData(eventKeyController.text);
                },
                child: Text(
                  'Load Event',
                  style: GoogleFonts.museoModerno(
                      fontSize: 15, color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 50),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.redAccent[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: Colors.red,
                      width: 3,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomePage(),
                        fullscreenDialog: true),
                  );
                },
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MatchPage(),
                        fullscreenDialog: true),
                  );
                },
                child: Text('Seek Home',
                    style: GoogleFonts.museoModerno(
                        fontSize: 15, color: Colors.white)),
              ),
            ],
          )),
    ];
  }

  getData(String eventKey) async {
    var ApiKey = Settings.getApiKey();
    print(ApiKey);
    var headers = {
      'X-TBA-Auth-Key': ApiKey,
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
      Hive.box('matchData')
          .put('matches', jsonDecode(responseForMatchData.body));
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
