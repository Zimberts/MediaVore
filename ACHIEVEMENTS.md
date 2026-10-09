# MediaVore Achievements

The single source-of-truth for achievement definitions is the JSON asset:

- `assets/achievements/definitions.json`

Edit that file to add or change achievements. This document provides a human-readable summary and examples but is no longer the authoritative source.

## How to edit

Add or modify entries in `assets/achievements/definitions.json` using the schema below.
Adding an achievement only requires editing the JSON: evaluation is generic, driven by
`type` and `params`, with no id-specific code.

JSON example:

```json
{
    "id": "genre_horror_50",
    "title": "Horror Harvester",
    "description": "Watch 50 horror movies",
    "iconPath": "assets/achievements/genre_horror_50.png",
    "type": "genre",
    "group": "genre_horror",
    "tier": 2,
    "params": { "genreId": 27, "target": 50 }
}
```

- `id`: stable, unique. Never rename an existing id: it is what is persisted when an
  achievement is unlocked.
- `group` / `tier` (optional): achievements sharing a `group` are levels of the same
  challenge and appear as one card on the achievements page. `tier` starts at 1, is
  consecutive, and follows increasing targets in file order. Omit both for a standalone
  achievement. `tier` is not persisted, so levels can be inserted (e.g. a new entry tier)
  without affecting existing unlocks.
- `params.target` (or `params.targetMinutes` for `runtime`) must be greater than 0.

The repository loads the JSON at runtime (tests inject a loader during unit tests).
`test/features/achievements/data/definitions_test.dart` validates the file: unique ids,
historical ids still present, known types, valid genre ids, and consistent tiers.

## Types

| `type` | `params` | Counts |
| --- | --- | --- |
| `count` | `mediaType` (`movie` / `tv`), `target` | movies or episodes watched |
| `genre` | `genreId` (TMDB movie genre id), `target` | movies of that genre (stored genre names are resolved to ids, English or French) |
| `rewatch` | `isTv`, `target` | views of the same movie / episode |
| `loyalist` | `target` | episodes of the same series |
| `behavioral` | `subtype` (`night_owl`: between midnight and 4 AM; `weekend`: within 72 hours), `target` | matching views |
| `marathon` | `target` | episodes of the same series in one day |
| `streak` | `target` | consecutive days with at least one view |
| `runtime` | `targetMinutes` | cumulative watch time (shown as `16h 40m`, `166h`, `10 days`, `1 year`) |

## Families (reference)

| Group | Tiers |
| --- | --- |
| `movies` | 1, 10, 50, 100, 500, 1000 |
| `episodes` | 1, 10, 50, 250, 1000, 2500, 5000 |
| `rewatch_movie` | 2, 5, 10 |
| `rewatch_episode` | 2, 5, 10 |
| `loyalist` | 100, 500 |
| `genre_comedy`, `genre_action`, `genre_scifi` | 10, 20, 50, 100 |
| `genre_romance` | 10, 15, 50, 100 |
| `genre_horror`, `genre_doc`, `genre_animation`, `genre_thriller`, `genre_drama`, `genre_crime`, `genre_fantasy`, `genre_adventure`, `genre_western`, `genre_war`, `genre_music`, `genre_family`, `genre_mystery`, `genre_history` | 10, 50, 100 |
| `night_owl` | 10, 50, 100, 250 |
| `weekend` | 15, 30, 50 |
| `marathon` | 5, 10, 20, 50 |
| `streak` | 7, 30, 365 days |
| `runtime` | 1000 min, 100 h, 10000 min, 10 days, 1000 h, 100000 min, 1 year |

For the up-to-date list, see the JSON asset.
