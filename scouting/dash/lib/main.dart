import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

import 'services/data_service.dart';
import 'theme.dart';
import 'screens/event_entry_screen.dart';
import 'screens/comparison_screen.dart';

void main() {
  setPathUrlStrategy();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DataService(),
      child: const ScoutOpsApp(),
    ),
  );
}

class ScoutOpsApp extends StatelessWidget {
  const ScoutOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scout-Ops Dash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return _fade(const EventEntryScreen());
        }
        if (settings.name == '/compare') {
          return _fade(const ComparisonScreen());
        }
        return _fade(const EventEntryScreen());
      },
    );
  }

  PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
