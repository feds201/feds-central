# Known Issues

## 1. Unhandled notification exception crashes the entire app

**Severity: Critical** | `lib/notifications/notification_service.dart:40-92`

`showMatchNotifications()` and `_showMatchNotification()` have zero error handling. If the notification plugin throws for any reason (permissions, platform bug, device constraint), the exception is unhandled.

Making it worse: in `main_screen.dart:241`, the call is fire-and-forget (no `await`). This means the TBA sync completes fine, the UI updates... and then seconds later the Dart runtime hits the unhandled Future exception and crashes the entire app. The user has no idea what happened or why.

**Trigger:** Any notification plugin failure during/after TBA sync.

## 2. Video viewer crashes on corrupted or missing video files

**Severity: Critical** | `lib/screens/video_viewer.dart:160-182`

Three `player.open(Media(path))` calls have no try-catch. If a video file is missing (deleted after import), corrupted (bad USB transfer), or inaccessible, the entire video viewer screen crashes with an unhandled exception.

Same bug exists in `lib/sync/video_preview_dialog.dart:24` — previewing a bad video during import also crashes the dialog.

**Trigger:** Open any match where a video file is corrupted or was deleted from disk. Very likely during FRC competitions with USB drive transfers.

## 3. Reimporting a match orphans the old video file on disk

**Severity: High** | `lib/data/data_store.dart:162-172`

`addRecording()` silently removes the old DB entry for the same `matchKey + allianceSide`, but never deletes the old video file from disk. The old file becomes permanently orphaned — invisible to the app, consuming storage, and impossible to clean up through the UI.

```dart
existing.removeWhere((r) =>
    r.matchKey == recording.matchKey &&
    r.allianceSide == recording.allianceSide);  // DB entry gone, file stays
```

**Trigger:** Re-import the same match/alliance from a different drive or after re-recording. Orphaned files accumulate over the competition, slowly filling storage.

## 4. Failed `addRecording()` orphans the just-copied video file

**Severity: High** | `lib/import/import_pipeline.dart:371`

During import, the video file is copied to disk first (line 296-300), then `await dataStore.addRecording(recording)` is called (line 371) with no try-catch. If the DB write fails (disk full, JSON serialization error), the file is already on disk but has no database entry — orphaned and unrecoverable.

**Trigger:** Disk nearly full during a multi-video import. Early videos fill the disk, later ones fail to persist metadata, leaving orphaned files that make the problem worse.

## 5. Dual-video scrubber bar broken on initial load

**Severity: Moderate** | `lib/viewer/sync_engine.dart:120-126`, `lib/screens/video_viewer.dart:227-233`

When `SyncEngine` is created immediately after `player.open()`, `player.state.duration` is still `Duration.zero` (metadata loads asynchronously). The `unifiedDuration` getter returns `null`, so the scrubber bar shows 0:00 duration and is unusable.

It self-heals once the duration stream fires, but there's a window where the user sees a broken timeline and can't scrub. If a user tries to scrub during this window, seeks are clamped to `Duration.zero`.

**Trigger:** Open any match with red+blue dual recordings. Always happens briefly on load.
