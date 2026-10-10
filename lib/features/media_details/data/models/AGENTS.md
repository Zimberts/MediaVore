# data/models/ — Isar collections

All Isar `@collection` persistence models for the `media_details` feature.

## Key files

- `lib/features/media_details/data/models/seen_item_model.dart`
- `lib/features/media_details/data/models/liked_item.dart`
- `lib/features/media_details/data/models/media_list_item.dart`
- `lib/features/media_details/data/models/user_list.dart`
- `lib/features/media_details/data/models/quick_add_item_model.dart`

## Gotchas

- Each `@collection` class has `part '*.g.dart'` (gitignored). Regenerate, never
  hand-edit — see `.ai/rules/codegen.md`.
- New/changed fields or `@Index` alter the on-disk schema; register every new
  `*Schema` in `lib/core/database/app_database.dart` `Isar.open([...])`.
- `media_details.dart` and `cast_member.dart` here are plain DTOs (no `.g.dart`), unlike
  the Isar-backed models.

Parent: [`media_details/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../../AGENTS.md)
