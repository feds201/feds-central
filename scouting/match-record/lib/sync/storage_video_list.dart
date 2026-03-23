import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';

/// Shared list component for displaying video recordings.
/// Used by both tablet storage mode and flash drive mode.
class StorageVideoList extends StatelessWidget {
  final List<Recording> recordings;
  final Set<String> selectedIds;
  final DataStore dataStore;
  final void Function(String id) onToggleSelection;

  const StorageVideoList({
    super.key,
    required this.recordings,
    required this.selectedIds,
    required this.dataStore,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by match key
    final sorted = List<Recording>.from(recordings)
      ..sort((a, b) => a.matchKey.compareTo(b.matchKey));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final recording = sorted[index];
        return _buildRecordingRow(context, recording);
      },
    );
  }

  Widget _buildRecordingRow(BuildContext context, Recording recording) {
    final theme = Theme.of(context);
    final isSelected = selectedIds.contains(recording.id);
    final match = dataStore.getMatchByKey(recording.matchKey);
    final matchDisplay = match?.displayName ?? recording.matchKey;
    final allianceColor =
        recording.allianceSide == 'red' ? Colors.red : Colors.blue;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          left: BorderSide(color: allianceColor, width: 4),
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => onToggleSelection(recording.id),
        ),
        title: Text(matchDisplay),
        subtitle: Text(
          '${recording.allianceSide.toUpperCase()} -- '
          '${recording.team1}, ${recording.team2}, ${recording.team3} -- '
          '${_formatFileSize(recording.fileSizeBytes)}',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          recording.originalFilename,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () => onToggleSelection(recording.id),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
