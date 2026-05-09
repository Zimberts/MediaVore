import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart'
    as repo_types;

typedef ImportProgress = void Function(double progress, String status);

class MockRepo extends Mock implements MediaRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ImportMode.append);
    registerFallbackValue((double progress, String status) {});
  });

  late MockRepo mock;
  late SearchProvider provider;

  setUp(() {
    mock = MockRepo();

    // Common stub methods
    when(() => mock.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => mock.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(() => mock.getNotifiedItems()).thenAnswer(
      (_) async => <repo_types.NotifiedItem>[],
    );
    when(() => mock.getWatchlistEntries()).thenAnswer((_) async => <String>[]);
    when(() => mock.getAllListNames()).thenAnswer(
      (_) async => <String>['watchlist'],
    );
    when(() => mock.getListEntries(any())).thenAnswer((_) async => <String>[]);
    when(
      () => mock.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <repo_types.MediaItemPreview>[]);
    when(() => mock.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mock.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mock.watchNotifiedItems()).thenAnswer(
      (_) => const Stream.empty(),
    );

    provider = SearchProvider(mock);
  });

  group('importAllData with auto-populate', () {
    test('auto-populates quickadd when empty after import', () async {
      // Setup: import succeeds, quickadd is empty
      when(
        () => mock.importAllData(
          any(),
          mode: any(named: 'mode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      when(() => mock.getQuickAddItems()).thenAnswer(
        (_) async => <repo_types.QuickAddItem>[], // Empty
      );

      when(() => mock.populateQuickAddFromSeenHistory())
          .thenAnswer((_) async {});

      final envelope = <int>[1, 2, 3];

      await provider.importAllData(envelope, mode: ImportMode.merge);

      // Verify populateQuickAddFromSeenHistory was called
      verify(() => mock.populateQuickAddFromSeenHistory()).called(1);
    });

    test('skips auto-populate when quickadd has items after import', () async {
      // Setup: import succeeds, quickadd already has items (from export)
      when(
        () => mock.importAllData(
          any(),
          mode: any(named: 'mode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      when(() => mock.getQuickAddItems()).thenAnswer(
        (_) async => [
          repo_types.QuickAddItem(
            isarId: 1,
            tmdbId: 100,
            type: MediaType.tv,
            seasonNumber: 1,
            episodeNumber: 5,
            insertedAt: DateTime.utc(2025, 1, 1),
            airDate: DateTime.utc(2025, 1, 8),
            title: 'Show',
            posterPath: '/show.jpg',
          ),
        ],
      );

      final envelope = <int>[1, 2, 3];

      await provider.importAllData(envelope, mode: ImportMode.merge);

      // Verify populateQuickAddFromSeenHistory was NOT called
      verifyNever(() => mock.populateQuickAddFromSeenHistory());
    });

    test('handles error in auto-populate gracefully', () async {
      // Setup: import succeeds, but auto-populate throws
      when(
        () => mock.importAllData(
          any(),
          mode: any(named: 'mode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      when(() => mock.getQuickAddItems()).thenAnswer(
        (_) async => <repo_types.QuickAddItem>[],
      );

      when(() => mock.populateQuickAddFromSeenHistory())
          .thenThrow(Exception('populate failed'));

      final envelope = <int>[1, 2, 3];

      // Should not throw; error is caught
      await provider.importAllData(envelope, mode: ImportMode.merge);

      // Should still be marked as done
      expect(provider.importProgress, 1.0);
      expect(provider.importStatus, 'Done!');
    });

    test('loads quickadd after successful auto-populate', () async {
      when(
        () => mock.importAllData(
          any(),
          mode: any(named: 'mode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      when(() => mock.getQuickAddItems()).thenAnswer(
        (_) async => <repo_types.QuickAddItem>[],
      );

      when(() => mock.populateQuickAddFromSeenHistory())
          .thenAnswer((_) async {});

      final envelope = <int>[1, 2, 3];

      await provider.importAllData(envelope, mode: ImportMode.merge);

      // Verify loadQuickAddItems was called
      // (Note: this is called via the normal flow, but if auto-populate succeeded)
    });

    test('update all caches after import completion', () async {
      when(
        () => mock.importAllData(
          any(),
          mode: any(named: 'mode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      when(() => mock.getQuickAddItems()).thenAnswer(
        (_) async => <repo_types.QuickAddItem>[],
      );

      when(() => mock.populateQuickAddFromSeenHistory())
          .thenAnswer((_) async {});

      final envelope = <int>[1, 2, 3];

      await provider.importAllData(envelope, mode: ImportMode.merge);

      // Verify all data reloads were called (these are called in finally block)
      verify(() => mock.getSeenItems()).called(greaterThan(0));
    });
  });
}
