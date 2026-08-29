---
description: "Use when scaffolding a new feature folder under lib/features/<name>/ following MediaVore's data/domain/presentation layering, get_it/injectable DI, and provider ChangeNotifier state patterns."
argument-hint: "Feature name: <name>"
---

# Add Feature

Scaffold a new feature under `lib/features/<name>/` following the existing layer layout, then wire it into DI and regenerate codegen.

## Task

1. Create the feature folder `lib/features/<name>/` with the layers the feature actually needs — `data/`, `domain/`, `presentation/` — mirroring the nearest existing feature.
2. Note that layer coverage is not uniform across features: `discovery/` and `settings/` are presentation-only, and `media_details/` has no `domain/`. Confirm which layers apply before scaffolding.
3. Implement models, repositories, and `ChangeNotifier` providers following existing patterns (see the root `AGENTS.md` for the canonical layout).
4. Register new dependencies via get_it/injectable following `.ai/rules/di.md`.
5. If any `IsarCollection` or injectable module was added or changed, regenerate codegen per `.ai/rules/codegen.md`.

## Required inputs

- **feature name** — the `<name>` used for `lib/features/<name>/`.
- **layers** — which of `data/`, `domain/`, `presentation/` this feature needs.
- **new dependencies** — any packages to add via `flutter pub add` (see `.ai/rules/dependencies.md`).
- **reference feature** — the existing feature whose structure to mirror.

## References

- Root `AGENTS.md` — canonical feature layout and conventions.
- `.ai/rules/di.md` — get_it/injectable registration.
- `.ai/rules/codegen.md` — build_runner regeneration.
- `.ai/rules/dependencies.md` — dependency management.

## Constraints

- Do not modify other features or `pubspec.yaml` beyond adding required dependencies.
- Do not hand-edit generated files (`*.g.dart`, `injection.config.dart`).
