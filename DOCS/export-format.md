# Export format (MediaVore)

## Overview

MediaVore exports and imports all user data as a single file with the `.mdv`
extension. The file body is a ZIP archive containing one `.csv` file per data
category:

- `meta.csv` — archive metadata (version, export time, source).
- `seen.csv` — seen/viewing history.
- `likes.csv` — liked items.
- `notifications.csv` — notification subscriptions.
- `quickadd.csv` — quick-add entries (next unseen episodes).
- `lists.csv` — user lists (watchlist and named lists).

> The `.mdv` extension is the app's own naming for this archive. The import
> dialog also accepts `.zip` files with identical contents as a convenience.

## Archive structure

```
export.mdv
├── meta.csv
├── seen.csv
├── likes.csv
├── notifications.csv
├── quickadd.csv
└── lists.csv
```

## CSV files rules

- All text is encoded in UTF-8.
- The first row in every CSV file is a header row identifying the columns.
- List fields (e.g. genres) are formatted as pipe-separated strings within their
  CSV cell (`Action|Drama`).
- Nullable fields are left empty.
- A data file is only present when that category is non-empty. An empty category
  produces no CSV entry in the archive.
- Unknown extra columns are ignored on import. Missing optional columns are
  handled gracefully.
- Dates are ISO8601 strings; booleans are the strings `true` / `false`.

### `meta.csv`

Columns: `version`, `exportedAt`, `source`

- `version` — integer, increment when breaking changes occur.
- `exportedAt` — ISO8601 timestamp of the export.
- `source` — string, optional origin.

### `seen.csv`

Columns: `tmdbId`, `type`, `title`, `posterPath`, `seenDate`, `seasonNumber`, `episodeNumber`, `runtime`, `genres`

- `tmdbId` — int (TMDB id).
- `type` — `movie` | `tv`.
- `title` — string.
- `posterPath` — nullable string.
- `seenDate` — ISO8601 string.
- `seasonNumber`, `episodeNumber` — nullable int (empty for movies).
- `runtime` — nullable int, minutes.
- `genres` — nullable pipe-separated list of strings.

### `likes.csv`

Columns: `tmdbId`, `type`, `title`

- `tmdbId` — int.
- `type` — `movie` | `tv`.
- `title` — string.

### `notifications.csv`

Columns: `tmdbId`, `type`, `title`, `posterPath`, `releaseDate`, `seasonNumber`, `episodeNumber`, `autoNotify`

- `tmdbId` — int.
- `type` — `movie` | `tv`.
- `title` — string.
- `posterPath` — nullable string.
- `releaseDate` — nullable ISO8601 string.
- `seasonNumber`, `episodeNumber` — nullable int.
- `autoNotify` — boolean (`true` | `false`).

### `quickadd.csv`

Columns: `tmdbId`, `type`, `seasonNumber`, `episodeNumber`, `insertedAt`, `airDate`, `title`, `posterPath`

- `tmdbId` — int.
- `type` — `movie` | `tv`.
- `seasonNumber`, `episodeNumber` — nullable int; for TV, the next unseen episode.
- `insertedAt` — ISO8601 string, when the entry was created.
- `airDate` — nullable ISO8601 string, air date of the episode or movie.
- `title`, `posterPath` — nullable strings, metadata snapshot at insertion time.

### `lists.csv`

Columns: `listName`, `tmdbId`, `type`, `title`, `position`

- `listName` — string, the list the item belongs to.
- `tmdbId` — int.
- `type` — `movie` | `tv`.
- `title` — string.
- `position` — int, the intended ordering within the list (see format notes).

## Import semantics

Imports are processed in a fixed order: seen, likes, notifications, quick add, lists.
A category is only imported when its CSV file is present in the archive.

- **append** — insert everything as-is, no deduplication.
- **replace** — clear the target category, then insert. Because a category is only
  processed when present in the archive, **only the categories present in the
  archive are cleared**; an omitted (empty) category leaves existing data intact
  even in replace mode.
- **merge** — deduplicate per item by these keys:
  - Seen: `(tmdbId, type, seasonNumber, episodeNumber)` plus a `seenDate` window of
    ±1 second (for movies `seasonNumber` and `episodeNumber` are empty).
  - Likes: `(tmdbId, type)`.
  - Notifications: `(tmdbId, type)`.
  - Quick add: `(tmdbId, seasonNumber, episodeNumber)`.
  - Lists: behaves the same as append; duplicates are resolved by
    `(tmdbId, type, listName)`.

## Format notes

- **List ordering (`position`) is not restored on import.** Items are re-ordered on
  import (in file order), so the `position` column is exported for reference only
  and is not authoritative across a round-trip.
- **Quick-add opt-outs are not part of the format.** There is no CSV column or
  archive entry for opt-out state, so it is not preserved across an export/import
  round-trip.
- **Seen `runtime` and `genres` are optional.** When absent from an imported seen
  row, the importing app may attempt to backfill them from remote data; this can
  make a seen-only import require network access.
