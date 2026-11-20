import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/media_details/domain/entities/stats_types.dart';

/// Month keys 1-12 matching 'Jan'..'Dec'.
const statsMonthKeys = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String statsMonthKey(DateTime date) => statsMonthKeys[date.month - 1];

class WatchTimeResult {
  final int days;
  final int remainingHours;
  final int minutes;
  final int totalMinutes;

  const WatchTimeResult({
    required this.days,
    required this.remainingHours,
    required this.minutes,
    required this.totalMinutes,
  });
}

class MediaSplitResult {
  final int movieCount;
  final int tvCount;
  final int movieRuntime;
  final int tvRuntime;

  const MediaSplitResult({
    required this.movieCount,
    required this.tvCount,
    required this.movieRuntime,
    required this.tvRuntime,
  });

  double moviePercentage(StatsMetric metric) {
    if (metric == StatsMetric.entries) {
      final total = movieCount + tvCount;
      return total > 0 ? (movieCount / total) * 100 : 0.0;
    } else {
      final total = movieRuntime + tvRuntime;
      return total > 0 ? (movieRuntime / total) * 100 : 0.0;
    }
  }

  double tvPercentage(StatsMetric metric) {
    if (metric == StatsMetric.entries) {
      final total = movieCount + tvCount;
      return total > 0 ? (tvCount / total) * 100 : 0.0;
    } else {
      final total = movieRuntime + tvRuntime;
      return total > 0 ? (tvRuntime / total) * 100 : 0.0;
    }
  }
}

class GenreStatItem {
  final String genre;
  final double value;
  final double percentage;

  const GenreStatItem({
    required this.genre,
    required this.value,
    required this.percentage,
  });
}

class DecadeStatItem {
  final String decadeLabel;
  final int count;
  final double? averageRating;

  const DecadeStatItem({
    required this.decadeLabel,
    required this.count,
    this.averageRating,
  });
}

class SeriesProgressionItem {
  final int tmdbId;
  final String title;
  final String? posterPath;
  final int watchedEpisodes;
  final int? totalEpisodes;

  const SeriesProgressionItem({
    required this.tmdbId,
    required this.title,
    this.posterPath,
    required this.watchedEpisodes,
    this.totalEpisodes,
  });

  double? get progressRatio {
    if (totalEpisodes == null || totalEpisodes! <= 0) return null;
    return (watchedEpisodes / totalEpisodes!).clamp(0.0, 1.0);
  }
}

class HallOfFameEntry {
  final String title;
  final int count;
  final int runtime;

  const HallOfFameEntry({
    required this.title,
    required this.count,
    required this.runtime,
  });
}

class HallOfFameResult {
  final HallOfFameEntry? topMovie;
  final HallOfFameEntry? topTV;
  final HallOfFameEntry? topEpisode;

  const HallOfFameResult({
    this.topMovie,
    this.topTV,
    this.topEpisode,
  });
}

/// Pure static calculator extracting all statistical calculations from the UI.
class StatsCalculator {
  const StatsCalculator._();

  /// Filters [items] according to the selected [scope], [year], and [month].
  static List<SeenItem> filterItems(
    List<SeenItem> items, {
    required StatsScope scope,
    String? year,
    String? month,
  }) {
    return items.where((i) {
      if (scope == StatsScope.allTime) return true;

      final yearMatch = i.seenDate.year.toString() == year;
      if (scope == StatsScope.specificYear) return yearMatch;

      final monthMatch = statsMonthKey(i.seenDate) == month;
      return yearMatch && monthMatch;
    }).toList();
  }

