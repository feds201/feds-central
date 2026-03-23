# System Design: Match Record

## 1. Overview

Offline-first Android tablet app for FRC Team 201 (The FEDS). Students record each match on personal phones (one per alliance side, vertical video), transfer via USB-C flash drives, and the tablet provides a synchronized dual-video viewer for match strategy analysis between matches.

**Scope:** P0 (core) + P1 (drawing) from SPECS.md. P2 items (iOS support, API 36 migration, local ripped YouTube pipeline, multi-field support) are deferred.

**Reference documents:**
- Requirements: `SPECS.md`
- Video prototype findings: `VIDEO_PROTOTYPE_LEARNINGS.md`
- Drawing prototype findings: `DRAWING_PROTOTYPE_LEARNINGS.md`
- Previous strawman: `SYSTEM_DESIGN_STRAWMAN.md` (superseded by this document)

---

## 2. Platform & Dependencies

**Platform:** Android tablet, sideloaded (not Play Store)

**Target SDK: API 35 (Android 15)**

> ⚠️ **WARNING:** Do NOT target API 36+. Android 16 removes the ability to lock screen orientation on devices with display width >= 600dp (all tablets). This breaks the forced-landscape video viewer. This warning must also appear wherever the target SDK is configured in build files.

### Runtime Dependencies

| Package | Purpose |
|---|---|
| `media_kit` + `media_kit_video` + `media_kit_libs_video` + `media_kit_native_event_loop` | Video playback engine (proven in prototype) |
| `uuid` | UUID generation for recording filenames |
| `dio` | HTTP client for TBA API |
| `saf_util` | USB file access via SAF — folder picking, listing, metadata |
| `saf_stream` | USB file access via SAF — streaming file copy |
| `path_provider` | App directory paths |
| `url_launcher` | Open YouTube URLs in browser/app |
| `logger` | File-based logging for offline debugging |
| `wakelock_plus` | Prevent screen sleep during playback/import (media_kit does NOT keep screen awake — confirmed in prototype) |

### Dev-Only Dependencies

| Package | Purpose |
|---|---|
| `mocktail` | Testing mocks without code generation |

### Removed Dependencies

| Package | Why Removed |
|---|---|
| `flutter_video_info` | Replaced by our custom platform channel that reads metadata directly from SAF content:// URIs without copying files. See §6.2. |
| `drift` + `sqlite3_flutter_libs` | Replaced by JSON file persistence + in-memory data model. The data volume is tiny (~50 teams, ~100 matches, ~50 recordings) — SQLite ORM adds code generation overhead (`drift_dev` + `build_runner`), SQL complexity, and dependency weight for no benefit at this scale. |
| `drift_dev` + `build_runner` | No longer needed without drift. |

### Custom Native Code

One Kotlin platform channel (~50-60 lines total) for video metadata extraction and iOS device detection. See §6.2 for full specification.

> **Implementation note:** The ftyp brand detection code (§9) MUST be thoroughly documented with inline comments explaining what ftyp is, why `qt  ` indicates iOS, and why this matters for timestamp interpretation. This is non-obvious domain knowledge that will confuse future maintainers without explanation.

---

## 3. Architecture

### 3.1 Layers

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                       │
│  Screens, Tabs, Widgets (Material 3)             │
├─────────────────────────────────────────────────┤
│               Business Logic                     │
│  Import Pipeline, Match Suggestion, Sync Engine  │
├─────────────────────────────────────────────────┤
│                 Data Layer                        │
│  DataStore (in-memory + JSON), TBA API, Drive    │
├─────────────────────────────────────────────────┤
│              Platform Layer                       │
│  Video Metadata Channel (Kotlin), SAF, media_kit │
└─────────────────────────────────────────────────┘
```

**Key principles:**
- **Offline-first:** All data in-memory, persisted to a JSON file. Network only for TBA API pulls.
- **Single data store:** One `DataStore` instance holds all app state. Loaded into memory on startup, saved to disk after every mutation.
- **No state management packages:** `StatefulWidget` + `ChangeNotifier` for screen-local state. `DataStore` extends `ChangeNotifier` — widgets listen to it and rebuild on changes.
- **Modular USB layer:** DriveAccess interface abstracts SAF details (files prototype not yet complete — this boundary must be clean enough to swap implementations).

### 3.2 Data Flow

```
TBA API (dio) ──→ DataStore (in-memory) ──→ Navigation UI (tabs, search, match lists)
                        ↑                            │
USB Drive (SAF) ────────┘                            ↓
    │                                         Video Viewer (media_kit)
    └── copy files ──→ App Storage ←──────────────┘
                        ↑
DataStore ←──── JSON file (persistence)
```

### 3.3 Project Structure

```
lib/
├── main.dart                         // MediaKit.ensureInitialized(), runApp
├── app.dart                          // MaterialApp, theme
├── data/
│   ├── models.dart                   // all data model classes (Event, Team, Match, etc.)
│   ├── data_store.dart               // DataStore: in-memory state + JSON persistence + ChangeNotifier
│   └── json_persistence.dart         // atomic read/write of JSON file
├── tba/
│   ├── tba_client.dart               // dio-based TBA API client
│   └── tba_models.dart               // JSON parsing for TBA responses
├── import/
│   ├── drive_access.dart             // DriveAccess interface
│   ├── saf_drive_access.dart         // SAF implementation
│   ├── video_metadata_service.dart   // platform channel wrapper
│   ├── import_pipeline.dart          // orchestrates the full import flow
│   ├── match_suggester.dart          // pure function: suggest match for each video
│   └── alliance_suggester.dart       // pure function: suggest alliance side for drive
├── viewer/
│   ├── sync_engine.dart              // dual-player sync logic
│   ├── scrub_controller.dart         // non-linear scrub math + seek throttling
│   └── drawing_controller.dart       // stroke management, undo/redo
├── screens/
│   ├── main_screen.dart              // shell: app bar, tabs, search bar
│   ├── video_viewer.dart             // forced landscape video viewer
│   ├── sync_page.dart                // import, history, storage tabs
│   └── settings_page.dart
├── tabs/
│   ├── search_tab.dart
│   ├── teams_tab.dart
│   ├── matches_tab.dart
│   └── alliances_tab.dart
├── widgets/
│   ├── match_list.dart               // shared match list component
│   ├── match_row.dart                // single match row
│   ├── team_tile.dart
│   ├── alliance_tile.dart
│   ├── app_search_bar.dart           // search bar with chips
│   ├── autocomplete_overlay.dart
│   ├── sync_button.dart              // icon only (no badge — no USB auto-detection)
│   ├── video_pane.dart               // one side of the viewer
│   ├── control_sidebar.dart
│   ├── scrubber_bar.dart
│   ├── drawing_overlay.dart          // Listener → CustomPaint (opacity via Paint color)
│   └── stroke_painter.dart           // CustomPainter
├── sync/
│   ├── import_tab.dart               // import preview list (also reused by history_tab)
│   ├── import_preview_row.dart
│   ├── history_tab.dart              // tapping an entry reopens import_tab with that session's data
│   ├── storage_tab.dart
│   └── storage_video_list.dart       // shared list, two modes
└── util/
    ├── result.dart                   // sealed Result<T> (Ok/Err with String message)
    └── constants.dart                // tunable thresholds, defaults
```

```
android/app/src/main/kotlin/.../
└── VideoMetadataChannel.kt           // ~50-60 lines: MediaMetadataRetriever + ftyp
```

---

## 4. Data Model & Persistence

### 4.1 Approach

All app data lives in memory as plain Dart objects. Persisted to a single JSON file on disk. No SQL, no ORM, no code generation.

**Why this works:** The data volume is tiny — ~50 teams, ~100 matches, ~50 recordings, ~8 alliances per event. Even with multiple events loaded, the total in-memory footprint is well under 1MB. List operations (`where`, `firstWhere`, `any`) on these collections are instantaneous. There is no query that benefits from database indexes at this scale.

### 4.2 Data Model Classes

All classes have `toJson()` and `factory fromJson(Map<String, dynamic>)` methods for serialization.

**TBA Data:**

```dart
class Event {
  final String eventKey;          // e.g., "2026mimid"
  final String name;
  final String shortName;         // for display when multiple events loaded
  final DateTime startDate;
  final DateTime endDate;
  final int playoffType;          // 10 = double elim, etc.
  final String timezone;          // IANA timezone
}

