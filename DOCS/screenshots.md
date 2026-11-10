# Screenshots

`tool/screenshots.sh` captures every screen of the app with sample films and
series, then builds an HTML gallery. It runs offline and needs no TMDB key.

```bash
tool/screenshots.sh                 # fr, light + dark, into build/screenshots/
tool/screenshots.sh -l en -t dark   # English, dark theme only
tool/screenshots.sh -o /tmp/shots   # other output folder
python3 tool/screenshots/build_gallery.py build/screenshots --inline
                                    # single self-contained HTML file
```

Prerequisites: those of `flutter test` (`flutter pub get`,
`dart run build_runner build`). The script copies the Isar native library to
the repo root when it is missing. One theme takes about 30 s.

## Output

```
build/screenshots/
  index.html            gallery: screens per locale/theme + sample catalog
  fr-light/
    01_discover.png …   one PNG per screen, 1170 x 2532 (390 x 844 pt @3x)
    manifest.json       screen titles, locale, theme, catalog
    posters/            generated posters used by the gallery
  fr-dark/ …
```

Screens: Discover, search, movie details (top and cast), actor, lists,
history, series details, alerts (releases and quick add), profile, stats,
achievements, settings.

## How it works

`test/screenshots/capture_screens.dart` is a widget test (no `_test` suffix,
so `flutter test` does not run it with the suite). It runs the real app
(`init(locator)`, Isar, repository, providers, pages) and replaces only the
edges:

| Edge | Replacement |
| --- | --- |
| TMDB API | `DemoTmdbInterceptor` on the app's `Dio` answers from `demo_catalog.dart` |
| TMDB images | `DemoHttpOverrides` serves posters drawn with `dart:ui` (`demo_images.dart`) |
| Plugins | in-memory path_provider, shared_preferences, secure storage, app_links |
| Fonts | Roboto and Material icons loaded from the Flutter SDK |

The library is then seeded through `MediaRepository` (lists, likes, a year of
viewing history, alerts) and the test navigates the UI, capturing each screen
from a `RepaintBoundary`. Dates are relative to the run date, so upcoming
episodes stay upcoming.

`debugForceNetworkImages` (`lib/core/utils/network_images.dart`) lets the
pages load images under `flutter test`, which they skip by default.

## Sample data

Titles, years, genres and cast are those of real works; ratings, runtimes,
episode lists and streaming availability are rounded or illustrative, and
overviews and biographies are written for the demo. No TMDB artwork is used.

To add a screen, add a navigation step and a `_shot(...)` call in
`capture_screens.dart`; to add a title, add a `DemoMedia` to `demoCatalog`.
