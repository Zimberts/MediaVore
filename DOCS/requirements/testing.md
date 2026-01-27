# Testing Requirements

Purpose: define test coverage targets and local developer checks to ensure quality. CI is optional and postponed for now.

- **Test types**: Maintain unit tests for domain logic, widget tests for UI components, and integration tests for end-to-end flows (deep links, offline, cache operations).
- **Coverage targets**: Aim for at least 80% coverage for core domain modules; track coverage artifacts locally or via optional tooling.
- **Deterministic tests**: Tests should avoid network dependence; use fixtures and network stubs where possible.
- **Local checks**: Document developer commands to run `flutter analyze`, `flutter test`, and formatting checks locally.
- **Test data**: Provide a small test dataset for integration tests and document how to regenerate it.
- **Device matrix**: Run critical integration tests on representative device/emulator configurations (Android API levels and iOS versions supported) during release verification.

Testable acceptance criteria:

- Developer runs `flutter analyze` and `flutter test` locally without errors for core modules.
- Integration tests cover deep link cold/warm start and cache fill/clear flows.
