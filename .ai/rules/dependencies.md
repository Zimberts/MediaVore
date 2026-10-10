---
description: "Use when adding, removing, or changing package dependencies in pubspec.yaml — SDK constraint, flutter pub add workflow, and the no-freezed / no-json_serializable policy."
applyTo:
  - "pubspec.yaml"
---

# Dependencies

## SDK constraint

- Keep `environment.sdk: ^3.10.4` (Dart 3.10.4).

## Adding/removing deps

- Add dependencies via `flutter pub add <package>` (and dev deps via
  `flutter pub add --dev <package>`); do not hand-edit version constraints.
- Keep the dependency list sorted into `dependencies` vs `dev_dependencies`.

## Serialization policy

- No `freezed`, no `json_serializable`. Models use hand-written `fromJson`/`toJson`
  and `equatable` for value equality.
- Do not introduce codegen-based JSON serializers.

## Codegen deps (dev)

- `isar_community_generator` and `injectable_generator` are codegen dev dependencies that
  pair with `isar_community`/`injectable`; see `.ai/rules/codegen.md`. Keep them as dev deps.
