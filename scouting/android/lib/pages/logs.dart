import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../components/SwipeCards.dart';
import 'components/DataBase.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> matchData = MatchLogs.getLogs();

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
              print(MatchLogs.getLogs());
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: CarouselSlider(
          items: [
            for (int i = 0; i < matchData.length; i++)
              Builder(
                builder: (BuildContext context) {
                  String correctedJsonString = correctJsonFormat(matchData[i]);
                  Map<String, dynamic> jsonObject =
                      jsonDecode(correctedJsonString);
                  return MatchCard(
                    matchData: matchData[i],
                    // pass individual match data
                    eventName: jsonObject['TypeseventKey'],
                    teamNumber: jsonObject['Typesteam'],
                    matchKey: jsonObject['TypesmatchKey'],
                    allianceColor: jsonObject['TypesallianceColor'],
                    selectedStation: jsonObject['TypesselectedStation'],
                  );
                },
              ),
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

  void parseAndLogJson(String jsonString) {
    try {
      String correctedJsonString = correctJsonFormat(jsonString);
      Map<String, dynamic> jsonObject = jsonDecode(correctedJsonString);

      print("Event Key: ${jsonObject['TypeseventKey']}");
      print("Alliance Color: ${jsonObject['TypesallianceColor']}");
      print("Selected Station: ${jsonObject['TypesselectedStation']}");
      print("Match Key: ${jsonObject['TypesmatchKey']}");
      print("Team: ${jsonObject['Typesteam']}");
      // Add more fields as needed
    } catch (e) {
      print('Error: $e');
    }
  }

  String correctJsonFormat(String jsonString) {
    // Adjusting the regex to correctly format the jsonString
    return jsonString
        .replaceAllMapped(RegExp(r'(\w+)\.'), (match) => '${match[1]}')
        .replaceAllMapped(RegExp(r'(\w+):'), (match) => '"${match[1]}":')
        .replaceAllMapped(RegExp(r': (\w+)'), (match) => ': "${match[1]}"')
        .replaceAll("'", '"');
  }
}
