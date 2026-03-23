# Progress

## What's Been Done

### Data Layer
- Full data model (`models.dart`): Event, Team, Match, Alliance, Recording, ImportSession, VideoIdentity, AppSettings, AppData -- all with JSON serialization round-trip.
- `DataStore` (ChangeNotifier): in-memory state with queries for matches by event/team, nearest match by timestamp, next match after a given key, recordings lookup, import session CRUD, skip history, and settings. Persists to disk via `JsonPersistence` after every mutation.
- `JsonPersistence`: atomic JSON file read/write with temp-file-then-rename pattern.
- `Result<T>` sealed type (Ok/Err) used throughout the codebase for error handling without exceptions.

### TBA Integration
- `TbaClient` (dio-based): fetches events by year, event details, teams, matches, and alliances from The Blue Alliance API. Parses all TBA response formats into the app's data model. Handles comp level normalization, match ordering, and playoff type detection.

### Navigation and Search
- `MainScreen`: app shell with four tabs (Search, Teams, Matches, Alliances), app bar with sync button, settings, and "recorded only" toggle.
- `AppSearchBar` with chip-based filtering (team chips, alliance chips). Chips are union-matched -- adding multiple chips shows matches involving any of the selected entities.
- `AutocompleteOverlay`: debounced (250ms) search across teams, alliances, and matches with color-coded type indicators. Clicking a match goes directly to the viewer; clicking a team/alliance creates a chip.
- `MatchesTab`, `TeamsTab`, `AlliancesTab`, `SearchTab`: all four tabs implemented. Matches tab shows user's matches first with divider. Teams tab shows user's team at top. Alliances tab conditionally visible when alliance data exists.
- `MatchList` / `MatchRow`: shared match list component with bold highlighting for search-matching teams/alliances, YouTube URL icon, local video icon, and recording availability indicator.
- `TeamTile` / `AllianceTile`: list item widgets for the Teams and Alliances tabs. Tapping navigates to Search tab with chip.
- `SyncButton`: app bar icon that opens the Sync UI page.
- "Recorded only" toggle: filters matches/search to only those with recordings. Persisted in AppSettings.

### Import Pipeline
- `DriveAccess` interface: abstract contract for USB drive operations (pickDrive, hasPermission, listVideoFiles, readTextFile, getDriveLabel, copyToLocal, deleteFile).
- `TestDriveAccess`: full implementation using embedded sample assets (two simulated drives -- iOS and Android -- with config.json alliance hints and realistic filenames/timestamps).
- `VideoMetadataService`: Dart wrapper that will call the platform channel on Android. Currently generates synthetic metadata on desktop (iOS detection via ftyp brand, platform-aware recording start time calculation, Android Pixel filename timestamp parsing).
- `VideoMetadata` model: sourceUri, duration, date, mimetype, dimensions, orientation, framerate, ftypBrand, fileSize. Includes `isIOSRecording` (ftyp brand + .mov fallback) and `recordingStartTime` (platform-aware: iOS creation_time = start, Android = end minus duration).
- `MatchSuggester`: pure function that auto-suggests match assignments for a list of videos. Uses timestamp proximity to schedule as primary signal, sequential gap logic with tunable thresholds (< 10 min = sequential, > 20 min = schedule lookup, 10-20 min = requires manual), and cascade logic when user manually edits a row.
- `AllianceSuggester`: pure function that parses config.json from drive root to suggest red/blue alliance side.
- `ImportPipeline`: orchestrates the full import flow -- scan drive, build preview rows, handle selections/deselections, execute import (copy files to device, create Recording entries, save ImportSession to DataStore). Tracks manual edits for cascade, auto-skips short videos and previously-skipped videos, manages video identity for reimport prevention.
- `IntegrityChecker`: startup reconciliation between disk and database. Deletes orphan files on disk with no DB entry, removes DB entries whose files are missing (marks as skip with "deleted" reason). Logs all cleanup actions.

### Sync UI
- `SyncPage`: full-screen page with three tabs (Import, History, Storage).
- `ImportTab`: drive connection flow (pickDrive -> scan -> preview list), import preview with per-row controls (match dropdown, alliance toggle, team editing), select/deselect with "select all", import execution with progress tracking, and error handling.
- `ImportPreviewRow` widget: displays video timestamp, duration, suggested match, teams, alliance side. All fields are tappable/editable. Rows requiring manual selection are highlighted.
- `HistoryTab`: lists past import sessions grouped by drive. Tapping reopens the import preview with that session's data for editing.
- `StorageTab` / `StorageVideoList`: tablet storage mode showing all imported recordings with file size, match assignment, alliance side. Supports checkbox selection with "select all" and "select all but our team". Delete removes from device and marks as skipped to prevent reimport.