class Team {
  final String eventKey;
  final int teamNumber;
  final String nickname;          // default ''
}

class Match {
  final String matchKey;          // e.g., "2026mimid_qm1"
  final String eventKey;
  final String compLevel;         // "qm", "sf", "f" (also "ef", "qf" for legacy)
  final int setNumber;
  final int matchNumber;
  final int? time;                // scheduled time, Unix seconds
  final int? actualTime;          // null if unplayed
  final int? predictedTime;       // TBA estimate
  final List<String> redTeamKeys; // ["frc201", "frc5166", "frc5712"]
  final List<String> blueTeamKeys;
  final int redScore;             // -1 = unplayed (never null, consistent with TBA)
  final int blueScore;            // -1 = unplayed (never null, consistent with TBA)
  final String winningAlliance;   // "red", "blue", or ""
  final String? youtubeKey;       // YouTube video ID (from TBA videos array), null if none

  /// Best available time for match suggestion algorithm.
  int? get bestTime => actualTime ?? predictedTime ?? time;
}
```

> **Design note:** Team keys stored as `List<String>` directly (not individual fields) because TBA returns them as arrays and some events (Einstein) have 4 teams per side.

> **YouTube key:** Stored directly on Match (not a separate collection) since it's always 0 or 1 per match for our events. Populated from the first `type: "youtube"` entry in TBA's `videos` array.

```dart
class Alliance {
  final String eventKey;
  final int allianceNumber;       // 1-8, or named at Worlds
  final String name;              // "Alliance 1" or "Newton"
  final List<String> picks;       // team keys
}
```

**Local Video Data:**

```dart
class Recording {
  final String id;                // UUID (also the filename on disk)
  final String eventKey;          // which event this recording belongs to
  final String matchKey;
  final String allianceSide;      // "red" or "blue"
  final String fileExtension;     // ".mp4", ".mov"
  final DateTime recordingStartTime; // computed (platform-aware)
  final int durationMs;
  final int fileSizeBytes;
  final String sourceDeviceType;  // "ios" or "android" (from ftyp detection)
  final String originalFilename;
  final int team1;                // } manually overridable
  final int team2;                // } during import
  final int team3;                // }
}
```

File path is derived: `{externalStorageDir}/recordings/{id}{fileExtension}`

**Uniqueness constraint:** Max 1 recording per `(matchKey, allianceSide)`. Enforced in `DataStore.addRecording()` — replaces any existing recording for that match+side.

```dart
class LocalRippedVideo {
  final String matchKey;          // unique per match
  final String filePath;
}
```

**Import / Sync Data:**

```dart
class ImportSession {
  final String id;                // UUID
  final DateTime importedAt;
  final String driveLabel;
  final String driveUri;          // SAF tree URI
  final int videoCount;           // how many were imported
  final List<ImportSessionEntry> entries;
}

class ImportSessionEntry {
  final String? recordingId;      // null if not imported
  final String originalFilename;
  final bool wasSelected;
  final bool wasAutoSkipped;
  final String? skipReason;       // "too_short", "previously_skipped"
  final DateTime? recordingStartTime; // } video identity
  final int? durationMs;          // } for skip
  final int? fileSizeBytes;       // } tracking
}

class VideoSkipEntry {
  final DateTime recordingStartTime;
  final int durationMs;
  final int fileSizeBytes;
  final String? skipReason;       // "user_unchecked", "too_short", "deleted"
}
```

**Settings:**

```dart
class AppSettings {
  int? teamNumber;
  List<String> selectedEventKeys;       // e.g., ["2026mimid", "2026mifor"]
  int shortVideoThresholdMs;            // default 30000
  int sequentialGapMinMinutes;          // default 10
  int sequentialGapMaxMinutes;          // default 20
  double scrubExponent;                 // default 2.5
  int scrubMaxRangeMs;                  // default 120000
  bool recordedMatchesOnly;             // default false — filters Matches tab, Search, and autocomplete to only show matches with recordings
}
```

> **"Recorded Only" toggle:** When `recordedMatchesOnly` is true, `DataStore.getMatchesWithVideosFiltered()` returns only matches where `hasRecordings || hasLocalRippedVideo`. The toggle icon in the app bar uses `Icons.videocam` (highlighted in primary color) when active and `Icons.videocam_off` when inactive. Teams and Alliances tabs are unaffected.

### 4.2.1 AppData Container

Top-level container for all persisted app state. Serialized as a single JSON file.

```dart
class AppData {
  static const int currentVersion = 1;

  final int version;              // migration version (see §4.3)
  final List<Event> events;
  final List<Team> teams;
  final List<Match> matches;
  final List<Alliance> alliances;
  final List<Recording> recordings;
  final List<LocalRippedVideo> localRippedVideos;
  final List<ImportSession> importSessions;
  final List<VideoSkipEntry> skipHistory;
  final AppSettings settings;
}
```

### 4.2.2 MatchWithVideos (View Model)

UI-layer view model used by `MatchList` and `MatchRow`. Constructed by querying the `DataStore` — not persisted.

```dart
class MatchWithVideos {
  final Match match;
  final Recording? redRecording;   // recording for red side, if any
  final Recording? blueRecording;  // recording for blue side, if any
  final LocalRippedVideo? localRippedVideo;
  final String? eventShortName;    // null when single event selected

  bool get hasRecordings => redRecording != null || blueRecording != null;
  bool get hasYouTube => match.youtubeKey != null;
  bool get hasLocalRippedVideo => localRippedVideo != null;
}
```

### 4.3 Persistence

Single JSON file: `{getApplicationDocumentsDirectory()}/app_data.json`

```dart
class JsonPersistence {
  /// Load all app data from disk. Returns empty AppData if file doesn't exist.
  /// Runs migrations if the stored version is older than AppData.currentVersion.
  Future<AppData> load();

  /// Save all app data to disk. Atomic write: write to temp file, then rename.
  /// This ensures a crash mid-write doesn't corrupt the file.
  Future<void> save(AppData data);
}
```

**Atomic write pattern:**
1. Serialize `AppData` to JSON string (includes `"version": AppData.currentVersion`)
2. Write to `app_data.json.tmp`
3. Rename `app_data.json.tmp` → `app_data.json` (atomic on all filesystems)

**Data migration:** The JSON file includes a `version` field. On load, if the stored version is older than `AppData.currentVersion`, run cascading migrations:

```dart
Map<String, dynamic> json = jsonDecode(contents);
int version = json['version'] ?? 0;
if (version == 0) { json = _migrateV0ToV1(json); }
if (version == 1) { json = _migrateV1ToV2(json); }
// ... etc
```

Each migration function transforms the raw JSON map in place (add fields with defaults, rename keys, restructure). This ensures the app can load data from any previous version, even if multiple versions were skipped (sideloaded app — updates are not sequential). All `fromJson` factories should also use default values for missing keys as a safety net.

### 4.4 DataStore

Central data access object. Extends `ChangeNotifier` so widgets can listen for changes.

```dart
class DataStore extends ChangeNotifier {
  final JsonPersistence _persistence;
  late AppData _data;

  /// Load from disk on startup. Call once in main().
  Future<void> init();

  // --- TBA Data ---
  List<Event> get events;
  List<Team> getTeamsForEvents(List<String> eventKeys);
  List<Match> getMatchesForEvents(List<String> eventKeys);
  List<Match> getMatchesForTeam(int teamNumber, List<String> eventKeys);
  Match? getNearestMatch(DateTime timestamp, List<String> eventKeys);
  List<Alliance> getAlliancesForEvents(List<String> eventKeys);
  Alliance? getAllianceForTeam(int teamNumber, List<String> eventKeys);
  bool get hasAllianceData;

  Future<void> setEvents(List<Event> events);
  Future<void> setTeamsForEvent(String eventKey, List<Team> teams);
  Future<void> setMatchesForEvent(String eventKey, List<Match> matches);
  Future<void> setAlliancesForEvent(String eventKey, List<Alliance> alliances);

  // --- Recordings ---
  List<Recording> getRecordingsForMatch(String matchKey);
  Recording? getRecordingByIdentity(VideoIdentity identity);  // for reimport check
  Future<void> addRecording(Recording recording);      // enforces match+side uniqueness (see below)
  Future<void> updateRecording(Recording recording);
  Future<void> deleteRecording(String id);              // also adds to skip history

  // --- Local Ripped Videos ---
  LocalRippedVideo? getLocalRippedVideo(String matchKey);

