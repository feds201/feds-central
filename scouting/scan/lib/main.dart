import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'homepage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  addHiveBoxes();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF0A0A0F),
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF82B1FF),
          tertiary: Color(0xFF00E676),
          error: Color(0xFFFF5252),
          onSurface: Color(0xFFE0E0E0),
          onPrimary: Colors.white,
          surfaceContainerHighest: Color(0xFF16162A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const Homepage(),
    );
  }
}

void addHiveBoxes() {
  //* Add your Hive boxes here if needed
}
