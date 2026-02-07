//! You do not need to change this file, unless you wanna add Hive Box's
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'homepage.dart';

void main() {
  // Set the app to fullscreen immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  addHiveBoxes();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Hide the status bar
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      home: Homepage(),
    );
  }
}

void addHiveBoxes() {
  //* Add your Hive boxes here if needed
  // Hive.openBox('your_box_name');
}

