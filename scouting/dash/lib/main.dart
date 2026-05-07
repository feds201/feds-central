import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

import 'services/data_service.dart';
import 'services/local_prefs.dart';
import 'theme.dart';
import 'screens/event_entry_screen.dart';
import 'screens/comparison_screen.dart';

void main() {
  setPathUrlStrategy();

  final dataService = DataService();
  final config = LocalPrefs.resolveConfig();
  String initialRoute = '/';

  if (config != null) {
    dataService.configure(
      eventKey: config.eventKey,
      tableName: config.tableName,
      neonConnString: config.neonConn,
      tbaApiKey: config.tbaKey,
    );

    final cached = LocalPrefs.loadData(config.eventKey);
    if (cached != null) {
      dataService.loadFromCache(
        scoutingByTeam: cached.scoutingByTeam,
        scoutingColumns: cached.scoutingColumns,
        oprByTeam: cached.oprByTeam,
        epaByTeam: cached.epaByTeam,
        lastUpdated: LocalPrefs.lastUpdated,
      );
      initialRoute = '/compare';
    }
  }

  runApp(
    ChangeNotifierProvider.value(
      value: dataService,
      child: ScoutOpsApp(initialRoute: initialRoute),
    ),
  );
}

class ScoutOpsApp extends StatelessWidget {
  const ScoutOpsApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scout-Ops Dash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          final args = settings.arguments as Map<String, dynamic>?;
          final autoLoad = args?['autoLoad'] ?? true;
          return _fade(EventEntryScreen(autoLoad: autoLoad));
        }
        if (settings.name == '/compare') {
          return _fade(const ComparisonScreen());
        }
        return _fade(EventEntryScreen());
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
