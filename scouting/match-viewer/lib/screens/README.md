# UI Layer

Covers `screens/`, `tabs/`, `sync/`, and `widgets/`.

## How to Use This Module

### Navigation

The app has four screen-level routes, all pushed via `Navigator.of(context).push(MaterialPageRoute(...))`. There is no GoRouter -- the app only has four screens and a simple push/pop model is sufficient.

| Route | Entry point |
|---|---|
| **MainScreen** | Root route. AppBar + search bar + tab body + bottom NavigationBar. |
| **VideoViewer** | Pushed from `_onMatchTap` in MainScreen. Full-screen landscape dual-video player. |
| **SyncPage** | Pushed from the SyncButton in the AppBar or the "Open Sync" button in SettingsPage. |
| **SettingsPage** | Pushed from the gear icon in the AppBar. Contains team number, event selection, TBA data loading, threshold tuning, and a link to SyncPage. |

### Tabs in MainScreen

MainScreen uses an `IndexedStack` with a bottom `NavigationBar` for tab switching. IndexedStack keeps all tab widgets alive so scroll position is preserved when switching tabs.

The tab count is dynamic: the Alliances tab only appears when `DataStore.hasAllianceData` is true (3 tabs without alliances, 4 with). The default tab is the Matches tab (index 2 with alliances, index 1 without).

| Index | Tab | Widget | Purpose |
|---|---|---|---|
| 0 | Search | `SearchTab` | Shows matches filtered by search chips. Empty state when no chips are active. |
| 1 | Teams | `TeamsTab` | Sorted team list. Your team (by `settings.teamNumber`) pinned at top with a divider. |
| 2 | Matches | `MatchesTab` | Full match list via `MatchList` with "Your Matches" and "All Matches" sections. |
| 3 | Alliances | `AlliancesTab` | Alliance list, grouped by event when multiple events are selected. Your alliance pinned at top. |

### Search

Search state is owned entirely by `_MainScreenState`: the `TextEditingController`, `FocusNode`, chip list, and autocomplete results all live there and are passed down.

**Autocomplete flow:**
1. User types in `AppSearchBar` -- `onTextChanged` fires on every keystroke.
2. `_onSearchTextChanged` debounces input (configurable via `AppConstants.searchDebounceMs`), then calls `_computeAutocomplete`.
3. `_computeAutocomplete` searches teams (by number or nickname), matches (by display name or match number), and alliances (by name or number). Results are capped at 20.
4. `AutocompleteOverlay` renders as a `Positioned` widget in a `Stack` above the tab body. It appears when `_showAutocomplete` is true and disappears when the search bar loses focus.

**Chip flow:**
- Tapping a team result or a team tile adds a `SearchChip.team` and switches to the Search tab (index 0).
- Tapping an alliance result or tile adds a `SearchChip.alliance` (which carries the `picks` list of team keys).
- Tapping a match result navigates directly to the VideoViewer (no chip).
- `SearchTab` expands all chips to a set of team numbers (alliance chips expand to all their picks), then filters the match list to matches containing any of those teams.
- Submitting the search field (keyboard enter) auto-selects the first autocomplete result.

### Viewer Lifecycle

`VideoViewer` is a full-screen landscape page with the following lifecycle:

**On enter (`initState`):**
1. Lock orientation to landscape via `SystemChrome.setPreferredOrientations`.
2. Enter immersive sticky mode via `SystemChrome.setEnabledSystemUIMode`.
3. Enable wakelock via `WakelockPlus.enable()`.
4. Initialize `Player` instances (media_kit) for red and/or blue recordings. Both start paused and muted.
5. If dual video, create a `SyncEngine` from both recordings and start position monitoring.
6. Subscribe to position, duration, and playing streams from the primary (earlier) player.

**On exit (`dispose`):**
1. Cancel all stream subscriptions.
2. Dispose SyncEngine, players, and DrawingController.
3. Restore orientation to all directions, UI mode to edge-to-edge, and disable wakelock.

**Playback:** Play/pause goes through `SyncEngine.startSyncedPlayback()` / `pauseBoth()` for dual video, or directly on the single player. The sync engine handles the timing offset between the two recordings.

**Scrubbing:** Two scrub mechanisms exist:
- **ScrubberBar:** A bottom slider bar. Drag suppresses position stream updates via `_isScrubBarDragging`.
- **Touch scrub on VideoPane:** Pan gesture on the video itself. Pauses playback on start, computes a seek offset using `ScrubController.computeScrubOffsetMs` (exponential curve based on horizontal delta), and throttles seeks via `ScrubController.enqueueSeek`.

**Drawing:** Available only when paused. The ControlSidebar shows draw/undo/redo/clear buttons. `DrawingController` manages stroke state with undo/redo stacks. Strokes render at full opacity when paused, half opacity during playback. `DrawingOverlay` captures raw pointer events; `StrokePainter` renders bezier-smoothed strokes. Drawing mode auto-exits when playback resumes.

