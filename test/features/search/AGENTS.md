# test/features/search/ — test conventions

Tests for the `search` feature, mirroring `lib/features/search/`.

## Key files

- `test/features/search/data/datasources/media_remote_data_source_test.dart`
- `test/features/search/data/repositories/media_repository_impl_test.dart`
- `test/features/search/presentation/providers/search_provider_test.dart`

## Gotchas

- Remote datasource tests use `MockDio` (`.ai/rules/testing.md`).
- `MediaRepository` import-mode tests exercise `ImportMode` (append/replace/merge) —
  keep in sync with `DOCS/export-format.md` (`.ai/rules/export-format.md`).

Parent: [`test/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
