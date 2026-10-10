---
description: "Use when regenerating build_runner codegen outputs — isar *.g.dart files and injection.config.dart — after model or DI changes."
argument-hint: "Trigger: isar model changed | injectable module changed"
---

# Regenerate Codegen

Run build_runner to regenerate generated files after a model or dependency-injection change.

## Task

1. Run `dart run build_runner build` to regenerate all `*.g.dart` (Isar) and `injection.config.dart` (injectable) outputs.
2. Confirm the generated files were updated and contain no hand edits (they must never be edited by hand — see `.ai/rules/codegen.md`).
3. Run `flutter analyze` to confirm the regenerated outputs compile.

## Required inputs

- **trigger** — what changed (Isar model, injectable module, or both) to justify regeneration.

## References

- `.ai/rules/codegen.md` — build_runner usage and the never-hand-edit rule.
- `.ai/rules/di.md` — injectable/get_it registration and `injection.config.dart`.
- Root `AGENTS.md` — build/analyze commands.

## Constraints

- Do not hand-edit `*.g.dart` or `injection.config.dart`.
- Do not modify Dart source or `pubspec.yaml` beyond what triggered the regeneration.
