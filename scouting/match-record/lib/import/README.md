# Import Pipeline

This module handles importing match videos from USB flash drives into the app. Each drive holds video files recorded by a phone during FRC matches, plus an optional `config.json` that declares which alliance the phone was filming.

## How to Use This Module

### End-to-end import (7 stages)

`ImportPipeline` orchestrates the full import flow. You provide it a `DriveAccess` implementation, a `VideoMetadataService`, a `DataStore`, and a local storage directory.

```dart
final pipeline = ImportPipeline(
  driveAccess: driveAccess,   // TestDriveAccess or a real SAF implementation
  metadataService: VideoMetadataService(),
  dataStore: dataStore,
  storageDir: appStorageDir,
);
```

**Stages 1-4: Scan and preview.** Call `scanDrive` with a drive URI to connect, list video files, extract metadata, and auto-suggest match assignments. Returns an `ImportSessionState` containing a list of `ImportPreviewRow`s ready for user review.

```dart
final result = await pipeline.scanDrive(driveUri);
if (result is Ok<ImportSessionState>) {
  final state = result.value;
  // state.rows -- one row per video, sorted by recording start time
  // state.allianceSuggestion -- parsed from config.json on the drive
  // state.driveLabel -- human-readable drive name
}
```

**Stage 5: User review (handled by UI).** The user sees the preview table and can:
- Toggle which videos to import (checkbox per row).
- Change the suggested match assignment on any row.
- Override the alliance side.

When the user changes a match assignment, call `cascadeMatchChange` to propagate sequential match assignments to subsequent rows (stops at the next manually-edited row or end of schedule):

```dart
pipeline.cascadeMatchChange(state, rowIndex, newMatchKey);
```

**Stages 6-7: Execute import.** Call `executeImport` to copy selected files to local storage, create `Recording` entries in the DataStore, and log an `ImportSession`. Unselected videos are recorded in skip history for future auto-skip.

```dart
final importResult = await pipeline.executeImport(
  state,
  (current, total, filename) {
    // progress callback
  },
  onCopyError: (destPath) async {
    // Return true to skip this file and continue, false to abort all remaining
    return true;
  },
);
```

### Using MatchSuggester independently

`MatchSuggester.suggest` is a pure static function. Pass it a list of videos (sorted by `recordingStartTime` ascending) and a match schedule:

```dart
final suggestions = MatchSuggester.suggest(
  videos: sortedMetadata,
  schedule: matchSchedule,
  gapMinMinutes: 10,
  gapMaxMinutes: 20,
);
// suggestions[i].matchKey -- suggested match, or null
// suggestions[i].confidence -- high, requiresManual, or none
```

The static `MatchSuggester.cascadeMatchChange` method can update a list of `MatchSuggestion` objects in-place without needing an `ImportPipeline` instance:

```dart
MatchSuggester.cascadeMatchChange(
  suggestions: suggestions,
  rowIndex: 2,
  newMatchKey: '2026mimid_qm5',
  schedule: matchSchedule,
  manuallySetRows: {2},
);
```

### Using AllianceSuggester independently

`AllianceSuggester.suggest` is a pure static function. Pass it the raw contents of `config.json` (or null):

```dart
final suggestion = AllianceSuggester.suggest(
  configJsonContent: '{"alliance": "blue"}',
);
// suggestion.side -- "red", "blue", or null
```

It is tolerant of malformed JSON, missing keys, wrong types, and extra whitespace/casing.

## Known Issues / Shortcomings

- **No real SAF implementation.** `DriveAccess` is an abstract interface. The only concrete implementation is `TestDriveAccess`, which reads sample videos from the device filesystem. There is no Android SAF (Storage Access Framework) implementation yet, so real USB drives cannot be accessed.

- **TestDriveAccess is hardcoded.** It defines exactly two test drives (an iOS drive and an Android drive) with one video each. Videos must be pushed to the device via adb (see `TestDriveAccess` doc comment). `pickDrive` always returns the first drive. `deleteFile` is a no-op. You cannot add drives at runtime.

- **VideoMetadataService uses synthetic data everywhere.** The `getMetadata` method always calls `_generateSyntheticMetadata` -- there is no platform channel path for real Android `MediaMetadataRetriever` extraction. On real devices, metadata (duration, date, ftyp brand) will be estimated from filenames and file sizes instead of read from the actual video container.

- **Synthetic duration estimation is approximate.** Duration is estimated as `fileSize / (200 KB/s)`, clamped to 10-120 seconds. This is a rough heuristic and will be inaccurate for real videos with varying bitrates.

- **Synthetic date extraction only parses Pixel filenames.** The `_extractDate` method parses the `PXL_YYYYMMDD_HHmmssSSS.mp4` format. Videos from other Android phones (Samsung, etc.) with different naming conventions will fall back to the file's `lastModified` timestamp, which may be unreliable on USB drives.

- **IntegrityChecker does not add orphaned recordings to skip history.** When a DB entry has no matching file on disk, the recording is deleted from the DataStore but is not added to skip history (unlike the design doc comment which mentions `reason: "deleted"`). This means the same video could be re-imported if the drive is connected again.

