# di/ — conventions

Dependency injection (get_it + injectable) and achievement-definition loading.

## Key files

- `lib/core/di/injection.dart` (`locator`, `@InjectableInit`, `RegisterModule`)
- `lib/core/di/injection.config.dart` (generated — do not edit)
- `lib/core/di/definitions_loader.dart` (interface)
- `lib/core/di/asset_definitions_loader.dart` (asset impl)

## Gotchas

- Global `locator` = `GetIt.instance`; resolve with `locator<X>()`.
- `injection.config.dart` is generated; regenerate after any `@LazySingleton(as:)`,
  `@module`, or binding change (`.ai/rules/di.md`).
- `DefinitionsLoader` / `AssetDefinitionsLoader` load achievements from
  `assets/achievements/definitions.json` at runtime.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
