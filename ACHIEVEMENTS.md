# MediaVore Achievements

The single source-of-truth for achievement definitions is the JSON asset:

- `assets/achievements/definitions.json`

Edit that file to add or change achievements. This document provides a human-readable summary and examples but is no longer the authoritative source.

## How to edit

Add or modify entries in `assets/achievements/definitions.json` using the schema below.

JSON example:

```json
{
	"id": "genre_horror_50",
	"title": "Horror Harvester",
	"description": "Watch 50 horror movies",
	"iconPath": "assets/achievements/horror_50.png",
	"type": "genre",
	"params": { "genre": "Horror", "target": 50 }
}
```

The repository loads the JSON at runtime (tests inject a loader during unit tests). Keep `id` values stable to preserve persisted unlocks.

## Summary (reference)

The rest of this file contains a quick reference of currently-supported achievement categories (movies, TV, genres, rewatches, streaks, runtime, behavioral). For the up-to-date list, see the JSON asset.