  // --- Import History ---
  List<ImportSession> get importSessions;
  Future<void> addImportSession(ImportSession session);
  Future<void> updateImportSession(ImportSession session); // for re-edit from history

  // --- Skip History ---
  bool isSkipped(VideoIdentity identity);
  Future<void> markAsSkipped(VideoIdentity identity, String reason);

  // --- Settings ---
  AppSettings get settings;
  Future<void> updateSettings(AppSettings settings);
}
```

**Every mutating method** calls `_persistence.save(_data)` then `notifyListeners()`. Widgets that depend on data use `ListenableBuilder` (or `AnimatedBuilder`) wrapping the `DataStore` to rebuild on changes.

**`addRecording` uniqueness enforcement:** Max 1 recording per `(matchKey, allianceSide)`. When adding a recording that conflicts:
1. Delete the old recording's file from disk
2. Add the old recording's video identity to skip history (reason: `replaced`)
3. Remove the old recording from the data store
4. Add the new recording

**Reimport prevention:** The import pipeline checks `DataStore.getRecordingByIdentity(identity)` before importing each video. If an identical recording already exists (same `VideoIdentity`), skip it — the video is already on the tablet. This prevents copying the same file twice when a user re-syncs a drive.

**Lookups:** All "get" methods are simple list operations — `where`, `firstWhere`, `any`. Match-by-team searches check `redTeamKeys.contains("frc$teamNumber")` — exact string match, no substring issues. At ~100 matches this takes <1ms.

---

## 5. TBA Integration

### 5.1 API Client

```dart
class TbaClient {
  final Dio _dio;
  static const _baseUrl = 'https://www.thebluealliance.com/api/v3';
  // API key stored as a constant (sideloaded app, not in Play Store)
  static const _apiKey = '...';

  Future<Result<List<TbaEvent>>> getEvents(int year);
  Future<Result<TbaEvent>> getEvent(String eventKey);
  Future<Result<List<TbaTeam>>> getTeams(String eventKey);
  Future<Result<List<TbaMatch>>> getMatches(String eventKey);
  Future<Result<List<TbaAlliance>?>> getAlliances(String eventKey);
}
```

All methods return `Result<T>` (see §13). Network errors produce `Err` with a user-readable message.

### 5.2 Event Selection (Multi-Event Support)

Settings stores `selected_event_keys` as a JSON array (e.g., `["2026mimid", "2026mifor"]`).

**Event picker UI in Settings:**
1. App fetches `/events/{year}` on first open (or when user taps refresh), where `year` is derived from `DateTime.now().year`. Results cached in the data store.
2. Dropdown shows all events for that year by name, sorted by start_date.
3. User selects an event → it appears as a chip with an X button.
4. "+" button adds another dropdown to pick another event.
5. "Load" button fetches TBA data (teams, matches, alliances) for ALL selected events.
6. Can re-load anytime to refresh data (e.g., after quals to get alliances/playoff matches).

**Multi-event behavior in the main UI:**
- All tabs query across all selected events.
- When multiple events are selected, match rows and team tiles show the event `short_name` (e.g., "Midland", "Forest Hills") as a subtle label.
- When only one event is selected, the event label is hidden.
- Alliances tab groups by event (section headers per event).
- Search works across all loaded events.

### 5.3 TBA Data Models

Based on **real API responses** from `2026mimid`, `2025micmp*`, and `2025cmptx` (verified March 2026).

**Match object key fields:**
| Field | Type | Notes |
|---|---|---|
| `key` | String | `"{event}_{compLevel}{setOrMatch}"` e.g., `2026mimid_qm1`, `2025micmp_sf3m1` |
| `comp_level` | String | `qm`, `sf`, `f` (modern). Also `ef`, `qf` (legacy) |
| `set_number` | int | For qm: always 1. For sf (double-elim): bracket position 1-13. For f: always 1. |
| `match_number` | int | For qm: match number 1-N. For sf (double-elim): always 1. For f: game 1-3. |
| `time` | int? | Scheduled time, **Unix seconds** (not ms!) |
| `actual_time` | int? | Actual start. **null if unplayed.** |
| `predicted_time` | int? | TBA running estimate |
| `alliances.red.score` | int | **-1 if unplayed** (not 0, not null) |
| `alliances.red.team_keys` | List\<String\> | `["frc201", "frc5166", "frc5712"]` — must strip `frc` prefix for display |
| `alliances.red.surrogate_team_keys` | List\<String\> | FIM surrogates |
| `alliances.red.dq_team_keys` | List\<String\> | Disqualified teams |
| `videos` | List\<{type, key}\> | `type: "youtube"`, `key` = YouTube video ID |
| `winning_alliance` | String | `"red"`, `"blue"`, or `""` (unplayed/tie) |

**Unplayed match indicators:** `actual_time == null` AND `score == -1` AND `winning_alliance == ""`.

**Alliances endpoint:** Returns `null` (not `[]`) before alliance selection. After selection, returns array of `{name, picks, status}`. At DCMP/Worlds, alliance names are division names (e.g., "Newton"), not numbers.

**Division structure (DCMP/Worlds):**
- Each division is a separate TBA event (e.g., `2025micmp1`)
- Division events have `parent_event_key` pointing to the parent (e.g., `2025micmp`)
- Parent event has `division_keys` listing all divisions
- Parent event has cross-division playoff matches only
- Our app treats each division as a separate event the user can select

> **Verified finding:** There is NO field indicator in TBA match data. The complete set of top-level keys on a match object is: `actual_time`, `alliances`, `comp_level`, `event_key`, `key`, `match_number`, `post_result_time`, `predicted_time`, `score_breakdown`, `set_number`, `time`, `videos`, `winning_alliance`. No `field`, `station`, or `arena` key exists at any nesting level. (Verified across 2026mimid, 2025micmp1, 2025arc, 2025cmptx.)

> **Data gap:** 2026mimid (a completed event) had only 32 qm + 2 f matches in TBA — the 13 double-elim bracket (sf) matches were absent despite alliances showing bracket records. 2025 events had all sf matches. This may be a TBA data ingestion issue for 2026. The app must handle events where playoff matches don't exist yet in TBA.

### 5.4 Match Display Format

**Match identifier** (for display in rows, viewer header, etc.):

| comp_level | Display Format | Example |
|---|---|---|
| `qm` | `Q{match_number}` | Q1, Q15, Q78 |
| `sf` | `SF {set_number}` | SF 1, SF 13 |
| `f` | `F{match_number}` | F1, F2, F3 |
| `ef` | `EF {match_number}` | EF 1 (legacy, rare) |
| `qf` | `QF {set_number}-{match_number}` | QF 2-1 (legacy) |

**Sort order:** By `time` (scheduled time, ascending). This naturally interleaves all match types correctly. If `time` is null, fall back to comp_level priority (qm=0 < ef=1 < qf=2 < sf=3 < f=4), then set_number, then match_number.

**Match row displays:**
- Match identifier (e.g., "Q15")
- Day/time (formatted from `time` field: "Fri 2:30 PM")
- Red teams (in red): "201 · 5166 · 5712"
- Blue teams (in blue): "8873 · 5424 · 5216"
- Scores (if played): red score | blue score. Winning side bold.
- If unplayed (score == -1): show "—" for both scores
- Video icons on right: YouTube icon (if match_videos has entry), camera icon (if recordings exist), film icon (if local_ripped_videos has entry)
- Event short_name label (only when multiple events loaded)
- Bold user's team number. Bold any team that caused this match to appear in search results.

---

## 6. USB Import Pipeline

### 6.1 Drive Access Abstraction

The file/USB prototype is not yet complete. This interface abstracts SAF so the implementation can be swapped.

```dart
/// A file on the drive, with metadata from the listing.
class DriveFile {
  final String uri;            // opaque identifier (SAF content:// URI)
  final String name;           // display name with extension (e.g., "IMG_1234.MOV")
  final int sizeBytes;
  final DateTime? lastModified;
}

/// Abstraction over USB drive access. Hides SAF details.
abstract class DriveAccess {
  /// Prompt user to pick a drive folder. Returns the drive URI
  /// (persisted permission) or null if cancelled.
  Future<String?> pickDrive();

  /// Check if a previously-persisted drive URI still has permission.
  Future<bool> hasPermission(String driveUri);

