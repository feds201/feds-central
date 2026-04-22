import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../screens/sync_page.dart';

class SyncButton extends StatelessWidget {
  final DataStore dataStore;

  const SyncButton({super.key, required this.dataStore});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      icon: const Icon(Icons.sync),
      tooltip: 'Sync',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SyncPage(dataStore: dataStore),
          ),
        );
      },
    );
  }
}
