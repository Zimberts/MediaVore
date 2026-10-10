# settings/ — feature conventions

App settings UI and persisted preferences. **Presentation-only** feature (no
`data`/`domain` layers).

## Key files

- `lib/features/settings/presentation/providers/settings_provider.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/settings/presentation/pages/data_cache_settings_page.dart`

## Gotchas

- `SettingsProvider` persists via `SharedPreferences` directly (theme, grid size,
  `tmdbApiKey`, display mode). No repository abstraction.
- TMDB key is stored under `tmdbApiKey` in SharedPreferences, not `.env`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
