# Export format (MediaVore)

## Overview

MediaVore uses a single ZIP archive to export/import user data. The archive contains multiple `.csv` files: `seen.csv`, `likes.csv`, `notifications.csv`, `lists.csv`, and a `meta.csv` header with a `version`, `exportedAt` timestamp and `source`.

## Archive structure

```
export.zip
├── meta.csv
├── seen.csv
├── likes.csv
├── notifications.csv
└── lists.csv
```

## CSV files rules

- All text is encoded in UTF-8.
- The first row in every CSV file is a header row identifying the columns.
- List fields like genres are formatted as pipe-separated strings within their CSV cells (`Action|Drama`).
- Nullable fields are left empty.

### `meta.csv`

Columns: `version`, `exportedAt`, `source`

- `version` -- integer, increment when breaking changes occur.
- `exportedAt` -- ISO8601 string.
- `source` -- string, optional origin.

### `seen.csv`

Columns: `tmdbId`, `type`, `title`, `posterPath`, `seenDate`, `seasonNumber`, `episodeNumber`, `runtime`, `genres`

- `tmdbId` (int), `type` ("movie"|"tv"), `title` (string)
- `posterPath` (nullable string)
- `seenDate` (ISO8601 string)
- `seasonNumber`, `episodeNumber` (nullable int)
- `runtime` (nullable int, minutes)
- `genres` (nullable pipe-separated list of strings)

### `likes.csv`

Columns: `tmdbId`, `type`, `title`

### `notifications.csv`

Columns: `tmdbId`, `type`, `title`, `posterPath`, `releaseDate`, `seasonNumber`, `episodeNumber`, `autoNotify`

- `autoNotify` is represented as `true` or `false` string.

### `lists.csv`

Columns: `listName`, `tmdbId`, `type`, `title`, `position`

- `listName` identifies which list the item belongs to. `position` determines the ordering.

## Import semantics

- `ImportMode.append` -- insert everything as-is.
- `ImportMode.replace` -- clear target collection then insert.
- `ImportMode.merge` -- deduplicate by keys:
  - Likes/Notifications: dedupe by `(tmdbId,type)`.
  - Lists: dedupe by `(listName, tmdbId)`.
  - Seen: dedupe by `(tmdbId,type,season,episode)` and a small seenDate window (+-1s) to avoid accidental duplicates.

## Notes

- The exporter converts DateTime to ISO8601 strings and booleans to string.
- Unknown extra columns are ignored. Missing optional columns are handled gracefully.
