# search/ — feature conventions

TMDB search/discovery and the central `MediaRepository`. Full `data` + `domain` +
`presentation` layering.

## Key files

- `lib/features/search/domain/repositories/media_repository.dart`
- `lib/features/search/data/repositories/media_repository_impl.dart`
- `lib/features/search/data/datasources/media_remote_data_source.dart`
- `lib/features/search/data/models/movie.dart`
- `lib/features/search/presentation/providers/search_provider.dart`

## Gotchas

- `MediaRepository` is the shared data gateway for the whole app (also used by
  `discovery`, `media_details`, `achievements`). Change its API with care.
- Remote access is TMDB via `dio`; credential read from SharedPreferences `tmdbApiKey`
  (v3 key or v4 bearer token). Throws `ConfigurationException` when missing.
- `ImportMode` enum (`append|replace|merge`) is declared here — see
  `.ai/rules/export-format.md`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
