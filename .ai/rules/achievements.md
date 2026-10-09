---
description: "Use when editing achievement definitions or icons under assets/achievements/ — definitions.json is the single source of truth with stable ids, loaded at runtime via DefinitionsLoader."
applyTo:
  - "assets/achievements/**"
---

# Achievements

## Single source of truth

- `assets/achievements/definitions.json` is the authoritative, runtime-loaded source of
  achievement definitions. The app loads it via `DefinitionsLoader`
  (`AssetDefinitionsLoader` reads `assets/achievements/definitions.json`).
- `ACHIEVEMENTS.md` (repo root) is human documentation only — non-authoritative. Do not
  treat it as a schema.

## Stable ids

- Each entry's `id` (e.g. `movie_1`, `tv_50`) is a stable public identifier. Never rename
  an existing `id` — changing it breaks persisted achievement progress that references it.
- New achievements get fresh, unique ids.

## Fields

- Entries follow `{ id, title, description, iconPath, type, group?, tier?, params }`.
  `iconPath` points into `assets/achievements/`. Keep icons alongside the JSON.
- `group` + `tier` mark levels of the same challenge (one card per group on the page).
  Tiers are 1..n, consecutive, in file order, with increasing targets. `tier` is not
  persisted, so inserting a level is safe; only `id` is.
- `genre` achievements use `params.genreId` (TMDB movie genre id), never a genre name.
- Adding an achievement = editing the JSON. Evaluation is generic by `type`/`params`; never
  add id-specific code in `AchievementRepositoryImpl`.

## Tests

- In tests, inject a fake `DefinitionsLoader` instead of reading the JSON asset directly;
  do not couple tests to the file contents of `definitions.json`.
- Exception: `test/features/achievements/data/definitions_test.dart` validates the real
  file (unique ids, historical ids kept, known types, consistent tiers). Keep it passing.
