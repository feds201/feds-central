# Neon Database Dashboard — Flutter Web

A Flutter web app that connects to your **Neon PostgreSQL** database, displays data in an interactive DataTable, and auto-generates charts from your data.

## Features

- **Connect** — paste your Neon connection string to connect instantly
- **Browse tables** — sidebar lists all `public` schema tables
- **DataTable** — sortable columns, row search, pagination (25 rows/page), type badges
- **Auto-charts** — detects numeric & label columns, then renders:
  - Bar chart
  - Line chart
  - Distribution histogram
  - Pie chart (aggregated by label column)
  - Scatter plot (when 2+ numeric columns exist)
- **Summary stats** — sum, average, min, max, median for selected numeric column
- **Custom SQL** — run any SELECT query directly from the top bar

## Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.2
- A [Neon](https://neon.tech) project with at least one table

### Run it

```bash
# 1. Navigate to the project
cd flutter_neon_app

# 2. Get dependencies
flutter pub get

# 3. Run on web
flutter run -d chrome
```

### Build for production

```bash
flutter build web
# Output is in build/web/ — deploy anywhere (Vercel, Netlify, S3, etc.)
```

## How It Works

The app uses **Neon's serverless HTTP API** (`https://<host>/sql`) to execute SQL queries directly from the browser — no backend server required. Your connection string is parsed to extract the host, credentials, and database name, then Basic Auth headers are sent with each request.

### Security Note

Your connection string stays in the browser and is sent directly to Neon's API. For production use, consider:
- Using a backend proxy to hide credentials
- Creating a read-only Neon database role
- Using Neon's connection pooling

## Project Structure

```
lib/
├── main.dart                   # App entry point + theme
├── screens/
│   ├── home_screen.dart        # Router
│   ├── connection_screen.dart  # Connection string input
│   └── dashboard_screen.dart   # Main dashboard with sidebar
├── widgets/
│   ├── data_table_view.dart    # Sortable, searchable DataTable
│   └── chart_panel.dart        # Auto-generated charts (fl_chart)
└── services/
    └── neon_service.dart       # Neon HTTP API client
```

## Dependencies

| Package        | Purpose                         |
|----------------|---------------------------------|
| `http`         | HTTP requests to Neon API       |
| `fl_chart`     | Bar, line, pie, scatter charts  |
| `google_fonts` | Inter font for clean typography |
| `intl`         | Number formatting               |
