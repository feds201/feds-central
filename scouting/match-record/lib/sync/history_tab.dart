import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../import/import_pipeline.dart';
import '../import/video_metadata_service.dart';
import '../util/format.dart';
import 'import_preview_row.dart';

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
          '${formatDateTime(session.importedAt)} -- ${session.videoCount} video(s)',
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => _openSessionReEdit(context, session),
      ),
    );
  }

  void _openSessionReEdit(BuildContext context, ImportSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SessionReEditPage(
          session: session,
          dataStore: dataStore,
        ),
      ),
    );
  }

}

/// Full-screen page that shows the import preview UI for a past import session,
/// allowing the user to re-edit match assignments, alliance sides, and teams.
///
/// No file operations -- videos are already on disk, this is metadata-only.
class _SessionReEditPage extends StatefulWidget {
  final ImportSession session;
  final DataStore dataStore;

  const _SessionReEditPage({
    required this.session,
    required this.dataStore,
  });

  @override
  State<_SessionReEditPage> createState() => _SessionReEditPageState();
}

class _SessionReEditPageState extends State<_SessionReEditPage> {
  late List<_ReEditRow> _rows;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _rows = _buildRowsFromSession();
  }

  /// Map ImportSessionEntry objects back to editable rows.
  /// For imported entries (recordingId != null), use current Recording data
  /// from the DataStore to populate current values.
  List<_ReEditRow> _buildRowsFromSession() {
    final rows = <_ReEditRow>[];

    for (final entry in widget.session.entries) {
      Recording? recording;
      if (entry.recordingId != null) {
        // Look up current recording data from DataStore
        for (final r in widget.dataStore.allRecordings) {
          if (r.id == entry.recordingId) {
            recording = r;
            break;
          }
        }
      }

      if (recording != null) {
        // Imported entry -- editable with current recording data
        final teams = recording.allianceSide == 'full'
            ? [
                recording.team1, recording.team2, recording.team3,
                recording.team4, recording.team5, recording.team6,
              ]
            : [recording.team1, recording.team2, recording.team3];
        rows.add(_ReEditRow(
          entry: entry,
          recording: recording,
          matchKey: recording.matchKey,
          allianceSide: recording.allianceSide,
          teams: teams,
          isImported: true,
        ));
      } else {
        // Not imported (skipped, failed, or recording since deleted)
        rows.add(_ReEditRow(
          entry: entry,
          recording: null,
          matchKey: null,
          allianceSide: 'red',
          teams: [0, 0, 0],
          isImported: false,
        ));
      }
    }

    return rows;
  }

  void _onMatchChanged(int rowIndex, String? matchKey) {
    if (matchKey == null) return;
    setState(() {
      final row = _rows[rowIndex];
      row.matchKey = matchKey;
      _hasChanges = true;

      // Update teams for the new match
      final match = widget.dataStore.getMatchByKey(matchKey);
      if (match != null) {
        final List<String> teamKeys;
        if (row.allianceSide == 'full') {
          teamKeys = [...match.redTeamKeys, ...match.blueTeamKeys];
        } else if (row.allianceSide == 'red') {
          teamKeys = match.redTeamKeys;
        } else {
          teamKeys = match.blueTeamKeys;
        }
        row.teams = teamKeys
            .map((key) => int.tryParse(key.replaceFirst('frc', '')) ?? 0)
            .toList();
      }
    });
  }

  void _onAllianceSideChanged(int rowIndex, String side) {
    setState(() {
      final row = _rows[rowIndex];
      row.allianceSide = side;
      _hasChanges = true;

      // Update teams for the new side
      if (row.matchKey != null) {
        final match = widget.dataStore.getMatchByKey(row.matchKey!);
        if (match != null) {
          final List<String> teamKeys;
          if (side == 'full') {
            teamKeys = [...match.redTeamKeys, ...match.blueTeamKeys];
          } else if (side == 'red') {
            teamKeys = match.redTeamKeys;
          } else {
            teamKeys = match.blueTeamKeys;
          }
          row.teams = teamKeys
              .map((key) => int.tryParse(key.replaceFirst('frc', '')) ?? 0)
              .toList();
        }
      }
    });
  }

  void _onTeamsChanged(int rowIndex, List<int> teams) {
    setState(() {
      _rows[rowIndex].teams = teams;
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    // Update recordings in DataStore
    for (final row in _rows) {
      if (!row.isImported || row.recording == null) continue;

      final updated = row.recording!.copyWith(
        matchKey: row.matchKey,
        allianceSide: row.allianceSide,
        team1: row.teams.isNotEmpty ? row.teams[0] : 0,
        team2: row.teams.length > 1 ? row.teams[1] : 0,
        team3: row.teams.length > 2 ? row.teams[2] : 0,
        team4: row.teams.length > 3 ? row.teams[3] : 0,
        team5: row.teams.length > 4 ? row.teams[4] : 0,
        team6: row.teams.length > 5 ? row.teams[5] : 0,
      );

      await widget.dataStore.updateRecording(updated);
    }

    // Update the import session
    final updatedSession = widget.session.copyWith(
      entries: widget.session.entries,
    );
    await widget.dataStore.updateImportSession(updatedSession);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventKeys = widget.dataStore.settings.selectedEventKeys;
    final allMatches = widget.dataStore.getMatchesForEvents(eventKeys);

    // Sort matches for the dropdown
    final sortedMatches = List<Match>.from(allMatches)
      ..sort((a, b) {
        final aTime = a.bestTime;
        final bTime = b.bestTime;
        if (aTime == null && bTime == null) {
          return a.matchKey.compareTo(b.matchKey);
        }
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.session.driveLabel}'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.usb, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.driveLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${formatDateTime(widget.session.importedAt)} -- '
                        '${widget.session.videoCount} imported',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final row = _rows[index];
                return _buildReEditRow(
                  context,
                  row,
                  index,
                  sortedMatches,
                );
              },
            ),
          ),

          // Save button
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReEditRow(
    BuildContext context,
    _ReEditRow row,
    int index,
    List<Match> allMatches,
  ) {
    final theme = Theme.of(context);

    if (!row.isImported) {
      // Non-imported entry -- show as disabled/greyed out
      return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: ListTile(
          leading: Icon(
            Icons.block,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            row.entry.originalFilename,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: Text(
            row.entry.skipReason ?? (row.entry.wasAutoSkipped ? 'Auto-skipped' : 'Not selected'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Imported entry -- show editable preview row using ImportPreviewRowWidget
    // Build a synthetic ImportPreviewRow to reuse the existing widget
    final previewRow = ImportPreviewRow(
      metadata: VideoMetadata(
        sourceUri: '',
        originalFilename: row.entry.originalFilename,
        durationMs: row.entry.durationMs,
        date: row.entry.recordingStartTime,
        fileSize: row.entry.fileSizeBytes,
      ),
      eventKey: row.recording?.eventKey,
      matchKey: row.matchKey,
      allianceSide: row.allianceSide,
      teams: row.teams,
      isSelected: true,
      isAutoSkipped: false,
    );

    final showMultiEvent =
        widget.dataStore.settings.selectedEventKeys.length > 1;

    return ImportPreviewRowWidget(
      row: previewRow,
      rowIndex: index,
      allMatches: allMatches,
      dataStore: widget.dataStore,
      onMatchChanged: (matchKey) => _onMatchChanged(index, matchKey),
      onAllianceSideChanged: (side) => _onAllianceSideChanged(index, side),
      onSelectionChanged: (_) {}, // No selection in re-edit mode
      onTeamsChanged: (teams) => _onTeamsChanged(index, teams),
      showEventSelector: showMultiEvent,
    );
  }

}

/// Mutable row for the re-edit UI.
class _ReEditRow {
  final ImportSessionEntry entry;
  final Recording? recording;
  String? matchKey;
  String allianceSide;
  List<int> teams;
  final bool isImported;

  _ReEditRow({
    required this.entry,
    required this.recording,
    required this.matchKey,
    required this.allianceSide,
    required this.teams,
    required this.isImported,
  });
}
