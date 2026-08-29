# test/helpers/ — conventions

Shared test utilities: mocks and fixture loading.

## Key files

- `test/helpers/mocks.dart`
- `test/helpers/fixture_reader.dart`

## Gotchas

- Add shared `mocktail` mocks (e.g. `MockDio`, `MockMediaRepository`) here rather than
  redefining per file.
- `fixture(name)` reads `test/fixtures/$name`; put payloads in `test/fixtures/`.
- See `.ai/rules/testing.md` for full test guidance.

Parent: [`test/AGENTS.md`](../AGENTS.md) · Root: [`AGENTS.md`](../../AGENTS.md)
