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

### Phase 4: Video Viewer — COMPLETE
- 250 total tests (52 new: scrub 14, drawing 20, sync 18)
- SyncEngine: dual-player sync by recording start timestamps, countdown from position stream
- ScrubController: non-linear scrub math (power curve), cancel-and-replace seek throttling
- DrawingController: ChangeNotifier strokes, undo/redo, opacity (1.0 paused, 0.5 playing)
- StrokePainter: quadratic bezier smoothing, red color, 3.5px
- VideoPane: alliance color bar, star icon, countdown overlay, touch scrub
- ControlSidebar: 72px, all controls, drawing controls when paused
- ScrubberBar: slider with position/duration, drag guard
- VideoViewer: landscape lock, immersive, wakelock, full lifecycle management

### Phase 5: Drawing Overlay — COMPLETE
- Built as part of Phase 4 (drawing_overlay.dart, stroke_painter.dart, drawing_controller.dart)
- Listener for raw pointer events (not GestureDetector)
- No pointer ID tracking (intentional multi-touch interleave)

### Phase 6: Remaining P1s — COMPLETE
- Startup integrity checker: reconciles files on disk vs DataStore
- Drive disconnection handling during import
- Storage management: "select past events" for bulk cleanup
- Import pipeline: drive permission check before import

## Bugs Found & Fixed

### BUG-1: Search bar stealing taps from match list
**Symptom:** Tapping a match row in the list focused the search bar instead
**Root cause:** PreferredSize only declares height but doesn't constrain child. TextField's Material tap target (48x48 minimum) expanded beyond the 48px boundary into the match list area.
**Fix:** Wrapped in SizedBox(height: 48) + ClipRect in main_screen.dart; added clipBehavior: Clip.hardEdge to search bar container.

### BUG-2: Sidebar buttons in viewer nearly untappable (~9px wide)
**Symptom:** Sidebar buttons on Pixel 9 Pro were 9px wide instead of 108px
**Root cause:** SafeArea's right padding (for display cutout/rounded corners) consumed most of the 72px sidebar width.
**Fix:** Added `right: false` to sidebar's SafeArea; wrapped entire viewer Row in outer SafeArea.

### BUG-3: Search bar hit target too narrow after BUG-1 fix
**Symptom:** After clipping fix, TextField tappable area was only ~127px wide
**Root cause:** IntrinsicWidth constrained TextField to content width only.
**Fix:** Added ConstrainedBox with minWidth: 150 around the IntrinsicWidth wrapper.

## Trade-offs & Decisions

### TD-1: Test-only pure computation for SyncEngine
Instead of mocking media_kit Player internals, we test only the pure computation parts (offset calculation, laterPositionFor, earlier/later determination). The player interaction code is thin wrappers proven in the prototype. This keeps the code simpler and avoids a needless abstraction layer.

### TD-2: Synthetic metadata for desktop testing
Since platform channels don't work on desktop, VideoMetadataService generates synthetic but realistic metadata for test files (parsing timestamps from Android PXL filenames, estimating duration from file size). This lets the app run on desktop during development.

### TD-3: Asset-based test drives
Sample videos are bundled as Flutter assets. TestDriveAccess auto-selects the first drive and the import flow works end-to-end on desktop without real USB hardware.

## Device Verification Results

### Verified on Pixel 9 Pro (API 36)
- App launches, loads TBA data, persists across restarts ✓
- All 4 tabs work (Matches, Teams, Alliances, Search) ✓
- "Your Matches" section correctly shows team 201 matches ✓
- Settings page: team number, event selection, thresholds ✓
- Import from iOS test drive: preview → import → history recorded ✓
- Camera icon appears on matches with recordings ✓
- Match tap → video viewer opens with recording ✓
- Video plays, scrubber updates (0:00/0:08) ✓
- Play/Pause button works ✓
- Sidebar buttons are tappable (108px wide after fix) ✓
- Back button returns to matches ✓
- YouTube links open YouTube app ✓
