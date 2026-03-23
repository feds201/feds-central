Goal: Offline-first Android tablet app for FRC Team 201 (The Feds) to ingest, organize, and review match footage during competitions. Two students record each match on personal phones (one per alliance side, vertical vid), transfer via USB-C flash drives, and the tablet provides a synchronized dual-video viewer for match strategy analysis.

Purpose: help our drive team see video of our own performance AND see performance of our opponents in playoffs. Used in between matches to debrief the drivers. Must be fast and easy to use and able to work with little to no network (besides 1x/day pulling some external data like match schedule)

Platform: Android tablet (sideloaded, not Play Store)
⚠️ TARGET SDK: API 35 (Android 15). Do NOT target API 36+ — it removes the ability to lock screen orientation on tablets (display width >= 600dp). See P2 "API 36 Migration" for details. This warning must also appear wherever the target SDK is configured in build files.

P0 — Core
Sync UI & Video Ingestion
- Sync button in the main app bar; always visible regardless of USB state
- Tapping the sync button opens the Sync UI (full-screen page)
- Settings also has an entry point to the same Sync UI
- Sync UI has sections/tabs: Import, History, Storage Management

USB Drive Access
- No automatic USB detection — user manually taps the Sync button to initiate
- SAF (Storage Access Framework) permission grant — one-time system "Allow" dialog per drive, permission persisted across app restarts
- After SAF grant, enumerate and read all video files from the drive without further user interaction
- Auto-suggest alliance side (red/blue) for the drive:
  - If a config.json with {"alliance": "red"} (or "blue") exists on the drive root → suggest that side
  - Otherwise → no suggestion, user must pick
- Alliance side is always an auto-suggestion with manual override, never a hard assignment

Import Preview
- When the Sync UI detects new videos on a connected drive, show them in an import preview list
- Sort videos by recording start timestamp (oldest at top); tiebreak by filename
- Each row shows: start time, duration, suggested match ID, teams, and alliance side
- Match ID is a tappable dropdown to change
- Each of the 3 team slots is tappable to change
- Alliance side is tappable to toggle red/blue
- If alliance data is available, offer "pick an alliance" shortcut instead of selecting 3 individual teams
- Match selection uses the matches available in TBA's schedule — no custom match creation. If a playoff match hasn't appeared in TBA yet, the row stays unassigned (re-sync after TBA ingests the match)
- If alliance data is available, tapping the team slots offers an "Alliance X" picker that auto-fills all 3 teams for that alliance
- Header area: tap alliance color to set ALL rows to the same color

Match Auto-Suggestion Algorithm
- For each video, auto-suggest which match it belongs to. All logic centralized in one function.
- Primary signal: recording start timestamp matched to the NEAREST match on the schedule
- Sequential logic based on gap between consecutive videos (tunable thresholds in Settings, defaults below):
  - Gap < 10 minutes: assume it's the next sequential match after the previous video's assigned match
  - Gap > 20 minutes: use match schedule (nearest match by timestamp)
  - Gap 10–20 minutes: highlight the row and REQUIRE the user to manually select the match
- When the user manually changes a match number in a row:
  - Update the teams in that row to match the new match's team composition
  - Update subsequent rows' match numbers sequentially (next match, next match, etc.)
  - Cascade: update those rows' team numbers accordingly
  - Stop cascading when hitting a row the user has previously manually set

Import Selection
- Checkbox on the left side of each row to select/deselect for import
- "Select all" checkbox in the header — does NOT check auto-skipped videos (see below)
- Default: all videos selected, EXCEPT:
  - Videos under 30 seconds → auto-unchecked
  - Videos previously shown during a prior import and unchecked by the user → auto-unchecked
- Manually checking an auto-skipped video shows a toast explaining why it was skipped ("This video was skipped before" or "This video is under 30 seconds")
- Rows with no match assigned have their checkbox disabled — a match must be assigned before import
- Confirm button imports all selected videos: copies files from USB to on-device storage and saves metadata

Video Identity & Skip Tracking
- Each video needs a robust unique identifier for skip tracking and reimport prevention
- Use recording timestamp + device identifier (if available from video metadata) as primary key
- Exact identity strategy TBD during implementation — must survive file copies, renames, and transfers across devices without false positives or negatives
- Persist skip history in the database (video identity → skipped flag)

Import History / Sync Log
- Shows a list of all past import sessions, grouped by flash drive
- Each entry shows: date/time, drive label, number of videos imported
- Tapping an entry reopens the same import preview UI with all the settings from that import, fully editable
- Changes saved from the history view update the match assignments, alliance sides, teams, etc. in the database
- Each recording is individually editable from the viewer screen (pencil icon per video pane) — provides a quick per-recording edit path for mislabeled videos alongside the bulk history edit path

