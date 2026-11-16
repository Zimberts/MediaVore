# library/ — feature conventions

Library tab: Lists and History behind a segment, with one media type filter for both.
`presentation` only; data comes from `SearchProvider` / `MediaRepository` (`search`).

## Key files

- `lib/features/library/presentation/pages/library_page.dart` — title, segment
  (`SearchProvider.librarySection`), type chips with counters, then `ListsOverview` and
  `SeenHistoryPage` kept alive in an `IndexedStack`.
- `lib/features/library/presentation/pages/list_page.dart` — page of a single list (sort,
  grid/list display mode, selection, sharing, deletion).
- `lib/features/library/presentation/widgets/lists_overview.dart` — one row per list (mini
  posters, films / series split, count), "New list" and "Import".
- `lib/features/library/presentation/widgets/list_dialogs.dart` — create a list, import by
  QR code or link (`showImportListMenu`, `importListFromQr`, `importListFromLink`,
  `confirmListImport`). Shared across library widgets: never duplicate these dialogs.
- `lib/features/library/presentation/widgets/list_sort_sheet.dart` — sort options sheet
  (manual, release date, shuffle, reverse order).
- `lib/features/library/presentation/widgets/list_display_mode_sheet.dart` — display options sheet
  (grid 2, 3, 4 columns, detailed list).
- `lib/features/library/presentation/widgets/list_share_sheet.dart` — QR and link share sheet.

## Gotchas

- The type filter is a `MediaType?` (`null` = all) owned by `LibraryPage`. It restricts the
  counters, the mini posters, the opened list (`ListPage.typeFilter`) and the history
  (`SeenHistoryPage.typeFilter` with `externalTypeFilter`). Books are not a `MediaType`:
  the "Books" chip arrives with the books epic (`LibraryPage.filterTypes`).
- Chip counters count list entries (`SearchProvider.countListEntries`), as in the design.
- The stored name of the default list is `watchlist` (`kWatchlistName`); always display it
  through `listDisplayName`. It is listed first.
- `SearchProvider` caches only the first previews of a list; under a type filter the
  overview reads further with `loadListPreviewsOfType`.
- A list opens as a pushed `ListPage` (design v1.5). The history is embedded as is until its own redesign.
- The camera is unavailable in tests: pass `scannerBuilder` to `LibraryPage`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
