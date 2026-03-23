import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../import/drive_access.dart';
import '../import/import_pipeline.dart';
import '../import/test_drive_access.dart';
import '../import/video_metadata_service.dart';
import '../util/result.dart';
import '../util/test_flags.dart';
import 'import_preview_row.dart';

class ImportTab extends StatefulWidget {
  final DataStore dataStore;
  final String storageDir;

  const ImportTab({
    super.key,
    required this.dataStore,
    required this.storageDir,
  });

  @override
  State<ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<ImportTab> {
  ImportSessionState? _sessionState;
  bool _isScanning = false;
  bool _isImporting = false;
  String? _error;
  int _importCurrent = 0;
  int _importTotal = 0;
  String _importFilename = '';

  late final DriveAccess _driveAccess;
  late final VideoMetadataService _metadataService;
  late final ImportPipeline _pipeline;

  @override
  void initState() {
    super.initState();
    _driveAccess = TestFlags.useEmbeddedSampleVideos
        ? TestDriveAccess()
        : TestDriveAccess(); // TODO: Replace with SafDriveAccess for production
    _metadataService = VideoMetadataService();
    _pipeline = ImportPipeline(
      driveAccess: _driveAccess,
      metadataService: _metadataService,
      dataStore: widget.dataStore,
      storageDir: widget.storageDir,
    );

    // Auto-connect first test drive when test flags active
    if (TestFlags.useEmbeddedSampleVideos) {
      _connectDrive(TestDriveAccess.availableDriveUris.first);
    }
  }

  Future<void> _connectDrive(String driveUri) async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    final result = await _pipeline.scanDrive(driveUri);

    if (!mounted) return;

    switch (result) {
      case Ok(:final value):
        setState(() {
          _sessionState = value;
          _isScanning = false;
        });
      case Err(:final message):
        setState(() {
          _error = message;
          _isScanning = false;
        });
    }
  }

  Future<void> _pickDrive() async {
    final uri = await _driveAccess.pickDrive();
    if (uri != null && mounted) {
      _connectDrive(uri);
    }
  }