  /// Extracts available sorted years (newest first).
  static List<String> getAvailableYears(List<SeenItem> items) {
    final years = items.map((i) => i.seenDate.year.toString()).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  /// Computes the total watch time breakdown.
  static WatchTimeResult calculateWatchTime(List<SeenItem> items) {
    final totalMinutes = items.fold<int>(
      0,
      (sum, item) => sum + (item.runtime ?? 0),
    );
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    return WatchTimeResult(
      days: days,
      remainingHours: remainingHours,
      minutes: minutes,
      totalMinutes: totalMinutes,
    );
  }

  /// Computes the media split between movies and TV episodes.
  static MediaSplitResult calculateMediaSplit(List<SeenItem> items) {
    var movieCount = 0;
    var tvCount = 0;
    var movieRuntime = 0;
    var tvRuntime = 0;

    for (final item in items) {
      final runtime = item.runtime ?? 0;
      if (item.type == MediaType.movie) {
        movieCount++;
        movieRuntime += runtime;
      } else {
        tvCount++;
        tvRuntime += runtime;
      }
    }

    return MediaSplitResult(
      movieCount: movieCount,
      tvCount: tvCount,
      movieRuntime: movieRuntime,
      tvRuntime: tvRuntime,
    );
  }

  /// Computes the top genres according to [metric].
  static List<GenreStatItem> calculateTopGenres(
    List<SeenItem> items, {
    required StatsMetric metric,
    int limit = 8,
    String Function(int genreId)? genreIdLocalizer,
  }) {
    final genreData = <String, double>{};
    double totalValue = 0;

    for (final item in items) {
      final value = metric == StatsMetric.entries
          ? 1.0
          : (item.runtime?.toDouble() ?? 0.0);
      totalValue += value;

      if (item.genres != null) {
        for (final rawGenre in item.genres!) {
          final genreId = GenreUtils.getGenreIdByName(rawGenre);
          final genreName = genreId != null && genreIdLocalizer != null
              ? genreIdLocalizer(genreId)
              : rawGenre;
          genreData[genreName] = (genreData[genreName] ?? 0) + value;
        }
      }
    }

    if (totalValue <= 0) return const [];

    final sortedEntries = genreData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).map((e) {
      final percentage = (e.value / totalValue) * 100;
      return GenreStatItem(
        genre: e.key,
        value: e.value,
        percentage: percentage,
      );
    }).toList();
  }

  /// Computes the Hall of Fame for movies, series, and episodes.
  static HallOfFameResult calculateHallOfFame(
    List<SeenItem> items, {
    required StatsMetric metric,
  }) {
    final Map<int, (String title, int count, int runtime)> movieCounts = {};
    final Map<int, (String title, int count, int runtime)> tvCounts = {};
    final Map<String, (String title, int count, int runtime)> episodeCounts = {};

    for (final item in items) {
      if (item.type == MediaType.movie) {
        final existing = movieCounts[item.tmdbId] ?? (item.title, 0, 0);
        movieCounts[item.tmdbId] = (
          existing.$1,
          existing.$2 + 1,
          existing.$3 + (item.runtime ?? 0),
        );
      } else {
        final existing = tvCounts[item.tmdbId] ?? (item.title, 0, 0);
        tvCounts[item.tmdbId] = (
          existing.$1,
          existing.$2 + 1,
          existing.$3 + (item.runtime ?? 0),
        );

        if (item.seasonNumber != null && item.episodeNumber != null) {
          final epKey =
              '${item.tmdbId}_${item.seasonNumber}_${item.episodeNumber}';
          final epTitle =
              '${item.title} S${item.seasonNumber}E${item.episodeNumber}';
          final existingEp = episodeCounts[epKey] ?? (epTitle, 0, 0);
          episodeCounts[epKey] = (
            existingEp.$1,
            existingEp.$2 + 1,
            existingEp.$3 + (item.runtime ?? 0),
          );
        }
      }
    }

    HallOfFameEntry? toEntry(
      (String title, int count, int runtime)? record,
    ) {
      if (record == null) return null;
      return HallOfFameEntry(
        title: record.$1,
        count: record.$2,
        runtime: record.$3,
      );
    }

    return HallOfFameResult(
      topMovie: toEntry(_findTop(movieCounts, metric)),
      topTV: toEntry(_findTop(tvCounts, metric)),
      topEpisode: toEntry(_findTop(episodeCounts, metric)),
    );
  }

  static (String, int, int)? _findTop<K>(
    Map<K, (String title, int count, int runtime)> map,
    StatsMetric metric,
  ) {
    if (map.isEmpty) return null;
    return map.values.reduce((a, b) {
      if (metric == StatsMetric.entries) {
        return a.$2 >= b.$2 ? a : b;
      } else {
        return a.$3 >= b.$3 ? a : b;
      }
    });
  }

