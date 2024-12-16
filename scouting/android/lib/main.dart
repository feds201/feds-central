import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scouting_app/Pit_Recorder/Pit_Recorder.dart';

import 'Match_Pages/about_page.dart';
import 'Match_Pages/match_page.dart';
import 'Match_Pages/settings_page.dart';
import 'home_page.dart';
import 'model/widget_data.dart';

const Color themeColor = Color.fromARGB(255, 255, 255, 255);
const bool material3 = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  await Hive.openBox('userData');
  await Hive.openBox('matchData');
  await Hive.openBox('settings');
  await Hive.openBox('pitData');
  await Hive.openBox('experiments');
  await Hive.openBox('scoutingItems');
  Hive.registerAdapter(WidgetDataAdapter());
  await Hive.openBox<WidgetData>('widgetBox');
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
        '/pit_page': (context) => const Pit_Recorder(),
      },
      home: const HomePage(),
    );
  }
}







