// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'Match_Pages/about_page.dart';
import 'Match_Pages/match_page.dart';
import 'Match_Pages/settings_page.dart';
import 'home_page.dart';

const Color themeColor = Color.fromARGB(255, 255, 255, 255);
const bool material3 = true;



void main() async {
  await Hive.initFlutter();
  await Hive.openBox('userData');
  await Hive.openBox('matchData');
  await Hive.openBox('autoData');
  await Hive.openBox('teleData');
  await Hive.openBox('endData');
  await Hive.openBox<String>('checklists');
  await Hive.openBox('settings');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scout Ops',
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







