# library/ — feature conventions

Library tab: Lists and History behind a segment, with one media type filter for both.
`presentation` only; data comes from `SearchProvider` / `MediaRepository` (`search`).

## Key files

- `lib/features/library/presentation/pages/library_page.dart` — title, segment
  (`SearchProvider.librarySection`), type chips with counters, then `ListsOverview` and
  `SeenHistoryPage` kept alive in an `IndexedStack`.
- `lib/features/library/presentation/widgets/lists_overview.dart` — one row per list (mini
  posters, films / series split, count), "New list" and "Import".
- `lib/features/library/presentation/widgets/list_dialogs.dart` — create a list, import by
  QR code or link (`showImportListMenu`, `importListFromQr`, `importListFromLink`,
  `confirmListImport`). Shared with `SavedMediaPage`: never duplicate these dialogs.

## Gotchas

- The type filter is a `MediaType?` (`null` = all) owned by `LibraryPage`. It restricts the
  counters, the mini posters, the opened list (`SavedMediaPage.typeFilter`) and the history
  (`SeenHistoryPage.typeFilter` with `externalTypeFilter`). Books are not a `MediaType`:
  the "Books" chip arrives with the books epic (`LibraryPage.filterTypes`).
- Chip counters count list entries (`SearchProvider.countListEntries`), as in the design.
- The stored name of the default list is `watchlist` (`kWatchlistName`); always display it
  through `listDisplayName`. It is listed first.
- `SearchProvider` caches only the first previews of a list; under a type filter the
  overview reads further with `loadListPreviewsOfType`.
- A list opens as a pushed `SavedMediaPage` (the pre-redesign page) until the list page of
  the redesign replaces it. The history is embedded as is until its own redesign.
- The camera is unavailable in tests: pass `scannerBuilder` to `LibraryPage`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
