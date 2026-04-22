# bot_path_drawer

A Flutter library for drawing and playing back robot paths on a field image. Built for FRC scouting apps.

Scouts trace a path on a field image with their finger or mouse, and the library outputs a compact string (~100 characters) you can store in a database. A second widget plays that string back as an animation.

See [Getting Started](#getting-started) to add it to your app, or [Details](#details) for the full API reference.

## Getting Started

A complete working app lives in [`example/lib/main.dart`](example/lib/main.dart). Each step below points to the relevant part of that file.

### 1. Add the dependency

```yaml
# pubspec.yaml
dependencies:
  bot_path_drawer:
    path: ../bot_path_drawer  # adjust the relative path as needed
```

### 2. Create a config

You need a `BotPathConfig` with at least a background image (your field image). Everything else has sensible FRC defaults. The `example/assets/` folder has a 2026 field image you can use.

```dart
final config = BotPathConfig(
  backgroundImage: AssetImage('assets/field.png'),
);
```

See [`_config` in the example](example/lib/main.dart) (line 99) for a version with custom colors.

### 3. Let the user draw a path

Drop a `BotPathDrawer` into your UI. It gives you a serialized path string via `onSave`:

```dart
BotPathDrawer(
  config: config,
  onSave: (String? pathData) {
    // pathData is the compact string, or null if empty.
    // Store it, send it to your server, etc.
  },
)
```

The example opens it in a dialog -- see [`_openDrawer()`](example/lib/main.dart) (line 129). That function also shows how to lock orientation to landscape while drawing.

### 4. Play back saved paths

Pass one or more saved paths to a `BotPathViewer`. The single-path API still works:

```dart
BotPathViewer(
  config: config,
  pathData: savedPathString,
)
```

To display multiple paths simultaneously, each with its own color:

```dart
BotPathViewer(
  config: config,
  paths: [
    BotViewerPath(pathData: path1, color: Colors.red),
    BotViewerPath(pathData: path2, color: Colors.blue),
  ],
)
```

Each path's `color` is used for the path line, robot fill (at 30% opacity), intake edge, and start/end dot outlines. The dot fills stay green/red from `BotPathConfig.startColor`/`endColor`.

### 5. Team/path strategy viewer

For match strategy, use `BotPathViewerWithSelector` to let users pick which paths to display from multiple teams:

```dart
BotPathViewerWithSelector(
  config: config,
  teams: {
    '201': TeamPaths(paths: {
      'Left Start': serializedPath1,
      'Center Start': serializedPath2,
    }),
    '254': TeamPaths(
      paths: {'Rush': serializedPath3},
      color: Colors.purple,  // optional override
    ),
  },
)
```

This shows a collapsible sidebar with expandable team sections and checkboxes per path. The first path of each team is selected by default.

**Color assignment:** Teams are auto-assigned colors from a 6-color palette (red, orange, yellow, blue, green, cyan) unless overridden via `TeamPaths.color`. The palette cycles if there are more than 6 teams. Selected paths within a team vary by saturation from 100% down to 30%.

**Alliance mode:** When every team has an `alliance` set, the viewer enters alliance mode. Red alliance teams get warm colors (red, orange, yellow) and blue alliance teams get cool colors (blue, green, cyan). Blue alliance paths are horizontally reflected so all paths appear from their respective driver station perspective. If only some teams have `alliance` set, the field is ignored with a debug warning.

**Crop fraction in alliance mode:** When alliance mode is active, `cropFraction` is forced to `1.0` (full field) regardless of the config value, since both sides of the field need to be visible.

**Mirror toggle:** When a path is selected, a mirror button appears next to it in the sidebar. Toggling it vertically mirrors that individual path. This is independent of the alliance horizontal reflection.

**Add path callback:** Pass `onAddPath` to show an add button on each team header. When tapped, it calls `onAddPath` with the team label.

### Run the example

```bash
cd example
flutter run                              # Android/iOS
flutter run -d web-server --web-port=8080  # Web
```

---

## Details

### BotPathConfig

Shared configuration for both widgets. Only `backgroundImage` is required.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `backgroundImage` | *required* | The field image (`ImageProvider`). The larger pixel dimension is treated as width. |
| `cropFraction` | `0.70` | Show only the left N% of the image (e.g. the autonomous zone). Range: (0, 1]. Forced to 1.0 in alliance mode. |
| `robotSizeFraction` | `~0.056` | Robot square size as fraction of canvas width. Default fits a 27.5" FRC robot on a standard field at 70% crop. |
| `defaultPlaybackSpeed` | `4.0` | Initial speed multiplier. |
| `maxPlaybackSpeed` | `10.0` | Maximum speed multiplier. |
| `playbackDurationMs` | `20000` | Base playback duration at 1x speed (ms). Defaults to 20s (FRC auto period). Set to `null` to use the path's actual recorded duration instead. |
| `pathColor` | yellow | Path line, intake edge, dial indicator, highlight. Used by `BotPathDrawer` always; used by `BotPathViewer` only with the legacy `pathData` API (overridden by `BotViewerPath.color` when using `paths`). |
| `robotColor` | semi-transparent blue | Robot body fill. Same scoping as `pathColor` -- overridden per-path when using `paths`. |
| `startColor` / `endColor` | green / red | Endpoint indicator circles. |
| `highlightSizeMultiplier` | `5.0` | Touch highlight circle radius relative to robot size. |
| `simplificationError` | `50` | Curve fitting error tolerance. Lower = tighter fit (more curves). Higher = simpler (fewer curves). |
| `pointFilterDistance` | `2.0` | Minimum pixel distance between recorded points (jitter filter). |
| `brightness` | `null` (system) | Override brightness for UI elements. |

`BotPathConfig` has a `copyWith()` method and constructor assertions on all numeric params.

### BotPathDrawer

The drawing widget. Props: `config` and `onSave`.

**Controls (all platforms):**
- Single row: [info] [Play/Stop] [-] speed [+] [Clear] [Save]
- Speed steps through 0.5x, 1x, 2x, 4x, 5x, 10x
- Info button shows a help toast on the canvas (auto-dismisses after 6s)

**Touch devices (Android/iOS):**
- Draw with your finger
- Rotation dial overlaid on the canvas (bottom-right, 80% opacity) to set robot heading
- Touch highlight circle around the robot for visibility

**Desktop/web:**
- Click and drag to draw
- Hold WASD before clicking to set initial direction
- Q/E to rotate the robot (11.25 degrees per press)
- Scroll wheel for fine rotation

**Other behavior:**
- Tap near the end of an existing path (within 10% of canvas width) to continue it
- Press Clear to start over
- The `onSave` callback receives the serialized path string, or `null` if the canvas is empty

### BotPathViewer

The playback widget. Props: `config`, and either `pathData` (single path) or `paths` (multiple `BotViewerPath` entries).

- Renders one or many paths simultaneously, each with its own color
- Play/Stop toggle and discrete speed steps, overlaid on the canvas
- All paths animate in sync; the longest path determines the base duration
- Shows each robot at its end position when not playing
- Re-parses automatically when `pathData` or `paths` changes. No re-parse needed on resize.

### BotViewerPath

A path entry for multi-path viewing.

| Field | Type | Description |
|-------|------|-------------|
| `pathData` | `String` (required) | Serialized path string from `BotPathDrawer`. |
| `color` | `Color` (required) | Used for the path line, robot fill (30% opacity), intake edge, and start/end dot outlines. |
| `alliance` | `Alliance?` | When set, the path is horizontally reflected for `Alliance.blue`. |
| `mirrored` | `bool` | Vertically mirrors the path. Defaults to `false`. |

### BotPathViewerWithSelector

A wrapper around `BotPathViewer` with a collapsible sidebar for team/path selection.

| Prop | Type | Description |
|------|------|-------------|
| `config` | `BotPathConfig` (required) | Configuration for the underlying viewer. |
| `teams` | `Map<String, TeamPaths>` (required) | Teams and their paths. Keys are team labels. |
| `onAddPath` | `void Function(String)?` | If provided, shows an add button on each team header. Called with the team label when tapped. |

**Sidebar behavior:**
- Expandable team sections with checkboxes per path
- Colored dots next to teams (base color) and paths (saturation variant)
- First path of each team is selected by default
- All teams expanded by default
- On wide screens (>=600px), sidebar is inline; on narrow screens it floats as an overlay with a scrim
- Mirror toggle button appears next to each selected path

### Alliance

```dart
enum Alliance { red, blue }
```

Used on `TeamPaths.alliance` and `BotViewerPath.alliance`. When all teams in a `BotPathViewerWithSelector` have an alliance set, alliance mode activates: teams are grouped under "RED ALLIANCE" / "BLUE ALLIANCE" headers, warm/cool color palettes are used, blue paths are horizontally reflected, and crop fraction is forced to 1.0.

### TeamPaths

A team's paths for `BotPathViewerWithSelector`.

| Field | Type | Description |
|-------|------|-------------|
| `paths` | `Map<String, String>` (required) | Map of path name to serialized path string. |
| `color` | `Color?` | Base color override. If null, auto-assigned from the palette. |
| `alliance` | `Alliance?` | Which alliance this team belongs to. Set on all teams or none. |

### BotPathData

The serialization model (also exported if you need to inspect or manipulate paths).

- Stores curves in normalized 0-1 coordinates
- `serialize()` -- returns the compact string
- `BotPathData.tryParse(String)` -- parses a string back, returns `null` if invalid
- `scaledCurves(Size)` / `scaledEndpoints(Size)` / `toFlutterPath(Size)` -- scale to pixel coords for rendering (accept optional `cropFraction` parameter, defaults to 1.0)
- `BotPathData.fromPixelCurves(...)` -- normalizes pixel-coordinate curves from a recording session

**Format versions:** v1 (legacy) normalized coordinates relative to the cropped canvas size, making paths crop-dependent. v2 (current) normalizes relative to the full uncropped image, so paths display correctly at any crop fraction. New paths are always written as v2. Both versions are parsed transparently.

### Serialization format

```
v2:M0.083,0.573C0.098,0.559 0.241,0.397 0.390,0.317|0.00:0,1.57:450,3.14:1200
```

- `v2:` prefix indicates format version (absent for legacy v1 paths).
- Before `|`: SVG path commands (`M` = moveTo, `C` = cubic Bezier). Normalized 0-1 coordinates, 3 decimal places.
- After `|`: comma-separated `rotation:timestamp` pairs. Rotation in radians (2 decimals), timestamp in ms (integer, 0 = start). One pair per waypoint.
- Typical size: 80-150 characters for a simple auto path.

### Dependencies

- [`fit_curve`](https://pub.dev/packages/fit_curve) (^1.0.4) -- Schneider curve fitting algorithm. Stable textbook algorithm, doesn't need updates.
