# System Design: Match Record (Overview)

> This is a high-level architectural overview. For full details on any section — data model field definitions, API response formats, algorithm pseudocode, platform channel specs — see `SYSTEM_DESIGN_SUMMARY.md`.

## 1. What This Is

Offline-first Android tablet app for FRC Team 201. Students record matches on phones (one per alliance side, vertical video), transfer via USB-C flash drives, and the tablet provides a synchronized dual-video viewer for match strategy analysis between matches.

**Platform:** Android tablet, sideloaded. Target SDK: API 35 (do NOT target API 36+ — breaks forced-landscape orientation on tablets).

**Scope:** P0 (core) + P1 (drawing, integrity check) from SPECS.md. P2 items deferred.

## 2. Architecture

### Layers

```
UI Layer          — Screens, Tabs, Widgets (Material 3)
Business Logic    — Import Pipeline, Match Suggestion, Sync Engine
Data Layer        — DataStore (in-memory + JSON), TBA API, Drive Access
Platform Layer    — Video Metadata Channel (Kotlin), SAF, media_kit
```

### Key Principles

- **Offline-first:** All data in-memory, persisted to a single JSON file. Network only for TBA API.
- **Single data store:** One `DataStore` instance (extends `ChangeNotifier`) holds all app state. Loaded on startup, saved after every mutation. Widgets listen and rebuild.
- **No state management packages:** `StatefulWidget` + `ChangeNotifier`. No Provider/Riverpod/BLoC.
- **No ORM/SQL:** JSON file persistence. Data volume is tiny (~50 teams, ~100 matches, ~50 recordings). In-memory list operations are instantaneous at this scale.
- **Modular USB layer:** `DriveAccess` abstract interface hides SAF details.
- **Pure algorithms:** Match suggestion, alliance suggestion, scrub math, video identity — all pure functions, testable without mocks.

### Data Flow

```
TBA API (dio) ──> DataStore (in-memory) ──> Navigation UI (tabs, search, match lists)
                        ^                           |
USB Drive (SAF) ────────┘                           v
    |                                        Video Viewer (media_kit)
    └── copy files ──> App Storage <────────────┘
                        ^
DataStore <──── JSON file (persistence)
```

## 3. Project Structure

```
lib/
├── main.dart / app.dart          — Entry point, MaterialApp, theme
├── data/                         — Models, DataStore, JSON persistence
├── tba/                          — TBA API client + response models
├── import/                       — Drive access, metadata service, import pipeline,
│                                   match/alliance suggesters, integrity checker
├── viewer/                       — Sync engine, scrub controller, drawing controller
├── screens/                      — Main screen, video viewer, sync page, settings
├── tabs/                         — Search, Teams, Matches, Alliances tabs
├── widgets/                      — Match list/row, team/alliance tiles, search bar,
│                                   video pane, scrubber, drawing overlay, etc.
├── sync/                         — Import tab, history tab, storage tab
└── util/                         — Result type, constants, test flags

android/.../VideoMetadataChannel.kt  — ~50-60 lines: metadata extraction + ftyp detection
```

Each major module (`data/`, `import/`, `viewer/`, `tba/`, `screens/`) has a `README.md` with How to Use, Known Issues, and Technical Details sections.

## 4. Data Model

All data is plain Dart objects, serialized to one JSON file via `AppData` container.

### Core Entities

| Entity | Key Fields | Source |
|--------|-----------|--------|
| **Event** | eventKey, name, shortName, startDate, endDate, timezone | TBA API |
| **Team** | eventKey, teamNumber, nickname | TBA API |
| **Match** | matchKey, eventKey, compLevel, setNumber, matchNumber, time/actualTime/predictedTime, red/blueTeamKeys, red/blueScore, youtubeKey | TBA API |
| **Alliance** | eventKey, allianceNumber, name, picks (team keys) | TBA API |
| **Recording** | id (UUID), eventKey, matchKey, allianceSide, fileExtension, recordingStartTime, durationMs, fileSizeBytes, sourceDeviceType, teams 1-3 | Local (imported from USB) |
| **ImportSession** | id, importedAt, driveLabel, entries | Local |
| **VideoSkipEntry** | recordingStartTime, durationMs, fileSizeBytes, skipReason | Local |
| **AppSettings** | teamNumber, selectedEventKeys, threshold/scrub tunables, recordedMatchesOnly | Local |

### Key Relationships

- Matches and Teams are scoped to Events via `eventKey`.
- Recordings link to Matches via `matchKey`. Max 1 recording per `(matchKey, allianceSide)`.
- `MatchWithVideos` is a UI view model joining a Match with its Recordings and LocalRippedVideo. Not persisted.
- `VideoIdentity` = `(recordingStartTime, durationMs, fileSizeBytes)` — used for skip tracking, reimport prevention, and deletion tracking.

