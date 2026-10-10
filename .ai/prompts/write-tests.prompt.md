---
description: "Use when writing unit or widget tests for a MediaVore module, mirroring source paths, using mocktail, test/helpers/mocks.dart, and the fixture(name) reader."
argument-hint: "Source path: lib/features/<name>/<layer>/file.dart"
---

# Write Tests

Write unit and/or widget tests for a source module, mirroring its path in `test/` and following MediaVore's testing conventions.

## Task

1. Mirror the source path in the test tree and name the file `<source>_test.dart` (e.g. `lib/features/<name>/domain/foo.dart` → `test/features/<name>/domain/foo_test.dart`).
2. Use mocktail for mocks, preferring the shared mocks in `test/helpers/mocks.dart`; only define a new mock locally if none exists there.
3. Load test data with `fixture(name)` from `test/helpers/fixture_reader.dart` rather than inlining large fixtures.
4. Name tests `test('should … when …')` and cover the module's behavior per `.ai/rules/testing.md`.
5. Verify with `flutter test` (or `flutter analyze` for lint-only changes).

## Required inputs

- **source path** — the file under `lib/` whose behavior to test.
- **scope** — unit, widget, or both.
- **behavior notes** — any edge cases or non-obvious expectations to encode.

## References

- `.ai/rules/testing.md` — mocking, fixtures, naming, and real-Isar scratch directories.
- Root `AGENTS.md` — project-wide test commands and conventions.

## Constraints

- Do not modify source code to make tests pass; change tests only.
- Do not hand-edit generated files.
