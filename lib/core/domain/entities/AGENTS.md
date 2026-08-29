# domain/entities/ — conventions

Shared, cross-feature domain entities (Equatable, hand-written JSON).

## Key files

- `lib/core/domain/entities/media_item.dart`
- `lib/core/domain/entities/media_details.dart`
- `lib/core/domain/entities/seen_item.dart`
- `lib/core/domain/entities/actor_details.dart`
- `lib/core/domain/entities/cast_member.dart`

## Gotchas

- Entities use `equatable` for value equality and **hand-written** `fromJson`/`toJson`
  (no `json_serializable`/`freezed` — see `.ai/rules/dependencies.md`).
- `MediaType` enum (`movie|tv|person|unknown`) is declared in `media_item.dart`.
- These are the canonical entities consumed by `MediaRepository` across features.

Parent: [`lib/AGENTS.md`](../../../AGENTS.md) · Root: [`AGENTS.md`](../../../../AGENTS.md)