  Future<void> _executeImport() async {
    if (_sessionState == null) return;

    setState(() {
      _isImporting = true;
      _importCurrent = 0;
      _importTotal = 0;
    });

    final result = await _pipeline.executeImport(
      _sessionState!,
      (current, total, filename) {
        if (mounted) {
          setState(() {
            _importCurrent = current;
            _importTotal = total;
            _importFilename = filename;
          });
        }
      },
    );

    if (!mounted) return;

    setState(() => _isImporting = false);

    switch (result) {
      case Ok(:final value):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $value video(s)')),
          );
          // Reset to show fresh state
          setState(() => _sessionState = null);
        }
      case Err(:final message):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $message')),
          );
        }
    }
  }

  void _onMatchChanged(int rowIndex, String? matchKey) {
    if (_sessionState == null || matchKey == null) return;

    setState(() {
      _pipeline.cascadeMatchChange(_sessionState!, rowIndex, matchKey);
    });
  }

  void _onAllianceSideChanged(int rowIndex, String side) {
    if (_sessionState == null) return;

    setState(() {
      final row = _sessionState!.rows[rowIndex];
      row.allianceSide = side;

      // Update teams for the new side
      if (row.matchKey != null) {
        final match = widget.dataStore.getMatchByKey(row.matchKey!);
        if (match != null) {
          final teamKeys =
              side == 'red' ? match.redTeamKeys : match.blueTeamKeys;
          row.teams = teamKeys
              .map((key) => int.tryParse(key.replaceFirst('frc', '')) ?? 0)
              .toList();
        }
      }
    });
  }

  void _onSelectionChanged(int rowIndex, bool selected) {
    if (_sessionState == null) return;

    setState(() {
      final row = _sessionState!.rows[rowIndex];
      row.isSelected = selected;

      // Show toast if checking an auto-skipped video
      if (selected && row.isAutoSkipped && row.autoSkipReason != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(row.autoSkipReason!),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _onSelectAll(bool? selected) {
    if (_sessionState == null) return;
    setState(() {
      for (final row in _sessionState!.rows) {
        // Select-all doesn't check auto-skipped videos
        if (!row.isAutoSkipped && row.matchKey != null) {
          row.isSelected = selected ?? false;
        }
      }
    });
  }

  void _onSetAllAllianceSide(String side) {
    if (_sessionState == null) return;
    setState(() {
      for (final row in _sessionState!.rows) {
        row.allianceSide = side;
        // Update teams for the new side
        if (row.matchKey != null) {
          final match = widget.dataStore.getMatchByKey(row.matchKey!);
          if (match != null) {
            final teamKeys =
                side == 'red' ? match.redTeamKeys : match.blueTeamKeys;
            row.teams = teamKeys
                .map((key) => int.tryParse(key.replaceFirst('frc', '')) ?? 0)
                .toList();
          }
        }
      }
    });
  }

  void _onTeamsChanged(int rowIndex, List<int> teams) {
    if (_sessionState == null) return;
    setState(() {
      _sessionState!.rows[rowIndex].teams = teams;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning drive...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(
                color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _pickDrive,
              icon: const Icon(Icons.usb),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_sessionState == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.usb, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Insert a USB drive and tap Connect',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickDrive,
              icon: const Icon(Icons.usb),
              label: const Text('Connect Drive'),
            ),
            if (TestFlags.useEmbeddedSampleVideos) ...[
              const SizedBox(height: 12),
              const Text(
                'Test drives available:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...TestDriveAccess.availableDriveUris.map((uri) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: OutlinedButton(
                    onPressed: () => _connectDrive(uri),
                    child: Text(uri.replaceFirst('test://', '')),
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }

    return _buildPreviewList();
  }

  Widget _buildPreviewList() {
    final state = _sessionState!;
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

    final allSelected = state.rows
        .where((r) => !r.isAutoSkipped && r.matchKey != null)
        .every((r) => r.isSelected);
    final noneSelected = state.rows
        .where((r) => !r.isAutoSkipped && r.matchKey != null)
        .every((r) => !r.isSelected);

    final selectedCount =
        state.rows.where((r) => r.isSelected && r.matchKey != null).length;

    return Column(
      children: [
        // Header
        _buildHeader(state, allSelected, noneSelected),

        // Import progress
        if (_isImporting) _buildProgressBar(),

        // Preview rows
        Expanded(
          child: ListView.builder(
            itemCount: state.rows.length,
            itemBuilder: (context, index) {
              final row = state.rows[index];
              return ImportPreviewRowWidget(
                row: row,
                rowIndex: index,
                allMatches: sortedMatches,
                dataStore: widget.dataStore,
                onMatchChanged: (matchKey) => _onMatchChanged(index, matchKey),
                onAllianceSideChanged: (side) =>
                    _onAllianceSideChanged(index, side),
                onSelectionChanged: (selected) =>
                    _onSelectionChanged(index, selected),
                onTeamsChanged: (teams) => _onTeamsChanged(index, teams),
              );
            },
          ),
        ),

        // Confirm button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isImporting || selectedCount == 0
                  ? null
                  : _executeImport,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isImporting
                  ? 'Importing...'
                  : 'Import $selectedCount Video(s)'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    ImportSessionState state,
    bool allSelected,
    bool noneSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Select all checkbox
          Checkbox(
            value: allSelected ? true : (noneSelected ? false : null),
            tristate: true,
            onChanged: (value) => _onSelectAll(value ?? false),
          ),
          const SizedBox(width: 8),

          // Drive label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.driveLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${state.rows.length} videos found',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Alliance color buttons
          const Text('Set all: '),
          _AllianceButton(
            label: 'RED',
            color: Colors.red,
            onTap: () => _onSetAllAllianceSide('red'),
          ),
          const SizedBox(width: 4),
          _AllianceButton(
            label: 'BLUE',
            color: Colors.blue,
            onTap: () => _onSetAllAllianceSide('blue'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: _importTotal > 0 ? _importCurrent / _importTotal : null,
          ),
          const SizedBox(height: 4),
          Text(
            'Importing $_importCurrent of $_importTotal: $_importFilename',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AllianceButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AllianceButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
