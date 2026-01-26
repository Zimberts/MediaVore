# Implemented Features

This document lists features and project artifacts that are currently implemented or present in the repository. Keep this file up to date as work completes.

## Project and platform scaffold

- Cross-platform Flutter project with folders for `android`, `ios`, `macos`, `linux`, `windows`, and `web`.
- `lib/main.dart` application entry point and platform-specific build files present.

## Tooling and configuration

- Code generation and build tooling are used (see `pubspec.yaml` and `build/` outputs).
- Build artifacts and generated files are present in the `build/` directory.

## Documentation & repo hygiene (recently added)

- `README.md` restructured with clear sections and links to per-topic docs.
- `CONTRIBUTING.md` added with branch, commit, and PR guidance.
- `DOCS/PLANNED_FEATURES.md` created to list planned work and roadmap checkboxes.
- `DOCS/DEEP_LINKING.md` created to hold platform-specific deep linking configuration.

## Notes for maintainers

- When a planned feature is completed, move it from `DOCS/PLANNED_FEATURES.md` to this file with a short note (date, commit/PR reference or file path).
- Keep implemented items focused and verifiable (link to files or tests when possible).

## User-visible implemented features (scanned)

- Search & discovery: discover content by name and browse results in the `SearchPage`.
- Saved lists / My Lists: create and manage named lists, reordering and multiple display modes (`SavedMediaPage`).
- Import/Export lists: import lists via share links or import flow, and export seen history as JSON.
- Seen history: record items you watched/read in `SeenHistoryPage`, with filters and export/import support.
- Achievements: gamified achievements with unlock detection, notifications, and an achievements page.
- Sharing & QR codes: generate QR codes for lists and share via platform share sheet.
- Barcode scanning: scan barcodes to add books or items (scanner UI integrated in lists).
- Deep links / share links: import lists from share links and handle app links to open content directly.
- Settings & preferences: theme, display mode, and other preferences saved in-app (`SettingsPage`).

## Developer notes

- Local persistence and DB: `isar` is used for local models (achievements, seen items, lists).
- DI & codegen: `injectable` / `build_runner` are configured for dependency injection (internal tooling).

> Note: This list focuses on user-facing features. When you want to record the exact commit/PR that implemented an item, add a short reference next to the entry.
