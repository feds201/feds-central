import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../util/constants.dart';

/// Shared list component for displaying video recordings.
/// Used by both tablet storage mode and flash drive mode.
class StorageVideoList extends StatelessWidget {
  final List<Recording> recordings;
  final Set<String> selectedIds;
  final DataStore dataStore;
  final void Function(String id) onToggleSelection;
  final void Function(Recording recording) onPlayVideo;

  const StorageVideoList({
    super.key,
    required this.recordings,
    required this.selectedIds,
    required this.dataStore,
    required this.onToggleSelection,
    required this.onPlayVideo,
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

  String _getEventShortName(String eventKey) {
    for (final event in dataStore.events) {
      if (event.eventKey == eventKey) {
        return event.shortName;
      }
    }
    return eventKey;
  }

  Widget _buildRecordingRow(BuildContext context, Recording recording) {
    final theme = Theme.of(context);
    final isSelected = selectedIds.contains(recording.id);
    final match = dataStore.getMatchByKey(recording.matchKey);
    final matchDisplay = match?.displayName ?? recording.matchKey;
    final allianceColor = AppColors.colorForAllianceSide(recording.allianceSide);
    final eventShortName = _getEventShortName(recording.eventKey);

    return InkWell(
      onTap: () => onToggleSelection(recording.id),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
            left: BorderSide(color: allianceColor, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggleSelection(recording.id),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Match label (bold)
                  Text(
                    matchDisplay,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Line 2: Team numbers · event short name
                  Text(
                    '${_formatTeams(recording)}  \u00b7  $eventShortName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Line 3: File size · original filename
                  Text(
                    '${recording.fileSizeBytes != null ? _formatFileSize(recording.fileSizeBytes!) : 'Unknown size'}  \u00b7  ${recording.originalFilename}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: IconButton(
                icon: const Icon(Icons.play_circle_outline),
                iconSize: 28,
                onPressed: () => onPlayVideo(recording),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTeams(Recording recording) {
    if (recording.allianceSide == 'full') {
      final teams = [
        recording.team1, recording.team2, recording.team3,
        recording.team4, recording.team5, recording.team6,
      ].where((t) => t > 0);
      return teams.join(', ');
    }
    return '${recording.team1}, ${recording.team2}, ${recording.team3}';
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
