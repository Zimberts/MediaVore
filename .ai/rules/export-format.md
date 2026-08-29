---
description: "Use when editing export/import serialization under lib/core/utils/ or its spec in DOCS/export-format.md — keep the ZIP-of-CSV schema and ImportMode semantics in sync."
applyTo:
  - "lib/core/utils/**"
  - "DOCS/export-format.md"
---

# Export / Import format

`lib/core/utils/export_import_serializer.dart` implements a ZIP-of-CSV format. Its
authoritative spec lives in `DOCS/export-format.md`. **Keep the serializer and the doc in
sync** — any schema change must update both.

## Archive contents

- `meta.csv` — `version`, `exportedAt`, `source`.
- `seen.csv`, `likes.csv`, `notifications.csv`, `quickadd.csv`, `lists.csv`.

## Schema rules

- UTF-8, first row is a header, pipe-separated (`|`) list cells, empty cell = null.
- Dates serialize to ISO8601 strings; booleans to `true`/`false` strings.
- `meta.csv` `version` is bumped on breaking changes.

## ImportMode semantics

- `ImportMode.append` — insert everything as-is.
- `ImportMode.replace` — clear target collection, then insert.
- `ImportMode.merge` — dedupe by keys:
  - Likes/Notifications: `(tmdbId, type)`.
  - Lists: `(listName, tmdbId)`.
  - Seen: `(tmdbId, type, season, episode)` plus a ±1s `seenDate` window.

When adding a column, changing a column name/order, or altering dedupe rules, update
`DOCS/export-format.md` in the same change and bump `meta.csv` `version` if breaking.