### Video Viewer
- `VideoViewer`: forced-landscape full-screen viewer. Dual-video layout (left pane + right pane + control sidebar). Red on left, blue on right by default. Thin red/blue indicator lines at top of each pane. Star icon on the pane containing the user's team. Wakelock enabled during playback. Per-recording edit from viewer: pencil icon on each video pane opens a bottom sheet for editing that recording's match, alliance, and team assignment.
- `SyncEngine`: dual-player synchronization using recording start timestamps. Manages sync offset, intended positions (to handle async seek updates), countdown for later-starting video ("Other side starting in X..."), coordinated play/pause/seek across both players.
- `ScrubController`: non-linear touch scrub math (configurable exponent curve, dead zone, max range). Cancel-and-replace seek throttling to prevent seek queue buildup during fast scrubbing.
- `VideoPane` widget: single video pane with touch scrub gesture handling (finger down = pause, horizontal drag = non-linear scrub, finger up = stay paused). Drawing overlay integration.
- `ControlSidebar`: swap sides, 3-state mute toggle (muted / red audio / blue audio), 3-state view mode toggle (both / red only / blue only), play/pause, rewind 10s, forward 10s, restart. Scrollable if controls overflow. Drawing mode controls (undo, redo, clear) appear at bottom when paused.
- `ScrubberBar`: bottom scrub bar (standard drag-to-seek).
- View mode: single-video maximization when only one recording exists or when toggled to one side.

### Drawing
- `DrawingController` (ChangeNotifier): stroke list with undo/redo stacks, opacity control (1.0 when paused, 0.5 when playing), clear all. In-memory only.
- `DrawingOverlay`: Listener -> CustomPaint widget. Captures pointer events for stroke input. Renders with configurable opacity.
- `StrokePainter`: CustomPainter that draws strokes in fixed bright red with configured stroke width.

### Settings
- `SettingsPage`: team number, event configuration, tunable import thresholds (short video cutoff, sequential gap min/max), TBA data management (pull/re-pull), storage management entry point.

### Test Coverage
- 266 tests across 12 test files covering: data models (serialization round-trips, edge cases), DataStore (queries, mutations, persistence), JSON persistence (atomic writes, corruption handling), TBA client (API parsing, error handling), match suggester (timestamp matching, sequential logic, cascade, edge cases), alliance suggester (config parsing), import pipeline (full flow, skip tracking, identity), integrity checker (orphan cleanup, reconciliation), Result type, drawing controller (strokes, undo/redo, opacity), scrub controller (non-linear math, dead zone, throttling), sync engine (offset calculation, coordinated playback, countdown).

---

## What Still Needs to Be Done (P0/P1)

All remaining work is related to real USB flash drive support. Currently the app runs against `TestDriveAccess` with embedded sample videos.

1. **SAF DriveAccess implementation** (`lib/import/saf_drive_access.dart`) -- Real implementation of the `DriveAccess` interface using the `saf_util` and `saf_stream` packages for USB drive access via Android's Storage Access Framework. The interface is fully defined in `drive_access.dart`. Needs to implement: SAF folder picker with persisted permissions, video file enumeration by extension, config.json reading, drive label retrieval, streaming file copy with progress callback, and file deletion.

2. **Video metadata platform channel** (`android/app/src/main/kotlin/.../VideoMetadataChannel.kt`) -- Kotlin platform channel (~50-60 lines) that reads video metadata from SAF `content://` URIs using `MediaMetadataRetriever` plus ftyp brand detection for iOS device identification. The Dart side already exists in `video_metadata_service.dart` (currently returning synthetic metadata on desktop); it needs to call the real platform channel when running on Android.

3. **Free space check platform channel** -- Small Kotlin method using `StatFs` to check available device storage before starting an import. Currently not implemented. Constants for low storage warning (1GB) and import blocking (100MB) are already defined in `constants.dart`.

4. **`content://` URI playback validation** -- Verify that `media_kit` can play videos directly from SAF `content://` URIs without first copying them to local storage. This is documented as untested in `VIDEO_PROTOTYPE_LEARNINGS.md`. If it does not work, a workaround (e.g., temporary local copy or file descriptor passing) will be needed for import preview video playback (P2) and potentially for flash drive storage mode.

5. **Drive switch UI in import tab** -- Currently no way to disconnect or switch drives mid-session in the import tab. Needs a "Disconnect" or "Switch Drive" button so users can swap flash drives without leaving and re-entering the Sync UI.

6. **Flash drive storage mode** -- The Storage tab should show videos still on the connected flash drive (not just imported ones) with sync status indicators (imported vs not-yet-imported). Requires real USB drive access to implement — currently blocked on SAF DriveAccess implementation (#1 above).
