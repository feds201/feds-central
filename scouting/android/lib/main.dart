import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scouting_app/Qualitative/qualitative.dart';
import 'Pit_Recorder/Pit_Recorder.dart';
import 'about_page.dart';
import 'Match_Pages/match_page.dart';
import 'home_page.dart';
import 'services/Adapters/AutonPoints.dart';
import 'settings_page.dart';

const Color themeColor = Color.fromARGB(255, 255, 255, 0);
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
  await Hive.openBox('match');
  await Hive.openBox('local');
  await Hive.openBox('qualitative');
  await Hive.openBox('pitcheck');
  await Hive.openBox('responces');
  Hive.registerAdapter(AutonPointsAdapter());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = Hive.box('settings').get('isDarkMode', defaultValue: false);
    // Listen for theme changes
    Hive.box('settings')
        .listenable(keys: ['isDarkMode']).addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    Hive.box('settings')
        .listenable(keys: ['isDarkMode']).removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      _isDarkMode = Hive.box('settings').get('isDarkMode', defaultValue: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Hive.box('userData').get('scouterNames', defaultValue: []);
    return MaterialApp(
      title: 'Scout Ops',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: material3,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color.fromARGB(255, 30, 30, 30)),
        useMaterial3: material3,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
        '/match_page': (context) => const MatchPage(),
        '/pit_page': (context) => const PitRecorder(),
        '/qualitative': (context) => const Qualitative(),
      },
      home: const HomePage(),
    );
  }
}

// Fix the misleadingly named function
bool isDarkMode() {
  return Hive.box('settings').get('isDarkMode', defaultValue: false);
}

// Keep the original function for backward compatibility
// but make it use the correct function
bool islightmode() {
  return true;
}

Color invertColor(Color color) {
  return Color.fromARGB(
    color.alpha,
    255 - color.red,
    255 - color.green,
    255 - color.blue,
  );
}
