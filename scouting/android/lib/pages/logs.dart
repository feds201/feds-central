import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/pages/components/DataBase.dart';

import '../components/SwipeCards.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  String? extractMatchKey(String data) {
    final match = RegExp(r'mk:([^,]+)').firstMatch(data);
    return match != null ? match.group(1) : '';
  }

  String? extractEventKey(String data) {
    final match = RegExp(r'ek:([^,]+)').firstMatch(data);
    return match != null ? match.group(1) : '';
  }

  String? extractTeam(String data) {
    final match = RegExp(r't:([^,]+)').firstMatch(data);
    return match != null ? match.group(1) : '';
  }

  String? extractMatchNumber(String data) {
    final match = RegExp(r'm(\d+)$').firstMatch(data);
    return match != null ? match.group(1) : '';
  }

  @override
  Widget build(BuildContext context) {
    // List<List<String>> matchData = [
    //   [
    //     "1",
    //     "Team 1 vs Team 2",
    //     "cmptx2024",
    //     "Event Name",
    //   ],
    //   [
    //     "2",
    //     "Team 3 vs Team 4",
    //     "Event Name",
    //     "cmptx2024",
    //   ],
    //   [
    //     "3",
    //     "Team 5 vs Team 6",
    //     "Event Name",
    //     "cmptx2024",
    //   ],
    //   [
    //     "4",
    //     "Team 7 vs Team 8",
    //     "Event Name",
    //     "cmptx2024",
    //   ],
    //   [
    //     "5",
    //     "Team 9 vs Team 10",
    //     "Event Name",
    //     "cmptx2024",
    //   ],
    //   [
    //     "6",
    //     "Team 11 vs Team 12",
    //     "Event Name",
    //     "cmptx2024",
    //   ],
    // ];

    List<String> matchData = MatchLogs.getLogs();

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Past Matches'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: CarouselSlider(
              items: [
                for (int i = 0; i < matchData.length; i++)
                  MatchCard(
                    colors: Colors.blue,
                    matchNumber: extractMatchNumber(
                            extractMatchKey((MatchLogs.getLogs())[i]) ?? "") ??
                        'Internal Error',
                    teamNumber: extractTeam((MatchLogs.getLogs())[i]) ??
                        'Internal Error',
                    eventName: extractEventKey((MatchLogs.getLogs())[i]) ??
                        'Internal Error',
                    matchKey: extractMatchKey((MatchLogs.getLogs())[i]) ??
                        'Internal Error',
                    matchData: (MatchLogs.getLogs())[i],
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
              )),
        ));
  }
}