### Persistence

- Single JSON file: `{appDocumentsDir}/app_data.json`
- Atomic write: serialize to `.tmp`, then rename (crash-safe).
- Version field with cascading migrations for schema evolution.
- `DataStore` extends `ChangeNotifier`. Every mutation saves to disk then notifies listeners.

> Full field definitions, AppData container, and DataStore API: `SYSTEM_DESIGN_FULL.md` sections 4.1-4.4.

## 5. TBA Integration

`TbaClient` (dio-based) fetches events, teams, matches, and alliances from The Blue Alliance API v3.

**Multi-event support:** Settings stores a list of selected event keys. All tabs query across all selected events. When multiple events are selected, UI shows event short names on rows.

**Match display:** Matches are sorted by `time` (scheduled). Format: Q1, SF 3, F2, etc. Rows show teams (color-coded red/blue), scores (-1 = unplayed, shown as "---"), video availability icons.

**Match time:** `bestTime = actualTime ?? predictedTime ?? time`. FRC events drift 15-60 min from schedule; actual/predicted times are far more accurate.

> Full TBA data model, API response fields, verified findings, and display format rules: `SYSTEM_DESIGN_FULL.md` sections 5.1-5.4.

## 6. USB Import Pipeline

Seven-stage linear pipeline for importing videos from USB flash drives.

### Stages

1. **Connect** — Check for persisted SAF permission, or prompt user via `DriveAccess.pickDrive()`.
2. **Scan Drive** — List video files, read `config.json` for alliance side hint.
3. **Extract Metadata** — Platform channel reads duration, creation time, ftyp brand from each video's SAF URI. Computes platform-aware `recordingStartTime` (iOS creation_time = start; Android = end, subtract duration).
4. **Suggest Matches** — `MatchSuggester` maps videos to matches using timestamps and sequential gaps.
5. **User Review** — Import preview UI. User can edit match assignments (cascades to subsequent rows), toggle alliance side, change teams, select/deselect.
6. **Execute Import** — Copy selected files to `{externalStorageDir}/recordings/{uuid}{ext}`. Add Recordings to DataStore. Wakelock during copy. Skip already-imported files (VideoIdentity check).
7. **Finalize** — Create ImportSession. Mark unselected/auto-skipped videos in skip history.

### Match Suggestion Algorithm

- First video: nearest match by timestamp.
- Subsequent videos: gap < 10min = next sequential match; gap > 20min = nearest by timestamp; gap 10-20min = ambiguous, requires manual.
- Manual edit cascades to subsequent non-manually-set rows.

### Alliance Suggestion

Reads `config.json` from drive root for `{"alliance": "red|blue"}`. No config = user picks manually.

### Drive Disconnection

Monitored during review and copy stages. Mid-copy abort keeps completed imports, deletes partial files.

### File Storage

All recordings in `{externalStorageDir}/recordings/`. Filename: `{uuid}{ext}`. Path derived, not stored. Free space checked via `StatFs` platform channel. `android:hasFragileUserData="true"` preserves data on uninstall.

> Full pipeline details, state classes, video identity spec, reimport logic: `SYSTEM_DESIGN_FULL.md` sections 6.1-6.8.

## 7. Video Viewer

### Dual-Player Sync

Two `media_kit` Player instances: "earlier" and "later" (by `recordingStartTime`). Sync offset = difference in recording start times. Earlier player is primary clock; later player tracks `earlierPos - syncOffset`.

**Unified timeline:** Scrub bar spans `min(start1, start2)` to `max(end1, end2)`. Panes show countdown/ended messages when outside their video's range.

**Single-video mode:** One player when only one recording exists or user selects red/blue-only view.

### Non-Linear Scrubbing

- Touch down on video = pause + anchor.
- Horizontal drag = non-linear scrub (power curve: `normalized^2.5 * maxRange`).
- Seek throttling: cancel-and-replace pattern (one seek in-flight, latest pending dispatched on completion).
- Position stream suppressed during scrub to prevent flicker.

### Other Viewer Features

- **Audio:** 3-state toggle: muted / red audio / blue audio.
- **View modes:** Both sides / red only / blue only.
- **Layout:** Forced landscape, immersive sticky. Control sidebar (~72px) with playback, view, and drawing controls.
- **Edit metadata:** Per-pane pencil icon opens bottom sheet to edit match assignment, alliance side, teams.
- **Lifecycle:** Lock landscape + immersive + wakelock on entry; restore all on exit.

> Full sync math, scrub formula, layout diagram, lifecycle details: `SYSTEM_DESIGN_FULL.md` sections 7.1-7.7.

