# media_details/ — feature conventions

Media detail pages, lists, seen/like/notify state, and quick-add. Has `data` +
`presentation` layers (no `domain/`; local entities live in `lib/core/domain/entities/`).

## Key files

- `lib/features/media_details/data/datasources/media_list_local_data_source.dart`
- `lib/features/media_details/presentation/pages/media_detail_page.dart` — owns the data
  (details, seen status, seasons) and the order of the sections; opened with
  `MediaDetailPage.show` as a pushed page (route `/media_details`), never a sheet.
- `lib/features/media_details/presentation/widgets/detail/` — one widget per section of the
  detail page: `media_detail_header.dart`, `media_detail_actions.dart` (list split button),
  `media_detail_synopsis.dart`, `media_detail_infos.dart`, `media_detail_seasons.dart`,
  `media_detail_cast.dart`, `media_detail_trailers.dart`, `media_detail_related.dart`,
  `media_detail_watch_providers.dart`.
- `lib/features/media_details/presentation/widgets/seen_manager.dart`
- `lib/features/media_details/presentation/widgets/watchlist_icon_button.dart`

## Gotchas

- Isar `@collection` models are centralized in `data/models/` — see its nested
  [`AGENTS.md`](data/models/AGENTS.md).
- `MediaListLocalDataSource` is the canonical local Isar access point for lists/seen/
  likes/notifications; import flows route through it.
- Detail page: add or change a section in its own widget under `widgets/detail/`; the page
  only places it. Order: header, offline banner, actions, then for a series the seasons
  first; genres, where to watch, synopsis, trailers, info, cast, similar, recommendations,
  "In your lists". Year and length are written in the header only.
- Lists on the detail page go through `ListSplitButton` / `toggleListWithFeedback` (first
  list in one tap, every list in two, always confirmed with Undo). Removing viewings takes
  the "more" menu plus a confirmation, never a single gesture.
- Country and language names come from the ARB `select` messages `detailCountryName` /
  `detailLanguageName` (unknown codes are shown as is).
- Reusable `WatchlistIconButton` should be reused, not reimplemented (see repo memory).

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
