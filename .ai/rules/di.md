---
description: "Use when editing dependency injection (lib/core/di/) or Isar database wiring (lib/core/database/) — get_it + injectable, @InjectableInit, @LazySingleton(as:), and regenerating injection.config.dart."
applyTo:
  - "lib/core/di/**"
  - "lib/core/database/**"
---

# Dependency injection & database wiring

- DI uses `get_it` + `injectable`. `lib/core/di/injection.dart` declares the global
  `locator` (`GetIt.instance`) and the `@InjectableInit` function
  (`configureDependencies()` → generated `init`).
- `lib/core/database/app_database.dart` defines `DatabaseModule`, which opens the Isar
  instance (`@preResolve @singleton Future<Isar>`) and registers every `*Schema`.

## Binding interfaces

- Bind interface → implementation with `@LazySingleton(as: Interface)` on the impl class
  (e.g. `@LazySingleton(as: DefinitionsLoader) class AssetDefinitionsLoader …`).
- Register external instances / simple singletons in the `@module` classes.

## Regenerate after any DI change

- After adding/removing/moving a provider, changing a binding (`as:`), or editing a
  `@module`, regenerate:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- `injection.config.dart` is generated — never hand-edit it. See `.ai/rules/codegen.md`.

## New Isar collections

- When adding a new `@collection` model, register its `*Schema` in `DatabaseModule`'s
  `Isar.open([...])` list or it won't be persisted.
