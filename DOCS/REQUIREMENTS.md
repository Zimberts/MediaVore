# MediaVore Requirements

This document is the concise index of functional and system requirements for MediaVore. Each linked page contains a short, testable list of requirements; longer topics are split into focused files to limit context.

## Core Features

- [**General Overview**](requirements/general.md): Purpose, target users, and core flows (browse → details → save/seen).
- [**Theming & Design System**](requirements/theming.md): Color tokens, multi-theme support, and accessibility contrast targets.
- [**Home Row & Navigation**](requirements/navigation.md): Persistent navigation, deep-link targets, and global UI rules.
- [**Discovery & Search**](requirements/discovery.md): Browsing grid, infinite scroll, search with debounce, and filtering semantics.
- [**Discovery & Search**](requirements/discovery.md): Browsing grid, infinite scroll, search with debounce, and filtering semantics.
  - UI: Discovery grid overlays (rating, notify, like, watchlist) must adapt to tile size and device width to avoid overlap. When space is constrained these overlays should be hidden or compacted. Tests must cover visibility thresholds.
- [**Media Details & Actors**](requirements/media_details.md): Detail views, metadata, actions (save, mark seen), and actor pages.
- [**Saved Media (My Lists)**](requirements/saved_media.md): List creation, ordering, sharing, and offline availability.
- [**Seen History & Logging**](requirements/seen_history.md): Local seen tracking, timestamps, and purge policies.
- [**Media Statistics**](requirements/statistics.md): Derived metrics, charting requirements, and update frequency.
- [**Notification Center**](requirements/notifications.md): User-visible notifications, scheduling, and quick-actions.

## System & Platform

- [**Settings**](requirements/settings.md): App preferences, display modes, and export/import knobs.
- [**Achievements**](requirements/achievements.md): Gamification rules, unlocking, and persistence.
- [**Storage & Data**](requirements/storage.md): Database (Isar) schemas, migrations, export/import, retention, and consistency guarantees.
- [**Caching & Offline**](requirements/caching.md): Cache strategies, prefetching, eviction, size controls, and offline UX.
- [**Deep Linking**](requirements/deeplinking.md): Intent and URL handling, mapping to app screens, and test cases. (See also `DEEP_LINKING.md` for design notes.)
- [**Platform Integrations**](requirements/platform_integrations.md): App links, home widget, platform channels, permissions, and platform-specific behaviors.
  -- [**Privacy & Data Management**](requirements/privacy.md): Telemetry opt-in, data export/delete, and retention/consent requirements.
  -- [**Testing**](requirements/testing.md): Unit/widget/integration test coverage goals and test data guidelines (CI postponed).

If a linked document grows large, it is intentionally split into smaller pages (for example: storage migrations vs. storage export). Each file keeps requirement statements concise and actionable.
