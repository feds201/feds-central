import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/data_service.dart';
import 'services/local_prefs.dart';
import 'theme.dart';
import 'screens/event_entry_screen.dart';
import 'screens/comparison_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dataService = DataService();
  String initialRoute = '/';

  final config = await LocalPrefs.resolveConfig();

  if (config != null) {
    dataService.configure(
      eventKey: config.eventKey,
      tableName: config.tableName,
      neonConnString: config.neonConn,
      tbaApiKey: config.tbaKey,
    );

    final cached = await LocalPrefs.loadData(config.eventKey);
    if (cached != null) {
      dataService.loadFromCache(
        scoutingByTeam: cached.scoutingByTeam,
        scoutingColumns: cached.scoutingColumns,
        oprByTeam: cached.oprByTeam,
        epaByTeam: cached.epaByTeam,
        matchEntries: cached.matchEntries,
        playoffAlliances: cached.playoffAlliances,
        teamNames: cached.teamNames,
        lastUpdated: await LocalPrefs.lastUpdated,
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
      title: 'Match Dash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          final args = settings.arguments as Map<String, dynamic>?;
          final autoLoad = args?['autoLoad'] ?? true;
          final dismissible = args?['dismissible'] ?? false;
          return _fade(EventEntryScreen(
            autoLoad: autoLoad,
            dismissible: dismissible,
          ));
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