  /// List all files in the drive root (non-recursive). Filters to video
  /// files by extension (.mp4, .mov, .avi, .mkv, .3gp).
  Future<Result<List<DriveFile>>> listVideoFiles(String driveUri);

  /// Read a small file from the drive root by name. Used for config.json.
  /// Returns null if the file doesn't exist.
  Future<Result<String?>> readTextFile(String driveUri, String filename);

  /// Get the drive's display name / volume label.
  Future<Result<String>> getDriveLabel(String driveUri);

  /// Copy a drive file to a local path. Reports progress via callback.
  Future<Result<void>> copyToLocal(
    String sourceUri,
    String destPath,
    void Function(int bytesCopied)? onProgress,
  );

  /// Delete a file from the drive.
  Future<Result<void>> deleteFile(String fileUri);
}
```

**SAF implementation** (`SafDriveAccess`) uses `saf_util` for listing/metadata/delete and `saf_stream` for file copy. Maps `SafDocumentFile` → `DriveFile` internally.

### 6.2 Video Metadata Service (Platform Channel)

Replaces `flutter_video_info`. Reads metadata directly from SAF `content://` URIs via Android's `MediaMetadataRetriever`, plus reads the first 32 bytes for ftyp brand detection.

**Channel:** `com.feds201.match_record/video_metadata`

**Kotlin side** (~50-60 lines total):

Method `getVideoMetadata(uri: String)`:
1. Create `MediaMetadataRetriever`, `setDataSource(context, Uri.parse(uri))`
2. Extract: `METADATA_KEY_DURATION`, `METADATA_KEY_DATE`, `METADATA_KEY_MIMETYPE`, `METADATA_KEY_VIDEO_WIDTH`, `METADATA_KEY_VIDEO_HEIGHT`, `METADATA_KEY_VIDEO_ROTATION`, `METADATA_KEY_CAPTURE_FRAMERATE`
3. **Parse date in Kotlin** — `METADATA_KEY_DATE` returns a string in 3GPP format (`"yyyyMMddTHHmmss.SSSZ"`), but format varies across OEMs. Parse with `SimpleDateFormat` (try multiple formats), return as epoch milliseconds (`Long`). This isolates all date format weirdness to the Kotlin side — Dart just does `DateTime.fromMillisecondsSinceEpoch()`. Parse `METADATA_KEY_DURATION` to `Long` in Kotlin as well.
4. Open `ContentResolver.openInputStream(uri)`, read first 32 bytes for ftyp box
5. Parse ftyp: bytes 4-7 must be ASCII `ftyp`, bytes 8-11 are the major brand (4 chars)
6. Return all fields as a `Map<String, Any?>`: numeric fields as `Long` (durationMs, dateEpochMs, width, height, orientation), strings (mimetype, ftypBrand), double (framerate). Include `ftyp_brand` as a String.
7. `release()` the retriever in a `finally` block
8. Catch all exceptions per-file — return `null` for that file, never throw

> **Implementation note:** The ftyp detection code MUST have thorough inline documentation. ftyp is the File Type Box at the very start of every MP4/MOV file. The 4-byte major brand at offset 8 declares the container type: `qt  ` (with two trailing spaces) = Apple QuickTime = iOS recording, `isom`/`mp42` = generic MP4 = Android recording. This matters because iOS and Android interpret the `creation_time` metadata differently (see §9).

**Dart wrapper:**

```dart
class VideoMetadata {
  final String sourceUri;
  final String originalFilename;
  final int? durationMs;
  final DateTime? date;         // creation_time: START on iOS, END on Android
  final String? mimetype;
  final int? width;
  final int? height;
  final int? orientation;
  final double? framerate;
  final String? ftypBrand;      // "qt  " = iOS, "isom"/"mp42" = Android
  final int? fileSize;          // from DriveFile, not from metadata

  /// iOS detection: ftyp brand is primary signal, file extension is fallback.
  bool get isIOSRecording {
    if (ftypBrand != null && ftypBrand!.trim() == 'qt') return true;
    return originalFilename.toLowerCase().endsWith('.mov');
  }

  /// Platform-aware recording start time.
  DateTime? get recordingStartTime {
    if (date == null) return null;
    if (isIOSRecording) return date; // iOS creation_time = start
    // Android: creation_time = END. Subtract duration for approximate start.
    // Imprecision: 0.5-3.3s from finalization delay (see VIDEO_PROTOTYPE_LEARNINGS.md §2).
    if (durationMs != null && durationMs! > 0) {
      return date!.subtract(Duration(milliseconds: durationMs!));
    }
    return date;
  }
}

class VideoMetadataService {
  static const _channel = MethodChannel('com.feds201.match_record/video_metadata');

  /// Extract metadata from a video at a content:// URI. Never throws.
  /// Returns VideoMetadata with null fields on failure.
  Future<VideoMetadata> getMetadata(DriveFile file);

  /// Batch extraction. Returns list in same order as input.
  Future<List<VideoMetadata>> getMetadataBatch(List<DriveFile> files);
}
```

**Error handling:** The service NEVER throws. If metadata extraction fails for a file, it returns a `VideoMetadata` with all metadata fields null but `originalFilename`, `sourceUri`, and `fileSize` populated (from the DriveFile). The import preview still shows the row — just with "Unknown" duration/time and no match suggestion.

### 6.3 Pipeline Stages

The import flow is a linear pipeline. Each stage has clear inputs and outputs.

```
Stage 1: Connect          → driveUri
Stage 2: Scan Drive       → List<DriveFile>, allianceSuggestion
Stage 3: Extract Metadata → List<VideoMetadata>
Stage 4: Suggest Matches  → List<ImportPreviewRow>
Stage 5: User Review      → (user edits, no processing)
Stage 6: Execute Import   → List<Recording> in DataStore + files on disk
Stage 7: Finalize         → ImportSession in DataStore, skip history updated
```

**Import tab empty state:** When no drive is connected (no persisted SAF permission, or permission check fails), show: "Insert a USB drive and tap Sync." No automatic drive detection — the user initiates by tapping the Sync button.

**Stage 1 — Connect to drive:**
- Check for persisted SAF permission. If valid, use it.
- Otherwise, call `DriveAccess.pickDrive()` to prompt user.
- Output: `driveUri` (the SAF tree URI for the drive root).

**Stage 2 — Scan drive:**
- `listVideoFiles(driveUri)` → list of DriveFile
- `readTextFile(driveUri, "config.json")` → parse for `{"alliance": "red|blue"}`
- Feed into `AllianceSuggester.suggest()` (see §6.5)
- Output: `List<DriveFile>`, `AllianceSuggestion`

**Stage 3 — Extract metadata:**
- Call `VideoMetadataService.getMetadataBatch(driveFiles)`
- Show loading spinner during this step (should be near-instant via platform channel)
- For each `VideoMetadata`, compute `recordingStartTime` (platform-aware)
- Compute video identity: `(recordingStartTime, durationMs, fileSizeBytes)`
- Check each identity against skip history in DataStore
- Output: `List<VideoMetadata>` enriched with skip status

**Stage 4 — Suggest matches:**
- Sort videos by `recordingStartTime` (ascending)
- Call `MatchSuggester.suggest()` (see §6.6) with the sorted videos and the match schedule from DataStore
- Output: `List<ImportPreviewRow>` with suggested match, teams, alliance side, auto-skip status

**Stage 5 — User review:**
- Display the import preview list (see SPECS.md "Import Preview" section for full UI spec)
- User can: change match assignment (cascades per §6.6), toggle alliance side, change teams, select/deselect
- **Header controls:**
  - Alliance color: tap to set ALL rows to the same color (red or blue). This is a bulk override, not cascade.
- **Alliance picker:** When alliance data exists, tapping the team slots on a row shows an "Alliance X" dropdown. Selecting an alliance auto-fills all 3 team slots for that row with the alliance's picks.
- **Match selection:** Dropdown shows matches from the TBA schedule. If a playoff match hasn't appeared in TBA yet, it won't be in the dropdown — the user can leave the row unassigned and re-sync later.
- **Rows with no match key** (`matchKey == null`) have their import checkbox disabled and a visual indicator ("Assign a match to import"). The confirm button skips these rows.
- Auto-skipped videos: under 30s duration, or previously skipped (from skip history)
- This stage is purely UI — no processing

