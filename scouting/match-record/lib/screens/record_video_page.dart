import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../import/storage_checker.dart';
import '../util/constants.dart';
import 'video_viewer.dart';

/// Full-screen camera recording page for capturing match video.
///
/// Pre-fills match info from the tapped match row. After recording,
/// saves the video and navigates to VideoViewer in paused state.
class RecordVideoPage extends StatefulWidget {
  final MatchWithVideos matchWithVideos;
  final DataStore dataStore;

  const RecordVideoPage({
    super.key,
    required this.matchWithVideos,
    required this.dataStore,
  });

  @override
  State<RecordVideoPage> createState() => _RecordVideoPageState();
}

class _RecordVideoPageState extends State<RecordVideoPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraError;

  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  late String _allianceSide;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _allianceSide = _defaultAllianceSide();
    _lockLandscape();
    _initCamera();
  }

  /// Default to the side our team is on in this match, or 'red' as fallback.
  String _defaultAllianceSide() {
    final teamNumber = widget.dataStore.settings.teamNumber;
    if (teamNumber == null) return 'red';
    final teamKey = 'frc$teamNumber';
    final match = widget.matchWithVideos.match;
    if (match.redTeamKeys.contains(teamKey)) return 'red';
    if (match.blueTeamKeys.contains(teamKey)) return 'blue';
    return 'red';
  }

  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
  }

  Future<void> _restoreOrientation() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    await WakelockPlus.disable();
  }

  Future<void> _initCamera() async {
    // Request camera + microphone permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted) {
      setState(() => _cameraError = 'Camera permission denied');
      return;
    }
    if (!micStatus.isGranted) {
      setState(() => _cameraError = 'Microphone permission denied');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras found');
        return;
      }

      // Prefer rear camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Camera initialization failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _cameraController?.dispose();
    _restoreOrientation();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || _isRecording) return;

    // Check storage before recording
    final docsDir = await getApplicationDocumentsDirectory();
    final storageStatus = await StorageChecker.check(docsDir.path);

    if (!mounted) return;

    if (storageStatus == StorageStatus.blocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough storage space to record.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (storageStatus == StorageStatus.low) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Low Storage'),
          content: const Text(
            'Device storage is running low (under 1 GB free). '
            'Recording may fail. Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _elapsed = Duration.zero;
      });
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _recordingStartTime != null) {
          setState(() {
            _elapsed = DateTime.now().difference(_recordingStartTime!);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;

    _elapsedTimer?.cancel();
    setState(() => _isSaving = true);

    try {
      final xFile = await _cameraController!.stopVideoRecording();
      final recordingEnd = DateTime.now();
      final durationMs =
          recordingEnd.difference(_recordingStartTime!).inMilliseconds;

      // Move file to recordings directory
      final uuid = const Uuid().v4();
      final docsDir = await getApplicationDocumentsDirectory();
      final destPath =
          '${docsDir.path}/${AppConstants.recordingsDirName}/$uuid.mp4';

      // Ensure directory exists
      await Directory('${docsDir.path}/${AppConstants.recordingsDirName}')
          .create(recursive: true);

      // Move the temp file to the recordings directory
      final sourceFile = File(xFile.path);
      try {
        await sourceFile.rename(destPath);
      } catch (_) {
        // rename can fail across filesystems; fall back to copy+delete
        await sourceFile.copy(destPath);
        await sourceFile.delete();
      }

      final destFile = File(destPath);
      final fileSizeBytes = await destFile.length();

      // Build teams list from the match
      final teams = _getTeamsForSide(widget.matchWithVideos.match, _allianceSide);

      final recording = Recording(
        id: uuid,
        eventKey: widget.matchWithVideos.match.eventKey,
        matchKey: widget.matchWithVideos.match.matchKey,
        allianceSide: _allianceSide,
        fileExtension: '.mp4',
        recordingStartTime: _recordingStartTime,
        durationMs: durationMs,
        fileSizeBytes: fileSizeBytes,
        sourceDeviceType: 'tablet',
        originalFilename:
            'recorded_${_recordingStartTime!.toIso8601String()}.mp4',
        team1: teams.isNotEmpty ? teams[0] : 0,
        team2: teams.length > 1 ? teams[1] : 0,
        team3: teams.length > 2 ? teams[2] : 0,
        team4: teams.length > 3 ? teams[3] : 0,
        team5: teams.length > 4 ? teams[4] : 0,
        team6: teams.length > 5 ? teams[5] : 0,
      );

      await widget.dataStore.addRecording(recording);

      if (!mounted) return;

      // Navigate to viewer with the newly recorded video, starting paused.
      // Pop this page first, then push the viewer so back goes to match list.
      final updatedMwv =
          widget.dataStore.getMatchWithVideos(recording.matchKey);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VideoViewer(
            matchWithVideos: updatedMwv ??
                widget.matchWithVideos,
            dataStore: widget.dataStore,
            startPaused: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recording: $e')),
        );
      }
    }
  }

  /// Get team numbers for a given alliance side from a match.
  List<int> _getTeamsForSide(Match match, String side) {
    final List<String> teamKeys;
    if (side == 'full') {
      teamKeys = [...match.redTeamKeys, ...match.blueTeamKeys];
    } else if (side == 'red') {
      teamKeys = match.redTeamKeys;
    } else {
      teamKeys = match.blueTeamKeys;
    }
    return teamKeys
        .map((key) => int.tryParse(key.replaceFirst('frc', '')) ?? 0)
        .toList();
  }

  /// Check if a recording already exists for the current match + alliance side.
  bool _hasExistingRecording() {
    return widget.dataStore.hasRecordingForSide(
      widget.matchWithVideos.match.matchKey,
      _allianceSide,
    );
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final match = widget.matchWithVideos.match;

    // Error state
    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _cameraError!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final teams = _getTeamsForSide(match, _allianceSide);
    final allianceColor = AppColors.colorForAllianceSide(_allianceSide);
    final existingWarning = _hasExistingRecording();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Camera preview — fills available space
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                // Recording indicator
                if (_isRecording)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fiber_manual_record,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'REC ${_formatElapsed(_elapsed)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Saving overlay
                if (_isSaving)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Saving recording...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Control sidebar
          Container(
            width: 200,
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                // Match name
                Text(
                  match.displayName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Event name
                Text(
                  widget.matchWithVideos.eventShortName ??
                      match.eventKey,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Alliance side picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _allianceChip('red', 'Red', AppColors.redAllianceLight),
                    const SizedBox(width: 6),
                    _allianceChip('blue', 'Blue', AppColors.blueAllianceLight),
                    const SizedBox(width: 6),
                    _allianceChip('full', 'Full', AppColors.fullAllianceLight),
                  ],
                ),
                const SizedBox(height: 8),

                // Existing recording warning
                if (existingWarning)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Recording exists for this side',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Team numbers
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: allianceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    teams.where((t) => t > 0).join(' \u00b7 '),
                    style: TextStyle(
                      color: allianceColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                // Record / Stop button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : (_isRecording ? _stopRecording : _startRecording),
                    icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                    label: Text(_isRecording ? 'Stop' : 'Record'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _isRecording ? Colors.grey[800] : Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isRecording || _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allianceChip(String side, String label, Color color) {
    final isSelected = _allianceSide == side;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null),
      ),
      selected: isSelected,
      selectedColor: color,
      visualDensity: VisualDensity.compact,
      onSelected: _isRecording
          ? null
          : (_) {
              setState(() => _allianceSide = side);
            },
    );
  }
}
