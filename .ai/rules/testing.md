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

## App-level tests (`test/app/`)

`test/app/harness.dart` boots the real app: `bootstrapServices` (real DI, real Isar in a
disposable `test/tmp_app_*` dir) then `MediaVoreApp` with every provider, TMDB answered by
`FakeTmdb` (`test/helpers/fake_tmdb.dart`). Platform plugins (path_provider, secure storage,
SharedPreferences, workmanager, app_links) are faked.

- Write an app test with `testApp('should …', (tester, app) async { … }, seed: AppSeed(…))`:
  it boots, runs the body, then disposes (unmount, close Isar, reset DI) even on failure.
  `AppSeed` sets the TMDB key (`null` = first launch), preferences, lists and seen history
  (written through the real repository).
- Navigate with `goToTab(tester, AppTab.x)` and `openDetail(tester, tmdbId)`; wait with
  `pumpUntilSettled(tester)`, never `pumpAndSettle` (infinite animations, real Isar I/O).
- `FakeTmdb` answers from `test/fixtures/tmdb/*.json`; override one path with
  `respond('movie/550', json)`, switch errors with `fail(FakeTmdbFailure.x)` / `recover()`,
  assert traffic with `requestCount`, `countFor(prefix)`, `byKind`. A request no route covers
  fails and fails the test at dispose: extend the routes, never silence them.
- Cross-screen journeys go in `test/app/journeys/<journey>_test.dart`, one journey per file.
- `test/app/smoke/screens_smoke_test.dart` renders every screen in light/dark, FR/EN, at
  320 dp with text x1.3, and fails on any Flutter error (overflow included) or raw ARB key.
  A new screen adds an entry to its `_screens` list.
- Find widgets by `Key` (or type), never by localized text.
- Every bug fix adds a regression test at the lowest level that reproduces it (unit, then
  widget, then app). A feature that touches two tabs or more extends a journey.
