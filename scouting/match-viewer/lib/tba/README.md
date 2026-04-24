# TBA (The Blue Alliance) API Client

## How to Use This Module

### Creating a Client

```dart
import 'package:match_record/tba/tba_client.dart';

// Default — uses the hardcoded API key and base URL
final client = TbaClient();

// For testing — inject a mock Dio instance
final client = TbaClient(dio: mockDio);
```

The app creates a single `TbaClient` instance at the top level (`MatchRecordApp`) and passes it down through `MainScreen`. If no `tbaClient` is provided to `MatchRecordApp`, a default one is constructed automatically.

### Available Methods

Every method returns a `Future<Result<T>>`, where `Result` is a sealed class with two subtypes:
- `Ok<T>` — contains `.value` with the data
- `Err<T>` — contains `.message` with a human-readable error string

**`getEvents(int year)`** `-> Result<List<Event>>`
Fetches all events for a given year. Returns a list of `Event` objects.

**`getEvent(String eventKey)`** `-> Result<Event>`
Fetches a single event by its TBA key (e.g., `"2026miket"`). Returns one `Event`.

**`getTeams(String eventKey)`** `-> Result<List<Team>>`
Fetches all teams registered at an event. Returns a list of `Team` objects.

**`getMatches(String eventKey)`** `-> Result<List<Match>>`
Fetches all matches for an event. Returns a list of `Match` objects. The list is unsorted; the caller is responsible for ordering (see `Match.compLevelPriority`, `Match.setNumber`, `Match.matchNumber`, `Match.bestTime`).

