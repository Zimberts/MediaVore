# error/ — conventions

Application exception hierarchy.

## Key files

- `lib/core/error/exceptions.dart`

## Gotchas

- Single base class `AppException` with subclasses: `ServerException`,
  `NetworkException`, `ParsingException`, `ConfigurationException`.
- Datasources throw these; presentation maps them to user-facing messages. Add new
  typed errors here rather than using bare `Exception`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
