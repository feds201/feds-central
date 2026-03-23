import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../data/data_store.dart';
import '../sync/history_tab.dart';
import '../sync/import_tab.dart';
import '../sync/storage_tab.dart';

class SyncPage extends StatefulWidget {
  final DataStore dataStore;

  const SyncPage({super.key, required this.dataStore});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  String? _storageDir;

  @override
  void initState() {
    super.initState();
    _initStorageDir();
  }

  Future<void> _initStorageDir() async {
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() => _storageDir = dir.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_storageDir == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sync'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Import'),
              Tab(text: 'History'),
              Tab(text: 'Storage'),
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
          ],
        ),
      ),
    );
  }
}
