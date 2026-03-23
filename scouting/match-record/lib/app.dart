import 'package:flutter/material.dart';

import 'data/data_store.dart';
import 'screens/main_screen.dart';
import 'tba/tba_client.dart';

class MatchRecordApp extends StatelessWidget {
  final DataStore dataStore;
  final TbaClient? tbaClient;

  const MatchRecordApp({
    super.key,
    required this.dataStore,
    this.tbaClient,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Record',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: MainScreen(
        dataStore: dataStore,
        tbaClient: tbaClient ?? TbaClient(),
      ),
    );
  }
}
