import 'dart:io';

import 'package:uuid/uuid.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../util/result.dart';
import 'alliance_suggester.dart';
import 'drive_access.dart';
import 'match_suggester.dart';
import 'video_metadata_service.dart';

/// Mutable state for an import session in progress.
class ImportSessionState {
  final String driveUri;
  final String driveLabel;
  final AllianceSuggestion allianceSuggestion;
  final List<ImportPreviewRow> rows;

  /// Track which rows the user has manually edited (for cascade logic).
  final Set<int> manuallySetRows;

  ImportSessionState({
    required this.driveUri,
    required this.driveLabel,
    required this.allianceSuggestion,
    required this.rows,
    Set<int>? manuallySetRows,
  }) : manuallySetRows = manuallySetRows ?? {};
}

/// A single row in the import preview.
class ImportPreviewRow {
  final VideoMetadata metadata;
  final VideoIdentity? identity;
  String? matchKey;
  String allianceSide;
  List<int> teams;
  bool isSelected;
  bool isAutoSkipped;
  String? autoSkipReason;
  bool requiresManualMatch;

  ImportPreviewRow({
    required this.metadata,
    this.identity,
    this.matchKey,
    this.allianceSide = 'red',
    this.teams = const [0, 0, 0],
    this.isSelected = true,
    this.isAutoSkipped = false,
    this.autoSkipReason,
    this.requiresManualMatch = false,
  });
}

/// Orchestrates the full import flow (stages 1-7 from system design).
class ImportPipeline {
  final DriveAccess driveAccess;
  final VideoMetadataService metadataService;
  final DataStore dataStore;
  final String storageDir;

  ImportPipeline({
    required this.driveAccess,
    required this.metadataService,
    required this.dataStore,
    required this.storageDir,
  });

