# Data Layer

## How to Use This Module

### Setup

`DataStore` is the single entry point for all data access and mutation. It requires a `JsonPersistence` instance and must be initialized before use:

```dart
final persistence = JsonPersistence(); // uses app documents directory
final store = DataStore(persistence);
await store.init(); // loads data from disk (or creates empty AppData)
```

For testing, you can pass a custom directory:

```dart
final persistence = JsonPersistence(directoryPath: '/tmp/test');
```

### Reading Data

All read methods are synchronous getters or methods on `DataStore`. Lists returned by getters are unmodifiable copies, so you cannot accidentally mutate internal state.

```dart
// TBA data - events, teams, matches, alliances
final events = store.events; // List<Event>, unmodifiable
final teams = store.getTeamsForEvents(['2026miket']);
final matches = store.getMatchesForEvents(['2026miket']);
final match = store.getMatchByKey('2026miket_qm42');

// Find nearest match to a timestamp (uses bestTime: actualTime ?? predictedTime ?? time)
final nearest = store.getNearestMatch(DateTime.now(), ['2026miket']);

// Team-specific queries
final teamMatches = store.getMatchesForTeam(201, ['2026miket']); // uses 'frc201' key internally
final alliance = store.getAllianceForTeam(201, ['2026miket']);

// Recordings
final all = store.allRecordings; // List<Recording>, unmodifiable
final forMatch = store.getRecordingsForMatch('2026miket_qm42');
final byIdentity = store.getRecordingByIdentity(VideoIdentity(...));

// Skip history - check if a video file has been previously skipped/deleted
final skipped = store.isSkipped(VideoIdentity(
  recordingStartTime: startTime,
  durationMs: 180000,
  fileSizeBytes: 524288000,
));

// Local ripped videos
final video = store.getLocalRippedVideo('2026miket_qm42');

// Import sessions
final sessions = store.importSessions;

// Settings
final settings = store.settings;
final teamNum = store.settings.teamNumber;
final eventKeys = store.settings.selectedEventKeys;
```

### View Models

`DataStore` provides pre-joined view models that combine match data with associated recordings:

```dart
// Get all matches with their red/blue recordings and local ripped videos attached
final matchesWithVideos = store.getMatchesWithVideos(['2026miket']);

// Same, but filtered to only matches that have recordings or local ripped videos (if setting is enabled)
final filtered = store.getMatchesWithVideosFiltered(['2026miket']);

// Single match
final mwv = store.getMatchWithVideos('2026miket_qm42');
if (mwv != null) {
  print(mwv.hasRecordings);       // true if red or blue recording exists
  print(mwv.hasYouTube);          // true if match.youtubeKey != null
  print(mwv.hasLocalRippedVideo); // true if a local ripped video exists
  print(mwv.redRecording);       // Recording? for the red alliance side
  print(mwv.blueRecording);      // Recording? for the blue alliance side
}
```

### Mutating Data

All mutation methods are `async` and return `Future<void>`. They update internal state, persist to disk, and then call `notifyListeners()`.

```dart
// TBA data - event-scoped replacement (replaces all data for that event key)
await store.setEvents(events);
await store.setTeamsForEvent('2026miket', teams);
await store.setMatchesForEvent('2026miket', matches);
await store.setAlliancesForEvent('2026miket', alliances);

// Recordings
await store.addRecording(recording);    // adds, replacing any existing with same matchKey+allianceSide
await store.updateRecording(recording); // replaces by id
await store.deleteRecording(id);        // removes by id AND adds to skip history

// Skip history
await store.markAsSkipped(identity, 'too short');

// Import sessions
await store.addImportSession(session);
await store.updateImportSession(session); // replaces by id

// Settings
await store.updateSettings(store.settings.copyWith(
  teamNumber: () => 201,
  recordedMatchesOnly: true,
));
```

### Listening for Changes

`DataStore` extends `ChangeNotifier`. Every mutation calls `notifyListeners()` after persisting. Use it with Flutter's standard listener patterns:

```dart
// With Provider (typical usage)
ChangeNotifierProvider.value(value: store, child: MyApp());

// In a widget
final store = context.watch<DataStore>();
final events = store.events; // rebuilds when data changes

// Manual listener
store.addListener(() {
  print('Data changed!');
});
```

