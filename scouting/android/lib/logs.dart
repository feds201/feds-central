import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/DataBase.dart';
import 'components/SwipeCards.dart';
import 'services/GeminiPrediction.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    MatchDataBase.LoadAll();
    print(MatchDataBase.Export());
    List<MatchRecord> matchData = MatchDataBase.GetAll();

    List<Widget> matchCards = [];
    for (int i = 0; i < matchData.length; i++) {
      matchCards.add(MatchCard(
        matchData: (matchData[i].toCsv()),
        teamNumber: matchData[i].teamNumber,
        eventName: matchData[i].eventKey,
        allianceColor: matchData[i].allianceColor,
        selectedStation: matchData[i].station.toString(),
        matchKey: matchData[i].matchKey,
      ));
    }

    if (matchCards.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text("No match logs available."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Center(
          child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.red, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
              child: Text(
                'Match Logs',
                style: GoogleFonts.museoModerno(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              )),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.brightness_auto_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GeminiPredictionPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.restore_from_trash_rounded),
            onPressed: () {
              MatchDataBase.ClearData();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const LogsPage(),
                    fullscreenDialog: true),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: CarouselSlider(
          items: matchCards,
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * .85,
            enlargeFactor: 1,
            aspectRatio: 3 / 3,
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
}
