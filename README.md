[Français](README.fr.md)

<p align="center">
  <img src="assets/icon/app_icon.png" alt="MediaVore icon" width="96" />
</p>

<h1 align="center">MediaVore</h1>

<p align="center">
  A local-first Flutter app to track movies and TV series you have watched or want to watch.
</p>

<p align="center">
  <a href="https://github.com/Zimberts/MediaVore/releases/latest">
    <img src="https://img.shields.io/github/v/release/Zimberts/MediaVore" alt="Latest release" />
  </a>
  <a href="https://github.com/Zimberts/MediaVore/actions/workflows/ci.yml">
    <img src="https://github.com/Zimberts/MediaVore/actions/workflows/ci.yml/badge.svg" alt="CI" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/Zimberts/MediaVore" alt="MIT License" />
  </a>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20(source)-blue" alt="Platforms" />
</p>

<p align="center">
  <a href="https://github.com/Zimberts/MediaVore/releases/latest/download/mediavore.apk">
    <strong>Download Android APK (latest)</strong>
  </a>
  &nbsp;·&nbsp;
  <a href="https://github.com/Zimberts/MediaVore/releases">All releases</a>
  &nbsp;·&nbsp;
  <a href="https://zimberts.github.io/MediaVore/">Website</a>
</p>

---

## Features

- **Home**: *Tonight* watchlist picks, *In Progress* series tracker with next-episode suggestions, and *Upcoming* movie and episode releases grouped by period.
- **Discover**: Search movies, TV series, and people on TMDB with filters (sort, decade, genres, rating, runtime, hide seen), trending titles, personalized *Because you watched* rows, and an optional swipe mode.
- **Media Details**: Ratings, *Where to Watch* streaming availability (JustWatch via TMDB), clickable cast and person pages, saga/collection tracking, collapsible seasons with episode checklists, rewatch cycles, and editable watch dates/counts (Advanced Mode).
- **Library**: Custom lists with sorting, filtering, multi-select, and sharing, alongside a daily-grouped watch history.
- **Together**: Find what to watch with friends offline — exchange watchlists via QR code, view common titles, and vote pass-the-phone style.
- **Me, Stats & Achievements**: Watch-time statistics, gamified achievements with tiers and hidden badges, 6 theme palettes (light & dark), English & French localization, and full ZIP/CSV backup & restore (append, replace, merge).

For planned features and upcoming milestones, see [GitHub Issues](https://github.com/Zimberts/MediaVore/issues) (including the [`v1.5.0`](https://github.com/Zimberts/MediaVore/labels/v1.5.0) label).

## Installation

### Android

1. Download [`mediavore.apk`](https://github.com/Zimberts/MediaVore/releases/latest/download/mediavore.apk) (and optionally [`mediavore.apk.sha256`](https://github.com/Zimberts/MediaVore/releases/latest/download/mediavore.apk.sha256)).
2. *(Optional)* Verify the download integrity:
   ```sh
   sha256sum -c mediavore.apk.sha256
   ```
   *(Versioned releases also publish `mediavore-vX.Y.Z.apk` and `mediavore-vX.Y.Z.apk.sha256`.)*
3. Allow installing apps from unknown sources if prompted by Android, then open the APK to install.

### iOS

There is no public iOS distribution at this time. Building for iOS requires Xcode and an Apple Developer account; see [DOCS/ios-release.md](DOCS/ios-release.md).

### TMDB API Key

MediaVore fetches movie and series metadata (posters, synopses, release dates, streaming providers) from The Movie Database (TMDB) using your own free personal key.

On first launch, the onboarding screen guides you to [TMDB API Settings](https://www.themoviedb.org/settings/api) to create and paste your v3 API key or v4 Read Access Token. You can also skip this step and configure it later in **Me › Settings › TMDB API Credential**.

## Development

### Prerequisites

- Flutter `3.47.6` (pinned in [`.github/workflows/ci.yml`](.github/workflows/ci.yml))
- Dart `^3.10.4` (see [`pubspec.yaml`](pubspec.yaml))

### Setup

```sh
flutter doctor
touch .env                                              # required asset, not committed
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

Install the git hooks once per clone (enforces Conventional Commits and `dart format`):

```sh
pip install pre-commit
pre-commit install
```

### Documentation

- [AGENTS.md](AGENTS.md) — architecture, conventions, and development workflow
- [DOCS/deep-links.md](DOCS/deep-links.md) — Android App Links (`assetlinks.json`) configuration
- [DOCS/i18n.md](DOCS/i18n.md) — localization guide
- [DOCS/export-format.md](DOCS/export-format.md) — ZIP/CSV backup & import format
- [DOCS/releasing.md](DOCS/releasing.md) — release process

## Contributing

Commit messages and pull request titles must follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) (`<type>(<scope>)!: <description>`). See [.ai/rules/commits.md](.ai/rules/commits.md) for the allowed types, scope conventions, and branch naming rules.

When updating documentation, please keep `README.md` and [`README.fr.md`](README.fr.md) in sync.

## Attributions & License

<a href="https://www.themoviedb.org/">
  <img src="https://www.themoviedb.org/assets/2/v4/logos/v2/blue_short-8e7b30f73a4020692ccca9c88bafe5dcb6f8a62a4c6bc55cd9ba82bb2cd95f6c.svg" alt="TMDB" width="120" />
</a>

- This product uses the TMDB API but is not endorsed or certified by TMDB.
- Streaming availability data provided by [JustWatch](https://www.justwatch.com/) via TMDB.
- Licensed under the [MIT License](LICENSE).
