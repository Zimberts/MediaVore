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
- `groupTitle` (first tier of a group only, required there): the family name shown on
  the card (e.g. `"Horror movies"`), translated as `translations.<code>.groupTitle`.
  Tier titles stay visible in the levels sheet. When a new first tier is inserted, move
  `groupTitle` onto it.
- Never raise an existing target: unlock state is recomputed from the history, so a
  higher target would re-lock users who earned it. Lowering is safe (checked by the
  definitions test). Ids are opaque: after a re-spacing a number in an id may no longer
  match its target (see `runtime` below).
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
| `season_complete` | `target` | regular seasons (specials excluded) fully aired and fully seen |
| `series_complete` | `target` | ended or canceled series with every episode seen |
| `up_to_date` | `target` | running series with every aired episode seen (current state) |
| `saga_complete` | `target` | TMDB collections with every released part seen (2 released parts minimum) |
| `watchlist_clear` | `target` | watchlist with no unseen title (series: caught up), once `target` titles are in the history |

The last five types read TMDB data from the local cache only (season sizes, last aired
episode, collection parts): a title absent from the cache does not count until its details
are cached (opening it, or the background cache warm-up). They can regress (a new episode
airs, a cache entry is purged, the watchlist grows), so once persisted their unlock is kept
even if the current state no longer meets the target. A completion is dated by the first
view of its last required episode or movie; `watchlist_clear` has no history and is dated
when first observed.

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
| `weekend` | 15, 30, 50, 100 (any 72-hour window; a 250 tier was dropped as unrealistic) |
| `marathon` | 5, 10, 20, 50 |
| `streak` | 7, 30, 365 days |
| `runtime` | 10, 20, 50, 100, 200, 500, 1000, 2000, 5000 h, 1 year |
| `season_complete` | 1, 10, 50 |
| `series_complete` | 1, 5, 25 |
| `up_to_date` | 1, 5, 10 |
| `saga_complete` | 1, 5, 15 |
| `watchlist_clear` (standalone) | 10 titles seen |

Watch time follows a 1-2-5 scale in hours, capped by one year. Historical ids were
kept and their targets only lowered: `runtime_1000` = 10 h (was 1000 min),
`runtime_10000` = 50 h (was 10000 min), `runtime_day_10` = 200 h (was 240 h),
`runtime_100000` = 500 h (was 100000 min).

For the up-to-date list, see the JSON asset.