Every setter/add/update/delete method follows the same pattern: mutate in-memory state, persist to disk, notify listeners. There is no way to mutate without persisting -- all changes are immediately durable.

## Known Issues / Shortcomings

- **No async mutation queue.** Mutations are fire-and-forget `Future<void>` calls. If two mutations race, the second `save()` will overwrite the first. In practice this is fine because the app is single-user and mutations are infrequent, but there is no locking or sequencing mechanism.

- **No SQLite -- intentional.** All data lives in a single `app_data.json` file. This is appropriate for the data volume (a season of FRC matches is a few hundred entries at most), but it means every save rewrites the entire file. There is no partial update.

- **No write-back batching.** Every single mutation triggers a full serialize-and-write cycle. There is no debouncing or batching of rapid mutations.

- **`localRippedVideos` has no setter.** The `DataStore` exposes a `getLocalRippedVideo()` reader but has no corresponding `addLocalRippedVideo()` or `setLocalRippedVideos()` mutation method. This data can only be populated by loading it from the JSON file directly (or it's written by some other mechanism outside this module).

- **`skipHistory` grows without bound.** Deleted recordings and manually skipped videos are appended to `skipHistory` forever. There is no pruning, expiration, or cleanup mechanism.

- **Event-scoped setters replace all data for that event.** `setTeamsForEvent`, `setMatchesForEvent`, and `setAlliancesForEvent` remove all existing entries for the given event key and replace them with the new list. This is a full replacement, not a merge/upsert.

- **Recording uniqueness is by `matchKey + allianceSide`, not by `id`.** `addRecording()` removes any existing recording with the same `matchKey` and `allianceSide` before adding the new one. This means only one recording per alliance side per match is kept. `updateRecording()` matches by `id`.

- **Migration system is a placeholder.** The version field exists (`AppData.currentVersion = 1`) and `_migrate()` is called on load, but it contains no actual migrations yet -- just a comment showing the pattern for future use.

- **Nullable `copyWith` patterns.** Several model classes (e.g., `Match`, `AppSettings`, `ImportSessionEntry`, `VideoSkipEntry`) use `T? Function()?` in their `copyWith` methods for nullable fields. This is the correct pattern for distinguishing "not provided" from "explicitly set to null", but it requires wrapping values in a closure: `copyWith(teamNumber: () => null)` to clear, vs. omitting the parameter to keep the existing value.

## Technical Details

### Model Classes

All models are immutable value objects in `models.dart`. Each one has:
- A `const` constructor with named parameters
- `toJson()` / `fromJson()` for JSON serialization
- `copyWith()` for immutable updates
- Value equality (`==` operator and `hashCode`)

**Domain models:**

| Class | Purpose | Key fields |
|---|---|---|
| `Event` | An FRC event (competition) | `eventKey`, `name`, `shortName`, `startDate`, `endDate`, `playoffType`, `timezone` |
| `Team` | A team at an event | `eventKey`, `teamNumber`, `nickname` |
| `Match` | A match at an event | `matchKey`, `eventKey`, `compLevel`, `setNumber`, `matchNumber`, time fields, team keys, scores, `youtubeKey` |
| `Alliance` | A playoff alliance at an event | `eventKey`, `allianceNumber`, `name`, `picks` (list of team keys) |
| `Recording` | A recorded video of a match | `id`, `eventKey`, `matchKey`, `allianceSide` (`"red"`/`"blue"`), `fileExtension`, `recordingStartTime`, `durationMs`, `fileSizeBytes`, `sourceDeviceType`, `originalFilename`, `team1`/`team2`/`team3` |
| `LocalRippedVideo` | A locally ripped video file for a match | `matchKey`, `filePath` |
| `ImportSession` | A record of a video import session | `id`, `importedAt`, `driveLabel`, `driveUri`, `videoCount`, `entries` |
| `ImportSessionEntry` | One video file within an import session | `recordingId`, `originalFilename`, `wasSelected`, `wasAutoSkipped`, `skipReason`, video identity fields |
| `VideoSkipEntry` | A record that a video was skipped or deleted | `recordingStartTime`, `durationMs`, `fileSizeBytes`, `skipReason` |
| `VideoIdentity` | A fingerprint for identifying a video file | `recordingStartTime`, `durationMs`, `fileSizeBytes` |
| `AppSettings` | User-configurable settings | `teamNumber`, `selectedEventKeys`, import thresholds, scrub settings, `recordedMatchesOnly` |

**Composite/view model:**

| Class | Purpose |
|---|---|
| `MatchWithVideos` | Joins a `Match` with its optional red/blue `Recording`s, optional `LocalRippedVideo`, and event short name. Provides `hasRecordings`, `hasYouTube`, `hasLocalRippedVideo` convenience getters. |

**Root container:**

| Class | Purpose |
|---|---|
| `AppData` | The top-level container holding all data. Has a `version` field (currently `1`), lists of every domain model, and `AppSettings`. `AppData.empty()` creates a blank slate. |

### Match Display and Sorting

`Match` has two computed properties:
- `displayName` -- human-readable name based on `compLevel`: `"Q12"` for quals, `"SF 1"` for semis, `"F2"` for finals, `"EF 3"` for eighths, `"QF 1-2"` for quarters.
- `compLevelPriority` -- numeric sort key: `qm=0`, `ef=1`, `qf=2`, `sf=3`, `f=4`, unknown=5.
- `bestTime` -- returns the best available timestamp: `actualTime ?? predictedTime ?? time`. All three are Unix epoch seconds (nullable `int`).

### Video Identity and Skip History

Videos are identified by a fingerprint of three fields: `recordingStartTime`, `durationMs`, and `fileSizeBytes`. This is encapsulated in `VideoIdentity`.

The skip history tracks videos that should not be re-imported. Entries are added in two ways:
1. **Explicit skip:** `markAsSkipped(identity, reason)` adds a `VideoSkipEntry` with the given reason.
2. **Deletion:** `deleteRecording(id)` removes the recording from the list AND adds a skip entry with reason `'deleted'`.

During import, `isSkipped(identity)` checks whether a video fingerprint matches any entry in skip history, preventing re-import of previously rejected or deleted videos.

### Recording Uniqueness

`addRecording()` enforces a uniqueness constraint: only one recording per `(matchKey, allianceSide)` pair. When adding a recording, any existing recording with the same match key and alliance side is removed first, then the new one is appended. This means re-importing a video for the same match/side silently replaces the old one.

`updateRecording()` is different -- it matches by `id` and replaces in-place, used for updating fields on an existing recording without changing identity.

### Persistence Strategy (`JsonPersistence`)

All data is stored in a single file: `app_data.json` in the app's documents directory (or a custom directory for testing).

**Atomic writes:** Saves use a write-to-temp-then-rename strategy:
1. Serialize `AppData` to pretty-printed JSON (`JsonEncoder.withIndent('  ')`)
2. Write to `app_data.json.tmp`
3. Rename `.tmp` to `app_data.json` (atomic on most filesystems)

This prevents data corruption if the app crashes mid-write.

**Loading:** On load, if the file does not exist, returns `AppData.empty()`. If it does exist, it is deserialized and then passed through `_migrate()`.

**Migration system:** `_migrate()` is called on every load. It receives the deserialized `AppData` and can transform it based on the `version` field. Currently version is `1` and no migrations exist, but the pattern is established:

```dart
// Future migration example:
// if (migrated.version < 2) {
//   migrated = migrated.copyWith(version: 2, ...);
// }
```

Migrations cascade -- each `if` block bumps the version, so data at any old version will be stepped through all intermediate migrations.

### DataStore Architecture

`DataStore` is a thin facade over `AppData` + `JsonPersistence`:
- Holds a single `AppData` instance in memory
- All reads go directly to the in-memory `AppData`
- All writes: (1) create a new `AppData` via `copyWith`, (2) call `_persistence.save()`, (3) call `notifyListeners()`
- Extends `ChangeNotifier` for Flutter widget integration

The store is the only class that should read or write `AppData`. It encapsulates all query logic (filtering by event keys, looking up matches by team, joining matches with recordings, etc.) so consumers don't need to understand the internal data shape.

### JSON Deserialization Defaults

All `fromJson` factories use defensive defaults (`?? ''`, `?? 0`, `?? []`, etc.) so that missing or null fields in the JSON never cause crashes. This makes the format forward-compatible -- new fields can be added to models without breaking existing data files.
