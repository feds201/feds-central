import 'package:flutter/material.dart';

import 'data/data_store.dart';
import 'notifications/notification_service.dart';
import 'screens/main_screen.dart';
import 'tba/tba_client.dart';
import 'tba/tba_config.dart';

class MatchRecordApp extends StatelessWidget {
  final DataStore dataStore;
  final TbaClient? tbaClient;
  final int integrityCleanupCount;
  final NotificationService? notificationService;

  const MatchRecordApp({
    super.key,
    required this.dataStore,
    this.tbaClient,
    this.integrityCleanupCount = 0,
    this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Viewr',
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
        tbaClient: tbaClient,
        integrityCleanupCount: integrityCleanupCount,
        notificationService: notificationService,
      ),
    );
  }
}

/// Wrapper that shows the integrity cleanup toast on first build, then
/// delegates to MainScreen.
class _AppHome extends StatefulWidget {
  final DataStore dataStore;
  final TbaClient? tbaClient;
  final int integrityCleanupCount;
  final NotificationService? notificationService;

  const _AppHome({
    required this.dataStore,
    this.tbaClient,
    required this.integrityCleanupCount,
    this.notificationService,
  });

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool _toastShown = false;
  late TbaClient _tbaClient;
  String? _currentApiKey;
  String? _initialNotificationPayload;

  @override
  void initState() {
    super.initState();
    _currentApiKey = _resolveApiKey();
    _tbaClient = widget.tbaClient ?? TbaClient(apiKey: _currentApiKey);
    widget.dataStore.addListener(_onDataStoreChanged);
    _checkInitialNotification();
  }

  @override
  void dispose() {
    widget.dataStore.removeListener(_onDataStoreChanged);
    super.dispose();
  }

  String? _resolveApiKey() {
    return TbaConfig.resolveApiKey(widget.dataStore.settings.tbaApiKey);
  }

  void _onDataStoreChanged() {
    final newKey = _resolveApiKey();
    if (newKey != _currentApiKey) {
      setState(() {
        _currentApiKey = newKey;
        _tbaClient = TbaClient(apiKey: _currentApiKey);
      });
    }
  }

  Future<void> _checkInitialNotification() async {
    final service = widget.notificationService;
    if (service == null) return;
    final payload = await service.getInitialPayload();
    if (payload != null && mounted) {
      setState(() => _initialNotificationPayload = payload);
    }
  }

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
      tbaClient: _tbaClient,
      notificationService: widget.notificationService,
      initialNotificationPayload: _initialNotificationPayload,
    );
  }
}