**Audio:** Cycles through muted -> red audio -> blue audio. Audio follows the logical alliance, not the visual position (swapping sides does not swap audio).

### Sync Page Tabs

`SyncPage` uses `DefaultTabController` + `TabBar` + `TabBarView` with four tabs:

| Tab | Widget | Purpose |
|---|---|---|
| Import | `ImportTab` | Connect a USB drive, scan for videos, preview/assign matches, and execute the import. |
| History | `HistoryTab` | Shows past import sessions in reverse chronological order. Tapping a session opens `_SessionReEditPage` for metadata-only re-editing. |
| Storage | `StorageTab` | Lists app-imported recordings only. Supports multi-select with smart selection modes (Select All, All But Ours, Past Events) and batch deletion. Camera and Quick Share source file management is not yet implemented as separate tabs. |
| USB Transfer Guide | `UsbInstructionsTab` | Static step-by-step instructions for transferring videos from phones to USB drives (Android and iOS). Responsive layout: cards stack vertically in portrait, side-by-side in landscape. |

### Key Callbacks and Data Flow

**DataStore** is the single source of truth. It is a `ChangeNotifier` passed down from `MainScreen` to every tab and widget that needs data. Both `MainScreen.build` and `StorageTab.build` wrap their content in `ListenableBuilder(listenable: dataStore, ...)` so the UI rebuilds whenever data changes. `HistoryTab` also uses a `ListenableBuilder`.

**Callback pattern:** Tabs are stateless (or minimal state) and receive callbacks from `MainScreen` for user actions:
- `onMatchTap(MatchWithVideos)` -- MainScreen checks `hasRecordings`; if none, shows a snackbar; otherwise pushes VideoViewer.
- `onTeamTap(Team)` -- Adds a team search chip and switches to Search tab.
- `onAllianceTap(Alliance)` -- Adds an alliance search chip and switches to Search tab.

**"Recorded Only" toggle:** The videocam icon in the AppBar toggles `settings.recordedMatchesOnly`. This is persisted in settings and used by `DataStore.getMatchesWithVideosFiltered` to filter the match list. Note: this only affects the Matches and Search tabs, not the Teams or Alliances tabs.

## Known Issues / Shortcomings

- **No GoRouter:** Intentional -- the app has only 4 screens with a linear push/pop model. A routing package would add complexity without benefit.
- **"Recorded Only" filters matches only:** The toggle filters the match list but does not affect the Teams or Alliances tabs. A team or alliance might show up even if none of their matches have recordings.
- **No drive switch button in ImportTab:** There is currently no way to disconnect from a scanned drive and connect a different one without leaving and re-entering the SyncPage. The `_pickDrive` method exists but is only surfaced in the initial "Connect Drive" state and the error state.
- **Viewer requires recordings to open:** Tapping a match that has only a YouTube link (no local recordings) shows a snackbar "No recordings for [match]" and does not navigate. YouTube-only matches cannot be viewed in the in-app player.
- **Import pipeline hardcoded to TestDriveAccess:** `ImportTab._driveAccess` is always `TestDriveAccess()` even when `TestFlags.useSampleVideos` is false. There is a TODO comment to replace it with `SafDriveAccess` for production.
- **SettingsPage "Manage Storage" button is a no-op:** The storage button's `onPressed` is an empty closure `() {}`.
- **Edit metadata defaults to red recording:** The `_EditMetadataSheet` in VideoViewer always defaults to editing the red recording (or blue if red is absent). There is no UI to switch which recording you are editing.
- **Autocomplete capped at 20 results:** If the query is broad enough to match more than 20 items, results are silently truncated.
- **Multi-touch drawing:** `DrawingOverlay` intentionally does not track pointer IDs. Multi-touch points interleave into the same stroke, which works acceptably for stylus use but can produce odd results with multiple fingers.

## Technical Details

### Widget Hierarchy

```
MainScreen (StatefulWidget)
  Scaffold
    AppBar
      AppSearchBar (search bar with chips)
      "Recorded Only" toggle button
      SyncButton -> pushes SyncPage
      Settings icon -> pushes SettingsPage
    body: Stack
      IndexedStack
        SearchTab (StatelessWidget)
          MatchList -> MatchRow (per match)
        TeamsTab (StatelessWidget)
          ListView -> TeamTile (per team)
        MatchesTab (StatelessWidget)
          MatchList -> MatchRow (per match)
        AlliancesTab (StatelessWidget, conditional)
          ListView -> AllianceTile (per alliance)
      AutocompleteOverlay (conditional, positioned above tabs)
    NavigationBar (bottom)

VideoViewer (StatefulWidget)
  Scaffold (black background)
    Row
      Column
        Row (dual video) or single VideoPane
          VideoPane (StatelessWidget)
            Video (media_kit)
            Alliance color bar (3px, top)
            Star icon (if user's team)
            Edit icon (pencil, top-right corner)
            Countdown overlay (if waiting for sync)
            DrawingOverlay (if drawing mode)
            _PassiveStrokePainter (if strokes exist but not drawing)
            _ScrubGestureDetector (if not drawing)
        ScrubberBar (StatefulWidget, bottom slider)
      ControlSidebar (StatelessWidget, 72px wide)

SyncPage (StatefulWidget)
  DefaultTabController
    TabBar: Import | History | Storage | USB Transfer Guide
    TabBarView
      ImportTab (StatefulWidget)
        ImportPreviewRowWidget (per scanned video)
      HistoryTab (StatelessWidget)
        -> _SessionReEditPage (pushed, per session)
           ImportPreviewRowWidget (per entry, metadata-only)
      StorageTab (StatefulWidget)
        StorageVideoList -> recording rows
      UsbInstructionsTab (StatelessWidget)
        _PlatformCard (Android) -> _StepRow (per step)
        _PlatformCard (iOS) -> _StepRow (per step)
```

