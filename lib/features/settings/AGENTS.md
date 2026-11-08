# settings/ — feature conventions

App settings UI and persisted preferences. **Presentation-only** feature (no
`data`/`domain` layers).

## Key files

- `lib/features/settings/presentation/providers/settings_provider.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/settings/presentation/pages/data_cache_settings_page.dart`
- `lib/features/settings/presentation/pages/tmdb_credential_page.dart` — TMDB key
  screen (first-launch onboarding from `MainPage`, and the Settings editor). It
  verifies the key with TMDB (`SearchProvider.validateTmdbCredential`) before saving.

## Gotchas

- `SettingsProvider` persists via `SharedPreferences` directly (theme, grid size,
  `tmdbApiKey`, display mode). No repository abstraction.
- TMDB key lives in secure storage (`TmdbCredentialStore`), not `.env`.
  `DiscoveryPage` listens to `SettingsProvider.tmdbApiKey` and reloads when it
  changes; don't add manual refreshes after saving a key.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
