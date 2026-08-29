# media_details/ — feature conventions

Media detail pages, lists, seen/like/notify state, and quick-add. Has `data` +
`presentation` layers (no `domain/`; local entities live in `lib/core/domain/entities/`).

## Key files

- `lib/features/media_details/data/datasources/media_list_local_data_source.dart`
- `lib/features/media_details/presentation/pages/media_detail_page.dart`
- `lib/features/media_details/presentation/widgets/seen_manager.dart`
- `lib/features/media_details/presentation/widgets/watchlist_icon_button.dart`

## Gotchas

- Isar `@collection` models are centralized in `data/models/` — see its nested
  [`AGENTS.md`](data/models/AGENTS.md).
- `MediaListLocalDataSource` is the canonical local Isar access point for lists/seen/
  likes/notifications; import flows route through it.
- Reusable `WatchlistIconButton` should be reused, not reimplemented (see repo memory).

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
