# test/core/cache/ — test conventions

Tests for `lib/core/cache/` (the `MediaCache` in-memory + Isar cache).

## Key files

- `test/core/cache/media_cache_test.dart`

## Gotchas

- Uses real Isar in a disposable `test/tmp_*` scratch dir; recreate per test
  (`.ai/rules/testing.md`).

Parent: [`test/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
