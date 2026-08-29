# utils/ — conventions

Shared formatting, genre maps, sort helpers, and export/import serialization.

## Key files

- `lib/core/utils/export_import_serializer.dart`
- `lib/core/utils/formatters.dart`
- `lib/core/utils/genres.dart`
- `lib/core/utils/release_sort.dart`
- `lib/core/utils/saga_sort.dart`

## Gotchas

- `export_import_serializer.dart` implements the ZIP-of-CSV format; its authoritative
  spec is `DOCS/export-format.md` and must stay in sync (`.ai/rules/export-format.md`).
- `genres.dart` hardcodes TMDB genre id→name maps; `release_sort.dart` / `saga_sort.dart`
  are pure, stateless sort helpers.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
