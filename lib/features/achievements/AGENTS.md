# achievements/ — feature conventions

Tracks earned achievements (full `data` + `domain` + `presentation` layering).

## Key files

- `lib/features/achievements/domain/entities/achievement.dart`
- `lib/features/achievements/domain/repositories/achievement_repository.dart`
- `lib/features/achievements/data/repositories/achievement_repository_impl.dart`
- `lib/features/achievements/data/models/achievement_model.dart` (Isar `@collection`)
- `lib/features/achievements/presentation/providers/achievement_provider.dart`

## Gotchas

- Definitions load at runtime from `assets/achievements/definitions.json` via
  `DefinitionsLoader`; that JSON is the single source of truth (stable ids). See
  `.ai/rules/achievements.md` — never hardcode titles/progress in Dart.
- `achievement_model.dart` has a generated `part 'achievement_model.g.dart'`; never
  hand-edit generated files (`.ai/rules/codegen.md`).

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
