import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider provider;

  setUpAll(() {
    registerFallbackValue(const SearchFilters());
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() async {
    mockRepository = MockMediaRepository();

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream<void>.empty());
    when(() => mockRepository.getQuickAddItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getQuickAddOmissions(),
    ).thenAnswer((_) async => []);

    provider = SearchProvider(mockRepository);
    await untilCalled(() => mockRepository.getQuickAddItems());
    clearInteractions(mockRepository);
  });

  group('SearchProvider - Page ceiling & client filtering', () {
    test(
      'searchMedia with client filters loads multiple pages up to ceiling of 5',
      () async {
        provider.setFilters(
          filters: const SearchFilters(type: MediaType.movie, minRating: 8.0),
        );

        // Each page returns 20 items, but only 1 per page has voteAverage >= 8.0
        when(
          () => mockRepository.searchMedia(
            'hero',
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).thenAnswer((invocation) async {
          final page = invocation.namedArguments[#page] as int;
          return List.generate(
            20,
            (i) => MediaItem(
              id: page * 100 + i,
              title: 'Hero $page-$i',
              overview: '',
              releaseDate: '2022-01-01',
              // Only 1 item per page meets the filter
              voteAverage: i == 0 ? 8.5 : 6.0,
            ),
          );
        });

        await provider.searchMedia('hero');

        // It should fetch up to maxSearchPagesBatch (5) pages because collected < 20
        verify(
          () => mockRepository.searchMedia(
            'hero',
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).called(1);
        verify(
          () => mockRepository.searchMedia(
            'hero',
            page: 2,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).called(1);
        verify(
          () => mockRepository.searchMedia(
            'hero',
            page: 5,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).called(1);

        // 5 items collected (1 per page)
        expect(provider.items.length, 5);
        expect(provider.hasMore, isTrue);
      },
    );

    test(
      'searchMedia with client filters stops early when target count is reached',
      () async {
        provider.setFilters(
          filters: const SearchFilters(type: MediaType.movie, minRating: 7.0),
        );

        // Page 1 returns 15 matches, Page 2 returns 15 matches (total 30 >= target 20)
        when(
          () => mockRepository.searchMedia(
            'hero',
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).thenAnswer((invocation) async {
          final page = invocation.namedArguments[#page] as int;
          return List.generate(
            20,
            (i) => MediaItem(
              id: page * 100 + i,
              title: 'Hero $page-$i',
              overview: '',
              releaseDate: '2022-01-01',
              voteAverage: i < 15 ? 7.5 : 5.0,
            ),
          );
        });

        await provider.searchMedia('hero');

        // Should stop after page 2 (15 + 15 = 30 >= 20)
        verify(
          () => mockRepository.searchMedia(
            'hero',
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).called(1);
        verify(
          () => mockRepository.searchMedia(
            'hero',
            page: 2,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).called(1);
        verifyNever(
          () => mockRepository.searchMedia(
            'hero',
            page: 3,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        );

        expect(provider.items.length, 30);
      },
    );

    test(
      'searchMedia stops and sets hasMore to false when TMDB returns empty results',
      () async {
        provider.setFilters(
          filters: const SearchFilters(type: MediaType.movie, minRating: 7.0),
        );

        // Page 1 has 5 results, Page 2 is empty
        when(
          () => mockRepository.searchMedia(
            'rare',
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).thenAnswer(
          (_) async => [
            const MediaItem(
              id: 1,
              title: 'Rare 1',
              overview: '',
              releaseDate: '2020',
              voteAverage: 7.5,
            ),
          ],
        );

        when(
          () => mockRepository.searchMedia(
            'rare',
            page: 2,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: MediaType.movie,
          ),
        ).thenAnswer((_) async => []);

        await provider.searchMedia('rare');

        expect(provider.items.length, 1);
        expect(provider.hasMore, isFalse);
      },
    );
  });

  group('SearchProvider - Filter mutations and reset', () {
    test('clearFilters resets to default state', () {
      provider.setFilters(
        filters: const SearchFilters(
          type: MediaType.movie,
          sort: SearchSort.rating,
          period: SearchReleasePeriod.d1990s,
          genreIds: {28},
          minRating: 7.0,
          duration: MovieDuration.under105,
          hideSeen: true,
        ),
      );

      expect(provider.filters.isEmpty, isFalse);
      expect(provider.filters.activeCount, 7);

      provider.clearFilters();

      expect(provider.filters.isEmpty, isTrue);
      expect(provider.filters.activeCount, 0);
      expect(provider.filterType, isNull);
      expect(provider.genreIds, isNull);
      expect(provider.minRating, isNull);
    });
  });
}