  /// Computes stats by release decade.
  /// [cachedItems] maps `tmdbId` to cached [MediaItem].
  /// Ignores items without release date data.
  static List<DecadeStatItem> calculateDecadeStats(
    List<SeenItem> allItems,
    Map<int, MediaItem> cachedItems, {
    String before1990Label = 'Before 1990',
    String after2020Label = '2020 and later',
  }) {
    // Map of decade keys to counts and rating sums
    final distinctMedia = <(int, MediaType)>{};
    for (final item in allItems) {
      distinctMedia.add((item.tmdbId, item.type));
    }

    final decadeCounts = <String, int>{
      before1990Label: 0,
      '1990–1999': 0,
      '2000–2009': 0,
      '2010–2019': 0,
      after2020Label: 0,
    };

    final decadeRatingSums = <String, double>{
      before1990Label: 0.0,
      '1990–1999': 0.0,
      '2000–2009': 0.0,
      '2010–2019': 0.0,
      after2020Label: 0.0,
    };

    final decadeRatingCounts = <String, int>{
      before1990Label: 0,
      '1990–1999': 0,
      '2000–2009': 0,
      '2010–2019': 0,
      after2020Label: 0,
    };

    for (final key in distinctMedia) {
      final media = cachedItems[key.$1];
      if (media == null) continue;
      final yearStr = media.releaseDate;
      if (yearStr.length < 4) continue;
      final year = int.tryParse(yearStr.substring(0, 4));
      if (year == null) continue;

      String decadeKey;
      if (year < 1990) {
        decadeKey = before1990Label;
      } else if (year <= 1999) {
        decadeKey = '1990–1999';
      } else if (year <= 2009) {
        decadeKey = '2000–2009';
      } else if (year <= 2019) {
        decadeKey = '2010–2019';
      } else {
        decadeKey = after2020Label;
      }

      decadeCounts[decadeKey] = (decadeCounts[decadeKey] ?? 0) + 1;
      if (media.voteAverage != null && media.voteAverage! > 0) {
        decadeRatingSums[decadeKey] =
            (decadeRatingSums[decadeKey] ?? 0.0) + media.voteAverage!;
        decadeRatingCounts[decadeKey] =
            (decadeRatingCounts[decadeKey] ?? 0) + 1;
      }
    }

    // Only return decades in order
    final orderedKeys = [
      before1990Label,
      '1990–1999',
      '2000–2009',
      '2010–2019',
      after2020Label,
    ];

    return orderedKeys.map((key) {
      final count = decadeCounts[key] ?? 0;
      final ratingCount = decadeRatingCounts[key] ?? 0;
      final avgRating = ratingCount > 0
          ? (decadeRatingSums[key]! / ratingCount)
          : null;
      return DecadeStatItem(
        decadeLabel: key,
        count: count,
        averageRating: avgRating,
      );
    }).where((item) => item.count > 0).toList();
  }

  /// Computes series progression (episodes seen / total episodes)
  /// for series started in history.
  static List<SeriesProgressionItem> calculateSeriesProgression(
    List<SeenItem> allItems,
    Map<int, MediaItem> cachedItems,
  ) {
    final tvItems = allItems.where((i) => i.type == MediaType.tv).toList();
    if (tvItems.isEmpty) return const [];

    // Group watched distinct episodes by series tmdbId
    final Map<int, Set<String>> watchedEpisodes = {};
    final Map<int, (String title, String? posterPath)> seriesInfo = {};

    for (final item in tvItems) {
      final key = item.tmdbId;
      final epKey = item.seasonNumber != null && item.episodeNumber != null
          ? 's${item.seasonNumber}e${item.episodeNumber}'
          : 'item_${item.id ?? item.seenDate.millisecondsSinceEpoch}';
      watchedEpisodes.putIfAbsent(key, () => {}).add(epKey);
      seriesInfo[key] = (item.title, item.posterPath);
    }

    final results = <SeriesProgressionItem>[];
    for (final entry in watchedEpisodes.entries) {
      final id = entry.key;
      final count = entry.value.length;
      final info = seriesInfo[id];
      final cached = cachedItems[id];

      results.add(
        SeriesProgressionItem(
          tmdbId: id,
          title: cached?.title ?? info?.$1 ?? 'Unknown Series',
          posterPath: cached?.posterPath ?? info?.$2,
          watchedEpisodes: count,
          totalEpisodes: cached?.numberOfEpisodes,
        ),
      );
    }

    // Sort by watched count descending
    results.sort((a, b) => b.watchedEpisodes.compareTo(a.watchedEpisodes));
    return results;
  }
}
