# Viewer Module

Business logic for dual-video synchronized match playback. The three classes in this directory (`SyncEngine`, `ScrubController`, `DrawingController`) are pure logic with no Flutter widget dependencies, consumed by `VideoViewer` and its child widgets.

## How to Use This Module

### SyncEngine

`SyncEngine` manages synchronized playback of two match recordings (red alliance and blue alliance) that started recording at different times.

**Earlier/later model.** One recording always started before the other. `SyncEngine.fromRecordings()` compares the two `Recording.recordingStartTime` values, designates the earlier one as the primary clock, and computes the `syncOffset` (absolute difference between start times). The later player's position is always derived: `laterPos = earlierPos - syncOffset`. The `earlierIsRed` flag tracks which alliance is which, and `redPlayer`/`bluePlayer` getters abstract over the earlier/later assignment so callers can address players by alliance color.

**Sync offset and countdown.** When playback starts from a position before the offset (i.e., the earlier video is at a point where the later video hadn't started recording yet), `laterWaiting` is set to `true` and the later pane shows a countdown overlay. The countdown is driven by the earlier player's position stream (not a wall-clock timer), so it stays accurate even if the video buffers. When the earlier player's position reaches the offset, `SyncEngine` automatically seeks and plays the later player.

**Position monitoring.** Call `startPositionMonitoring(onStateChanged)` after creating the engine. This subscribes to the earlier player's position stream and manages the countdown/trigger lifecycle. The `onStateChanged` callback lets the UI rebuild when `laterWaiting` or `countdownRemaining` change.

**Intended position tracking.** `_intendedEarlierPosition` tracks where the earlier player *should* be, separately from `player.state.position` (which updates asynchronously via streams and may lag behind after a `seek()`). Every code path that changes position (`seekToEarlierPosition`, `restartBoth`, `updateIntendedPosition`) updates this value. The UI reads it via `intendedEarlierPosition` as the authoritative position for scrub offset calculations.

**Key operations:**
- `startSyncedPlayback()` -- starts both players from the current intended position, handling the offset logic (both play immediately if past the offset, otherwise earlier plays and later waits).
- `pauseBoth()` -- pauses both players.
- `seekToEarlierPosition(duration)` -- seeks both players, clamping to valid ranges. If the target is before the offset, puts the later player in waiting state.
- `restartBoth()` -- pauses both, seeks both to zero, resets waiting/countdown state.

### ScrubController

`ScrubController` handles non-linear scrub math and cancel-and-replace seek throttling.

**Non-linear curve.** `computeScrubOffsetMs` is a static pure function that converts a horizontal pixel delta (from the touch origin) into a millisecond offset. It uses a power curve: `offset = sign * (|delta| / halfWidth)^exponent * maxRange`. With the default exponent of 2.5, small finger movements near the touch point produce fine-grained scrubbing, while dragging to the edge of the pane covers up to 2 minutes. A 3px dead zone prevents accidental micro-scrubs.

**Cancel-and-replace throttling.** Only one `seek()` call is in-flight at a time. `enqueueSeek(position, seekFn)` stores the desired position and calls `_dispatchSeek`. If a seek is already in-flight, the new position simply replaces `_pendingPosition`. When the in-flight seek completes (via `.whenComplete()`, not `.then()`, so it fires even if the seek throws), if a newer pending position exists, it dispatches immediately. This naturally adapts to decoder speed: fast hardware gets more seeks per second, slow hardware gets fewer, and the decoder is never overloaded.

**Lifecycle.** Call `reset()` when a scrub gesture ends to clear the in-flight/pending state.

### DrawingController

`DrawingController` manages freehand drawing strokes with undo/redo, extending `ChangeNotifier` so widgets rebuild on changes.

**Strokes.** Each stroke is a `List<Offset>`. `onPointerDown` starts a new stroke, `onPointerMove` appends points, `onPointerUp` finalizes it into `_strokes` and clears the redo stack (any new stroke after an undo invalidates the redo history). `strokes` and `currentStroke` are exposed as unmodifiable lists.

**Undo/redo.** `undo()` moves the last completed stroke to `_redoStack`. `redo()` moves it back. `clear()` wipes everything.

**Opacity.** `setOpacity(value)` controls drawing visibility. `VideoViewer` sets this to 1.0 when paused and 0.5 when playing, so drawings fade during playback without disappearing entirely. The opacity is applied via the `Paint.color` alpha channel in the stroke painters, not via a Flutter `Opacity` widget (which would create an offscreen buffer).

### How VideoViewer Ties Them Together

`VideoViewer` is the full-screen landscape widget that orchestrates everything:

1. **Initialization.** Creates `Player`/`VideoController` pairs for red and blue recordings, opens media files without auto-play, mutes both. If dual video is available, creates a `SyncEngine.fromRecordings()` and starts position monitoring.

2. **Stream subscriptions.** Listens to the primary (earlier) player's `position`, `duration`, and `playing` streams. The position listener updates `_position` in state and calls `syncEngine.updateIntendedPosition()` -- but only when not finger-scrubbing or scrub-bar-dragging (position stream suppression).

3. **Playback controls.** Play/pause, rewind 10s, forward 10s, and restart all delegate to `SyncEngine` in dual mode or directly to the single player. After each operation, state is synced (`_laterWaiting`, `_countdownRemaining`, `_position`).

4. **Finger scrubbing.** Either `VideoPane` accepts a pan gesture. `_onScrubStart` pauses playback and sets the `_isFingerScrubbing` guard. `_onScrubUpdate` computes the non-linear offset via `ScrubController.computeScrubOffsetMs`, calculates the target position relative to `intendedEarlierPosition`, updates the UI immediately (responsive), and enqueues the actual seek through `_scrubController.enqueueSeek`. `_onScrubEnd` clears the guard and resets the scrub controller.

5. **Scrubber bar.** The bottom `ScrubberBar` shows position/duration with a draggable slider. During user drag, `_isScrubBarDragging` suppresses position stream updates to prevent flicker. On drag end, it seeks to the final position.

6. **Drawing.** Drawing mode is only available when paused. `_isDrawingMode` toggles whether `VideoPane` shows a `DrawingOverlay` (which captures pointer events) or the normal scrub gesture detector. When not in drawing mode but strokes exist, a passive `CustomPaint` renders them (wrapped in `IgnorePointer` so touches pass through to the scrub detector). The `ControlSidebar` shows undo/redo/clear buttons only when drawing mode is active.

7. **View modes.** Dual video can show both panes side-by-side, red-only, or blue-only. Sides can be swapped visually (left/right) without affecting the audio routing (audio follows alliance color, not visual position).

## Known Issues / Shortcomings

- **Sync offset cannot be manually adjusted.** The offset is computed automatically from recording timestamps. Android timestamps have a 0.5-3.3s imprecision due to the finalization delay (creation_time = recording end on Android). There is no UI to fine-tune the offset. This was flagged as an open question in the prototype.

- **Drawing is in-memory only.** Strokes are not persisted to disk or associated with a timestamp. Navigating away loses all drawings. This is by design for quick telestration during review, not annotation storage.

- **Single drawing controller shared across both panes.** In dual video mode, both `VideoPane` widgets receive the same `DrawingController`. Drawing on one pane draws on both. This is intentional (telestration typically annotates the field, not a specific camera), but could be surprising.

- **Scrub throttling adapts to decoder speed, not user expectation.** The cancel-and-replace pattern means slow hardware will show fewer intermediate frames during scrubbing. The UI position updates immediately (responsive), but the video frames lag behind until the seek completes.

- **Position stream suppression during scrub.** While finger-scrubbing or dragging the scrub bar, the position stream listener is suppressed (`_isFingerScrubbing`, `_isScrubBarDragging` guards). This prevents flicker but means the displayed position during a scrub is the computed target, not the actual decoded frame position.

- **No playback speed control.** Playback is always at 1x speed. Slow-motion review would require `player.setRate()`.

- **`hasEnded` overlay is passed to VideoPane but not computed in VideoViewer.** The `VideoPane` widget accepts a `hasEnded` parameter for showing a "Video ended" overlay, but `VideoViewer` does not currently compute or pass this value (it defaults to `false`).

- **Drawing mode auto-exits on play.** When playback starts, `_isDrawingMode` is set to `false` in the playing stream listener. This means drawings are preserved but the drawing tools disappear. The user must pause and re-enter drawing mode to continue annotating.

## Technical Details

These patterns were validated in the video prototype (documented in `VIDEO_PROTOTYPE_LEARNINGS.md`) and are implemented in this module:

- **Intended position tracking, not `player.state.position`.** `SyncEngine._intendedEarlierPosition` is the single source of truth for the earlier player's position. `player.state.position` is updated asynchronously via streams and may reflect stale values after a `seek()`. All sync decisions (scrub offset calculation, countdown, synced seeking) use `_intendedEarlierPosition`. The position stream still feeds the UI for display during normal playback, but is suppressed during scrub operations.

- **Countdown driven by position stream, not wall clock.** `startPositionMonitoring` subscribes to `earlierPlayer.stream.position`. If the video buffers, the countdown pauses too (because no new position events arrive). A `DateTime.now()`-based timer would keep counting and trigger the later player too early.

- **`.whenComplete()` not `.then()` for seek completion.** In `ScrubController._dispatchSeek`, the seek future's completion is handled with `.whenComplete()`. media_kit's `seek()` can throw during rapid seeking. `.then()` only fires on success, which would leave `_seekInFlight = true` permanently and block all subsequent seeks. `.whenComplete()` fires on both success and error.

- **Quadratic bezier stroke smoothing.** Both `StrokePainter` and `_PassiveStrokePainter` render strokes using quadratic bezier curves through midpoints: for each consecutive triplet of points, a `quadraticBezierTo` call uses the middle point as the control point and the midpoint between the middle and next point as the end point. This produces smooth curves from noisy touch input without post-processing. Single-point strokes are rendered as filled circles.

- **Opacity via `Paint.color` alpha, not `Opacity` widget.** Drawing opacity is set directly on the `Paint` object's color alpha channel (`Colors.red.withValues(alpha: opacity)`). An `Opacity` widget would force Flutter to create an offscreen compositing layer, which is expensive for a full-screen overlay that repaints frequently during active drawing.

- **Non-linear scrub curve with configurable exponent.** The power curve `(normalized)^exponent` with exponent 2.5 means the first ~40% of horizontal travel covers only ~10% of the scrub range, giving fine control. The last 20% of travel covers ~60% of the range. The exponent and max range are configurable via `DataStore.settings` (not hardcoded in the scrub controller).

- **Position stream suppression during scrub.** The position stream listener in `VideoViewer` is guarded by `!_isScrubBarDragging && !_isFingerScrubbing`. Without this, the stream would overwrite the UI position set by scrub logic with the player's actual (lagging) decoded position, causing the scrubber and position display to flicker between the desired and actual positions.

- **Cancel-and-replace naturally adapts to decoder speed.** Unlike a fixed-rate timer (which must guess the right interval), the cancel-and-replace pattern dispatches the next seek the instant the previous one completes. On fast hardware, seeks fire rapidly. On slow hardware, intermediate positions are skipped but the final position is always reached. The UI stays responsive regardless because `setState` updates the displayed position immediately, independently of the actual seek.

- **Landscape lock and immersive mode.** `VideoViewer` locks to landscape orientation and enables `SystemUiMode.immersiveSticky` on init, restoring default orientation and `edgeToEdge` mode on dispose. `WakelockPlus` keeps the screen on during the entire viewer session.

- **Audio follows alliance, not visual position.** Mute state cycles through muted/red/blue. The `_applyMuteState` method uses `syncEngine.redPlayer`/`bluePlayer` (which resolve to the correct underlying player regardless of earlier/later assignment), so swapping the visual side order does not change which audio track is active.
