# test/features/settings/ — test conventions

Tests for the `settings` feature, mirroring `lib/features/settings/`.

## Key files

- `test/features/settings/presentation/providers/settings_provider_test.dart`
- `test/features/settings/presentation/pages/data_cache_settings_fileio_test.dart`

## Gotchas

- Provider tests use `SharedPreferences.setMockInitialValues` to avoid real prefs.
- General test rules: `test/AGENTS.md` and `.ai/rules/testing.md`.

Parent: [`test/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
