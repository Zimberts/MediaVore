# discovery/ — feature conventions

Media discovery browsing UI. **Presentation-only** feature (no `data`/`domain` layers).

## Key files

- `lib/features/discovery/presentation/pages/discovery_page.dart`
- `lib/features/discovery/presentation/providers/discovery_provider.dart`

## Gotchas

- This feature is UI-only; it relies on `search`'s `MediaRepository` for all data
  access. Don't add a repository/datasource here.
- `DiscoveryProvider` is a thin `ChangeNotifier`; keep business logic in `search`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
