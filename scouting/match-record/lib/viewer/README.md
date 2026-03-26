# Viewer Module

Business logic for dual-video synchronized match playback. The three classes in this directory (`SyncEngine`, `ScrubController`, `DrawingController`) are pure logic with no Flutter widget dependencies, consumed by `VideoViewer` and its child widgets.

## Expected UX Behavior

This section defines every user-facing interaction in the video viewer. Each behavior includes a rationale (**Why**) so future developers understand the intent, not just the implementation.

### Screen Layout

The viewer is a forced-landscape full-screen page with three horizontal sections:

1. **Video area** (Expanded) — one or two video panes showing match recordings
2. **Scrubber bar** (fixed width) — vertical slider for coarse position seeking
3. **Control sidebar** (fixed width) — all buttons and controls

The video area, scrubber bar, and sidebar are siblings in a Row. The video area is the only section that responds to touch gestures (scrub/draw/zoom).

### Touch Gesture Layer

A single gesture layer covers the entire video area (spanning both panes in dual mode). Individual video panes have NO touch handling — all touch input is processed by this top-level layer.

**Why:** Per-pane gesture handling caused inconsistent scrub behavior (different pane widths in different view modes produced different scrub sensitivity). A single layer guarantees identical touch behavior regardless of view mode or which pane the finger is over.

The gesture layer routes touch input based on play state and finger count:

| State | 1 finger | 2 fingers |
|-------|----------|-----------|
| Playing | Scrub | Zoom |
| Paused | Draw | Zoom |

There are no other gesture combinations. There is no "drawing off while paused" state — drawing is always active when paused.

**Why:** This is the simplest possible gesture model. Play state determines whether one finger scrubs or draws. Two fingers always zoom. No toggles, no modes to remember, no conflicting gesture recognizers.

**Multi-touch disambiguation.** When the first finger touches down, the gesture layer immediately starts the appropriate 1-finger action (scrub or draw). If a second finger arrives, the 1-finger action is cancelled — scrub state is cleaned up and playback resumes (if it was playing), or the in-progress drawing stroke is discarded. The gesture becomes a zoom/pan handled by InteractiveViewer for its entire remaining lifetime: even if the user lifts back to one finger, scrub/draw does not resume. The gesture resets only when all fingers are lifted.

**Why immediate start + cancel:** Deferring the 1-finger action (e.g., with a timer) would add latency to every touch. The split-second of scrub or draw before the 2nd finger lands is within the scrub dead zone (3px) and acceptable for drawing (will be further mitigated by a drawing dead zone in a future update).

### Scrubbing

Scrubbing lets the user control the playback position by dragging horizontally.

**Finger down** does NOT pause playback — it enters scrub mode. The displayed frame is now controlled entirely by finger position. Finger still = frame still. Finger moves = frame changes. This is a fundamentally different concept from pausing (which is an explicit user action via the pause button). Scrub and pause must NEVER be conflated in code or in conversation — they are separate states with separate entry/exit conditions. This distinction is permanent and non-negotiable.

**Finger drag** applies a non-linear curve: `offset = sign * (|delta| / halfWidth)^exponent * maxRange`. The `halfWidth` is half the width of the entire gesture layer (the full video area), NOT an individual pane. Small movements near the touch origin produce fine-grained scrubbing; large movements cover up to the configured max range (default 2 minutes). A dead zone (default 3px) prevents accidental micro-scrubs.

**Why non-linear:** Linear scrubbing makes fine control impossible on a small screen — you'd need sub-pixel precision to scrub frame-by-frame. The power curve gives fine control near the touch point and coarse jumps at the edges.

**Why full-width reference:** Using the full gesture layer width (not individual pane width) means scrub sensitivity is identical in dual mode, single mode, or any future layout. Moving your finger X pixels always scrubs the same amount.

**Finger up** exits scrub mode. If the video was playing when the finger went down, playback continues from the current scrub position. If it was paused, it stays paused.

**Why continue playback:** Scrubbing is not pausing. The user is scanning through footage to find a moment. When they find it and lift their finger, they want to keep watching from that point.

### Zooming