- **`bestTime` on Match is unix seconds, not milliseconds.** `_findNearestMatch` compares `timestamp.millisecondsSinceEpoch ~/ 1000` against `m.bestTime` (which is already seconds). This is correct, but worth noting: all schedule times in the Match model are epoch seconds from The Blue Alliance, while Dart's `DateTime` uses milliseconds natively.

## Technical Details

### DriveAccess abstraction

`DriveAccess` is the interface between the import pipeline and the underlying filesystem. It provides 7 operations:

| Method | Purpose |
|---|---|
| `pickDrive()` | Prompt user to select a drive folder; returns a persistent URI |
| `hasPermission(driveUri)` | Check if a previously-granted URI still has access |
| `listVideoFiles(driveUri)` | List video files in the drive root (non-recursive), filtered to `.mp4`, `.mov`, `.avi`, `.mkv`, `.3gp` |
| `readTextFile(driveUri, filename)` | Read a small text file by name (used for `config.json`) |
| `getDriveLabel(driveUri)` | Get the drive's display name / volume label |
| `copyToLocal(sourceUri, destPath, onProgress)` | Copy a drive file to a local path with progress reporting |
| `deleteFile(fileUri)` | Delete a file from the drive |

All fallible operations return `Result<T>` (an `Ok<T>` or `Err` with a message string). `DriveFile` carries `uri`, `name`, `sizeBytes`, and an optional `lastModified`.

### VideoMetadata and platform-aware timestamp logic

`VideoMetadata` holds fields extracted (or synthesized) from a video file: duration, date, resolution, framerate, mimetype, file size, and critically the **ftyp major brand** from the MP4/MOV container header.

**iOS vs Android creation_time difference:**

This is the central complexity of timestamp handling. iOS and Android embed the `creation_time` metadata field with opposite semantics:

- **iOS (QuickTime, `.MOV`):** `creation_time` = **start** of recording.
- **Android (MP4, `.mp4`):** `creation_time` = **end** of recording.

Detection uses a two-tier approach:
1. **Primary signal:** `ftypBrand`. A value of `"qt  "` (with trailing spaces) indicates Apple QuickTime (iOS). `"isom"` or `"mp42"` indicates generic MP4 (Android).
2. **Fallback:** File extension. `.mov` = iOS, everything else = Android.

The `recordingStartTime` getter normalizes this: for iOS files it returns `date` as-is; for Android files it subtracts `durationMs` from `date` to approximate the start time.

### Match suggestion algorithm

`MatchSuggester.suggest` takes videos sorted by recording start time and a match schedule, and assigns each video to a match. The algorithm works as follows:

1. **First video:** Find the match whose `bestTime` (epoch seconds) is nearest to the video's `recordingStartTime`.

2. **Subsequent videos:** Compute the time gap between this video's start time and the previous video's start time.
   - **Gap < `gapMinMinutes` (default 10):** Treat as sequential -- assign the next match in schedule order after the previous video's match.
   - **Gap > `gapMaxMinutes` (default 20):** Treat as a new session (e.g., lunch break) -- find the nearest match by timestamp again.
   - **Gap between min and max:** Ambiguous -- still suggests the next sequential match, but marks confidence as `requiresManual` so the UI highlights the row for user verification.

### Cascade logic

When a user manually changes a match assignment at row N, the cascade propagates sequential matches to rows N+1, N+2, ... until one of these stopping conditions:

- A row that was previously manually edited (tracked in `ImportSessionState.manuallySetRows`).
- The end of the match schedule (no next match exists).

Both `ImportPipeline.cascadeMatchChange` (operates on `ImportPreviewRow` objects, also updates team numbers) and the static `MatchSuggester.cascadeMatchChange` (operates on `MatchSuggestion` objects) implement this same logic.

### Video identity for skip tracking

`VideoIdentity` is a value object composed of three fields: `recordingStartTime`, `durationMs`, and `fileSizeBytes`. It implements `==` and `hashCode` for use as a map/set key.

During scan, each video with all three fields available gets a `VideoIdentity`. This identity is used for:

- **Reimport prevention:** If a recording with the same identity already exists in the DataStore, the row is auto-skipped with reason `"Already imported"`.
- **Skip history:** If a video was previously skipped (by the user or automatically), it is auto-skipped with reason `"This video was skipped before"`.
- **Post-import tracking:** After import completes, all unselected videos have their identity added to the skip history (with the auto-skip reason, or `"user_unchecked"` if manually deselected).

Videos without all three metadata fields (e.g., missing duration or file size) get `identity: null` and cannot participate in skip tracking.

### Integrity checker reconciliation

`IntegrityChecker.reconcile` runs at startup and performs bidirectional cleanup between the recordings directory on disk and the DataStore:

1. **Orphaned files** (on disk but not in DB): Deleted from disk.
2. **Orphaned DB entries** (in DB but file missing from disk): Removed from the DataStore.

If the recordings directory does not exist, it is created, and only the DB-to-disk check runs (to clean up entries pointing to nonexistent files). The method returns the total number of items cleaned up.
