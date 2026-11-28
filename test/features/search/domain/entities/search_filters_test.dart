import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';

void main() {
  group('SearchFilters - toDiscoverParams', () {
    test('default filters should set popularity.desc and page for movies', () {
      const filters = SearchFilters();
      final params = filters.toDiscoverParams(MediaType.movie, page: 2);

      expect(params['page'], 2);
      expect(params['sort_by'], 'popularity.desc');
      expect(params.containsKey('vote_average.gte'), isFalse);
      expect(params.containsKey('vote_count.gte'), isFalse);
      expect(params.containsKey('primary_release_date.gte'), isFalse);
      expect(params.containsKey('with_genres'), isFalse);
      expect(params.containsKey('with_runtime.gte'), isFalse);
    });

    test(
      'sort by rating should set vote_average.desc and vote_count.gte floor',
      () {
        const filters = SearchFilters(sort: SearchSort.rating);
        final params = filters.toDiscoverParams(MediaType.movie);

        expect(params['sort_by'], 'vote_average.desc');
        expect(params['vote_count.gte'], 50);
      },
    );

    test('sort by date should format movie vs tv keys correctly', () {
      const filtersDesc = SearchFilters(sort: SearchSort.releaseDateDesc);
      const filtersAsc = SearchFilters(sort: SearchSort.releaseDateAsc);

      expect(
        filtersDesc.toDiscoverParams(MediaType.movie)['sort_by'],
        'primary_release_date.desc',
      );
      expect(
        filtersDesc.toDiscoverParams(MediaType.tv)['sort_by'],
        'first_air_date.desc',
      );
      expect(
        filtersAsc.toDiscoverParams(MediaType.movie)['sort_by'],
        'primary_release_date.asc',
      );
      expect(
        filtersAsc.toDiscoverParams(MediaType.tv)['sort_by'],
        'first_air_date.asc',
      );
    });

    test('release periods should map to exact date boundaries', () {
      // before1990
      final b1990 = const SearchFilters(
        period: SearchReleasePeriod.before1990,
      ).toDiscoverParams(MediaType.movie);
      expect(b1990['primary_release_date.lte'], '1989-12-31');

      // 1990s
      final d90s = const SearchFilters(
        period: SearchReleasePeriod.d1990s,
      ).toDiscoverParams(MediaType.movie);
      expect(d90s['primary_release_date.gte'], '1990-01-01');
      expect(d90s['primary_release_date.lte'], '1999-12-31');

      // 2000s
      final d00s = const SearchFilters(
        period: SearchReleasePeriod.d2000s,
      ).toDiscoverParams(MediaType.movie);
      expect(d00s['primary_release_date.gte'], '2000-01-01');
      expect(d00s['primary_release_date.lte'], '2009-12-31');

      // 2010s
      final d10s = const SearchFilters(
        period: SearchReleasePeriod.d2010s,
      ).toDiscoverParams(MediaType.movie);
      expect(d10s['primary_release_date.gte'], '2010-01-01');
      expect(d10s['primary_release_date.lte'], '2019-12-31');

      // 2020plus
      final d20s = const SearchFilters(
        period: SearchReleasePeriod.d2020plus,
      ).toDiscoverParams(MediaType.movie);
      expect(d20s['primary_release_date.gte'], '2020-01-01');
      expect(d20s.containsKey('primary_release_date.lte'), isFalse);

      // TV period mapping
      final tv90s = const SearchFilters(
        period: SearchReleasePeriod.d1990s,
      ).toDiscoverParams(MediaType.tv);
      expect(tv90s['first_air_date.gte'], '1990-01-01');
      expect(tv90s['first_air_date.lte'], '1999-12-31');
    });

    test('exactYear should take precedence over period', () {
      final params = const SearchFilters(
        period: SearchReleasePeriod.d2010s,
        exactYear: 1995,
      ).toDiscoverParams(MediaType.movie);

      expect(params['primary_release_year'], 1995);
      expect(params.containsKey('primary_release_date.gte'), isFalse);
    });

    test('genres should be sorted and comma-separated', () {
      final params = const SearchFilters(
        genreIds: {878, 28, 12},
      ).toDiscoverParams(MediaType.movie);

      expect(params['with_genres'], '12,28,878');
    });

    test('minRating should set vote_average.gte and vote_count.gte floor', () {
      final params = const SearchFilters(
        minRating: 7.0,
      ).toDiscoverParams(MediaType.movie);

      expect(params['vote_average.gte'], 7.0);
      expect(params['vote_count.gte'], 50);
    });

    test(
      'duration should set runtime bounds for movie and be omitted for tv',
      () {
        final under105 = const SearchFilters(
          duration: MovieDuration.under105,
        ).toDiscoverParams(MediaType.movie);
        expect(under105['with_runtime.lte'], 104);

        final between = const SearchFilters(
          duration: MovieDuration.between105And150,
        ).toDiscoverParams(MediaType.movie);
        expect(between['with_runtime.gte'], 105);
        expect(between['with_runtime.lte'], 150);

        final over150 = const SearchFilters(
          duration: MovieDuration.over150,
        ).toDiscoverParams(MediaType.movie);
        expect(over150['with_runtime.gte'], 151);

        // TV discover should NOT include runtime
        final tvParams = const SearchFilters(
          duration: MovieDuration.under105,
        ).toDiscoverParams(MediaType.tv);
        expect(tvParams.containsKey('with_runtime.lte'), isFalse);
      },
    );

    test('originalLanguage should be passed when non-empty', () {
      final params = const SearchFilters().toDiscoverParams(
        MediaType.movie,
        originalLanguage: 'fr',
      );
      expect(params['with_original_language'], 'fr');
    });
  });

  group('SearchFilters - matchesSearchFilters', () {
    const movie = MediaItem(
      id: 1,
      title: 'Action SciFi',
      overview: '',
      releaseDate: '1995-06-15',
      genres: ['Action', 'Science Fiction'],
      genreIds: [28, 878],
      voteAverage: 7.8,
      voteCount: 300,
      runtime: 120,
    );

    const tvShow = MediaItem(
      id: 2,
      title: 'TV Drama',
      overview: '',
      releaseDate: '2021-01-10',
      mediaType: MediaType.tv,
      genres: ['Drama'],
      genreIds: [18],
      voteAverage: 8.2,
      voteCount: 500,
    );

    test('type matching', () {
      expect(
        matchesSearchFilters(movie, const SearchFilters(type: MediaType.movie)),
        isTrue,
      );
      expect(
        matchesSearchFilters(movie, const SearchFilters(type: MediaType.tv)),
        isFalse,
      );
      expect(
        matchesSearchFilters(tvShow, const SearchFilters(type: MediaType.tv)),
        isTrue,
      );
      expect(matchesSearchFilters(tvShow, const SearchFilters()), isTrue);
    });

    test('hideSeen matching', () {
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(hideSeen: true),
          isSeen: (item) => true,
        ),
        isFalse,
      );
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(hideSeen: true),
          isSeen: (item) => false,
        ),
        isTrue,
      );
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(),
          isSeen: (item) => true,
        ),
        isTrue,
      );
    });

    test('minRating matching', () {
      expect(
        matchesSearchFilters(movie, const SearchFilters(minRating: 7.0)),
        isTrue,
      );
      expect(
        matchesSearchFilters(movie, const SearchFilters(minRating: 8.0)),
        isFalse,
      );
      expect(
        matchesSearchFilters(tvShow, const SearchFilters(minRating: 8.0)),
        isTrue,
      );
    });

    test('duration matching for movies and ignored for tv', () {
      // movie has runtime: 120
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(duration: MovieDuration.under105),
        ),
        isFalse,
      );
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(duration: MovieDuration.between105And150),
        ),
        isTrue,
      );
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(duration: MovieDuration.over150),
        ),
        isFalse,
      );

      // tv duration is ignored
      expect(
        matchesSearchFilters(
          tvShow,
          const SearchFilters(duration: MovieDuration.under105),
        ),
        isTrue,
      );
    });

    test('period matching', () {
      // movie releaseDate: 1995-06-15
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(period: SearchReleasePeriod.before1990),
        ),
        isFalse,
      );
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(period: SearchReleasePeriod.d1990s),
        ),
        isTrue,
      );
      expect(
        matchesSearchFilters(
          movie,
          const SearchFilters(period: SearchReleasePeriod.d2000s),
        ),
        isFalse,
      );

      // tv releaseDate: 2021-01-10
      expect(
        matchesSearchFilters(
          tvShow,
          const SearchFilters(period: SearchReleasePeriod.d2020plus),
        ),
        isTrue,
      );
      expect(
        matchesSearchFilters(
          tvShow,
          const SearchFilters(period: SearchReleasePeriod.d2010s),
        ),
        isFalse,
      );

      // exactYear
      expect(
        matchesSearchFilters(movie, const SearchFilters(exactYear: 1995)),
        isTrue,
      );
      expect(
        matchesSearchFilters(movie, const SearchFilters(exactYear: 2020)),
        isFalse,
      );
    });

    test('genre matching requires all specified genres to match', () {
      // movie has 28 (Action) and 878 (SciFi)
      expect(
        matchesSearchFilters(movie, const SearchFilters(genreIds: {28})),
        isTrue,
      );
      expect(
        matchesSearchFilters(movie, const SearchFilters(genreIds: {28, 878})),
        isTrue,
      );
      expect(
        matchesSearchFilters(movie, const SearchFilters(genreIds: {28, 35})),
        isFalse,
      );
    });
  });

  group('SearchFilters - sortMediaItems', () {
    const itemA = MediaItem(
      id: 1,
      title: 'Alpha',
      overview: '',
      releaseDate: '2020-01-01',
      voteAverage: 7.0,
      voteCount: 100,
    );
    const itemB = MediaItem(
      id: 2,
      title: 'Beta',
      overview: '',
      releaseDate: '2023-01-01',
      voteAverage: 8.5,
      voteCount: 200,
    );
    const itemC = MediaItem(
      id: 3,
      title: 'Gamma',
      overview: '',
      releaseDate: '1999-01-01',
      voteAverage: 8.5,
      voteCount: 50,
    );

    test('sort by rating descending with secondary voteCount', () {
      final list = [itemA, itemC, itemB];
      sortMediaItems(list, SearchSort.rating);

      // B (8.5, 200 votes) -> C (8.5, 50 votes) -> A (7.0, 100 votes)
      expect(list.map((i) => i.id).toList(), [2, 3, 1]);
    });

    test('sort by release date descending', () {
      final list = [itemA, itemB, itemC];
      sortMediaItems(list, SearchSort.releaseDateDesc);

      // 2023 -> 2020 -> 1999
      expect(list.map((i) => i.id).toList(), [2, 1, 3]);
    });

    test('sort by release date ascending', () {
      final list = [itemA, itemB, itemC];
      sortMediaItems(list, SearchSort.releaseDateAsc);

      // 1999 -> 2020 -> 2023
      expect(list.map((i) => i.id).toList(), [3, 1, 2]);
    });
  });

  group('SearchFilters - activeCount and copyWith', () {
    test('activeCount calculates active criteria correctly', () {
      const empty = SearchFilters();
      expect(empty.activeCount, 0);
      expect(empty.isEmpty, isTrue);

      final withType = empty.copyWith(type: () => MediaType.movie);
      expect(withType.activeCount, 1);

      final withSort = withType.copyWith(sort: SearchSort.rating);
      expect(withSort.activeCount, 2);

      final withPeriod = withSort.copyWith(period: SearchReleasePeriod.d2010s);
      expect(withPeriod.activeCount, 3);

      final withGenres = withPeriod.copyWith(genreIds: {28, 12});
      expect(withGenres.activeCount, 5); // 3 + 2 genres = 5

      final withRating = withGenres.copyWith(minRating: () => 7.0);
      expect(withRating.activeCount, 6);

      final withDuration = withRating.copyWith(
        duration: MovieDuration.under105,
      );
      expect(withDuration.activeCount, 7);

      final withHideSeen = withDuration.copyWith(hideSeen: true);
      expect(withHideSeen.activeCount, 8);
    });

    test('duration filter count is omitted for tv type', () {
      const tvWithDuration = SearchFilters(
        type: MediaType.tv,
        duration: MovieDuration.under105,
      );
      // type (1) + duration (0 because tv) = 1
      expect(tvWithDuration.activeCount, 1);
    });

    test(
      'should count excludedGenreIds, originalLanguage and hideUnreleased',
      () {
        const filters = SearchFilters(
          excludedGenreIds: {27, 53},
          originalLanguage: 'ja',
          hideUnreleased: true,
        );
        expect(filters.activeCount, 4);
        expect(filters.hasClientFilters, isTrue);
      },
    );
  });

  group('SearchFilters - swipe filters and serialization', () {
    test('should join genres with pipe when genresMatchAny is true', () {
      const filters = SearchFilters(genreIds: {35, 28, 12});
      final params = filters.toDiscoverParams(
        MediaType.movie,
        genresMatchAny: true,
      );
      expect(params['with_genres'], '12|28|35');
    });

    test(
      'should include without_genres when excludedGenreIds is non-empty',
      () {
        const filters = SearchFilters(excludedGenreIds: {53, 27});
        final params = filters.toDiscoverParams(MediaType.movie);
        expect(params['without_genres'], '27,53');
      },
    );

    test(
      'should cap primary_release_date.lte to today when hideUnreleased is true',
      () {
        const filters = SearchFilters(hideUnreleased: true);
        final params = filters.toDiscoverParams(
          MediaType.movie,
          now: DateTime(2026, 6, 5),
        );
        expect(params['primary_release_date.lte'], '2026-06-05');
      },
    );

    test(
      'should keep earlier period upper bound when hideUnreleased is true',
      () {
        const filters = SearchFilters(
          period: SearchReleasePeriod.d2010s,
          hideUnreleased: true,
        );
        final params = filters.toDiscoverParams(
          MediaType.movie,
          now: DateTime(2026, 6, 5),
        );
        expect(params['primary_release_date.gte'], '2010-01-01');
        expect(params['primary_release_date.lte'], '2019-12-31');
      },
    );

    test(
      'should use originalLanguage from SearchFilters when not overridden',
      () {
        const filters = SearchFilters(originalLanguage: 'fr');
        final params = filters.toDiscoverParams(MediaType.movie);
        expect(params['with_original_language'], 'fr');
      },
    );

    test('should round-trip all fields through toJson and fromJson', () {
      const original = SearchFilters(
        type: MediaType.movie,
        sort: SearchSort.rating,
        period: SearchReleasePeriod.d2000s,
        exactYear: 2005,
        genreIds: {28, 12},
        excludedGenreIds: {27},
        minRating: 7.5,
        duration: MovieDuration.between105And150,
        originalLanguage: 'ja',
        hideSeen: true,
        hideUnreleased: true,
      );

      final decoded = SearchFilters.fromJson(original.toJson());
      expect(decoded, original);
    });

    test('should fall back to defaults for unknown or missing JSON fields', () {
      final decoded = SearchFilters.fromJson({
        'type': 'not_a_type',
        'sort': 'not_a_sort',
        'period': 'not_a_period',
        'duration': 'not_a_duration',
      });
      expect(decoded, const SearchFilters());
    });

    test(
      'should match excludedGenreIds, originalLanguage and hideUnreleased client-side',
      () {
        const movie = MediaItem(
          id: 1,
          title: 'Test',
          overview: '',
          releaseDate: '2025-01-10',
          genreIds: [28, 35],
          originalLanguage: 'fr',
        );
        final today = DateTime(2025, 6);

        expect(
          matchesSearchFilters(
            movie,
            const SearchFilters(excludedGenreIds: {27}),
            now: today,
          ),
          isTrue,
        );
        expect(
          matchesSearchFilters(
            movie,
            const SearchFilters(excludedGenreIds: {28}),
            now: today,
          ),
          isFalse,
        );
        expect(
          matchesSearchFilters(
            movie,
            const SearchFilters(originalLanguage: 'fr'),
            now: today,
          ),
          isTrue,
        );
        expect(
          matchesSearchFilters(
            movie,
            const SearchFilters(originalLanguage: 'en'),
            now: today,
          ),
          isFalse,
        );
        expect(
          matchesSearchFilters(
            movie,
            const SearchFilters(hideUnreleased: true),
            now: DateTime(2024, 12, 31),
          ),
          isFalse,
        );
        expect(
          matchesSearchFilters(
            movie,
            const SearchFilters(hideUnreleased: true),
            now: today,
          ),
          isTrue,
        );
      },
    );
  });
}