Storage Management
- Accessible from the Sync UI (as a tab/section) and from Settings
- Two modes using the same list component:

Tablet Storage Mode
- Shows all imported recordings on the device
- Each row shows: video preview info, match assignment, alliance side, teams, file size
- Checkboxes with "Select all" and "Select all but our team" (our team = the team set in Settings)
- Deleting a video removes it from device storage AND marks it as skipped so it won't be reimported
- Does NOT affect the flash drive

Flash Drive Mode (only when a drive is connected)
- Shows all videos on the currently-connected drive
- Uses the same list component as tablet storage mode
- Additional: checkmark icon on each row showing whether the video has been synced (imported) to the tablet
- Checkboxes with "Select all" and "Select all synced" (select all videos that have already been imported to the tablet)
- Deleting removes files from the flash drive ONLY — does NOT delete copies on the tablet
- Import NEVER auto-deletes tablet videos that are missing from the flash drive

Data Source
- Pull match schedule, team roster, and alliance data from The Blue Alliance API before the event
- App functions fully offline after initial pull
- Ability to re-pull if network becomes temporarily available

Data Storage
- Internal storage for match metadata, team/alliance data, recorded video references
- Separate storage (not just TBA data) for YouTube match URLs (official TBA recordings) and local ripped video URIs
- Video file references with mapping to match, alliance side, and teams
- Import session history (date, drive info, video list with selections)
- Video skip history (video identity → skipped flag, reason)

Navigation — Four Tabs: Search, Teams, Matches, Alliances
- Default selected tab: Matches
- Alliances tab only visible when alliance data exists
- Settings field for "your team number"
- Sync button in the app bar (see Sync UI section above)
- Teams tab: your team at top, divider, all teams (including yours again)
- Matches tab: your matches at top sorted by order, divider, all matches
- Alliances tab: your alliance at top, divider, all alliances

Search Tab & Unified Search
- Search bar accessible from any tab
- While typing: autocomplete overlay/dropdown shows partial and full matches across teams, alliances, and individual matches (debounced at 250ms)
- Each autocomplete result has a colored left-edge indicator corresponding to its source type (team/match/alliance each get a distinct color)
- Clicking autocomplete result that is a match → go directly to viewer
- Clicking autocomplete result that is a team or alliance → creates a chip in the search bar, switches to Search tab, shows all matches for that selection
- Clicking an alliance internally expands to its constituent teams; visually displayed as the alliance name
- Multiple chips supported (union of results): e.g., chip for team 201 + chip for team 217 → shows all matches involving either team
- Enter key with text typed → selects the top autocomplete result (behaves as if you clicked it)
- Search results (the actual tab content) show only matches, using the same match list subcomponent as the Matches tab
- Matches in results bold the team number or alliance name that caused the match to appear; if multiple reasons, bold all of them
- Empty search tab (no chips, no text) → empty state
- Clicking a team in the Teams tab or an alliance in the Alliances tab → switches to Search tab with that item as a chip

Match Row Behavior
- Clicking the row → opens viewer
- If a YouTube URL exists for the match, show a YouTube icon on the right; tapping opens YouTube app
- If a local ripped video URI exists, show a different icon; tapping opens it in the single-video viewer
- If both exist, show both icons; user chooses
- If neither exists, no icon
- If no recorded video (our own recordings) exists for the match, row indicates this but is not fully disabled (YouTube/local video may still be available)

Video Viewer
- Forced landscape (via SystemChrome.setPreferredOrientations, requires API 35 target — see platform note at top)
- Layout: left video pane | right video pane | control sidebar (own column, far right, not overlaid)
- Red on left, blue on right by default
- Thin red/blue indicator lines at top of each video pane
- Star icon on the pane containing your team
- No app bar at top
- Mute control: 3-state toggle (muted / red audio / blue audio); uses speaker icon with a cross when muted, red circle around icon for red audio, blue circle for blue audio; swaps correctly when sides swap
- Sidebar controls: swap sides, mute toggle, view mode toggle, play/pause, rewind 10s, forward 10s, restart
- Sidebar is scrollable if controls overflow
- Sidebar is not transparent; it's its own column alongside the video panes
- View mode toggle: 3 states (both sides / red only / blue only)
- Grayed out when only one recording exists or when viewing a local ripped full-match video
- When viewing a single video (any reason: toggle selection, only one recording exists, or local ripped video), maximize the video to fill available space — orient the widest dimension of the video along the widest dimension of the screen
- Videos synced by start timestamp: earlier video plays first, later video's pane shows black with countdown text ("Other side starting in X…")
- Single-video playback: same player, dual-video-specific controls (swap, per-side mute, view mode) are hidden or grayed out as appropriate
- Bottom scrubber bar (bottom 5–10% of screen), standard scrub behavior
- Full-area touch scrub: finger down anywhere on video = pause at current timestamp; horizontal drag = continuous non-linear scrub; finger stops moving = stays paused at scrubbed position
- Non-linear interpolation: small movements near the touch-down point = fine scrub, larger movements = coarser scrub; continuous function (not stepwise)
- Dragging from center to screen edge ≈ scrubs from current position to start/end
- Use Flutter's Curves classes (e.g., Curves.easeIn or custom Curve subclass) for the non-linear interpolation — equivalent to Android's AccelerateInterpolator
- Tunable constants for the curve