**`getAlliances(String eventKey)`** `-> Result<List<Alliance>?>`
Fetches playoff alliance selections. Note the **nullable inner type**: returns `Ok(null)` when the TBA response is null or an empty list (i.e., alliances haven't been selected yet). Returns `Ok(List<Alliance>)` once selections exist.

### TBA Data to App Model Mapping

| TBA JSON field          | App model field                |
|-------------------------|--------------------------------|
| `key`                   | `Event.eventKey`, `Match.matchKey` |
| `name`                  | `Event.name`                   |
| `short_name`            | `Event.shortName` (falls back to `name` if null) |
| `start_date` / `end_date` | `Event.startDate` / `Event.endDate` (parsed from `YYYY-MM-DD` strings) |
| `playoff_type`          | `Event.playoffType`            |
| `timezone`              | `Event.timezone`               |
| `team_number`           | `Team.teamNumber`              |
| `nickname`              | `Team.nickname`                |
| `event_key`             | `Match.eventKey`               |
| `comp_level`            | `Match.compLevel` (`"qm"`, `"sf"`, `"f"`, `"ef"`, `"qf"`) |
| `set_number`            | `Match.setNumber`              |
| `match_number`          | `Match.matchNumber`            |
| `time`                  | `Match.time` (nullable)        |
| `actual_time`           | `Match.actualTime` (nullable)  |
| `predicted_time`        | `Match.predictedTime` (nullable) |
| `alliances.red.team_keys` | `Match.redTeamKeys`          |
| `alliances.blue.team_keys` | `Match.blueTeamKeys`        |
| `alliances.red.score`   | `Match.redScore` (defaults to -1 if absent) |
| `alliances.blue.score`  | `Match.blueScore` (defaults to -1 if absent) |
| `winning_alliance`      | `Match.winningAlliance`        |
| `videos[].key` (first youtube entry) | `Match.youtubeKey` (nullable) |
| `alliances[].name`      | `Alliance.name` (defaults to `"Alliance N"`) |
| `alliances[].picks`     | `Alliance.picks` (list of team key strings like `"frc201"`) |

The `Alliance.allianceNumber` is extracted from the alliance `name` field by pulling the first sequence of digits via regex. If the name contains no digits, it falls back to the 1-based index in the array.

## Known Issues / Shortcomings

- **Hardcoded API key.** The TBA API key is a string literal in the source code. This is intentional since the app is sideloaded (not published to app stores), but it means the key is visible to anyone who decompiles the app and cannot be rotated without a code change.

- **No ETag / If-Modified-Since caching.** Every request fetches the full response from TBA. The TBA API supports `ETag` and `If-Modified-Since` headers for conditional requests, which would reduce bandwidth and improve response times, but the client does not implement this.

- **No retry logic.** If a request fails (timeout, transient server error, etc.), the client returns an `Err` immediately. There is no automatic retry with backoff.

- **Alliances endpoint returns null before selection.** `getAlliances` returns `Ok(null)` when alliances haven't been selected yet. Callers must handle this null case explicitly — it does not return an empty list.

- **2026 TBA data may be missing semifinal matches.** For the 2026 season, TBA may not yet have complete data for semifinal (`sf`) matches at some events, which can cause gaps in the match list.

- **Scores default to -1 for unplayed matches.** `redScore` and `blueScore` default to -1 when the TBA response is null (match hasn't been played yet). Callers should treat -1 as "no score available" rather than a real score.

- **Base URL is duplicated.** The base URL `https://www.thebluealliance.com/api/v3` is defined both as a private constant in `TbaClient._baseUrl` and in `AppConstants.tbaBaseUrl`. They are not connected — changing one does not affect the other.

- **Team keys include the `frc` prefix.** `redTeamKeys`, `blueTeamKeys`, and `Alliance.picks` contain strings like `"frc201"`, not plain team numbers. Callers must strip the prefix if they need a numeric team number.

## Technical Details

### URL Patterns

All requests go to `https://www.thebluealliance.com/api/v3` with the `X-TBA-Auth-Key` header. The endpoints used:

| Method          | URL path                           |
|-----------------|------------------------------------|
| `getEvents`     | `/events/{year}`                   |
| `getEvent`      | `/event/{eventKey}`                |
| `getTeams`      | `/event/{eventKey}/teams`          |
| `getMatches`    | `/event/{eventKey}/matches`        |
| `getAlliances`   | `/event/{eventKey}/alliances`      |

Connection and receive timeouts are both set to 10 seconds.

### JSON Parsing

All JSON parsing is done manually (no code generation). Every field access uses null-safe casts with fallback defaults (e.g., `as int? ?? 0`, `as String? ?? ''`). This means the client will not throw on unexpected null fields — it will silently use defaults.

`Event.startDate` and `Event.endDate` are parsed from `YYYY-MM-DD` strings via `DateTime.parse()`. If the TBA field is null, the fallback string `'2000-01-01'` is used, producing a DateTime for January 1, 2000.

### Match `comp_level` Handling

TBA uses short string codes for competition levels. The `Match` model stores these directly and provides two computed properties:

`displayName` — human-readable label:
| `comp_level` | `displayName` format | Example     |
|--------------|----------------------|-------------|
| `qm`         | `Q{matchNumber}`     | `Q42`       |
| `sf`          | `SF {setNumber}`     | `SF 3`      |
| `f`           | `F{matchNumber}`     | `F1`        |
| `ef`          | `EF {matchNumber}`   | `EF 2`      |
| `qf`          | `QF {setNumber}-{matchNumber}` | `QF 2-1` |
| other         | raw `matchKey`       |             |

`compLevelPriority` — integer for sorting (lower = earlier in event):
`qm` = 0, `ef` = 1, `qf` = 2, `sf` = 3, `f` = 4, other = 5.

### YouTube Key Extraction

Match video data from TBA comes as an array of `{ "type": "...", "key": "..." }` objects. The parser iterates through the `videos` array and takes the `key` of the **first** entry where `type == "youtube"`. If no YouTube video exists, `youtubeKey` is null. Non-YouTube video types (e.g., TBA's own video hosting) are ignored.

### Error Handling with the `Result` Type

The `Result<T>` sealed class (defined in `lib/util/result.dart`) forces callers to handle both success and failure cases:

```dart
final result = await client.getMatches('2026miket');
switch (result) {
  case Ok(:final value):
    // value is List<Match>
  case Err(:final message):
    // message is a human-readable error string
}
```

Error messages are generated from `DioException` details:
- Timeout (connect, receive, send) -> `"Connection timed out. Check your internet connection."`
- Connection error -> `"Could not connect to The Blue Alliance. Check your internet connection."`
- HTTP 401 -> `"TBA API key is invalid."`
- HTTP 404 -> `"Data not found on The Blue Alliance."`
- Other HTTP errors -> `"TBA returned error {statusCode}."`
- Other DioExceptions -> `"Network error: {message}"`
- Non-Dio exceptions -> `"Failed to load data: {exception}"`

### Date/Time as Unix Seconds

Match time fields (`time`, `actualTime`, `predictedTime`) are Unix timestamps in **seconds** (not milliseconds), as returned directly from TBA. They are nullable — unscheduled or future matches may have null values for some or all of these fields. The `Match.bestTime` getter returns the first non-null value in the priority order: `actualTime` -> `predictedTime` -> `time`.
