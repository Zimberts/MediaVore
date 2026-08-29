---
description: "Use when writing, editing, or running Flutter tests (test/**). Covers mocktail mocks, test/helpers/mocks.dart, fixture(name), 'should … when …' naming, and disposable real-Isar scratch dirs."
applyTo:
  - "test/**"
---

# Testing

Tests mirror source paths and append `_test.dart`
(e.g. `lib/core/utils/formatters.dart` → `test/core/utils/formatters_test.dart`).

## Mocks

- Use `mocktail` for all mocks. Shared mock classes live in `test/helpers/mocks.dart`
  (e.g. `MockDio`, `MockMediaRepository`). Add new shared mocks there rather than
  redefining them per-file.
- Stub with `when(() => mock.method(...)).thenAnswer(...)` and verify with `verify()`.

## Fixtures

- Load fixture files with `fixture(name)` from `test/helpers/fixture_reader.dart`, which
  reads `test/fixtures/$name`. Put test payloads in `test/fixtures/`.

## Naming & structure

- Wrap cases in `group('...', () { ... })` and name tests
  `test('should … when …', () { ... })` (see `formatters_test.dart` for the canonical shape).
- Tests should describe behavior, not implementation.

## Real Isar tests

- When testing against real Isar, open a scratch database in a disposable `test/tmp_*`
  directory (e.g. `test/tmp_cache`, `test/tmp_import_modes`) so runs don't leak state.
- Clean up / recreate the scratch dir per test; never depend on a pre-existing file.

## Widget/network guards

- Widget tests that could touch the network should bail out when not under the test
  harness, guarding with `Platform.environment.containsKey('FLUTTER_TEST')`.