## 8. Drawing Overlay (P1)

- `CustomPainter` + `Listener` (raw pointer events). No library.
- Active when paused via play/pause button. Scrubbing disabled during drawing.
- Fixed bright red, 3.5px strokes. Quadratic bezier smoothing.
- Undo/redo stacks. In-memory only (cleared on viewer exit).
- Opacity via `Paint` color alpha (not `Opacity` widget — avoids offscreen buffer overhead).
- Multi-touch intentionally interleaves into one stroke.

> Full drawing spec: `SYSTEM_DESIGN_FULL.md` section 8.

## 9. iOS Detection

Video `creation_time` means different things per platform: iOS = recording start, Android = recording end. Getting this wrong shifts sync offset by the full video duration (~2.5 min).

**Detection:** ftyp major brand in first 32 bytes (`qt  ` = iOS, `isom`/`mp42` = Android). File extension as fallback (`.MOV` = iOS). Both checked in the platform channel's `getVideoMetadata` call.

> Full ftyp spec and byte offsets: `SYSTEM_DESIGN_FULL.md` section 9.

## 10. Navigation & Screens

Four routes via plain `Navigator.push`/`pop`: MainScreen, VideoViewer, SyncPage, SettingsPage.

**MainScreen:** AppBar with search bar + sync button + settings. `IndexedStack` body preserving all tab states (Search, Teams, Matches, Alliances). Bottom NavigationBar.

**Search:** Owned by MainScreen. Team/alliance chips + debounced autocomplete. Cross-tab flows: tapping a team adds a chip and switches to Search tab.

**Settings:** Team number, multi-event picker (fetch from TBA), sync/storage shortcuts, tunable thresholds, log viewer.

**Storage Management:** Two modes (tablet / flash drive) using shared list component. Bulk selection patterns: select all, all but our team, all from past events. Deletion adds identity to skip history.

> Full widget hierarchy, tab state details, viewer lifecycle: `SYSTEM_DESIGN_FULL.md` sections 10-12.

## 11. Startup Integrity Check (P1)

`IntegrityChecker.reconcile()` runs on every launch. Compares recordings directory against DataStore:
- Files without DataStore entries: delete (crashed import leftovers).
- DataStore entries without files: remove + add to skip history.
- Log all cleanup. Toast if anything was cleaned.

> Full spec: `SYSTEM_DESIGN_FULL.md` section 14.

## 12. Error Handling

- **Result type:** Sealed `Result<T>` with `Ok` and `Err` variants. ~20 lines, no package.
- **Recoverable errors:** SnackBar (network, file copy, metadata failures).
- **Blocking errors:** AlertDialog (database corruption, storage full).
- **Degraded data:** Visual indicators on affected rows (amber, "Unknown" labels).
- **Logging:** `logger` package. Log import operations, TBA fetches, errors. Do NOT log per-frame video events.

## 13. Dependencies

**Runtime:** `media_kit` (video playback), `dio` (HTTP), `saf_util`/`saf_stream` (USB via SAF), `uuid`, `path_provider`, `url_launcher`, `logger`, `wakelock_plus`.

**Dev-only:** `mocktail` (testing mocks).

**Removed:** `flutter_video_info` (replaced by custom platform channel), `drift`/`sqlite3_flutter_libs` (replaced by JSON persistence).

**Custom native:** One Kotlin platform channel (~50-60 lines) for video metadata extraction from SAF URIs + ftyp brand detection.

> Full dependency table with version rationale and removed dependency history: `SYSTEM_DESIGN_FULL.md` section 2.

## 14. Testing

Unit tests cover: DataStore, match/alliance suggestion, integrity check, video identity, iOS detection, TBA client, import pipeline, scrub math, video sync. NOT unit tested: widget rendering, platform channel, SAF operations (all tested manually on device).

> Full testing matrix: `SYSTEM_DESIGN_FULL.md` section 15.

## 15. Key Decisions

The full document has a 42-entry decision log (`SYSTEM_DESIGN_FULL.md` section 17). Most significant:

- JSON + in-memory over SQLite/drift (tiny data volume, no benefit from SQL at this scale)
- Custom platform channel over `flutter_video_info` (reads from SAF URIs directly, adds ftyp detection)
- Plain `Navigator.push`/`pop` over GoRouter (4 screens, simple flows)
- No USB auto-detection (SAF has no insertion events; user taps Sync manually)
- Pure function algorithms for all import logic (testable without mocks)
- `addRecording` enforces uniqueness and cleans up replaced files inline
- Unified scrub bar timeline spanning both videos' full range
- Drawing opacity via Paint color, not Opacity widget (avoids per-frame offscreen buffer)
