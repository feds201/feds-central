import 'package:flutter/material.dart';

import 'data/data_store.dart';
import 'screens/main_screen.dart';
import 'tba/tba_client.dart';

class MatchRecordApp extends StatelessWidget {
  final DataStore dataStore;
  final TbaClient? tbaClient;
  final int integrityCleanupCount;

  const MatchRecordApp({
    super.key,
    required this.dataStore,
    this.tbaClient,
    this.integrityCleanupCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Recorder',
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
      home: _AppHome(
        dataStore: dataStore,
        tbaClient: tbaClient ?? TbaClient(),
        integrityCleanupCount: integrityCleanupCount,
      ),
    );
  }
}

/// Wrapper that shows the integrity cleanup toast on first build, then
/// delegates to MainScreen.
class _AppHome extends StatefulWidget {
  final DataStore dataStore;
  final TbaClient tbaClient;
  final int integrityCleanupCount;

  const _AppHome({
    required this.dataStore,
    required this.tbaClient,
    required this.integrityCleanupCount,
  });

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool _toastShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_toastShown && widget.integrityCleanupCount > 0) {
      _toastShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cleaned up ${widget.integrityCleanupCount} orphaned file(s)',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScreen(
      dataStore: widget.dataStore,
      tbaClient: widget.tbaClient,
    );
  }
}
