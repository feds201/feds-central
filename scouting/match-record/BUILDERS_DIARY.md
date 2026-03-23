# Builder's Diary — Match Record App

## Build Plan

1. **Foundation** — Data models, JSON persistence, DataStore + tests
2. **TBA + Navigation** — TBA client, main screen shell, tabs, match list, settings
3. **Import Pipeline** — DriveAccess test impl, match/alliance suggestion, import preview
4. **Video Viewer** — Dual-player sync, scrubbing, audio, sidebar
5. **Drawing Overlay (P1)** — CustomPainter strokes, undo/redo
6. **Remaining P1s** — Integrity check, storage management, import history

---

## Progress Log

### Phase 1: Foundation — COMPLETE
- 148 tests passing
- All 13 data model classes with full serialization (toJson/fromJson/copyWith/==/hashCode)
- JsonPersistence with atomic write (tmp + rename)
- DataStore with ChangeNotifier, all CRUD, uniqueness enforcement, skip history
- Result<T> sealed type, constants, test flags

### Phase 2: TBA + Navigation — COMPLETE
- 166 total tests passing (18 new TBA tests)
- TBA client with dio, parses events/teams/matches/alliances
- Main screen with IndexedStack tabs, bottom NavigationBar
- Search bar with chips + autocomplete overlay (debounced 250ms)
- All 4 tabs: Search, Teams, Matches, Alliances (conditional)
- Match list + match row with full display (scores, teams, video icons, time formatting)
- Settings page with team number, event picker, thresholds
- TestFlags auto-loads 2026mimid on first launch

### Phase 3: Import Pipeline — COMPLETE
- All tests passing
- DriveAccess interface + TestDriveAccess using embedded sample videos from assets
- VideoMetadataService with platform-aware timestamps (iOS start vs Android end)
- AllianceSuggester (pure function, 12 tests)
- MatchSuggester with gap-based algorithm + cascade logic (11 tests)
- ImportPipeline orchestrating full flow (scan → preview → execute → finalize)
- Full Sync Page UI: Import tab with preview list, History tab, Storage tab
- Import preview rows with match dropdown, team editing, alliance toggle, auto-skip

### Phase 4: Video Viewer — IN PROGRESS
- Building sync engine, scrub controller, drawing controller
- Video panes, control sidebar, scrubber bar
- Forced landscape, immersive mode, wakelock

## Trade-offs & Decisions

### TD-1: Test-only pure computation for SyncEngine
Instead of mocking media_kit Player internals, we test only the pure computation parts (offset calculation, laterPositionFor, earlier/later determination). The player interaction code is thin wrappers proven in the prototype. This keeps the code simpler and avoids a needless abstraction layer.

### TD-2: Synthetic metadata for desktop testing
Since platform channels don't work on desktop, VideoMetadataService generates synthetic but realistic metadata for test files (parsing timestamps from Android PXL filenames, estimating duration from file size). This lets the app run on desktop during development.

### TD-3: Asset-based test drives
Sample videos are bundled as Flutter assets. TestDriveAccess auto-selects the first drive and the import flow works end-to-end on desktop without real USB hardware.
