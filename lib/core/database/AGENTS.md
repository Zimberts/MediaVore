# database/ — conventions

Isar instance opening and schema registration (`DatabaseModule`).

## Key files

- `lib/core/database/app_database.dart`

## Gotchas

- `DatabaseModule` (`@module`) opens Isar with the full `Isar.open([...Schema])` list.
  Every new `@collection` model's `*Schema` must be added here or it won't persist.
- Wiring and regenerate rules live in `.ai/rules/di.md` and `.ai/rules/codegen.md`.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