P1 — Secondary
Drawing Mode
- Activated when paused (works with cheap capacitive stylus)
- Fixed bright red color
- In-memory only — not persisted
- Undo, redo, clear buttons appear at bottom of sidebar (positioned so they don't shift existing buttons)
- On resume/play, drawings remain visible at 50% alpha
- Exiting the viewer clears all drawings

Drive Disconnection During Import
- If the USB drive is disconnected during import review (before copying starts), show a dialog asking to re-plug or cancel
- If the USB drive is disconnected during file copying, abort remaining copies, keep any already-completed imports, clean up partial files
- On cancel from the review stage, discard the preview cleanly (no partial state left behind)

"Recorded Only" Toggle
- Toggle button in the app bar (upper right, next to sync and settings icons)
- Icon: `Icons.videocam` (highlighted in primary color) when active, `Icons.videocam_off` (default color) when inactive
- When enabled, filters the Matches tab, Search results tab, and match autocomplete to only show matches that have recordings (our own recordings or local ripped videos)
- Teams tab and Alliances tab are unaffected — they always show all teams/alliances
- Toggle state persists in AppSettings (survives app restarts)
- Tooltip: "Show recorded matches only" when inactive, "Show all matches" when active

Startup Integrity Check
- On app launch, scan the recordings directory and reconcile with the database
- Files on disk with no matching recording row in the DB → delete the orphaned file
- Recording rows in the DB whose file is missing from disk → delete the DB row
- Log all cleanup actions for debugging
- Runs silently on startup — no UI unless something was cleaned up, in which case show a brief toast ("Cleaned up N orphaned files")

P2 — Later
Local Ripped YouTube Videos
- External process (Python script on a networked computer, or similar) downloads official TBA YouTube match videos
- Videos transferred to tablet via some mechanism (ADB push, flash drive, TBD — not building the pipeline now)
- Database already has the local URI field (P0); UI already handles the icon and player behavior (P0)
- This P2 item is just building/defining the actual transfer workflow

Multi-Field Support
- Adapt for district championships with multiple fields

API 36 Migration
- Currently targeting API 35 to retain orientation locking on tablets
- Android API 36 (Android 16) removes the ability for apps to restrict orientation on devices with display width >= 600dp (all tablets)
- Google Play requires targeting API 36 by August 2026 (not relevant for sideloaded apps, but we should not fall too far behind)
- Migration requires: replacing forced landscape with a responsive layout that works in both orientations (optimized for landscape)
- No other API 36 features are relevant to this app — the only blocker is the orientation restriction

Import Preview Video Playback
- Tapping a row in the import preview opens a modal overlay playing the video directly from the USB drive, starting from min(duration/2, 30s)
- Requires validating that media_kit can play from SAF content:// URIs without copying the file first

Foreground Service for Import
- Add an Android foreground service during file import to prevent the OS from killing the app if backgrounded
- Shows a persistent notification with import progress
- Without this, Android may kill the app if the user accidentally switches apps or taps a notification during a multi-file import (wakelock only prevents screen sleep, not process death)

iPad / iOS Support
- Currently Android-only. iOS support requires addressing the following:
- USB drive detection: iOS has NO programmatic USB detection. The user must manually use the system Files picker each time to select files from a USB drive. No auto-detect, no volume label reading. The entire Sync UI import flow would need a fallback path where the user manually picks files.
- Drive color identification: Volume label is not reliably readable on iOS. User must manually confirm which drive is red/blue every time.
- Orientation locking: Works on iPad ONLY if multitasking is disabled (UIRequiresFullScreen = YES in Info.plist), which removes Split View and Slide Over.
- Flash drive clearing: Deleting files from a USB drive via iOS app APIs is extremely limited. May need to direct users to the Files app for this.
- Flash drive file systems: iOS supports FAT, FAT32, exFAT, APFS. NTFS read-only since iOS 16. Drives must use a compatible format.
- All other features (video playback, database, search, drawing, URL launching) work on iOS without changes.
