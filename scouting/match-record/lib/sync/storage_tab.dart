import 'dart:io';

import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../import/local_drive_access.dart';
import '../util/constants.dart';
import 'storage_video_list.dart';

class StorageTab extends StatefulWidget {
  final DataStore dataStore;
  final String storageDir;
  final LocalDriveAccess? cameraAccess;
  final LocalDriveAccess? quickShareAccess;

  const StorageTab({
    super.key,
    required this.dataStore,
    required this.storageDir,
    this.cameraAccess,
    this.quickShareAccess,
  });

  @override
  State<StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends State<StorageTab> {
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  // Source file management
  List<FileSystemEntity> _cameraFiles = [];
  List<FileSystemEntity> _quickShareFiles = [];
  final Set<String> _selectedSourceFiles = {};
  bool _isDeletingSourceFiles = false;
  bool _isLoadingSourceFiles = false;

  List<Recording> get _recordings => widget.dataStore.allRecordings;

  @override
  void initState() {
    super.initState();
    _refreshSourceFiles();
  }

  Future<void> _refreshSourceFiles() async {
    setState(() => _isLoadingSourceFiles = true);

    final cameraFiles = await _listSourceFiles(widget.cameraAccess);
    final quickShareFiles = await _listSourceFiles(widget.quickShareAccess);

    if (mounted) {
      setState(() {
        _cameraFiles = cameraFiles;
        _quickShareFiles = quickShareFiles;
        _isLoadingSourceFiles = false;
      });
    }
  }

  Future<List<FileSystemEntity>> _listSourceFiles(LocalDriveAccess? access) async {
    if (access == null) return [];
    final dir = Directory(access.dirPath);
    if (!await dir.exists()) return [];

    const videoExtensions = {'.mp4', '.mov', '.avi', '.mkv', '.3gp'};
    final files = <FileSystemEntity>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last.toLowerCase();
      final ext = name.contains('.') ? '.${name.split('.').last}' : '';
      if (videoExtensions.contains(ext)) {
        files.add(entity);
      }
    }
    // Sort by modification time, newest first
    final stats = <FileSystemEntity, FileStat>{};
    for (final f in files) {
      stats[f] = await f.stat();
    }
    files.sort((a, b) => stats[b]!.modified.compareTo(stats[a]!.modified));
    return files;
  }

  void _toggleSourceFileSelection(String path) {
    setState(() {
      if (_selectedSourceFiles.contains(path)) {
        _selectedSourceFiles.remove(path);
      } else {
        _selectedSourceFiles.add(path);
      }
    });
  }

  Future<void> _deleteSelectedSourceFiles() async {
    if (_selectedSourceFiles.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Source Files'),
        content: Text(
          'Permanently delete ${_selectedSourceFiles.length} file(s) from the device? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingSourceFiles = true);

    int deletedCount = 0;
    for (final path in Set<String>.from(_selectedSourceFiles)) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _selectedSourceFiles.clear();
        _isDeletingSourceFiles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $deletedCount source file(s)')),
      );
      _refreshSourceFiles();
    }
  }

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
        if (r.team1 != ourTeam &&
            r.team2 != ourTeam &&
            r.team3 != ourTeam &&
            r.team4 != ourTeam &&
            r.team5 != ourTeam &&
            r.team6 != ourTeam) {
          _selectedIds.add(r.id);
        }
      }
    });
  }

  void _selectAllFromPastEvents() {
    final now = DateTime.now();
    final events = widget.dataStore.events;

    // Find event keys for events whose end date + 1 day buffer is before today
    final pastEventKeys = <String>{};
    for (final event in events) {
      final endWithBuffer = event.endDate.add(const Duration(days: 1));
      if (endWithBuffer.isBefore(now)) {
        pastEventKeys.add(event.eventKey);
      }
    }

    if (pastEventKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No past events found'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      for (final r in _recordings) {
        if (pastEventKeys.contains(r.eventKey)) {
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

  Widget _buildSourceFilesSection(
    String title,
    IconData icon,
    List<FileSystemEntity> files,
  ) {
    return ExpansionTile(
      leading: Icon(icon, size: 20),
      title: Text(
        '$title (${files.length})',
        style: const TextStyle(fontSize: 14),
      ),
      dense: true,
      children: files.map((entity) {
        final path = entity.path;
        final name = entity.uri.pathSegments.last;
        final isSelected = _selectedSourceFiles.contains(path);
        return InkWell(
          onTap: () => _toggleSourceFileSelection(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSourceFileSelection(path),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _selectAll,
                            child: const Text('Select All'),
                          ),
                          TextButton(
                            onPressed: _selectAllButOurTeam,
                            child: const Text('All But Ours'),
                          ),
                          TextButton(
                            onPressed: _selectAllFromPastEvents,
                            child: const Text('Past Events'),
                          ),
                          if (_selectedIds.isNotEmpty)
                            TextButton(
                              onPressed: _deselectAll,
                              child: const Text('Deselect'),
                            ),
                        ],
                      ),
                    ),
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

            // Source files sections (collapsible)
            if (_cameraFiles.isNotEmpty)
              _buildSourceFilesSection(
                'Camera Source Files',
                Icons.photo_camera,
                _cameraFiles,
              ),
            if (_quickShareFiles.isNotEmpty)
              _buildSourceFilesSection(
                'Quick Share Source Files',
                Icons.share,
                _quickShareFiles,
              ),

            // Refresh source files button
            if (widget.cameraAccess != null || widget.quickShareAccess != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _isLoadingSourceFiles ? null : _refreshSourceFiles,
                      icon: _isLoadingSourceFiles
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh source files'),
                    ),
                  ],
                ),
              ),

            // Delete buttons
            if (_selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                        'Delete ${_selectedIds.length} Imported Video(s)'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            if (_selectedSourceFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isDeletingSourceFiles
                        ? null
                        : _deleteSelectedSourceFiles,
                    icon: _isDeletingSourceFiles
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.delete_sweep),
                    label: Text(
                        'Delete ${_selectedSourceFiles.length} Source File(s)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
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
