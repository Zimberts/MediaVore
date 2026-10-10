# Project Guidelines

Flutter/Dart app to track media seen. See `README.md` for the product overview and
`DOCS/export-format.md` for the import/export format.

## Code Style

- Files/dirs `snake_case`; classes `PascalCase`; members `camelCase`; private with `_`.
- Use `debugPrint`, never `print`.
- Naming suffixes: `Provider`, `Repository` / `RepositoryImpl`, `DataSource`.
- Lint is enforced by `analysis_options.yaml` (stock `package:flutter_lints/flutter.yaml`,
  no custom rules). Don't add linter config here; rely on `flutter analyze`.

## Architecture

Feature-first, layered under `lib/features/<feature>/{data,domain,presentation}`.
Shared entities live in `lib/core/domain/entities/`.

The layers are **asymmetric** — do not assume every feature has all three:

| Feature | Layers present |
| --- | --- |
| `achievements`, `search` | full `data` + `domain` + `presentation` |
| `media_details` | `data` + `presentation` (no `domain`; entities in `lib/core`) |
| `discovery`, `settings` | `presentation` only |

Key wiring:

- **DI** — get_it + injectable (`@LazySingleton(as: X)`, `@module`, `@InjectableInit`).
  Entry point `lib/core/di/injection.dart`; DB in `lib/core/database/app_database.dart`;
  initialized in `main.dart` via `await init(locator)`.
- **State** — provider `ChangeNotifier`, wired in `MultiProvider` in `main.dart`
  (`SearchProvider`, `SettingsProvider`, `AchievementProvider`).
- **Errors** — `AppException` hierarchy in `lib/core/error/exceptions.dart`.

`search` owns `MediaRepository`. For deeper context see `DOCS/ai-guidelines.md`.

## Build and Test

Run from the repo root:

```bash
flutter doctor                                            # check environment
flutter pub get                                           # install deps
dart run build_runner build                               # REQUIRED after fresh clone
flutter analyze                                           # lint
flutter test                                              # tests
```

`build_runner` regenerates gitignored Isar `*.g.dart` and injectable
`injection.config.dart`. Always run it after a fresh clone or when models/DI change.

## Conventions

- **Commits** — Conventional Commits: `<type>(<scope>): <desc>`. Types `feat`/`fix`/`chore`/`bump`; scopes `README`/`back`/`front`.
- **Tests** — mirror source path + `_test.dart`; `group('...', () { test('should ...', ...) })`.
  Mock with `mocktail`; shared mocks in `test/helpers/mocks.dart`; load fixtures with
  `fixture(name)` from `test/helpers/fixture_reader.dart`. Real Isar tests use `test/tmp_*`
  scratch dirs; widget tests guard with `Platform.environment.containsKey('FLUTTER_TEST')`.

## Gotchas

- **Generated files** — `*.g.dart` and `*.config.dart` are gitignored; regenerate with
  build_runner, never hand-edit.
- **Isar** — persistence comes from the community fork `isar_community` (v3 API), **not**
  the upstream `isar` package, which is abandoned and ships 4 KB-aligned Android
  binaries. Do not switch back; imports are `package:isar_community/isar.dart`.
- **Achievements** — source of truth is `assets/achievements/definitions.json` (stable ids).
  `ACHIEVEMENTS.md` is a non-authoritative summary; don't treat it as the schema.
- **Config** — `.env` is bundled as an asset but never referenced in code; the TMDB key is
  stored in SharedPreferences under `tmdbApiKey`.
- **i18n** — no l10n/`.arb`; `intl` is used for formatting only.
- **Scratch** — `test/tmp_*` dirs and `test/tmp_io_test.dart` are disposable; ignore them.

## Workflow

Write Conventional Commit messages per the rules above (`<type>(<scope>): <desc>`).
Verify with `flutter analyze` and `flutter test` before considering a change done.
