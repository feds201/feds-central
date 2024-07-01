// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scouting_app/pages/home_page.dart';
import 'package:scouting_app/pages/about_page.dart';
import 'package:scouting_app/pages/match_page.dart';
import 'package:scouting_app/pages/settings_page.dart';

const Color themeColor = Color.fromARGB(255, 255, 255, 255);
const bool material3 = true;



void main() async {
  await Hive.initFlutter();
  await Hive.openBox('userData');
  await Hive.openBox('matchData');
  await Hive.openBox('autoData');
  await Hive.openBox('teleData');
  await Hive.openBox('endData');
  await Hive.openBox('pitData');
  await Hive.openBox('settings');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scouting App 2024',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        useMaterial3: material3,
      ),
      initialRoute: '/',
      routes: {
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
        '/match_page': (context) => const MatchPage(),

      },
      home: const HomePage(),
    );
  }
}







