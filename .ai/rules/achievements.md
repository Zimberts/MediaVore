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

- Entries follow `{ id, title, description, iconPath, type, params }`. `iconPath` points
  into `assets/achievements/`. Keep icons alongside the JSON.

## Tests

- In tests, inject a fake `DefinitionsLoader` instead of reading the JSON asset directly;
  do not couple tests to the file contents of `definitions.json`.
