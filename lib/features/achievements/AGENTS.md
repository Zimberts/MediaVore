# achievements/ — feature conventions

Tracks earned achievements (full `data` + `domain` + `presentation` layering).

## Key files

- `lib/features/achievements/domain/entities/achievement.dart`
- `lib/features/achievements/domain/repositories/achievement_repository.dart`
- `lib/features/achievements/data/repositories/achievement_repository_impl.dart`
- `lib/features/achievements/data/models/achievement_model.dart` (Isar `@collection`)
- `lib/features/achievements/domain/entities/achievement_family.dart` (tiers grouped by
  `group`; the page shows one card per family)
- `lib/features/achievements/presentation/providers/achievement_provider.dart`
- `lib/features/achievements/data/datasources/achievement_media_source.dart` (cached
  season sizes, sagas, title metadata and episode air dates; local reads only)

## Gotchas

- Definitions load at runtime from `assets/achievements/definitions.json` via
  `DefinitionsLoader`; that JSON is the single source of truth (stable ids). See
  `.ai/rules/achievements.md` — never hardcode titles/progress in Dart.
- Titles/descriptions are translated in the JSON (`translations.<code>`); display them
  with `achievement.titleFor(context.l10n.localeName)`, never `achievement.title`.
  A family card shows `family.titleFor(...)` (the `groupTitle` of its first tier).
- Collection types (`season_complete`, `series_complete`, `up_to_date`, `saga_complete`,
  `watchlist_clear`) can regress, so a persisted unlock of these types stays unlocked
  (`_stickyTypes` in the repository). So do the cache-based diversity types
  (`_titleTypes`: countries, decades, release year, TMDB rating, day one). Other types
  are recomputed from history only.
- `AchievementProvider` persists every newly unlocked tier but notifies only the highest
  tier per family in a batch.
- `achievement_model.dart` has a generated `part 'achievement_model.g.dart'`; never
  hand-edit generated files (`.ai/rules/codegen.md`).

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
