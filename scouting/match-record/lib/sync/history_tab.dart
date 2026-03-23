import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';

class HistoryTab extends StatelessWidget {
  final DataStore dataStore;

  const HistoryTab({
    super.key,
    required this.dataStore,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dataStore,
      builder: (context, _) {
        final sessions = dataStore.importSessions;

        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No import history yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Import videos from the Import tab to see history here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Show sessions in reverse chronological order
        final sortedSessions = List<ImportSession>.from(sessions)
          ..sort((a, b) => b.importedAt.compareTo(a.importedAt));

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: sortedSessions.length,
          itemBuilder: (context, index) {
            final session = sortedSessions[index];
            return _buildSessionCard(context, session);
          },
        );
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, ImportSession session) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: const Icon(Icons.usb),
        title: Text(session.driveLabel),
        subtitle: Text(
          '${_formatDateTime(session.importedAt)} -- ${session.videoCount} video(s)',
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          // TODO: Reopen import preview with session data (Phase 6)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session re-edit coming in Phase 6'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}