  /// Stages 1+2+3+4: Connect, scan drive, extract metadata, suggest matches.
  /// Returns an ImportSessionState ready for user review.
  Future<Result<ImportSessionState>> scanDrive(String driveUri) async {
    // Stage 2: Get drive label
    final labelResult = await driveAccess.getDriveLabel(driveUri);
    final driveLabel =
        labelResult is Ok<String> ? labelResult.value : 'Unknown Drive';

    // Stage 2: List video files
    final filesResult = await driveAccess.listVideoFiles(driveUri);
    if (filesResult is Err<List<DriveFile>>) {
      return Err(filesResult.message);
    }
    final driveFiles = (filesResult as Ok<List<DriveFile>>).value;

    // Stage 2: Read config.json for alliance suggestion
    final configResult = await driveAccess.readTextFile(driveUri, 'config.json');
    String? configContent;
    if (configResult is Ok<String?>) {
      configContent = configResult.value;
    }
    final allianceSuggestion =
        AllianceSuggester.suggest(configJsonContent: configContent);

    // Stage 3: Extract metadata
    final metadataList = await metadataService.getMetadataBatch(driveFiles);

    // Sort by recordingStartTime (ascending), tiebreak by filename
    final indexed = List.generate(
      metadataList.length,
      (i) => MapEntry(i, metadataList[i]),
    );
    indexed.sort((a, b) {
      final aTime = a.value.recordingStartTime;
      final bTime = b.value.recordingStartTime;
      if (aTime == null && bTime == null) {
        return a.value.originalFilename.compareTo(b.value.originalFilename);
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final cmp = aTime.compareTo(bTime);
      if (cmp != 0) return cmp;
      return a.value.originalFilename.compareTo(b.value.originalFilename);
    });
    final sortedMetadata = indexed.map((e) => e.value).toList();

    // Stage 4: Suggest matches
    final eventKeys = dataStore.settings.selectedEventKeys;
    final schedule = dataStore.getMatchesForEvents(eventKeys);

    final suggestions = MatchSuggester.suggest(
      videos: sortedMetadata,
      schedule: schedule,
      gapMinMinutes: dataStore.settings.sequentialGapMinMinutes,
      gapMaxMinutes: dataStore.settings.sequentialGapMaxMinutes,
    );

    // Build preview rows
    final rows = <ImportPreviewRow>[];
    final defaultSide = allianceSuggestion.side ?? 'red';

    for (int i = 0; i < sortedMetadata.length; i++) {
      final meta = sortedMetadata[i];
      final suggestion = suggestions[i];

      // Compute video identity for skip tracking
      VideoIdentity? identity;
      if (meta.recordingStartTime != null &&
          meta.durationMs != null &&
          meta.fileSize != null) {
        identity = VideoIdentity(
          recordingStartTime: meta.recordingStartTime!,
          durationMs: meta.durationMs!,
          fileSizeBytes: meta.fileSize!,
        );
      }

      // Check auto-skip conditions
      bool isAutoSkipped = false;
      String? autoSkipReason;

      // Short video check
      if (meta.durationMs != null &&
          meta.durationMs! < dataStore.settings.shortVideoThresholdMs) {
        isAutoSkipped = true;
        autoSkipReason = 'Video is under 30 seconds';
      }

      // Previously skipped check
      if (!isAutoSkipped && identity != null && dataStore.isSkipped(identity)) {
        isAutoSkipped = true;
        autoSkipReason = 'This video was skipped before';
      }

      // Check if already imported (reimport prevention)
      if (!isAutoSkipped &&
          identity != null &&
          dataStore.getRecordingByIdentity(identity) != null) {
        isAutoSkipped = true;
        autoSkipReason = 'Already imported';
      }

      // Determine teams from match assignment
      List<int> teams = [0, 0, 0];
      if (suggestion.matchKey != null) {
        final match = dataStore.getMatchByKey(suggestion.matchKey!);
        if (match != null) {
          teams = _getTeamsForSide(match, defaultSide);
        }
      }

      rows.add(ImportPreviewRow(
        metadata: meta,
        identity: identity,
        matchKey: suggestion.matchKey,
        allianceSide: defaultSide,
        teams: teams,
        isSelected: !isAutoSkipped && suggestion.matchKey != null,
        isAutoSkipped: isAutoSkipped,
        autoSkipReason: autoSkipReason,
        requiresManualMatch:
            suggestion.confidence == MatchSuggestionConfidence.requiresManual,
      ));
    }

    return Ok(ImportSessionState(
      driveUri: driveUri,
      driveLabel: driveLabel,
      allianceSuggestion: allianceSuggestion,
      rows: rows,
    ));
  }

  /// Stages 6+7: Execute import for selected rows.
  /// Copies files, creates Recording entries, and saves ImportSession.
  ///
  /// [onCopyError] is called when a file copy fails. It receives the
  /// destination path that was being written. Return false to abort
  /// all remaining imports (e.g., drive disconnected), or true to
  /// skip this file and continue with the next.
  Future<Result<int>> executeImport(
    ImportSessionState state,
    void Function(int current, int total, String filename)? onProgress, {
    Future<bool> Function(String destPath)? onCopyError,
  }) async {
    final selectedRows = <ImportPreviewRow>[];
    for (final row in state.rows) {
      if (row.isSelected && row.matchKey != null) {
        selectedRows.add(row);
      }
    }

    if (selectedRows.isEmpty) {
      return const Ok(0);
    }

    final uuid = const Uuid();
    int importedCount = 0;
    final entries = <ImportSessionEntry>[];

    for (int i = 0; i < state.rows.length; i++) {
      final row = state.rows[i];

      if (!row.isSelected || row.matchKey == null) {
        // Record as not imported
        entries.add(ImportSessionEntry(
          originalFilename: row.metadata.originalFilename,
          wasSelected: false,
          wasAutoSkipped: row.isAutoSkipped,
          skipReason: row.autoSkipReason ?? (row.isAutoSkipped ? null : 'user_unchecked'),
          recordingStartTime: row.metadata.recordingStartTime,
          durationMs: row.metadata.durationMs,
          fileSizeBytes: row.metadata.fileSize,
        ));
        continue;
      }

      onProgress?.call(importedCount + 1, selectedRows.length,
          row.metadata.originalFilename);

      // Check for reimport
      if (row.identity != null) {
        final existing = dataStore.getRecordingByIdentity(row.identity!);
        if (existing != null) {
          entries.add(ImportSessionEntry(
            recordingId: existing.id,
            originalFilename: row.metadata.originalFilename,
            wasSelected: true,
            wasAutoSkipped: false,
            recordingStartTime: row.metadata.recordingStartTime,
            durationMs: row.metadata.durationMs,
            fileSizeBytes: row.metadata.fileSize,
          ));
          importedCount++;
          continue;
        }
      }

      // Generate UUID for filename
      final recordingId = uuid.v4();
      final ext = _getExtension(row.metadata.originalFilename);
      final destPath = '$storageDir/recordings/$recordingId$ext';

      // Copy file
      final copyResult = await driveAccess.copyToLocal(
        row.metadata.sourceUri,
        destPath,
        null,
      );

      if (copyResult is Err<void>) {
        // Delete partial file
        try {
          final file = File(destPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}

        // Ask the caller whether to continue or abort
        final shouldContinue = onCopyError != null
            ? await onCopyError(destPath)
            : true;

        entries.add(ImportSessionEntry(
          originalFilename: row.metadata.originalFilename,
          wasSelected: true,
          wasAutoSkipped: false,
          skipReason: shouldContinue ? 'copy_failed' : 'drive_disconnected',
          recordingStartTime: row.metadata.recordingStartTime,
          durationMs: row.metadata.durationMs,
          fileSizeBytes: row.metadata.fileSize,
        ));

        if (!shouldContinue) {
          // Abort remaining imports, but keep already-completed ones.
          // Record remaining selected rows as skipped.
          for (int j = i + 1; j < state.rows.length; j++) {
            final remaining = state.rows[j];
            entries.add(ImportSessionEntry(
              originalFilename: remaining.metadata.originalFilename,
              wasSelected: remaining.isSelected && remaining.matchKey != null,
              wasAutoSkipped: remaining.isAutoSkipped,
              skipReason: remaining.isSelected && remaining.matchKey != null
                  ? 'drive_disconnected'
                  : remaining.autoSkipReason,
              recordingStartTime: remaining.metadata.recordingStartTime,
              durationMs: remaining.metadata.durationMs,
              fileSizeBytes: remaining.metadata.fileSize,
            ));
          }
          break;
        }
        continue;
      }

      // Determine event key from match
      final match = dataStore.getMatchByKey(row.matchKey!);
      final eventKey = match?.eventKey ?? '';

      // Create recording
      final recording = Recording(
        id: recordingId,
        eventKey: eventKey,
        matchKey: row.matchKey!,
        allianceSide: row.allianceSide,
        fileExtension: ext,
        recordingStartTime:
            row.metadata.recordingStartTime ?? DateTime.now(),
        durationMs: row.metadata.durationMs ?? 0,
        fileSizeBytes: row.metadata.fileSize ?? 0,
        sourceDeviceType: row.metadata.isIOSRecording ? 'ios' : 'android',
        originalFilename: row.metadata.originalFilename,
        team1: row.teams.isNotEmpty ? row.teams[0] : 0,
        team2: row.teams.length > 1 ? row.teams[1] : 0,
        team3: row.teams.length > 2 ? row.teams[2] : 0,
        team4: row.teams.length > 3 ? row.teams[3] : 0,
        team5: row.teams.length > 4 ? row.teams[4] : 0,
        team6: row.teams.length > 5 ? row.teams[5] : 0,
      );

      await dataStore.addRecording(recording);
      importedCount++;

      entries.add(ImportSessionEntry(
        recordingId: recordingId,
        originalFilename: row.metadata.originalFilename,
        wasSelected: true,
        wasAutoSkipped: false,
        recordingStartTime: row.metadata.recordingStartTime,
        durationMs: row.metadata.durationMs,
        fileSizeBytes: row.metadata.fileSize,
      ));
    }

    // Stage 7: Create ImportSession
    final session = ImportSession(
      id: const Uuid().v4(),
      importedAt: DateTime.now(),
      driveLabel: state.driveLabel,
      driveUri: state.driveUri,
      videoCount: importedCount,
      entries: entries,
    );
    await dataStore.addImportSession(session);

    // Mark unselected videos in skip history
    for (final row in state.rows) {
      if (!row.isSelected && row.identity != null) {
        final reason = row.autoSkipReason ?? 'user_unchecked';
        if (!dataStore.isSkipped(row.identity!)) {
          await dataStore.markAsSkipped(row.identity!, reason);
        }
      }
    }

    return Ok(importedCount);
  }

  /// When user changes match at [rowIndex], cascade the change to subsequent rows.
  void cascadeMatchChange(
    ImportSessionState state,
    int rowIndex,
    String newMatchKey,
  ) {
    state.manuallySetRows.add(rowIndex);
    state.rows[rowIndex].matchKey = newMatchKey;

    // Update teams for the changed row
    final match = dataStore.getMatchByKey(newMatchKey);
    if (match != null) {
      state.rows[rowIndex].teams =
          _getTeamsForSide(match, state.rows[rowIndex].allianceSide);
    }

    // Cascade to subsequent rows
    final eventKeys = dataStore.settings.selectedEventKeys;
    final schedule = dataStore.getMatchesForEvents(eventKeys);
    final sortedSchedule = List<Match>.from(schedule)
      ..sort((a, b) {
        final aTime = a.bestTime;
        final bTime = b.bestTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

    String currentMatchKey = newMatchKey;

    for (int i = rowIndex + 1; i < state.rows.length; i++) {
      if (state.manuallySetRows.contains(i)) break;

      Match? nextMatch;
      for (int j = 0; j < sortedSchedule.length; j++) {
        if (sortedSchedule[j].matchKey == currentMatchKey) {
          if (j + 1 < sortedSchedule.length) {
            nextMatch = sortedSchedule[j + 1];
          }
          break;
        }
      }

      if (nextMatch == null) break;

      state.rows[i].matchKey = nextMatch.matchKey;
      state.rows[i].teams =
          _getTeamsForSide(nextMatch, state.rows[i].allianceSide);
      state.rows[i].requiresManualMatch = false;
      currentMatchKey = nextMatch.matchKey;
    }
  }

  /// Get team numbers for a given alliance side from a match.
  /// For 'full' (full-field), returns all 6 teams (red + blue).
  List<int> _getTeamsForSide(Match match, String side) {
    final List<String> teamKeys;
    if (side == 'full') {
      teamKeys = [...match.redTeamKeys, ...match.blueTeamKeys];
    } else if (side == 'red') {
      teamKeys = match.redTeamKeys;
    } else {
      teamKeys = match.blueTeamKeys;
    }
    // Strip "frc" prefix
    return teamKeys
        .map((key) => int.tryParse(key.replaceFirst('frc', '')) ?? 0)
        .toList();
  }

  /// Get file extension from filename.
  String _getExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0) return '.mp4';
    return filename.substring(dotIndex).toLowerCase();
  }
}
