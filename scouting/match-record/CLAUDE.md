# Match Record — Claude Code Guide

## For New AI Sessions

- Start by reading this CLAUDE.md
- Then read PROGRESS.md to know what's done and what's remaining
- Before touching any module, read its README.md first (they have How to Use / Known Issues / Technical Details sections)
- Use SPECS.md for product requirements, SYSTEM_DESIGN_SUMMARY.md for architecture overview, SYSTEM_DESIGN.md for full detailed specs
- Use BUILDERS_DIARY.md for development history and trade-offs (it's long — use a subagent to read it)
- The user will likely just say "do X" — use these docs to get context rather than asking questions the docs already answer

## What This Project Is

Offline-first Android tablet app for FRC Team 201 (The FEDS) to ingest, organize, and review match footage during competitions. Students record each match on personal phones (one per alliance side), transfer via USB-C flash drives, and the tablet provides a synchronized dual-video viewer for match strategy analysis between matches.

**Platform:** Android tablet, sideloaded (not Play Store). Target SDK: API 35.

**Stack:** Flutter, media_kit for video playback, dio for TBA API, JSON file persistence.

## Key Documents

| File | Purpose |
|------|---------|
| `SPECS.md` | Product requirements (P0/P1/P2 features) |
| `SYSTEM_DESIGN_SUMMARY.md` | High-level architecture overview (~300 lines, context-friendly) |
| `SYSTEM_DESIGN.md` | Full technical design — data model details, API specs, algorithms, decision log |
| `PROGRESS.md` | What's been built and what still needs to be done |
| `BUILDERS_DIARY.md` | Development journal — trade-offs, bugs found, adjustments made |
| `ISSUES.md` | User-reported bugs and improvements, organized by screen area |

Prototype learning docs (VIDEO_PROTOTYPE_LEARNINGS.md, DRAWING_PROTOTYPE_LEARNINGS.md) were archived after all patterns were applied to the codebase.

## Module READMEs

Each major module has a README.md with 3 sections: **How to Use**, **Known Issues/Shortcomings**, and **Technical Details**. Check these before diving into the code — they'll save significant time:

- `lib/data/README.md` — Data models, DataStore, JSON persistence
- `lib/import/README.md` — Import pipeline, drive access, match/alliance suggestion, integrity checker
- `lib/viewer/README.md` — Sync engine, scrub controller, drawing controller
- `lib/tba/README.md` — TBA API client
- `lib/screens/README.md` — UI layer (screens, tabs, sync UI, widgets)

## Working in This Codebase

### Context Management (Critical)

Context pollution is the #1 threat to performance on this codebase. The app has ~12,500 lines across 80+ files. Rules:

- **Use subagents for research, exploration, code review, and anything producing large output.** They run in a separate context and return only a summary.
- **Never read an entire module just to understand how to use it** — read the README first, then read only the specific files you need.
- **Use subagents for device verification** — screenshots, UI hierarchy dumps, and adb interaction produce large output. Always delegate to a subagent.
- **Shrink screenshots before reading** — `convert input.png -resize 50% -quality 75 output.jpg`. Raw device screenshots are 2-4MB.
- **When thinking hard about a specific feature or problem**, dispatch a subagent with the relevant context rather than pulling it all into your main context.

### Fixing Issues from ISSUES.md

`ISSUES.md` contains user-reported bugs and improvements. When fixing issues, follow this process:

1. **Reproduce** — Use MCP tools on the REAL connected device to confirm the bug. Take a screenshot, get the view hierarchy, interact with the app. Do this via a subagent to avoid context pollution.
2. **Explore** — Read the relevant SPEC/SYSTEM_DESIGN sections, the module README, and the specific source files involved. Understand the intended behavior vs actual behavior.
3. **Plan** — Decide on the fix. For non-trivial changes, outline what files change and why.
4. **Update tests** — Write or update unit tests to cover the fix. Tests should fail before the fix.
5. **Implement** — Make the code changes.
6. **Verify tests pass** — Run `flutter test` and confirm all tests pass.
7. **Verify on device** — Build, install, and reproduce the original issue on the real device via MCP tools (in a subagent). Confirm it's fixed. Take before/after screenshots if helpful.

Issues are labeled by screen area (m = main screen, v = video player, s = sync/import). Some are questions — answer them before implementing.

### Builder's Diary

`BUILDERS_DIARY.md` documents the development journey — trade-offs made, bugs found, adjustments to the plan. Update it when making significant changes. It's long, so use a subagent to read through it if needed.

### Test Flags

`lib/util/test_flags.dart` contains flags for development:
- `useSampleVideos` — uses sample videos from device filesystem instead of USB drives (see `TestDriveAccess` for adb push instructions)
- `forceEventId` — auto-loads 2026mimid TBA data on first launch
- `forceSampleMatchAssignment` — assigns sample videos to Q1

These make the app testable on devices without USB drives.

### Testing

266 tests across 12 test files. Run with `flutter test`. All business logic has unit tests. Widget rendering is tested manually on device.

### Device Testing

The app targets Android tablets but is tested on a Pixel 9 Pro (API 36). To test:
1. `flutter build apk --debug`
2. `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
3. `adb shell am start -n com.feds201.match_record/.MainActivity`

Use subagents for all device interaction to avoid context pollution.