Pinch-to-zoom (2 fingers) works in ALL states — playing or paused. Zoom affects the video pane the gesture started in.

Panning a zoomed view is only possible via 2-finger drag (which is naturally part of the pinch-to-zoom gesture). There is NO separate 1-finger pan mode. 1-finger gestures ALWAYS follow the gesture table (scrub while playing, draw while paused), even when zoomed in. This is non-negotiable — any zoom implementation that steals 1-finger input for panning is broken by design.

**Why always-available zoom:** During live match review, users need to zoom into a specific robot or field area without stopping playback. Requiring a pause first would break the review flow.

**Zoom resets on view mode change.** Switching between both/red-only/blue-only/full resets all zoom controllers to identity (no zoom).

**Why:** The zoom level that made sense for a half-screen pane makes no sense for a full-screen view. Carrying zoom state across layout changes would be confusing.

### Drawing

Drawing is automatically active whenever the video is paused. There is no separate "enable drawing" toggle — `canDraw = !isPlaying`.

The drawing color button in the sidebar cycles through: red -> blue -> red -> blue. It does not cycle through "off" — drawing cannot be disabled while paused.

**Pausing via the sidebar pause button** sets the initial drawing color to red (if not already set).

**Why auto-enable drawing on pause:** The only reason to pause match footage is to annotate or study a frame. Requiring a separate button press to enable drawing adds friction to the most common workflow. Drawing is always available, and if the user doesn't want to draw, they simply don't touch the screen (or they use two fingers to zoom instead).

**Playing disables drawing.** When playback resumes (play button or scrub-finger-up-while-was-playing), drawing input is disabled and existing strokes render at reduced opacity (0.3).

**Why reduced opacity, not hidden:** Strokes provide spatial context even during playback — "watch what happens in this area I circled." Full opacity would obscure the video; hidden would lose the context.

**Drawing coordinates are in screen space.** Touch input goes directly to the drawing controller with no coordinate transformation. Strokes are rendered on a canvas that sits above the video layer but below the chrome layer, at the same level in the widget tree. Strokes do not zoom, pan, or rotate with the video — they stay fixed on screen.

