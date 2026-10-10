---
name: codegen
description: "Use when regenerating build_runner codegen output for MediaVore - Isar `*.g.dart` collection files and injectable `injection.config.dart` - after adding or changing `@collection`, `@injectable`, or `@module` classes. Run `dart run build_runner build`, then verify with `dart analyze` and `flutter test`."
argument-hint: "Scope: full or verify-only"
user-invocable: true
---
# Codegen (build_runner)

Regenerates the gitignored generated Dart files that build_runner produces for Isar
persistence and injectable dependency injection. This skill documents the exact
commands and the rules around never hand-editing generated output.

## When to Use
- You added, renamed, or changed the fields of an Isar `@collection` class (any of
  the 9 collections under `lib/core/cache/`,
  `lib/features/media_details/data/models/`, and
  `lib/features/achievements/data/models/`).
- You added or changed an `@injectable` or `@module` class that feeds
  `lib/core/di/injection.config.dart`.
- A build fails with "missing generated file" for a `*.g.dart` or `*.config.dart`.
- You pulled a change that touched `@collection`/`@injectable`/`@module` classes and
  the generated files are stale (or absent, since they are gitignored).

## Procedure
1. **Run codegen** from the repo root:
   ```bash
   dart run build_runner build
   ```
   Older build_runner versions required `--delete-conflicting-outputs` to clear stale
   outputs; build_runner 2.15+ removed that flag and deletes them automatically.

2. **Analyze**:
   ```bash
   dart analyze
   ```
   Expect zero issues. Fix any analysis errors in your source before proceeding
   (never in the generated files).

3. **Test**:
   ```bash
   flutter test
   ```
   Run the full suite — Isar/injectable wiring can break tests far from the changed
   files if a generated file is stale.

## Verify
- All three commands exit clean (build_runner, analyze, test).
- The generated files changed but no hand-written Dart source was edited.
- `git status` shows only generated files (which are gitignored) and, if relevant,
  the source change that required the regeneration.

## Gotchas
- **Generated files are gitignored** (`*.g.dart`, `*.config.dart`). A fresh clone
  has none of them — never expect them to exist until codegen runs.
- **Never hand-edit** `*.g.dart`, `*.config.dart`, or any build_runner output. If it
  is wrong, fix the source class/annotation and re-run codegen.
- **Run codegen after every change** to `@collection`, `@injectable`, or `@module`
  classes — the generated files will silently go stale otherwise.
- `.vscode/settings.json` auto-approves `dart analyze` and `dart test`, but
  `build_runner` still runs manually.
- If codegen emits "conflicting outputs" even with the flag, check for a
  hand-edited or duplicate generated file and delete it, then re-run.
