---
description: "Use when editing Dart source that has generated companions — Isar @collection models, injectable DI, or any file that relies on *.g.dart / injection.config.dart. Run build_runner instead of hand-editing generated output."
applyTo:
  - "lib/**/*.dart"
---

# Code generation

This repo uses `build_runner` to regenerate gitignored, machine-generated files.
Never hand-edit generated output — always regenerate and let the generator rewrite it.

## What is generated

- `*.g.dart` — Isar `@collection` adapters. Generated beside the models in:
  - `lib/core/cache/` (`cached_media.g.dart`)
  - `lib/features/media_details/data/models/` (`*.g.dart`)
  - `lib/features/achievements/data/models/` (`achievement_model.g.dart`)
- `lib/core/di/injection.config.dart` — injectable-generated `init()` / locator wiring.

## Rules

- Never edit a `*.g.dart` or `injection.config.dart` by hand; if it looks wrong, fix the
  source (annotation, field, or import) and regenerate.
- After changing an Isar model (fields, indexes, `@collection` name) or any DI
  annotation (`@LazySingleton`, `@Injectable`, `@module`, `as:` bindings), run:

  ```bash
  dart run build_runner build
  ```

- `isar_community_generator` and `injectable_generator` are codegen dev dependencies (see
  the root `AGENTS.md` dependencies section); do not remove them.

## Isar model changes require care

- Adding/renaming/removing a field or `@Index` changes the on-disk schema. Keep
  migration implications in mind; see the root `AGENTS.md` for database guidance.
- A model must remain `part` of the generated file and keep `@collection`.
