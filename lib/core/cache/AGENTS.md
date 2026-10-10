# cache/ — conventions

In-memory + Isar-backed media cache (`MediaCache`) and its `CachedMedia` collection.

## Key files

- `lib/core/cache/media_cache.dart`
- `lib/core/cache/cached_media.dart` (Isar `@collection`)

## Gotchas

- `cached_media.dart` has `part 'cached_media.g.dart'` (gitignored) — regenerate via
  build_runner, never hand-edit (`.ai/rules/codegen.md`).
- `MediaCache` stores `MediaDetails`/`MediaItem` as JSON strings inside the Isar
  collection; it also caches actor profile paths and season data in-memory.
- `CachedMediaSchema` is registered in `lib/core/database/app_database.dart`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
