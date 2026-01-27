import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider provider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
    registerFallbackValue(ImportMode.append);
  });

  setUp(() {
    mockRepository = MockMediaRepository();

    // Basic stubs used by SearchProvider during initialization
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);

    provider = SearchProvider(mockRepository);
  });

  group('Export/Import round-trip', () {
    test('exported data is returned by provider', () async {
      final sample = [
        {
          'tmdbId': 1,
          'type': 'movie',
          'title': 'Sample',
          'posterPath': '/p.jpg',
          'seenDate': DateTime(2023, 1, 1).toIso8601String(),
        },
      ];

      when(
        () => mockRepository.exportSeenData(
          start: any(named: 'start'),
          end: any(named: 'end'),
          tmdbId: any(named: 'tmdbId'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => sample);

      final result = await provider.exportSeenData();
      expect(result, equals(sample));
    });

    test('import triggers progress updates and refreshes seen state', () async {
      // We'll control what getSeenItems returns before and after import
      var currentSeen = <SeenItem>[];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => currentSeen);

      // Stub importSeenData to call the onProgress callback and then update currentSeen
      when(
        () => mockRepository.importSeenData(
          any(),
          mode: any(named: 'mode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        // Extract the named onProgress callback from the invocation
        final onProgress =
            invocation.namedArguments[#onProgress] as Function(double, String)?;
        onProgress?.call(0.0, 'Starting');
        await Future<void>.delayed(const Duration(milliseconds: 1));
        onProgress?.call(0.5, 'Halfway');
        await Future<void>.delayed(const Duration(milliseconds: 1));

        // Simulate that import added one seen item
        currentSeen = [
          SeenItem(
            id: 10,
            tmdbId: 42,
            type: MediaType.movie,
            title: 'Imported',
            seenDate: DateTime.now(),
          ),
        ];

        onProgress?.call(1.0, 'Saving entries...');
        return Future.value();
      });

      // Ensure other refresh calls don't throw
      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
      when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);

      final importData = [
        {
          'tmdbId': 42,
          'type': 'movie',
          'title': 'Imported',
          'posterPath': null,
          'seenDate': DateTime.now().toIso8601String(),
        },
      ];

      final importFuture = provider.importSeenData(
        importData,
        mode: ImportMode.append,
      );

      // After starting, provider should report importing state and progress updates will be applied
      expect(provider.isImporting, isTrue);

      await importFuture;

      // After import completes, provider should have refreshed seen items
      expect(provider.isImporting, isFalse);
      expect(provider.seenItems, isNotEmpty);
      expect(provider.seenItems.first.tmdbId, equals(42));
    });
  });
}
