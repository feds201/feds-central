import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'video_preview_dialog.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../import/drive_access.dart';
import '../import/import_pipeline.dart';
import '../import/local_drive_access.dart';
import '../import/usb_drive_service.dart';
import '../import/video_metadata_service.dart';
import '../util/constants.dart';
import '../util/result.dart';
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

class _ImportTabState extends State<ImportTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ImportSessionState? _sessionState;
  bool _isScanning = false;
  bool _isImporting = false;
  String? _error;
  int _importCurrent = 0;
  int _importTotal = 0;
  String _importFilename = '';

  /// Whether the current import session is from a local source (Camera/Quick Share).
  bool _isLocalSource = false;
  /// Rolling time window for local sources (hours).
  int _localTimeWindowHours = 12;
  /// The active LocalDriveAccess when importing from a local source.
  LocalDriveAccess? _activeLocalDriveAccess;

  /// Detected USB drives (null = not yet scanned, empty = no drives found).
  List<DetectedUsbDrive>? _detectedDrives;
  bool _isDetectingDrives = false;
  bool _hasStoragePermission = true;
  final UsbDriveService _usbDriveService = UsbDriveService();

  late final VideoMetadataService _metadataService;
  late ImportPipeline _pipeline;

  @override
  void initState() {
    super.initState();
    _metadataService = VideoMetadataService();
    // Initialize with a dummy pipeline; it gets replaced when a source is selected
    _pipeline = ImportPipeline(
      driveAccess: const LocalDriveAccess(dirPath: '', label: ''),
      metadataService: _metadataService,
      dataStore: widget.dataStore,
      storageDir: widget.storageDir,
    );
    _checkPermissionAndDetectDrives();
  }

  Future<void> _checkPermissionAndDetectDrives() async {
    final status = await Permission.manageExternalStorage.status;
    if (mounted) {
      setState(() => _hasStoragePermission = status.isGranted);
    }
    await _detectUsbDrives();
  }

  Future<void> _detectUsbDrives() async {
    setState(() => _isDetectingDrives = true);
    try {
      final drives = await _usbDriveService.detectDrives();
      if (mounted) {
        setState(() {
          _detectedDrives = drives;
          _isDetectingDrives = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _detectedDrives = [];
          _isDetectingDrives = false;
        });
      }
    }
  }

  Future<void> _connectDrive(String driveUri, {DateTime? newerThan}) async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    final result = await _pipeline.scanDrive(driveUri, newerThan: newerThan);

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

  Future<void> _connectLocalSource(LocalDriveAccess access) async {
    final dir = Directory(access.dirPath);
    if (!await dir.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${access.label} folder not found')),
        );
      }
      return;
    }

    setState(() {
      _isLocalSource = true;
      _localTimeWindowHours = 12;
      _activeLocalDriveAccess = access;
    });

    // Create a pipeline with the local drive access
    _pipeline = ImportPipeline(
      driveAccess: access,
      metadataService: _metadataService,
      dataStore: widget.dataStore,
      storageDir: widget.storageDir,
    );

    final newerThan = DateTime.now().subtract(Duration(hours: _localTimeWindowHours));
    await _connectDrive(access.dirPath, newerThan: newerThan);
  }

  Future<void> _expandTimeWindow() async {
    if (_activeLocalDriveAccess == null) return;

    // If user has manually edited rows, confirm before re-scanning
    if (_sessionState != null && _sessionState!.manuallySetRows.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Re-scan?'),
          content: const Text(
            'You have manually edited match assignments. '
            'Expanding the time window will re-scan and reset your changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Re-scan'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _localTimeWindowHours += 12;
    });

    final newerThan = DateTime.now().subtract(Duration(hours: _localTimeWindowHours));
    await _connectDrive(_activeLocalDriveAccess!.dirPath, newerThan: newerThan);
  }

  void _resetToSourceSelection() {
    setState(() {
      _sessionState = null;
      _isScanning = false;
      _isImporting = false;
      _isLocalSource = false;
      _activeLocalDriveAccess = null;
      _error = null;
    });
    _detectUsbDrives();
  }

  /// Connect a USB drive source (no time window, with optional pre-set alliance side).
  Future<void> _connectUsbSource(DetectedUsbDrive detected) async {
    final access = LocalDriveAccess(
      dirPath: detected.drive.path,
      label: detected.drive.label,
    );
    final dir = Directory(access.dirPath);
    if (!await dir.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${access.label} is no longer connected')),
        );
      }
      _detectUsbDrives();
      return;
    }

    setState(() {
      _isLocalSource = false;
      _activeLocalDriveAccess = access;
    });

    _pipeline = ImportPipeline(
      driveAccess: access,
      metadataService: _metadataService,
      dataStore: widget.dataStore,
      storageDir: widget.storageDir,
    );

    await _connectDrive(access.dirPath);

    // After scan completes, if alliance side was detected, apply it to all rows
    if (detected.allianceSide != null && _sessionState != null) {
      _onSetAllAllianceSide(detected.allianceSide!);
    }
  }

  /// Check if the drive is still connected. Returns true if connected.
  Future<bool> _checkDriveConnected() async {
    if (_sessionState == null) return false;
    return _pipeline.driveAccess.hasPermission(_sessionState!.driveUri);
  }

  /// Show a dialog when the drive is disconnected during review.
  /// Returns true if the user re-plugged and we confirmed connection,
  /// false if the user cancelled.
  Future<bool> _showDriveDisconnectedDialog() async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DriveDisconnectedDialog(
        driveAccess: _pipeline.driveAccess,
        driveUri: _sessionState!.driveUri,
      ),
    );

    return result ?? false;
  }

  Future<void> _executeImport() async {
    if (_sessionState == null) return;

    // Check drive connection before starting import
    final connected = await _checkDriveConnected();
    if (!connected) {
      final reconnected = await _showDriveDisconnectedDialog();
      if (!reconnected || !mounted) return;
    }

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
      onCopyError: (destPath) async {
        // Check if the error is due to drive disconnection
        final stillConnected = await _checkDriveConnected();
        if (!stillConnected) {
          // Clean up partial file
          try {
            final file = File(destPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
          return false; // Signal to abort remaining imports
        }
        return true; // Not a disconnect issue, continue with next file
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

  void _onEventChanged(int rowIndex, String? eventKey) {
    if (_sessionState == null || eventKey == null) return;

    setState(() {
      final row = _sessionState!.rows[rowIndex];
      row.eventKey = eventKey;
      // Clear match selection since it may not belong to the new event
      row.matchKey = null;
      row.teams = [0, 0, 0];
      row.isSelected = false;

      // Cascade event to subsequent rows
      for (int i = rowIndex + 1; i < _sessionState!.rows.length; i++) {
        if (_sessionState!.manuallySetRows.contains(i)) break;
        _sessionState!.rows[i].eventKey = eventKey;
      }
    });
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
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
              onPressed: _resetToSourceSelection,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        ),
      );
    }

    if (_sessionState == null) {
      return _buildSourceSelection();
    }

    return _buildPreviewList();
  }

  Widget _buildSourceSelection() {
    final mappedDrives = _detectedDrives
        ?.where((d) => d.allianceSide != null)
        .toList() ?? [];
    final unmappedDrives = _detectedDrives
        ?.where((d) => d.allianceSide == null)
        .toList() ?? [];
    final noDrives = _detectedDrives != null && _detectedDrives!.isEmpty;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Permission warning banner
            if (!_hasStoragePermission) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Storage permission required for USB drives',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Grant'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Icon(Icons.video_library, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Select a video source',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Local sources first
            FilledButton.icon(
              onPressed: () => _connectLocalSource(
                const LocalDriveAccess(dirPath: kCameraDir, label: 'Camera'),
              ),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Camera'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _connectLocalSource(
                const LocalDriveAccess(dirPath: kQuickShareDir, label: 'Quick Share'),
              ),
              icon: const Icon(Icons.share),
              label: const Text('Quick Share'),
            ),

            // USB drives section
            const SizedBox(height: 24),
            const Divider(indent: 48, endIndent: 48),
            const SizedBox(height: 16),

            // Alliance-detected USB drives
            ...mappedDrives.map((detected) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UsbDriveButton(
                  detected: detected,
                  onTap: () => _connectUsbSource(detected),
                ),
              );
            }),

            // Unmapped USB drives
            ...unmappedDrives.map((detected) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => _connectUsbSource(detected),
                  icon: const Icon(Icons.usb),
                  label: Text('USB: ${detected.drive.label}'),
                ),
              );
            }),

            // No drives — disabled button
            if (noDrives)
              Column(
                children: [
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.usb),
                    label: const Text('USB Drive'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No USB drive detected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

            // Still detecting
            if (_isDetectingDrives && _detectedDrives == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),

            // Refresh button
            const SizedBox(height: 8),
            IconButton(
              onPressed: _isDetectingDrives ? null : () {
                _checkPermissionAndDetectDrives();
              },
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh USB drives',
            ),
          ],
        ),
      ),
    );
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

        // Time window strip for local sources
        if (_isLocalSource) _buildTimeWindowStrip(),

        // Import progress
        if (_isImporting) _buildProgressBar(),

        // Preview rows
        Expanded(
          child: ListView.builder(
            itemCount: state.rows.length,
            itemBuilder: (context, index) {
              final row = state.rows[index];
              final showMultiEvent =
                  widget.dataStore.settings.selectedEventKeys.length > 1;
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
                onEventChanged: showMultiEvent
                    ? (eventKey) => _onEventChanged(index, eventKey)
                    : null,
                showEventSelector: showMultiEvent,
                onPlayPreview: () => _playPreview(row),
              );
            },
          ),
        ),

        // Confirm button — bottom padding accounts for snackbar height
        // so the button doesn't get obscured when a snackbar appears.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
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
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 60),
                padding: const EdgeInsets.symmetric(horizontal: 48),
              ),
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
          // Back button to source selection
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: _resetToSourceSelection,
            tooltip: 'Back to source selection',
          ),

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
            color: AppColors.redAlliance,
            onTap: () => _onSetAllAllianceSide('red'),
          ),
          const SizedBox(width: 4),
          _AllianceButton(
            label: 'BLUE',
            color: AppColors.blueAlliance,
            onTap: () => _onSetAllAllianceSide('blue'),
          ),
          const SizedBox(width: 4),
          _AllianceButton(
            label: 'FULL',
            color: AppColors.fullAlliance,
            onTap: () => _onSetAllAllianceSide('full'),
          ),
        ],
      ),
    );
  }

  void _playPreview(ImportPreviewRow row) {
    showDialog(
      context: context,
      builder: (ctx) => VideoPreviewDialog(filePath: row.metadata.sourceUri),
    );
  }

  Widget _buildTimeWindowStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'Showing last ${_localTimeWindowHours}h',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Expand +12h'),
            onPressed: _expandTimeWindow,
            visualDensity: VisualDensity.compact,
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

