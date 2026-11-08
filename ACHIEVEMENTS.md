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
| `behavioral` | `subtype` (`night_owl`: between midnight and 4 AM; `early_bird`: between 5 AM and 9 AM; `weekend`: within 72 hours), `target` | matching views |
| `marathon` | `target` | episodes of the same series in one day |
| `streak` | `target` | consecutive days with at least one view |
| `runtime` | `targetMinutes` | cumulative watch time (shown as `16h 40m`, `166h`, `10 days`, `1 year`) |
| `season_complete` | `target` | regular seasons (specials excluded) fully aired and fully seen |
| `series_complete` | `target` | ended or canceled series with every episode seen |
| `up_to_date` | `target` | running series with every aired episode seen (current state) |
| `saga_complete` | `target` | TMDB collections with every released part seen (2 released parts minimum) |
| `watchlist_clear` | `target` | watchlist with no unseen title (series: caught up), once `target` titles are in the history |
| `distinct_genres` | `target` | distinct genres among the views (stored genre names resolved to TMDB ids; movie and series genre ids) |
| `distinct_countries` | `target` | distinct countries of origin (TMDB `origin_country`, else `production_countries`) among the titles seen |
| `distinct_decades` | `target` | distinct release decades (first air date for a series) among the titles seen |
| `released_before` | `year`, `target` | titles seen released strictly before `year` |
| `tmdb_rating` | `minRating`, `minVotes`, `maxVotes` (each optional, inclusive), `target` | titles seen whose TMDB vote average / vote count are within the bounds |
| `day_one` | `maxDelayDays` (default 0), `target` | movies (first view) and episodes seen on their TMDB release / air day, or at most `maxDelayDays` calendar days later |
| `double_feature` | `minMovies` (default 2), `target` | calendar days with at least `minMovies` distinct movies |
| `every_weekday` | `target` | views on each day of the week (progress = least-watched weekday) |
| `monthly_streak` | `target` | consecutive calendar months with at least one view |
| `anniversary` | `target` (years) | full years since the first view in the history (imported views included) |
| `calendar_date` | `dates` (`MM-DD` list), `target` | distinct years with a view on one of the dates |

The collection types (`season_complete`, `series_complete`, `up_to_date`,
`saga_complete`, `watchlist_clear`) read TMDB data from the local cache only (season sizes, last aired
episode, collection parts): a title absent from the cache does not count until its details
are cached (opening it, or the background cache warm-up). They can regress (a new episode
airs, a cache entry is purged, the watchlist grows), so once persisted their unlock is kept
even if the current state no longer meets the target. A completion is dated by the first
view of its last required episode or movie; `watchlist_clear` has no history and is dated
when first observed.

The diversity types count **titles** (a movie, or a series as soon as one episode is seen),
dated by their first view, except `day_one` which also counts each episode. All but
`distinct_genres` read the cached title (`origin_country`, `vote_count` are cached since
#226: titles cached earlier count once their details are refreshed) and, for `day_one`
episodes, the cached season (episode air dates). They are sticky like the collection types,
since votes drift and the cache can be purged. `distinct_genres` uses the genres stored on
the views and is recomputed from history only. TMDB `popularity` is not used: it is a
short-term trending score, not a stable property of a title. `day_one` uses a one-day delay
because TMDB air dates are in the broadcaster's time zone (a US evening airing is the next
day in Europe); TMDB movie release dates are the primary (often world premiere) date, so a
theatrical release in the user's country may come later and not count.

The rhythm types (`early_bird`, `double_feature`, `every_weekday`, `monthly_streak`,
`anniversary`, `calendar_date`) use the history only and are not sticky. Dates and hours
are the local time of the view. Views recorded without a time (00:00:00.000) count for the
day-based types but never fall in the `early_bird` window. Several episodes of the same
series in one day ("binge") is the existing `marathon` type. `anniversary` is dated by the
anniversary of the first view, so an imported history counts from its first entry (no
install date is stored).

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
| `weekend` | 15, 30, 50 (any 72-hour window; 100 and 250 tiers were dropped as unrealistic) |
| `marathon` | 5, 10, 20, 50 |
| `streak` | 7, 30, 365 days |
| `runtime` | 10, 20, 50, 100, 200, 500, 1000, 2000, 5000 h, 1 year |
| `season_complete` | 1, 10, 50 |
| `series_complete` | 1, 5, 25 |
| `up_to_date` | 1, 5, 10 |
| `saga_complete` | 1, 5, 15 |
| `watchlist_clear` (standalone) | 10 titles seen |
| `countries` | 5, 15, 30 countries |
| `genres` | 5, 10, 15 genres |
| `decades` | 3, 5, 8 decades |
| `classic` | 1, 10, 50 titles released before 1970 |
| `day_one` | 1, 10, 50 (same day or the day after) |
| `hidden_gem` | 1, 5, 20 titles rated ≥ 7.5 with 20 to 500 votes |
| `blockbuster` | 5, 25, 100 titles with ≥ 10,000 votes |
| `critics_taste` | 5, 25, 100 titles rated ≥ 8.0 with ≥ 1,000 votes |
| `early_bird` | 10, 50, 100 (5 AM to 9 AM) |
| `double_feature` | 1, 10, 50 days with 2 distinct movies |
| `every_weekday` | 1, 10, 50 views on each weekday |
| `monthly` | 3, 6, 12, 24 consecutive months |
| `anniversary` | 1, 2, 5 years |
| `christmas` (24–25 Dec), `halloween` (31 Oct), `new_years_eve` (31 Dec) | 1, 3, 5 years |

Watch time follows a 1-2-5 scale in hours, capped by one year. Historical ids were
kept and their targets only lowered: `runtime_1000` = 10 h (was 1000 min),
`runtime_10000` = 50 h (was 10000 min), `runtime_day_10` = 200 h (was 240 h),
`runtime_100000` = 500 h (was 100000 min).

For the up-to-date list, see the JSON asset.
