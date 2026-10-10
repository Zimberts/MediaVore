# lib/ — conventions

This directory follows a **feature-first** layout. For project-wide rules (build,
lint, code style, dependencies, workflows), see the root [`AGENTS.md`](../AGENTS.md).

## Layout

- `core/` — shared, cross-feature code: `cache/`, `database/`, `di/`, `domain/`,
  `error/`, `services/`, `theme/`, `utils/`.
- `features/` — one folder per feature (`achievements`, `discovery`, `media_details`,
  `search`, `settings`), each internally layered (data / domain / presentation).

## Area-specific rules (loaded on demand)

- Code generation: `.ai/rules/codegen.md` — never hand-edit `*.g.dart` /
  `injection.config.dart`.
- DI + database wiring: `.ai/rules/di.md`.
- Export/import serializer: `.ai/rules/export-format.md`.

## Asymmetries to be aware of

- Isar `@collection` models are split across `core/cache/` and
  `features/*/data/models/`; generated `.g.dart` files sit next to their sources.
- `lib/core/di/` also holds the `DefinitionsLoader` interface + `AssetDefinitionsLoader`
  implementation that load achievement definitions at runtime.