**Stage 5.5 — Drive disconnection handling:**
- During Stages 5 and 6, monitor drive availability by calling `DriveAccess.hasPermission(driveUri)` before starting import.
- If the drive is disconnected during Stage 5 (user review): show a dialog — "Drive disconnected. Plug it back in to continue, or cancel." On cancel, discard the preview state (no data store changes needed — nothing was imported yet).
- If the drive is disconnected during Stage 6 (mid-copy): abort remaining copies. For videos already successfully copied + added to the data store, keep them (they're complete). For the in-progress copy that failed, delete the partial file from disk. Show a summary: "Imported N of M videos. Drive was disconnected — plug it back in and re-sync to import the rest."
- No orphan cleanup needed here — each file is either fully copied + data store entry added, or the partial file is deleted immediately on failure.

**Stage 6 — Execute import:**
- For each selected video:
  1. Check `DataStore.getRecordingByIdentity(identity)` — if an identical recording already exists, skip (already on tablet)
  2. Generate UUID for filename
  3. Copy file: `DriveAccess.copyToLocal(file.uri, "{storageDir}/recordings/{uuid}{ext}")`
  4. Add `Recording` to DataStore (handles uniqueness cleanup if replacing a different recording for the same match+side)
- Progress UI: shows current file name, file N of M, bytes copied / total bytes
- Wakelock enabled during copy. Warning toast: "Do not leave the app during import."
- If a copy fails: delete any partial file, skip that file, show error, continue with remaining files

**Stage 7 — Finalize:**
- Create `ImportSession` row
- Create `ImportSessionEntry` rows for ALL videos (selected and unselected)
- For unselected videos: mark in `video_skip_history` with reason `user_unchecked`
- For auto-skipped videos: mark in `video_skip_history` with appropriate reason

**Import history re-edit flow:**
- Tapping an entry in the History tab reopens the import preview UI (`import_tab`) populated with that session's data.
- The `ImportSession.entries` are mapped back to `ImportPreviewRow`s. For entries that were imported (`recordingId != null`), the current `Recording` data from the DataStore is used (it may have been edited since import).
- User can edit match assignments, alliance sides, and teams — same UI as fresh import.
- On save: call `DataStore.updateRecording()` for each changed recording, then `DataStore.updateImportSession()` to persist the session metadata changes.
- No file operations — the videos are already on disk. This only updates metadata.

### 6.4 Import Session State

```dart
class ImportSessionState {
  final String driveUri;
  final String driveLabel;
  final AllianceSuggestion allianceSuggestion;
  final List<ImportPreviewRow> rows;

  // Track which rows the user has manually edited (for cascade logic)
  final Set<int> manuallySetRows;
}

class ImportPreviewRow {
  final VideoMetadata metadata;
  final VideoIdentity identity;
  String? matchKey;           // suggested or manually set
  String allianceSide;        // "red" or "blue"
  List<int> teams;            // 3 team numbers
  bool isSelected;
  bool isAutoSkipped;
  String? autoSkipReason;
  bool requiresManualMatch;   // true if gap is ambiguous (10-20 min)
}

class VideoIdentity {
  final DateTime recordingStartTime;
  final int durationMs;
  final int fileSizeBytes;
}
```

### 6.5 Alliance Suggestion

Pure function. Testable independently.

```dart
class AllianceSuggestion {
  final String? side;           // "red", "blue", or null
}

class AllianceSuggester {
  /// Parse config.json content for alliance side. Returns null if no config
  /// or config doesn't contain a valid alliance value.
  static AllianceSuggestion suggest({
    required String? configJsonContent,    // raw file content from config.json, or null
  });
}
```

Logic:
1. If `configJsonContent` is non-null, parse as JSON. If it contains `{"alliance": "red"}` or `{"alliance": "blue"}` (case-insensitive value) → suggest that side.
2. Otherwise → `side: null`, user must pick manually in the import preview UI.

### 6.6 Match Suggestion Algorithm

Pure function. Testable independently.

```dart
class MatchSuggestion {
  final String? matchKey;
  final MatchSuggestionConfidence confidence;
}

enum MatchSuggestionConfidence {
  high,             // timestamp match or sequential (clear gap)
  requiresManual,   // ambiguous gap (10-20 min) — highlight row
  none,             // no suggestion possible
}

class MatchSuggester {
  static List<MatchSuggestion> suggest({
    required List<VideoMetadata> videos,       // sorted by recordingStartTime
    required List<Match> schedule,             // sorted by best available time
    required int gapMinMinutes,                // default 10
    required int gapMaxMinutes,                // default 20
  });
}
```

**Match time resolution:** For each match, use the best available timestamp: `actual_time ?? predicted_time ?? time`. FRC events routinely drift 15–60 minutes from schedule; `actual_time` (filled after a match is played) and `predicted_time` (TBA running estimate) are significantly more accurate than the original scheduled `time`.

Algorithm:
1. For the FIRST video: find the nearest match by best available timestamp (`|video.recordingStartTime - match.bestTime|` minimized).
2. For each subsequent video, compute gap = `video[i].recordingStartTime - video[i-1].recordingStartTime`:
   - Gap < `gapMinMinutes`: assign the next sequential match after the previous video's match.
   - Gap > `gapMaxMinutes`: find the nearest match by best available timestamp.
   - Gap between min and max: `confidence = requiresManual`, no automatic suggestion.
3. "Next sequential match" means: from the sorted schedule, find the match after the previously assigned match. If the end of the known schedule is reached, `confidence = none`.
4. If `recordingStartTime` is null (metadata extraction failed), `confidence = none`.

**Cascade on manual edit:** When the user changes the match in row N:
- Row N is marked as `manuallySet`.
- Rows N+1, N+2, ... are updated to sequential matches (and their teams updated accordingly).
- Cascading stops when hitting a row that is already in `manuallySetRows` or the end of the schedule.

### 6.7 Video Identity

```dart
class VideoIdentity {
  final DateTime recordingStartTime;
  final int durationMs;
  final int fileSizeBytes;

  /// Two identities are equal if all three fields match.
  /// This triplet is intrinsic to the video content and survives
  /// file copies, renames, and cross-device transfers.
}
```

Used for:
- **Skip tracking:** Before showing in the preview, check `video_skip_history` for this identity.
- **Reimport prevention:** Before importing, check if a `recording` with this identity already exists.
- **Deletion tracking:** When a recording is deleted from storage management, the identity is added to `video_skip_history` with reason `deleted`.

If `recordingStartTime` is null (metadata failure), the identity cannot be computed. The video is treated as new (no skip check, no reimport check).

### 6.8 File Storage

All imported videos stored in: `{getExternalStorageDirectory()}/recordings/`

Filename: `{uuid}{original_extension}` (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890.mp4`)

The UUID is the recording's identifier. File path is derived, not stored: `"${storageDir}/recordings/${recording.id}${recording.fileExtension}"`.

**Free space check:** Before import, query available space via `StatFs` through the platform channel (add a `getAvailableBytes(path)` method — 3 lines of Kotlin: `StatFs(path).availableBytes`). More reliable than parsing `df` output, which varies across OEMs. Warn if < 1GB free. Block import if < 100MB free.

**Uninstall data preservation:** Add `android:hasFragileUserData="true"` to `AndroidManifest.xml`. On uninstall, Android will prompt the user "Do you want to keep app data?" — if they check yes, the recordings directory and database survive. Without this flag, uninstalling the app (as opposed to updating via `adb install -r`, which always preserves data) deletes all imported videos.

---

## 7. Video Viewer

### 7.1 Player Management

Two `media_kit` `Player` instances: one "earlier" (started recording first), one "later."

```dart
final _earlierPlayer = Player();
final _laterPlayer = Player();

// Open without auto-play
await _earlierPlayer.open(Media(filePath), play: false);
```

Which player is "earlier" is determined by comparing `recordingStartTime` of the two recordings.

**Single-video mode:** When only one recording exists (or user selects red-only/blue-only view mode, or viewing a local ripped video), only one player is used. Dual-video-specific controls (swap, per-side mute, view mode) are hidden/grayed.

### 7.2 Timestamp Sync

From VIDEO_PROTOTYPE_LEARNINGS.md (proven in prototype):

- `_syncOffset = laterVideo.recordingStartTime - earlierVideo.recordingStartTime`
- Earlier player is the primary clock. Later player's position = `earlierPos - syncOffset`.
- Track `_intendedEarlierPosition` separately (do NOT use `Player.state.position` — it's async and stale after seek).
- Countdown driven by earlier player's position stream, NOT wall clock.
- Later player shows black with "Starting in X.Xs" until `earlierPos >= syncOffset`.

**Unified timeline:** The scrub bar and playback span the full combined range: `min(start1, start2)` to `max(end1, end2)`, where start/end are derived from each video's `recordingStartTime` and duration. For any timeline position where a video is not yet playing, that pane shows black with "Video starts in X.Xs". For any position after a video has ended, that pane shows black with "Video ended X.Xs ago". This means the scrub bar may extend beyond either individual video's range to cover the full span of both recordings.

### 7.3 Non-Linear Scrubbing

From VIDEO_PROTOTYPE_LEARNINGS.md (proven in prototype):

**Touch interaction:**
- Finger down anywhere on video = pause, record touch-down position and current playback time
- Horizontal drag = continuous non-linear scrub from the touch-down point
- Finger lift = stay paused at scrubbed position

**Non-linear curve:**
```dart
const kScrubExponent = 2.5;      // higher = more dead zone near touch point
const kScrubMaxRangeMs = 120000;  // max seek range from touch-down point
const kScrubDeadZonePx = 3.0;

int computeScrubOffsetMs(double deltaX, double paneWidth) {
  final halfWidth = paneWidth / 2.0;
  final normalized = (deltaX.abs() / halfWidth).clamp(0.0, 1.0);
  final fraction = pow(normalized, kScrubExponent).toDouble();
  return (deltaX.sign * fraction * kScrubMaxRangeMs).round();
}
```

**Seek throttling:** Cancel-and-replace pattern (proven in prototype). Only one seek in-flight at a time. When it completes (`.whenComplete()`, NOT `.then()`), dispatch the latest pending position. Naturally adapts to decoder speed.

**Position stream suppression:** Guard both players' position stream listeners during scrubbing to prevent flicker:
```dart
player.stream.position.listen((pos) {
  if (mounted && !_isScrubBarSeeking && !_isFingerScrubbing) {
    setState(() => _position = pos);
  }
});
```

### 7.4 Audio State

3-state toggle per spec: muted → red audio → blue audio.

```dart
enum MuteState { muted, redAudio, blueAudio }
```

Icons: speaker with cross (muted), speaker with red circle (red), speaker with blue circle (blue). When sides are swapped, the audio assignment follows the alliance (not the physical position).

### 7.5 View Modes

3-state toggle: both sides → red only → blue only.

In single-video mode (any reason: toggle, only one recording, or local ripped video): maximize the video to fill available space, orienting the widest dimension of the video along the widest dimension of the screen.

### 7.6 Layout

Forced landscape. Immersive sticky mode.

```
┌────────────────┬────────────────┬──────┐
│   Red Pane     │   Blue Pane    │ Side │
│                │                │ bar  │
│  thin red bar  │ thin blue bar  │      │
│  at top        │  at top        │ ☆    │
│                │                │ 🔇   │
│                │                │ ⇆    │
│                │                │ ▶    │
│                │                │ ⏪   │
│                │                │ ⏩   │
│                │                │ ↺    │
│                │                │ ✏    │
│                │                │      │
│                │                │ ↩    │
│                │                │ ↪    │
│                │                │ ✕    │
├────────────────┴────────────────┤      │
│         Scrubber Bar            │      │
└─────────────────────────────────┴──────┘
```

Sidebar: own column (~72px), not transparent, not overlaid. Scrollable if controls overflow. Drawing controls (undo, redo, clear) appear at bottom of sidebar when paused — positioned so they don't shift existing buttons.

Star icon on the pane containing the user's team.

### 7.7 Edit Recording Metadata

Each video pane has a small pencil/edit icon (e.g., in the corner near the alliance color bar). Tapping it opens a bottom sheet for **that specific recording** — edit match assignment (dropdown), alliance side (toggle), and team numbers. Changes are saved to the `DataStore` immediately.

This is per-recording, not per-match: the red and blue recordings might need different corrections (e.g., one was assigned to the wrong match). In single-video mode, only one edit icon is shown.

This provides a quick single-video edit path for mislabeled recordings without navigating to the Sync UI's import history.

---

## 8. Drawing Overlay (P1)

From DRAWING_PROTOTYPE_LEARNINGS.md (proven in prototype):

- **Engine:** `CustomPainter` + `Listener` (raw pointer events). No library.
- **Activation:** When paused via the play/pause button (not touch-to-pause). Scrubbing is disabled during drawing mode.
- **Color:** Fixed bright red (`Colors.red`).
- **Stroke width:** `3.5px`.
- **Storage:** In-memory only. `List<List<Offset>> _strokes` + `List<Offset> _currentStroke`.
- **Undo/redo:** Two stacks. New stroke clears redo stack.
- **Smoothing:** Quadratic bezier through midpoints.
- **Multi-touch:** Single `_currentStroke` with no pointer ID tracking. Two fingers interleave into one stroke (intentional — useful for quick area annotation).
- **Opacity:** Pass opacity value into the `StrokePainter` and apply directly to the `Paint` color (`Colors.red` when paused, `Colors.red.withAlpha(128)` during playback). Do NOT use the `Opacity` widget — it forces an offscreen buffer allocation every frame, which combined with `shouldRepaint => true` causes unnecessary compositing overhead.
- **shouldRepaint:** Always returns `true` (fine for our stroke counts, per prototype).
- **Lifecycle:** Exiting the viewer clears all drawings (widget dispose).
- **Pressure:** Not used (cheap capacitive styluses report constant 1.0).

---

## 9. iOS Detection

**Why it matters:** The `creation_time` metadata in video files means different things on different platforms:
- **iOS:** `creation_time` = recording **start** time
- **Android:** `creation_time` = recording **end** time (file finalization). Subtract duration for approximate start, with 0.5-3.3s imprecision from finalization delay.

Getting this wrong means video sync offset is off by the full video duration (~2.5 minutes).

**Detection method** (two signals, checked in order):

1. **ftyp major brand** (primary, content-based): Read the first 32 bytes of the file. The `ftyp` box declares the container type. Bytes 8-11 are the major brand:
   - `qt  ` (with two trailing spaces, ASCII `0x71 0x74 0x20 0x20`) = Apple QuickTime = **iOS**
   - `isom`, `mp42`, or any other value = **Android** (or generic MP4)

2. **File extension** (fallback): `.MOV` (case-insensitive) = iOS. `.mp4` = Android.

The ftyp check is bundled into the platform channel's `getVideoMetadata` call — zero extra I/O.

> **Why ftyp and not just the extension?** The extension can be changed by file rename or transfer tools. The ftyp brand is embedded in the file content and survives any file operation. Combined, the two signals are ~99.9% accurate for stock camera app recordings.

---

## 10. Navigation & Screens

### 10.1 Navigation Strategy

**Plain `Navigator.push` / `Navigator.pop`.** Four routes:
- `MainScreen` (home, always in the stack)
- `VideoViewer` (pushed on top)
- `SyncPage` (pushed on top)
- `SettingsPage` (pushed on top)

No GoRouter, no Navigator 2.0. This app has ~4 screens with simple push/pop flows. The simplest approach is correct.

### 10.2 Widget Hierarchy

```
MainScreen (StatefulWidget)
├── AppBar
│   ├── AppSearchBar (custom: TextField + InputChip Wrap)
│   ├── SyncButton (IconButton, no badge — see note below)
│   └── Settings IconButton (gear → push SettingsPage)
├── Stack
│   ├── IndexedStack (body, preserves all tab states)
│   │   ├── SearchTab
│   │   ├── TeamsTab
│   │   ├── MatchesTab
│   │   └── AlliancesTab (conditional)
│   └── AutocompleteOverlay (positioned below search bar, conditional)
└── NavigationBar (bottom, 3-4 destinations)
```

> **No USB detection:** The app does NOT auto-detect USB drive insertion/removal. There is no badge or indicator on the sync button. The user manually taps the Sync button to open the Sync UI, which then checks for a connected drive via SAF. This is a deliberate simplification over the spec — SAF packages do not provide drive insertion events, and polling is unreliable. The sync flow is: user plugs in drive → taps Sync button → SAF picker if no persisted permission, or direct scan if permission exists.

### 10.3 Tab State & Search

**Tab preservation:** `IndexedStack` keeps all tab widget trees alive. Switching tabs = changing the visible index, NOT rebuilding widgets.

**Search state ownership:** `_MainScreenState` owns:
- `TextEditingController` for the search field
- `List<SearchChip>` (team/alliance chips)
- `List<AutocompleteResult>` (debounced at 250ms)
- `bool _showAutocomplete`

This state lives in `MainScreen` because the search bar is in the AppBar (outside any tab).

**Cross-tab flows:**
- Tapping a team in TeamsTab → calls `_addChipAndSwitchToSearch(SearchChip.team(...))` on MainScreen (passed down as callback). This adds the chip and sets `_selectedTabIndex = 0`.
- Tapping an alliance in AlliancesTab → same pattern with `SearchChip.alliance(...)`.
- Autocomplete match result → `Navigator.push(VideoViewer)`.
- Autocomplete team/alliance result → add chip, switch to Search tab.
- Enter key in search field → selects top autocomplete result.

**Conditional Alliances tab:** Driven by `DataStore.hasAllianceData`. When alliance data is deleted and user is on Alliances tab, clamp index to Matches tab.

### 10.4 Viewer Lifecycle

**Entry (`initState`):**
1. Lock landscape: `SystemChrome.setPreferredOrientations([landscapeLeft, landscapeRight])`
2. Immersive: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`
3. Enable wakelock: `WakelockPlus.enable()`
4. Initialize players, compute sync offset, open media files (without auto-play)
5. Subscribe to position/duration streams

**Exit (`dispose`):**
1. Cancel all stream subscriptions
2. Dispose players
3. Restore all orientations: `SystemChrome.setPreferredOrientations(DeviceOrientation.values)`
4. Restore system UI: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`
5. Release wakelock: `WakelockPlus.disable()`
6. Drawings cleared implicitly (in-memory, widget disposed)

**Back navigation:** System back gesture works automatically (triggers `Navigator.pop` → `dispose`). Sidebar also has an explicit back button: `IconButton(onPressed: () => Navigator.pop(context))`.

### 10.5 Shared Match List Component

`MatchList` widget is used in MatchesTab and SearchTab.

```dart
class MatchList extends StatelessWidget {
  final List<MatchWithVideos> matches;
  final int? yourTeamNumber;
  final Set<int>? highlightTeamIds;       // bold these team numbers
  final bool showYourMatchesSection;       // "Your Matches" header + divider
  final bool showEventLabel;               // event short_name on each row
  final void Function(MatchWithVideos) onMatchTap;
}
```

`MatchRow` is the individual row widget, showing match identifier, day/time, teams (color-coded), scores, and video icons.

---

## 11. Settings

**Settings page contents:**

1. **Your team number** — editable text field, saved to `settings.team_number`
2. **Events** — multi-event picker:
   - Dropdown of 2026 events (cached from TBA `/events/2026`)
   - Selected events shown as chips with X buttons
   - "+" button to add another event
   - "Load from TBA" button fetches teams/matches/alliances for all selected events
   - "Refresh events list" to re-fetch the event dropdown from TBA
3. **Sync** — opens SyncPage
4. **Storage** — opens SyncPage on Storage tab
5. **Thresholds** — tunable values with defaults:
   - Short video threshold: 30s
   - Sequential gap min: 10 min
   - Sequential gap max: 20 min
   - Scrub exponent: 2.5
   - Scrub max range: 120s
6. **Log** — view/clear log file

---

## 12. Storage Management

Accessible from SyncPage (as a tab) and from Settings. Two modes using the same list component.

### Tablet Storage Mode

Shows all imported recordings on the device.

Each row: video preview info, match assignment, alliance side, teams, file size.

Selection options:
- **Select all**
- **Select all but our team** — deselects recordings where any of team1/team2/team3 matches `settings.team_number`
- **Select all from past events** — selects recordings whose `match.event_key` belongs to an event with `end_date < today`

Deleting a video:
1. Deletes the file from device storage
2. Removes the recording from the DataStore
3. Adds the video identity to `video_skip_history` with reason `deleted` (prevents reimport)

### Flash Drive Mode (only when drive is connected)

Shows all videos on the connected drive.

Same list component. Additional: checkmark icon on each row showing whether the video has been synced (imported) to the tablet (checked by video identity lookup against recordings in DataStore).

Selection options:
- **Select all**
- **Select all synced** — selects videos that have already been imported to the tablet

Deleting removes from the flash drive ONLY (via `DriveAccess.deleteFile`). Does NOT delete tablet copies.

---

## 13. Error Handling

### Result Type

```dart
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}
```

~20 lines, no package.

### Error Display

- **Recoverable errors** (network timeout, file copy failure, metadata extraction failure): `SnackBar` with description.
- **Blocking errors** (database corruption, storage full): `AlertDialog` requiring user action.
- **Degraded data** (metadata partially missing, match suggestion uncertain): visual indicators on the affected rows (amber highlight, "Unknown" labels), NOT error dialogs.

### Logging

`logger` package, single log file. Log: import operations, TBA fetch results, errors, USB events. Do NOT log: per-frame video events, position stream updates, UI rebuilds.

---

## 14. Startup Integrity Check (P1)

On app launch, reconcile the recordings directory with the database to clean up orphans left by crashes or interrupted imports.

```dart
class IntegrityChecker {
  /// Scan recordings directory and DataStore, delete orphans in both directions.
  /// Returns the number of items cleaned up (0 = no action needed).
  Future<int> reconcile({
    required String recordingsDir,
    required DataStore dataStore,
  });
}
```

**Steps:**
1. List all files in `{storageDir}/recordings/`
2. Get all recordings from the DataStore
3. **Files without DataStore entries:** Delete the file from disk. These are leftovers from a crashed import (Stage 6 copied the file but never added the recording to the data store, or Stage 7 never ran).
4. **DataStore entries without files:** Remove the recording from the DataStore and add the video identity to skip history with reason `deleted` (consistent with normal deletion behavior).
5. Log all cleanup actions.
6. If any cleanup occurred, show a brief toast: "Cleaned up N orphaned files."

Runs on every app launch. Should be fast — just a directory listing + in-memory list comparison.

---

## 15. Testing Strategy

### What to Test

| Layer | What | How |
|---|---|---|
| DataStore | Mutations, lookups, persistence round-trip, notifyListeners | In-memory DataStore with mock JsonPersistence |
| Match Suggestion | Algorithm correctness, edge cases (empty schedule, all gaps ambiguous, cascade, overflow) | Pure function tests, no mocks needed |
| Alliance Suggestion | config.json parsing, missing/malformed config, case insensitivity | Pure function tests |
| Integrity Check | Orphaned files, orphaned data store entries, clean state (no-op), mixed | Mock filesystem + in-memory DataStore |
| Video Identity | Equality, null handling | Pure function tests |
| iOS Detection | ftyp brand parsing, extension fallback | Pure function tests |
| TBA Client | JSON parsing, error handling | Mock dio responses with `mocktail` |
| Import Pipeline | Stage transitions, error recovery | Mock `DriveAccess` and `VideoMetadataService` with `mocktail` |
| Scrub Math | Non-linear curve, dead zone, edge cases | Pure function tests |
| Video Sync | Offset computation, countdown, position tracking | Unit tests on sync logic (mock player) |

### What NOT to Unit Test

- Widget rendering (test manually on device)
- Platform channel (test via integration tests on device)
- SAF file operations (test manually on device with real USB drive)

---

## 16. Open Questions

| # | Question | Status |
|---|---|---|
| 1 | **Files prototype results** — Does `saf_util` + `saf_stream` work reliably for USB? The DriveAccess interface is ready to swap implementations. | Blocked on prototype testing |
| 2 | **SAF permission persistence across re-plugs** — Does the persisted SAF URI work when the same drive is unplugged and re-plugged? | Needs runtime testing |
| 3 | **Android timestamp imprecision** — How much error does the finalization delay introduce for ~2.5 minute recordings? | Needs measurement with real match-length videos |
| 4 | **Manual sync offset adjustment** — If automated sync is noticeably off, do we need a UI to nudge the offset? | Deferred until we test with real recordings |
| 5 | **2026 TBA sf match data** — 2026mimid is missing sf (bracket) matches in TBA despite having alliances with bracket records. Is this a data lag or a change in how TBA ingests 2026 data? | Monitor; app handles missing playoff data gracefully |
| 6 | **MediaMetadataRetriever MIME type for .MOV** — Does it return `video/quicktime` (reliable) or `video/mp4` (unreliable)? `flutter_video_info` returned `video/mp4` in the prototype. Our channel may differ. | Test during implementation |
| 7 | **moov-at-end files over USB+SAF** — Metadata extraction could be slow (1-3s per file) if the MP4 moov atom is at the end. Phone camera videos typically have moov at the start, but edge cases exist. | Monitor performance, add timeout if needed |

---

## 17. Decision Log

Decisions made during design, with rationale.

| # | Decision | Rationale |
|---|---|---|
| 1 | Custom Kotlin platform channel for video metadata | `flutter_video_info` requires local file paths. Our channel reads from SAF `content://` URIs directly via `MediaMetadataRetriever.setDataSource(context, uri)`, avoiding a full file copy just for metadata. ~50-60 lines of Kotlin. |
| 2 | ftyp brand detection for iOS vs Android | Content-based signal that survives file renames. Combined with extension fallback, ~99.9% accurate. Added to the same platform channel (reads first 32 bytes). |
| 3 | Drop `flutter_video_info` dependency | Our platform channel replaces it with better functionality (SAF URI support, ftyp detection) and fewer lines of code. |
| 4 | Plain `Navigator.push`/`pop` | ~4 screens, simple push/pop flows. GoRouter/Navigator 2.0 add complexity with no benefit. |
| 5 | `IndexedStack` for tab preservation | Keeps all tab widgets alive. Simple, built-in, no state restoration logic needed. |
| 6 | No state management package | App state is either screen-local (StatefulWidget) or in the DataStore (ChangeNotifier). Widgets listen to DataStore and rebuild on changes. No Provider/Riverpod/BLoC. |
| 7 | Team keys stored as List<String> on Match | TBA returns them as arrays. Some events have 4 teams per side (Einstein). Avoids 6+ nullable columns. |
| 8 | Multi-event support via JSON array in settings | Allows selecting multiple events for DCMP/Worlds. All queries filter by the set of selected event keys. |
| 9 | Video file path derived from UUID + extension, not stored | Single directory, predictable naming. Avoids storing redundant paths that can go stale. |
| 10 | DriveAccess as abstract interface | Files prototype not yet complete. Clean boundary allows swapping SAF implementation for alternatives. |
| 11 | All import algorithms as pure functions | `MatchSuggester`, `AllianceSuggester`, video identity computation — all testable without mocks, data store, or UI. |
| 12 | Single-file import directory (no subdirectories) | Simple. Files are identified by UUID. Metadata is in the data store. No directory structure to manage or break. |
| 13 | Score = -1 means unplayed (from TBA) | Display as "—" in match rows. Do not confuse with 0. |
| 14 | Sort matches by `time` field | Works correctly across all comp_levels and playoff formats. No need for complex comp_level ordering logic. |
| 15 | Three storage selection modes | "Select all", "Select all but our team", "Select all from past events" — covers the main bulk-selection patterns for cleanup. |
| 16 | Alliance suggestion: config.json only | Simpler than multi-signal heuristics (volume label, hint files, stored mappings). If no config.json, user picks manually — fast and unambiguous. Removed drive color mappings and `fileExists` from DriveAccess. |
| 17 | Match suggestion uses best available time | `actual_time ?? predicted_time ?? time` instead of just scheduled `time`. FRC events drift 15–60 min from schedule; actual/predicted times are far more accurate. |
| 18 | Startup integrity check (P1) | Reconciles recordings directory with data store on launch. Catches orphaned files from crashed imports and data store entries whose files were lost. Prevents silent storage leaks on a space-constrained tablet. |
| 19 | No foreground service (P2) | Wakelock prevents screen sleep but not process death if backgrounded during import. A foreground service would fix this but adds ~30 lines of Kotlin + notification channel. Deferred — warn user not to leave the app during import. |
| 20 | Import preview video playback deferred (P2) | Playing video directly from USB drive requires content:// URI playback in media_kit, which is untested. Deferred to avoid blocking P0 on an unvalidated dependency. |
| 21 | Drawing opacity via Paint color, not Opacity widget | `Opacity` widget forces offscreen buffer allocation every frame. Applying alpha directly to the `Paint` color avoids this overhead entirely with the same visual result. |
| 22 | Platform channel returns parsed numeric types | Kotlin parses `METADATA_KEY_DATE` (3GPP format, varies by OEM) into epoch milliseconds and returns `Long`. Dart just does `DateTime.fromMillisecondsSinceEpoch()`. Isolates format-handling to one place. |
| 23 | Viewer restores all orientations on exit | Previous design forced `portraitUp` on exit, which is wrong for tablets (may have been landscape). Restoring `DeviceOrientation.values` lets the system handle it. |
| 24 | Unified scrub bar timeline | Range spans `min(start1,start2)` to `max(end1,end2)`. Panes show "starts in Xs" / "ended Xs ago" for out-of-range positions. Ensures all content from both videos is accessible. |
| 25 | Free space via StatFs, not `df` | `df` output format varies across OEMs. `StatFs(path).availableBytes` is 3 lines of Kotlin and always reliable. |
| 26 | `android:hasFragileUserData="true"` | On uninstall, Android prompts "keep app data?" — preserves recordings if user opts in. Without this, uninstall deletes everything. Normal updates (`adb install -r`) always preserve data regardless. |
| 27 | Drive disconnection handling (P1) | Detect drive disconnect during import review and copy stages. Clean abort: keep completed imports, delete partial files, show clear status. No orphaned state. |
| 28 | JSON file + in-memory over SQLite/drift | Data volume is tiny (~50 teams, ~100 matches, ~50 recordings). SQLite adds code generation, SQL complexity, and 4 dependencies for no benefit at this scale. In-memory Dart lists with `where`/`firstWhere` are instantaneous. Atomic JSON persistence (write to tmp, rename) is safe against crashes. Team search uses `List.contains()` — exact match, no substring issues. |
| 29 | No USB auto-detection | SAF packages don't provide drive insertion/removal events. Polling is unreliable. User manually taps Sync button — simple and predictable. Spec's badge/indicator requirement intentionally dropped. |
| 30 | `addRecording` cleans up replaced files | When uniqueness constraint replaces an old recording, the old file is deleted from disk and its identity added to skip history. Prevents orphaned files eating storage between integrity check runs. |
| 31 | Reimport prevention via VideoIdentity | Import pipeline checks if a recording with the same identity already exists before copying. Prevents duplicate imports when re-syncing a drive. |
| 32 | Recording stores eventKey | Each recording knows which event it belongs to. When the user switches events, recordings from other events are not shown. Prevents stale cross-event data from appearing. |
| 33 | JSON version + cascading migration | `AppData` has a `version` field. On load, cascading `if` blocks migrate from any older version to current. Handles skipped versions (sideloaded app, non-sequential updates). |
| 34 | Event year derived from `DateTime.now().year` | No hardcoded year. Works across seasons without code changes. |
| 35 | Audio: 3-state mute toggle (no "both" state) | Muted → red audio → blue audio. The 4th "both" state from the prototype was for testing sync — not useful in production. Hearing one side at a time is the intended use case. |
| 36 | Edit recording metadata from viewer (per-pane) | Pencil icon on each video pane opens quick-edit for that specific recording's match assignment, alliance side, and teams. Per-recording, not per-match — red and blue sides may need different corrections. |
| 37 | Import preview component reused for import history detail | Tapping a sync log entry reopens the same import preview UI with that session's data, fully editable. Same component, different data source. |
| 38 | Scores as non-nullable `int`, -1 = unplayed | TBA returns -1 for unplayed (never null). Model uses `int` not `int?` to eliminate ambiguity — every score check is just `== -1`, never null-checking. |
| 39 | Match selection from TBA schedule only | No custom match creation. Import preview dropdown shows matches from TBA. If a playoff match isn't in TBA yet, the row stays unassigned. Simplifies the data model (all matchKeys are real TBA keys). |
| 40 | Rows without matchKey can't be imported | Checkbox disabled, visual indicator. Prevents creating Recording objects with no match association. `Recording.matchKey` stays non-nullable. |
| 41 | Alliance picker in import preview | When alliance data exists, tapping team slots offers "Alliance X" shortcut that auto-fills all 3 teams. Speeds up playoff video labeling. |
| 42 | Header alliance color sets all rows | Bulk override for alliance side. Per-row cascade is only for match ID changes (cascade to subsequent rows, stop at manually-set rows). |
