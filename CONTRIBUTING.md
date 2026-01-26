# Contributing to MediaVore

Thanks for your interest in contributing! This document contains guidelines to make contributions consistent and easy to review.

## How to contribute

- Fork the repository or create a branch on the main repo according to your workflow.
- Create a branch per change using the issue-first convention: `<issue-number>-<short-description>`.
  - Examples: `123-add-watchlist-ui`, `45-fix-null-poster`
- Keep PRs small and focused; prefer multiple small PRs over one large PR.

## Branch & PR conventions

- Branch names: `<issue-number>-<short-description>` where `<issue-number>` is the main issue or ticket number (without a `#`).
- If you are not using an issue tracker for a small change, you may use `local-<short-description>`.
- Base branch for work: follow the repository workflow (default branch or feature branches used by maintainers).
- Open a PR and include a short description of the change, tests added, and manual verification steps.

## Commit messages

Use Conventional Commits: `<type>(<scope>): <short description>`

- Examples: `feat(front): add watchlist sorting`, `fix(back): handle null poster paths`
- Common types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `bump`.

## Code style & testing

- Follow existing code style in `lib/` and tests in `test/`.
- Add unit tests for logic where feasible. Widget tests are encouraged for UI components.
- Run tests locally before opening a PR:

```pwsh
flutter test
```

- If code generation is required, run:

```pwsh
flutter pub run build_runner build --delete-conflicting-outputs
```

## Review checklist for PRs

- [ ] Builds and tests pass locally
- [ ] Code is adequately covered by tests or manual verification steps provided
- [ ] No unrelated changes included
- [ ] Commit messages follow Conventional Commits

## Communication

- Open issues for larger design discussions before starting work.
- Mention maintainers or reviewers in PRs as needed.

## Getting help

If you need help setting up or reproducing an issue, open an issue with reproduction steps and environment details.
