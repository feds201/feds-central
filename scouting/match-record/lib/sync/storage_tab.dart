import 'dart:io';

import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../util/constants.dart';
import 'storage_video_list.dart';

class StorageTab extends StatefulWidget {
  final DataStore dataStore;
  final String storageDir;

  const StorageTab({
    super.key,
    required this.dataStore,
    required this.storageDir,
  });

  @override
  State<StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends State<StorageTab> {
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  List<Recording> get _recordings => widget.dataStore.allRecordings;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(_recordings.map((r) => r.id));
    });
  }

  void _selectAllButOurTeam() {
    final ourTeam = widget.dataStore.settings.teamNumber;
    if (ourTeam == null) {
      _selectAll();
      return;
    }
    setState(() {
      for (final r in _recordings) {
        if (r.team1 != ourTeam && r.team2 != ourTeam && r.team3 != ourTeam) {
          _selectedIds.add(r.id);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Videos'),
        content: Text(
          'Delete ${_selectedIds.length} video(s) from tablet? '
          'They will also be marked as skipped so they won\'t be reimported.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final idsToDelete = Set<String>.from(_selectedIds);
    int deletedCount = 0;

    for (final id in idsToDelete) {
      final recording = _recordings.where((r) => r.id == id).firstOrNull;
      if (recording == null) continue;

      // Delete the file
      final filePath =
          '${widget.storageDir}/${AppConstants.recordingsDirName}/${recording.id}${recording.fileExtension}';
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Continue even if file deletion fails
      }

      // Delete from data store (also marks as skipped)
      await widget.dataStore.deleteRecording(id);
      deletedCount++;
    }

    if (mounted) {
      setState(() {
        _selectedIds.clear();
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $deletedCount video(s)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dataStore,
      builder: (context, _) {
        final recordings = _recordings;

        if (recordings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No imported videos',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Import videos from the Import tab',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Selection controls header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${recordings.length} recordings',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('Select All'),
                  ),
                  TextButton(
                    onPressed: _selectAllButOurTeam,
                    child: const Text('All But Ours'),
                  ),
                  if (_selectedIds.isNotEmpty)
                    TextButton(
                      onPressed: _deselectAll,
                      child: const Text('Deselect'),
                    ),
                ],
              ),
            ),

            // Recording list
            Expanded(
              child: StorageVideoList(
                recordings: recordings,
                selectedIds: _selectedIds,
                dataStore: widget.dataStore,
                onToggleSelection: _toggleSelection,
              ),
            ),

            // Delete button
            if (_selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isDeleting ? null : _deleteSelected,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.delete),
                    label: Text(
                        'Delete ${_selectedIds.length} Video(s)'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
