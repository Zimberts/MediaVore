# test/ — conventions

For project-wide rules, see the root [`AGENTS.md`](../AGENTS.md). For test-specific
guidance, see `.ai/rules/testing.md` (loaded automatically for `test/**`).

## Quick reference

- Tests mirror source paths + `_test.dart` (e.g. `test/core/utils/formatters_test.dart`).
- Mock with `mocktail`; shared mocks go in `test/helpers/mocks.dart`.
- Load payloads with `fixture(name)` (`test/helpers/fixture_reader.dart` → `test/fixtures/`).
- Naming: `group('...')` → `test('should … when …')`.
- Real-Isar tests use disposable `test/tmp_*` scratch dirs.
- Widget tests guard network access with `Platform.environment.containsKey('FLUTTER_TEST')`.
- `test/app/` boots the whole app (real DI, real Isar, fake TMDB) through
  `test/app/harness.dart`; cross-screen journeys go in `test/app/journeys/`.
- `test/helpers/fake_tmdb.dart` is the fake TMDB server (Dio adapter, fixtures
  in `test/fixtures/tmdb/`, switchable errors, request counter).
- `test/benchmark/` measures a full cache reload against a fake TMDB server
  (simulated latency, request count). N = 50 runs in CI; N = 200/500 run with
  `MEDIAVORE_BENCHMARK=1 flutter test test/benchmark/`.
