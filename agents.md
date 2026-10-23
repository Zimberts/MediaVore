# MediaVore Project Guidelines & Agent Instructions

This document provides essential context and guidelines for AI agents (GitHub Copilot, Gemini, etc.) working on the MediaVore project.

## 🛠 Project Overview
MediaVore is a Flutter application designed to track movies, series, and books. It aims to be a personal media library and watchlist.

## 🏗 Architecture & Structure
The project follows a **Feature-driven Clean Architecture**:
- **Location**: All features reside in `lib/features/`.
- **Layers**:
  - `data/`: Data Transfer Objects (DTOs), JSON serialization (`factory Model.fromJson`), and Repository implementations.
  - `domain/`: Business entities and abstract Repository interfaces.
  - `presentation/`: Widgets, Pages, and State management.
- **State Management**: Uses standard `StatefulWidget` and `setState` for now, but is architected to support migration to Bloc or Provider.

## 🚀 Tech Stack
- **Framework**: Flutter (SDK ^3.10.4)
- **Networking**: `http` package for REST calls.
- **Environment Variables**: `flutter_dotenv` (Key: `TMDB_API_TOKEN`).
- **Testing**: `mocktail` for mocking, `flutter_test` for unit/widget tests.
- **Linting**: Follows `analysis_options.yaml` (based on `flutter_lints`).

## 🎬 External APIs (TMDB)
- **Reference**: [TMDB API Documentation](https://developer.themoviedb.org/reference/getting-started)
- **Base URL**: `https://api.themoviedb.org/3`
- **Authentication**: Use `Authorization: Bearer <TMDB_API_TOKEN>` header.
- **Images**: Base URL `https://image.tmdb.org/t/p/`. Typical size: `w92` or `w500`.

## 📝 Development Standards
- **Commits**: Follow [Conventional Commits](https://www.conventionalcommits.org/).
  - Format: `<type>(<scope>): <description>`
  - Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`.
  - Scopes: `back`, `front`, `README`, `search`, `movies`, `books`.
- **Naming**: Use descriptive, intention-revealing names. Widgets should be organized in `presentation/pages` or `presentation/widgets`.
- **Code Style**: Prefer `const` constructors where possible. Ensure all network models have `fromJson` and `toJson` methods.

## 🧪 Testing Guidelines
- **Mocks**: Use `mocktail`. Shared mocks are located in `test/helpers/mocks.dart`.
- **Fixtures**: Store sample API JSON responses in `test/fixtures/`.
- **Mocktail Setup**: If using custom types in `any()`, ensure they are registered in `registerTestFallbacks()`.

## 🗺 Roadmap & Priorities
1. **Movies/Series Search**: Implement TMDB search and result listing (Current focus).
2. **Watchlist**: Local storage for "To Watch" and "Seen" lists.
3. **Ratings & History**: Ability to add manual dates and ratings.
4. **Books**: Barcode scanning and manual entry for book series.
5. **Import/Export**: CSV import functionality for existing lists.
