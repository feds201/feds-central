# Scout-Ops Dash

Scouting dashboard for **FRC Team 201 – The Feds**.  
Aggregates data from three sources and displays it per-team for any competition event.

## Data Sources

| Source       | What it provides                       | Auth                    |
|------------- |----------------------------------------|-------------------------|
| **Neon**     | Scouting table (one row per match)     | PostgreSQL conn string  |
| **TBA**      | OPR (Offensive Power Rating)           | `X-TBA-Auth-Key`        |
| **Statbotics** | EPA (Expected Points Added)          | None (public API)       |

## Prerequisites

- Flutter SDK ≥ 3.2 (web-enabled)
- A Neon PostgreSQL database with your scouting table
- A TBA API key from <https://www.thebluealliance.com/account>

## Getting Started

```bash
# Clone or copy this project
cd scout_ops_dash

# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome
```

### Field Image (optional)

Drop a field image (PNG or JPG) into `assets/` and update the
`AutoPathViewer` to load it as the background instead of the grid
placeholder. The path visualiser uses normalised 0-1 coordinates, so any
field image with the correct aspect ratio will work.

## Architecture

```
lib/
├── main.dart                 # Entry + routing
├── theme.dart                # Dark theme (Outfit / JetBrains Mono)
├── models/
│   └── auto_path_data.dart   # Parses bot_path_drawer strings
├── services/
│   ├── neon_service.dart     # Neon SQL-over-HTTP client
│   ├── tba_service.dart      # TBA REST client
│   ├── statbotics_service.dart
│   └── data_service.dart     # Central state (Provider)
├── screens/
│   ├── event_entry_screen.dart
│   ├── dashboard_screen.dart
│   └── team_detail_screen.dart
└── widgets/
    └── auto_path_viewer.dart # CustomPainter path renderer
```

## Neon Connection (Flutter Web)

Flutter web cannot open raw TCP sockets, so the standard `postgres`
Dart package won't work in the browser.  This project uses Neon's
**serverless SQL-over-HTTP** endpoint instead.

Provide a normal Postgres URI on the entry screen:

```
postgresql://user:password@ep-xxx-123.us-east-2.aws.neon.tech/mydb?sslmode=require
```

The app parses it and POSTs queries to `https://{host}/sql` with the
full connection string in the `Neon-Connection-String` header.

> **CORS:** Neon's serverless endpoint supports browser requests.  If
> you hit CORS issues, enable the "Pooler" → "Serverless" toggle in
> your Neon project settings.

## Auto Path Format

The encoded path column stores a compact string:

```
M0.083,0.573C0.098,0.559 0.241,0.397 0.390,0.317|0.00:0,1.57:450,3.14:1200
```

- **Before `|`** — SVG path commands (`M` = moveTo, `C` = cubic Bézier) in normalised 0-1 coordinates
- **After `|`** — comma-separated `rotation:timestamp` pairs (radians : milliseconds)

The viewer auto-detects which column contains path data by scanning
for values that match this pattern.

## Customisation

- **Schema:** The app dynamically reads whatever columns exist in your
  scouting table — no hardcoded schema required.
- **Theme:** Edit `lib/theme.dart` to change colours, fonts, and spacing.
- **Table columns:** The dashboard shows the first 6 scouting columns.
  Adjust the `visibleCols` limit in `dashboard_screen.dart` to show
  more or fewer.

## License

Internal tool for FRC Team 201.
