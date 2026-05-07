import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/data_store.dart';
import '../sync/history_tab.dart';
import '../sync/import_tab.dart';
import '../sync/storage_tab.dart';
import '../sync/usb_instructions_tab.dart';

class SyncPage extends StatefulWidget {
  final DataStore dataStore;

  const SyncPage({super.key, required this.dataStore});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  String? _storageDir;
  bool _hasPermission = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _initStorageDir();
    _checkAndRequestPermission();
  }

  Future<void> _initStorageDir() async {
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() => _storageDir = dir.path);
    }
  }

  Future<void> _checkAndRequestPermission() async {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) {
      if (mounted) setState(() { _hasPermission = true; _checkingPermission = false; });
      return;
    }

    // Not granted — request it (opens system settings on Android 11+)
    final result = await Permission.manageExternalStorage.request();
    if (mounted) {
      setState(() {
        _hasPermission = result.isGranted;
        _checkingPermission = false;
      });
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission required. Please enable in Settings > Apps > match_record > Permissions.'),
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Still loading storage dir or checking permission
    if (_storageDir == null || _checkingPermission) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Permission denied — block the screen
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sync')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Storage Permission Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app needs access to storage to import match videos from USB drives.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _checkAndRequestPermission,
                  icon: const Icon(Icons.security),
                  label: const Text('Grant Permission'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Open App Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sync'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Import'),
              Tab(text: 'History'),
              Tab(text: 'Storage'),
              Tab(text: 'USB Transfer Guide'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ImportTab(
              dataStore: widget.dataStore,
              storageDir: _storageDir!,
            ),
            HistoryTab(dataStore: widget.dataStore),
            StorageTab(
              dataStore: widget.dataStore,
              storageDir: _storageDir!,
            ),
            const UsbInstructionsTab(),
          ],
        ),
      ),
    );
  }
}
