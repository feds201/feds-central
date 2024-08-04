import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../components/DataBase.dart';
import '../components/SwipeCards.dart';
import '../components/compactifier.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> matchData = MatchLogs.getLogs();
    for (int i = 0; i < matchData.length; i++) {
      print(parseAndLogJson(matchData[i]));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Past Matches'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.restore_from_trash_rounded),
            onPressed: () {
              MatchLogs.clearLogs();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LogsPage()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: CarouselSlider(
          items: [
            for (int i = 0; i < matchData.length; i++)
              MatchCard(
                matchData: matchData[i],
                teamNumber: parseAndLogJson(matchData[i])[4],
                eventName: parseAndLogJson(matchData[i])[0],
                allianceColor: parseAndLogJson(matchData[i])[1],
                selectedStation: parseAndLogJson(matchData[i])[2],
                matchKey: parseAndLogJson(matchData[i])[3],
              )
          ],
          options: CarouselOptions(
            height: 750,
            enlargeFactor: 1,
            aspectRatio: 16 / 9,
            viewportFraction: 0.85,
            initialPage: 0,
            enableInfiniteScroll: false,
            reverse: false,
            autoPlay: false,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 200),
            autoPlayCurve: Curves.easeInOutQuad,
            enlargeCenterPage: true,
            scrollDirection: Axis.horizontal,
          ),
        ),
      ),
    );
  }

  List<String> parseAndLogJson(String jsonString) {
    try {
      String correctedJsonString = correctJsonFormat(jsonString);
      Map<String, dynamic> jsonObject = jsonDecode(correctedJsonString);
      // Add more fields as needed
      return [
        jsonObject['TypeseventKey'],
        jsonObject['TypesallianceColor'],
        jsonObject['TypesselectedStation'],
        jsonObject['TypesmatchKey'],
        jsonObject['Typesteam']
      ];
    } catch (e) {
      return [('Error: $e')];
    }
  }
}