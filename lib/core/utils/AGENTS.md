# utils/ — conventions

Shared formatting, genre maps, sort helpers, and export/import serialization.

## Key files

- `lib/core/utils/export_file_name.dart`
- `lib/core/utils/export_import_serializer.dart`
- `lib/core/utils/formatters.dart`
- `lib/core/utils/genres.dart`
- `lib/core/utils/notification_center_filter.dart`
- `lib/core/utils/release_groups.dart`
- `lib/core/utils/release_sort.dart`
- `lib/core/utils/release_status.dart`
- `lib/core/utils/saga_sort.dart`
- `lib/core/utils/watch_tail.dart`

## Gotchas

- `export_import_serializer.dart` implements the ZIP-of-CSV format; its authoritative
  spec is `DOCS/export-format.md` and must stay in sync (`.ai/rules/export-format.md`).
- `genres.dart` hardcodes TMDB genre id→name maps; `release_sort.dart` / `saga_sort.dart`
  are pure, stateless sort helpers.
- `release_status.dart` (`isReleased`: out on today's local calendar day; empty date = not
  out) is the single release rule of "To watch tonight", the saga "Upcoming" banner and the
  list "hide non-released" filter.
- `notification_center_filter.dart` (`filterReleases`: visible releases and the hidden ones
  with their reason) and `release_groups.dart` (`groupReleases`: released / this week /
  this month / later / undated, and by calendar month) feed "Upcoming" on Home and
  `UpcomingPage`. Both are pure and take the clock as a parameter.
- `watch_tail.dart` derives the viewing `WatchTail` (the furthest-along seen episode by
  position, `seriesStartTail()` when there is no episode history) and selects the episode to
  anchor to: `findFirstAiredUnseenAfterTail` (aired and unseen) with `findNextEpisodeAfterTail`
  as the pending/undated fallback. Releases anchoring in
  `NotificationRefreshService.refreshNotificationDate` (via `NextEpisodeScanner`) depends on it; keep it pure and unit-tested.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