/// Color-coded button for a USB drive with a detected alliance side.
class _UsbDriveButton extends StatelessWidget {
  final DetectedUsbDrive detected;
  final VoidCallback onTap;

  const _UsbDriveButton({
    required this.detected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final side = detected.allianceSide!;
    final Color color;
    final String label;

    switch (side) {
      case 'red':
        color = AppColors.redAlliance;
        label = 'Sync Red Matches';
      case 'blue':
        color = AppColors.blueAlliance;
        label = 'Sync Blue Matches';
      case 'full':
        color = AppColors.fullAlliance;
        label = 'Sync Full Field Matches';
      default:
        color = Colors.grey;
        label = 'Sync Matches';
    }

    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.usb),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(
            detected.drive.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}

/// Dialog shown when the drive is disconnected during import review or copy.
class _DriveDisconnectedDialog extends StatefulWidget {
  final DriveAccess driveAccess;
  final String driveUri;

  const _DriveDisconnectedDialog({
    required this.driveAccess,
    required this.driveUri,
  });

  @override
  State<_DriveDisconnectedDialog> createState() =>
      _DriveDisconnectedDialogState();
}

class _DriveDisconnectedDialogState extends State<_DriveDisconnectedDialog> {
  bool _isChecking = false;

  Future<void> _retryConnection() async {
    setState(() => _isChecking = true);
    final connected = await widget.driveAccess.hasPermission(widget.driveUri);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (connected) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drive still not connected'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Drive Disconnected'),
      content: const Text(
        'The USB drive has been disconnected. '
        'Plug it back in and tap Retry, or cancel.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isChecking ? null : _retryConnection,
          child: _isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Retry'),
        ),
      ],
    );
  }
}
