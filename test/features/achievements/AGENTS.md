# test/features/achievements/ — test conventions

Tests for the `achievements` feature, mirroring `lib/features/achievements/`.

## Key files

- `test/features/achievements/domain/achievement_test.dart`
- `test/features/achievements/data/repositories/achievement_repository_impl_test.dart`
- `test/features/achievements/presentation/providers/achievement_provider_test.dart`

## Gotchas

- Inject a fake `DefinitionsLoader` rather than reading `assets/achievements/
  definitions.json` directly (`.ai/rules/achievements.md`).
- General test rules: `test/AGENTS.md` and `.ai/rules/testing.md`.

Parent: [`test/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
