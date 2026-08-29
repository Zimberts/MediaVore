# test/features/media_details/ — test conventions

Tests for the `media_details` feature, mirroring `lib/features/media_details/`.

## Key files

- `test/features/media_details/data/datasources/media_list_local_data_source_test.dart`
- `test/features/media_details/presentation/pages/media_detail_page_test.dart`
- `test/features/media_details/presentation/widgets/seen_manager_test.dart`

## Gotchas

- Datasource tests use real Isar in disposable `test/tmp_*` scratch dirs
  (`.ai/rules/testing.md`).
- Widget tests guard network with `Platform.environment.containsKey('FLUTTER_TEST')`.
- The seen-history page asserts formatted runtime text (see repo memory).

Parent: [`test/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
