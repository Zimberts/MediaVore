# test/core/utils/ — test conventions

Tests for `lib/core/utils/` (formatters, sorts, export/import serializer).

## Key files

- `test/core/utils/formatters_test.dart`
- `test/core/utils/export_import_serializer_edgecases_test.dart`
- `test/core/utils/release_sort_test.dart`
- `test/core/utils/saga_sort_test.dart`

## Gotchas

- Export/import tests assert the ZIP-of-CSV schema from `DOCS/export-format.md`;
  keep them in sync (`.ai/rules/export-format.md`).

Parent: [`test/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
