# services/ — conventions

Background task scheduling (workmanager).

## Key files

- `lib/core/services/background_task_service.dart`

## Gotchas

- Uses `workmanager` for `dailySync` and `refreshReturningSeries` tasks (iOS/Android
  only). Task identifiers use the `fr.zimberts.mediavore` prefix.
- The background callback re-inits DI via `init(locator)` before resolving
  `locator<MediaRepository>()`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