**Why screen-space, not video-space:** Video-space drawing requires inverting zoom, pan, and rotation transforms on input, then re-applying them on render, and recomputing when rotation changes. This produced persistent coordinate bugs at odd rotation angles. Screen-space eliminates all transform math. The trade-off (strokes don't track video content through zoom/rotate) is acceptable because drawings are ephemeral telestration, not permanent annotations.

**Per-pane drawing controllers.** Each video source (red, blue, full) has its own drawing controller. In dual mode, the touch point's horizontal position determines which controller receives the stroke (left half vs right half). When a stroke is drawn on one pane, a no-op is pushed to the other pane's undo stack so that undo/redo stays synchronized.

**Drawing is in-memory only.** Strokes are not persisted to disk. Navigating away loses all drawings.

### Chrome vs. Video Content

"Chrome" refers to all non-video UI overlaid on the video panes: alliance color bar (top), star icon (user's team), rotate button, edit button, and countdown overlay ("Starting in X...").

**Chrome and drawings NEVER zoom or rotate.** These elements are fixed on screen regardless of video zoom level or rotation state. They sit in layers above the video layout in the Stack.

**Only the video zooms and rotates.** The VideoPane inside InteractiveViewer/RotatedBox is the only thing affected by zoom and rotation.

**Why:** Chrome is UI — it must always be readable and tappable in the same location. If the rotate button rotated with the video, the user would have to hunt for it at different orientations. If buttons zoomed with the video, they'd become huge and cover the content.

### Auto-Rotation

Videos are auto-rotated based on view mode so they fill the available space optimally. The user can manually override with the rotate button.

**Dual mode (both panes visible):** Each pane is tall and narrow (portrait-shaped). Videos are rotated so their longest dimension is vertical:
- Portrait video (taller than wide): no rotation needed, displayed upright
- Landscape video (wider than tall): rotated 90° so the wide side becomes vertical

"Right side up" in dual mode: portrait videos have their top pointing up. Landscape videos have their top pointing left.

**Single mode (red-only, blue-only, full):** The screen is landscape. Videos are rotated so their longest dimension is horizontal:
- Landscape video (wider than tall): no rotation needed, displayed in natural orientation
- Portrait video (taller than wide): rotated 90° so the tall side becomes horizontal

"Right side up" in single mode: landscape videos have their top pointing up. Portrait videos have their top pointing left.

**Why "top points left" for rotated videos:** The user can physically rotate the tablet so that "left" becomes "up" and the video appears right-side-up. Since orientation is locked to landscape, the device won't auto-rotate and disrupt the layout.

**Manual rotation overrides auto-rotation.** Once the user manually rotates a pane, auto-rotation no longer updates that pane (even on view mode change). This prevents the system from undoing the user's explicit choice.

**Auto-rotation recomputes on view mode change** (for panes that haven't been manually rotated). A video that was rotated for dual mode gets re-rotated for single mode, because the optimal orientation changes with the pane shape.

### Video Scaling

Scaling depends on the relationship between the video's **post-rotation** aspect ratio and the pane shape, not just the view mode. The goal is to minimize black bars without introducing massive cropping.

**The rule:** If the video's post-rotation aspect ratio is "tall" relative to the pane (i.e., the video is taller than the pane's aspect ratio), scale to fill width (fitWidth) — this eliminates small side black bars and only crops a bit of top/bottom. If the video's post-rotation aspect ratio is "wide" relative to the pane, use contain — because filling width would crop a huge amount of the sides.

**In practice for dual mode (tall narrow panes):** Portrait videos (already tall) fit naturally with small side bars → fitWidth removes them. Landscape videos (wide) would need massive cropping to fill width → contain.

**In practice for single mode (wide landscape pane):** Landscape videos (already wide) fit naturally with small top/bottom bars → contain is fine. Portrait videos (tall) would have huge side bars → fitWidth fills the width.

**Post-rotation matters:** If the user manually rotates a portrait video 90°, its effective aspect ratio becomes landscape. The scaling must recompute based on the new effective aspect ratio, not the original video dimensions.

**Why this rule instead of "dual=fitWidth, single=contain":** Manual rotation changes the effective aspect ratio. A static per-view-mode rule produces wrong scaling after rotation (e.g., super-zoomed or massive black bars).

### View Modes

Available modes depend on which recordings exist. Cycling order: both -> full (if exists) -> red-only -> blue-only -> both.

- **Both:** Red on left, blue on right (or swapped). Each pane takes 50% of the video area width.
- **Red/Blue only:** Single video fills the entire video area.
- **Full only:** Full-field video fills the entire video area.

**Zoom resets** when switching view modes (covered above).

**Auto-rotation recomputes** when switching view modes (covered above).

### Audio

Mute state cycles through: muted -> full (if exists) -> red audio -> blue audio -> muted. Audio follows the logical alliance color, not the visual position — swapping sides does not swap audio.

### Side Swapping

In dual mode, the "Swap" button swaps the visual left/right positions of red and blue panes. This is purely visual — audio routing, sync logic, and all internal state remain tied to the logical red/blue identity. The swap preference is persisted in settings.

### Sidebar Play/Pause Button

The play/pause button has a subtle lighter gray background to make it visually distinct from the other sidebar buttons.

**Why:** Play/pause is the most frequently used control. A subtle highlight makes it faster to locate, especially in a column of same-colored icons.

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

`ScrubController` handles non-linear scrub math and seek throttling.

**Non-linear curve.** `computeScrubOffsetMs` is a static pure function that converts a horizontal pixel delta (from the touch origin) into a millisecond offset. Uses the power curve described in the Expected UX Behavior section. The exponent and max range are configurable via `DataStore.settings`.

**Cancel-and-replace throttling.** Only one `seek()` call is in-flight at a time. `enqueueSeek(position, seekFn)` stores the desired position and calls `_dispatchSeek`. If a seek is already in-flight, the new position simply replaces `_pendingPosition`. When the in-flight seek completes (via `.whenComplete()`, not `.then()`, so it fires even if the seek throws), if a newer pending position exists, it dispatches immediately. This naturally adapts to decoder speed.

**Lifecycle.** Call `reset()` when a scrub gesture ends to clear the in-flight/pending state.

### DrawingController

`DrawingController` manages freehand drawing strokes with undo/redo, extending `ChangeNotifier` so widgets rebuild on changes.

**Strokes.** Each stroke is a `List<Offset>` with a `DrawingColor`. `onPointerDown` starts a new stroke, `onPointerMove` appends points, `onPointerUp` finalizes it into `_strokes` and clears the redo stack (any new stroke after an undo invalidates the redo history). `strokes` and `currentStroke` are exposed as unmodifiable lists.

**Undo/redo.** `undo()` moves the last completed stroke to `_redoStack`. `redo()` moves it back. `clear()` wipes everything.

**Cancel/cleanup.** `cancelStroke()` discards the current in-progress stroke without finalizing it (used when multi-touch is detected). `popLastStroke()` removes the last completed stroke without pushing to the redo stack (used to clean up no-ops that were pushed before the gesture was recognized as multi-touch).

**Opacity.** `setOpacity(value)` controls drawing visibility (1.0 when paused, 0.3 when playing). Applied via the `Paint.color` alpha channel, not via a Flutter `Opacity` widget (which would create an offscreen compositing layer).

## Known Issues / Shortcomings

- **Sync offset cannot be manually adjusted.** The offset is computed automatically from recording timestamps. There is no UI to fine-tune the offset.

- **No playback speed control.** Playback is always at 1x speed. Slow-motion review would require `player.setRate()`.

- **Chrome overlay positioning on view mode switch.** Chrome reads pane positions via GlobalKey.findRenderObject. On view mode switch, the old pane's RenderBox may be gone before the new one is laid out, causing a brief frame where chrome can't position itself. Currently mitigated with addPostFrameCallback, which triggers an extra rebuild.

## Technical Details

- **Intended position tracking, not `player.state.position`.** `SyncEngine._intendedEarlierPosition` is the single source of truth for the earlier player's position. `player.state.position` is updated asynchronously via streams and may reflect stale values after a `seek()`. All sync decisions (scrub offset calculation, countdown, synced seeking) use `_intendedEarlierPosition`. The position stream still feeds the UI for display during normal playback, but is suppressed during scrub operations.

- **Countdown driven by position stream, not wall clock.** `startPositionMonitoring` subscribes to `earlierPlayer.stream.position`. If the video buffers, the countdown pauses too (because no new position events arrive). A `DateTime.now()`-based timer would keep counting and trigger the later player too early.

- **`.whenComplete()` not `.then()` for seek completion.** In `ScrubController._dispatchSeek`, the seek future's completion is handled with `.whenComplete()`. media_kit's `seek()` can throw during rapid seeking. `.then()` only fires on success, which would leave `_seekInFlight = true` permanently and block all subsequent seeks. `.whenComplete()` fires on both success and error.

- **Quadratic bezier stroke smoothing.** Strokes are rendered using quadratic bezier curves through midpoints for smooth curves from noisy touch input. Single-point strokes are rendered as filled circles.

- **Opacity via `Paint.color` alpha, not `Opacity` widget.** An `Opacity` widget would force Flutter to create an offscreen compositing layer, which is expensive for a full-screen overlay that repaints frequently during active drawing.

- **Position stream suppression during scrub.** The position stream listener in `VideoViewer` is guarded by `!_isScrubBarDragging && !_isFingerScrubbing`. Without this, the stream would overwrite the UI position set by scrub logic with the player's actual (lagging) decoded position, causing flicker.

- **Cancel-and-replace naturally adapts to decoder speed.** On fast hardware, seeks fire rapidly. On slow hardware, intermediate positions are skipped but the final position is always reached. The UI stays responsive because `setState` updates the displayed position immediately, independently of the actual seek.

- **Landscape lock and immersive mode.** `VideoViewer` locks to landscape orientation and enables `SystemUiMode.immersiveSticky` on init, restoring default orientation and `edgeToEdge` mode on dispose. `WakelockPlus` keeps the screen on during the entire viewer session.
