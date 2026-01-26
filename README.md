# MediaVore

An app to keep track of movies, series, and books you've seen/read or want to watch/read.

---

## Table of Contents

- [About](#about)
- [Status & Features](#status--features)
- [Deep Linking](#deep-linking)
- [Quick Start](#quick-start)
- [Project Documentation](#project-documentation)
- [Contributing](#contributing)

---

## About

MediaVore helps users track media (movies, series, books), manage watch/read lists, and record when content was consumed. The project is a cross-platform Flutter app and is actively developed.

## Status & Features

- **Implemented features:** see [Implemented Features](DOCS/IMPLEMENTED_FEATURES.md) for a concise, maintained list of completed work.
- **Planned features / roadmap:** the product vision and checklists live in [Planned Features](DOCS/PLANNED_FEATURES.md).

If you want to propose or implement features, add them to the roadmap or open a PR with the completed work and move items between the documents as appropriate.

## Deep Linking

Platform-specific deep linking configuration is maintained in [Deep Linking](DOCS/DEEP_LINKING.md).

## Quick Start

If you have cloned this project on a new machine, you may encounter errors when trying to run it for the first time. This is often due to missing dependencies or stale auto-generated files that are specific to the previous development environment.

Run the following to get started (PowerShell example):

```pwsh
flutter doctor
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

These steps check your Flutter setup, fetch dependencies, and regenerate generated code.

## Project Documentation

- **Project structure & developer guidelines:** [Project Structure](DOCS/PROJECT_STRUCTURE.md)
- **Requirements:** [Requirements](DOCS/REQUIREMENTS.md)
- **Achievements:** [Achievements](DOCS/ACHIEVEMENTS.md)
- **Implemented features:** [Implemented Features](DOCS/IMPLEMENTED_FEATURES.md)
- **Planned features / roadmap:** [Planned Features](DOCS/PLANNED_FEATURES.md)
- **Deep linking details:** [Deep Linking](DOCS/DEEP_LINKING.md)

Open those files for more detail about architecture, testing, and planned work.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming, commit, and PR guidance. We use Conventional Commits for commit messages.

Format: `<type>(<scope>): <description>`

Common types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `bump`

Common scopes: `README`, `back`, `front`