### Search State Ownership

All search state lives in `_MainScreenState`:
- `_searchController` (TextEditingController) -- bound to the text field in AppSearchBar.
- `_searchFocusNode` (FocusNode) -- hides autocomplete on blur.
- `_chips` (List<SearchChip>) -- the active filter chips. Each chip is either a team (single number) or an alliance (list of `frc*` pick keys).
- `_autocompleteResults` (List<AutocompleteResult>) -- computed from the debounced query.
- `_showAutocomplete` (bool) -- controls overlay visibility.
- `_debounceTimer` (Timer) -- ensures autocomplete does not fire on every keystroke.

`SearchTab` receives the chip list as a prop and is stateless. It calls `_expandChipsToTeamNumbers()` to flatten all chips (including alliance picks) into a `Set<int>`, then filters the match list against those team numbers.

### Cross-Tab Flows

- **Team/Alliance -> Search:** Tapping a team (TeamsTab) or alliance (AlliancesTab) calls `_addChip` in MainScreen, which adds the chip and sets `_selectedTab = 0` to switch to the Search tab.
- **Autocomplete match -> Viewer:** Tapping a match in the autocomplete dropdown calls `_onMatchTap` directly, bypassing the Search tab.
- **MatchRow YouTube icon:** MatchRow contains an inline `IconButton` that launches the YouTube URL via `url_launcher`. This does not go through the MainScreen callback chain.

### Viewer Lifecycle Details

**Orientation and UI:** On enter, the viewer forces landscape orientation and immersive sticky mode. On dispose, it restores all orientations and edge-to-edge UI. The wakelock prevents the screen from sleeping during review.

**Dual video sync:** When both red and blue recordings exist, `SyncEngine` handles the timing offset. The "earlier" player (the one whose recording started first) is the primary source of position/duration. The "later" player shows a countdown overlay until its recording's start time is reached. Seeking and play/pause always go through the SyncEngine for coordinated control.

**View modes:** Cycles through both -> red-only -> blue-only. Only available for dual-video matches. In single-video mode, the single available recording fills the space.

**Side swapping:** `_sidesSwapped` swaps the visual left/right positions of red and blue panes. This is purely visual -- audio routing, sync logic, and all internal state remain tied to the logical red/blue identity.

**Edit metadata:** A bottom sheet (`_EditMetadataSheet`) allows changing the match assignment, alliance side, and team numbers for a recording. Changes are persisted via `DataStore.updateRecording`.

### ImportPreviewRowWidget Controls

Each row in the import preview list (`ImportPreviewRowWidget`) shows:
- **Checkbox** for selection (disabled if no match assigned and not auto-skipped).
- **Video info column:** filename, recording start time, duration, auto-skip reason or "Assign a match to import" prompt.
- **Match dropdown:** All matches from selected events, sorted by time.
- **Team chips:** Tappable (if alliances are available) to open an alliance picker dialog that sets team numbers.
- **Alliance side toggle:** Tappable inline button that flips between red/blue. Updates the left border color and team numbers.

The `ImportTab` header has a "Set all" row with RED/BLUE buttons to batch-set the alliance side for all rows at once. A "Select all" checkbox controls batch selection (auto-skipped videos are excluded from select-all).

Match assignment cascading: When a match is changed via `_onMatchChanged`, `ImportPipeline.cascadeMatchChange` is called to update subsequent rows sequentially.

### Storage Management

`StorageTab` tracks selection via a `Set<String>` of recording IDs. Selection modes:
- **Select All:** Selects every recording.
- **All But Ours:** Selects recordings where the user's team is not in team1/team2/team3.
- **Past Events:** Selects recordings belonging to events whose `endDate` is before now.
- **Deselect:** Clears the selection set. Only appears when something is selected.

Deletion confirms via dialog, then iterates: deletes the file from disk, then calls `DataStore.deleteRecording` (which also marks the video as skipped so it is not reimported). `StorageVideoList` renders rows sorted by match key, each with a checkbox, match display name, alliance/team/size info, and original filename.
