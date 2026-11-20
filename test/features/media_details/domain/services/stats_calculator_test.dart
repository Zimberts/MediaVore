import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/domain/services/stats_calculator.dart';
import 'package:mediavore/features/media_details/domain/entities/stats_types.dart';

void main() {
  group('StatsCalculator - Scope filtering', () {
    final items = [
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'M1',
        seenDate: DateTime(2025, 5, 10),
        runtime: 120,
      ),
      SeenItem(
        tmdbId: 2,
        type: MediaType.movie,
        title: 'M2',
        seenDate: DateTime(2026, 1, 15),
        runtime: 90,
      ),
      SeenItem(
        tmdbId: 3,
        type: MediaType.tv,
        title: 'TV1',
        seenDate: DateTime(2026, 1, 20),
        runtime: 45,
      ),
      SeenItem(
        tmdbId: 4,
        type: MediaType.tv,
        title: 'TV2',
        seenDate: DateTime(2026, 2, 5),
        runtime: 50,
      ),
    ];

    test('filters allTime returns all items', () {
      final res = StatsCalculator.filterItems(items, scope: StatsScope.allTime);
      expect(res.length, 4);
    });

    test('filters specificYear', () {
      final res2026 = StatsCalculator.filterItems(
        items,
        scope: StatsScope.specificYear,
        year: '2026',
      );
      expect(res2026.length, 3);

      final res2025 = StatsCalculator.filterItems(
        items,
        scope: StatsScope.specificYear,
        year: '2025',
      );
      expect(res2025.length, 1);
    });

    test('filters specificMonth', () {
      final resJan = StatsCalculator.filterItems(
        items,
        scope: StatsScope.specificMonth,
        year: '2026',
        month: 'Jan',
      );
      expect(resJan.length, 2);

      final resFeb = StatsCalculator.filterItems(
        items,
        scope: StatsScope.specificMonth,
        year: '2026',
        month: 'Feb',
      );
      expect(resFeb.length, 1);
    });

    test('getAvailableYears sorts descending', () {
      final years = StatsCalculator.getAvailableYears(items);
      expect(years, ['2026', '2025']);
    });
  });

  group('StatsCalculator - Watch time and Media split', () {
    final items = [
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'M1',
        seenDate: DateTime(2026, 1, 1),
        runtime: 120,
      ),
      SeenItem(
        tmdbId: 2,
        type: MediaType.tv,
        title: 'TV1',
        seenDate: DateTime(2026, 1, 2),
        runtime: 60,
      ),
      SeenItem(
        tmdbId: 3,
        type: MediaType.tv,
        title: 'TV2',
        seenDate: DateTime(2026, 1, 3),
        runtime: 90,
      ),
    ];

    test('calculateWatchTime accurately breaks down days, hours, minutes', () {
      // Total minutes: 120 + 60 + 90 = 270 min = 4 hours 30 min = 0 days 4h 30m
      final res = StatsCalculator.calculateWatchTime(items);
      expect(res.totalMinutes, 270);
      expect(res.days, 0);
      expect(res.remainingHours, 4);
      expect(res.minutes, 30);
    });

    test('calculateMediaSplit computes counts, runtimes and percentages', () {
      final split = StatsCalculator.calculateMediaSplit(items);
      expect(split.movieCount, 1);
      expect(split.tvCount, 2);
      expect(split.movieRuntime, 120);
      expect(split.tvRuntime, 150);

      expect(split.moviePercentage(StatsMetric.entries), closeTo(33.33, 0.1));
      expect(split.tvPercentage(StatsMetric.entries), closeTo(66.67, 0.1));

      expect(split.moviePercentage(StatsMetric.runtime), closeTo(44.44, 0.1));
      expect(split.tvPercentage(StatsMetric.runtime), closeTo(55.56, 0.1));
    });
  });

  group('StatsCalculator - Top genres and Hall of fame', () {
    final items = [
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'M1',
        seenDate: DateTime(2026, 1, 1),
        runtime: 120,
        genres: const ['Action', 'Sci-Fi'],
      ),
      SeenItem(
        tmdbId: 2,
        type: MediaType.tv,
        title: 'TV1',
        seasonNumber: 1,
        episodeNumber: 1,
        seenDate: DateTime(2026, 1, 2),
        runtime: 60,
        genres: const ['Sci-Fi', 'Drama'],
      ),
      SeenItem(
        tmdbId: 2,
        type: MediaType.tv,
        title: 'TV1',
        seasonNumber: 1,
        episodeNumber: 2,
        seenDate: DateTime(2026, 1, 3),
        runtime: 60,
        genres: const ['Sci-Fi', 'Drama'],
      ),
    ];

    test('calculateTopGenres groups by genre according to metric', () {
      final genreStats = StatsCalculator.calculateTopGenres(
        items,
        metric: StatsMetric.entries,
      );
      // Sci-Fi appears in 3 items, Drama in 2, Action in 1
      expect(genreStats.first.genre, 'Sci-Fi');
      expect(genreStats.first.value, 3.0);
      expect(genreStats[1].genre, 'Drama');
      expect(genreStats[1].value, 2.0);
      expect(genreStats[2].genre, 'Action');
      expect(genreStats[2].value, 1.0);
    });

    test('calculateHallOfFame finds most watched movie, series and episode', () {
      final hof = StatsCalculator.calculateHallOfFame(
        items,
        metric: StatsMetric.entries,
      );
      expect(hof.topMovie?.title, 'M1');
      expect(hof.topMovie?.count, 1);

      expect(hof.topTV?.title, 'TV1');
      expect(hof.topTV?.count, 2);

      expect(hof.topEpisode?.title, 'TV1 S1E1');
    });
  });

  group('StatsCalculator - Decade stats', () {
    final seen = [
      SeenItem(
        tmdbId: 10,
        type: MediaType.movie,
        title: 'Classic',
        seenDate: DateTime(2026, 1, 1),
      ),
      SeenItem(
        tmdbId: 20,
        type: MediaType.movie,
        title: '90s Hit',
        seenDate: DateTime(2026, 1, 2),
      ),
      SeenItem(
        tmdbId: 30,
        type: MediaType.movie,
        title: 'Modern',
        seenDate: DateTime(2026, 1, 3),
      ),
      SeenItem(
        tmdbId: 40,
        type: MediaType.movie,
        title: 'Future',
        seenDate: DateTime(2026, 1, 4),
      ),
      SeenItem(
        tmdbId: 50,
        type: MediaType.movie,
        title: 'No Date',
        seenDate: DateTime(2026, 1, 5),
      ),
    ];

    final cached = <int, MediaItem>{
      10: const MediaItem(
        id: 10,
        title: 'Classic',
        overview: '',
        releaseDate: '1975-04-12',
        mediaType: MediaType.movie,
        voteAverage: 8.4,
      ),
      20: const MediaItem(
        id: 20,
        title: '90s Hit',
        overview: '',
        releaseDate: '1994-10-14',
        mediaType: MediaType.movie,
        voteAverage: 9.0,
      ),
      30: const MediaItem(
        id: 30,
        title: 'Modern',
        overview: '',
        releaseDate: '2015-06-20',
        mediaType: MediaType.movie,
        voteAverage: 7.2,
      ),
      40: const MediaItem(
        id: 40,
        title: 'Future',
        overview: '',
        releaseDate: '2023-11-01',
        mediaType: MediaType.movie,
        voteAverage: 6.8,
      ),
      50: const MediaItem(
        id: 50,
        title: 'No Date',
        overview: '',
        releaseDate: '', // Empty date
        mediaType: MediaType.movie,
      ),
    };

    test('calculateDecadeStats groups correctly and computes average rating', () {
      final stats = StatsCalculator.calculateDecadeStats(seen, cached);
      expect(stats.length, 4);

      final before90 = stats.firstWhere((s) => s.decadeLabel == 'Before 1990');
      expect(before90.count, 1);
      expect(before90.averageRating, closeTo(8.4, 0.01));

      final nineties = stats.firstWhere((s) => s.decadeLabel == '1990–1999');
      expect(nineties.count, 1);
      expect(nineties.averageRating, closeTo(9.0, 0.01));

      final tens = stats.firstWhere((s) => s.decadeLabel == '2010–2019');
      expect(tens.count, 1);
      expect(tens.averageRating, closeTo(7.2, 0.01));

      final twenties = stats.firstWhere((s) => s.decadeLabel == '2020 and later');
      expect(twenties.count, 1);
      expect(twenties.averageRating, closeTo(6.8, 0.01));
    });
  });

  group('StatsCalculator - Series progression', () {
    final seen = [
      SeenItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show A',
        seasonNumber: 1,
        episodeNumber: 1,
        seenDate: DateTime(2026, 1, 1),
      ),
      SeenItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show A',
        seasonNumber: 1,
        episodeNumber: 2,
        seenDate: DateTime(2026, 1, 2),
      ),
      SeenItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show A',
        seasonNumber: 1,
        episodeNumber: 2, // Re-watched same episode
        seenDate: DateTime(2026, 1, 3),
      ),
      SeenItem(
        tmdbId: 200,
        type: MediaType.tv,
        title: 'Show B',
        seasonNumber: 1,
        episodeNumber: 1,
        seenDate: DateTime(2026, 1, 4),
      ),
    ];

    final cached = <int, MediaItem>{
      100: const MediaItem(
        id: 100,
        title: 'Show A',
        overview: '',
        releaseDate: '2020-01-01',
        mediaType: MediaType.tv,
        numberOfEpisodes: 10,
      ),
      200: const MediaItem(
        id: 200,
        title: 'Show B',
        overview: '',
        releaseDate: '2022-01-01',
        mediaType: MediaType.tv,
        numberOfEpisodes: null, // Unknown total
      ),
    };

    test('calculateSeriesProgression calculates distinct episodes and progress ratio', () {
      final progression = StatsCalculator.calculateSeriesProgression(seen, cached);
      expect(progression.length, 2);

      final showA = progression.firstWhere((p) => p.tmdbId == 100);
      expect(showA.watchedEpisodes, 2); // 2 distinct episodes (ep 1 and ep 2)
      expect(showA.totalEpisodes, 10);
      expect(showA.progressRatio, closeTo(0.2, 0.01));

      final showB = progression.firstWhere((p) => p.tmdbId == 200);
      expect(showB.watchedEpisodes, 1);
      expect(showB.totalEpisodes, isNull);
      expect(showB.progressRatio, isNull);
    });
  });
}
