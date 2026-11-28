import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/services/search_relevance.dart';

/// Available sorting modes for search and discovery.
enum SearchSort { relevance, rating, releaseDateDesc, releaseDateAsc }

/// Release period categories.
enum SearchReleasePeriod { all, before1990, d1990s, d2000s, d2010s, d2020plus }

/// Movie duration categories (applies to films only).
enum MovieDuration { all, under105, between105And150, over150 }

/// Immutable search and discovery filter state.
class SearchFilters extends Equatable {
  final MediaType? type;
  final SearchSort sort;
  final SearchReleasePeriod period;
  final int? exactYear;
  final Set<int> genreIds;
  final Set<int> excludedGenreIds;
  final double? minRating;
  final MovieDuration duration;
  final String? originalLanguage;
  final bool hideSeen;
  final bool hideUnreleased;

  const SearchFilters({
    this.type,
    this.sort = SearchSort.relevance,
    this.period = SearchReleasePeriod.all,
    this.exactYear,
    this.genreIds = const {},
    this.excludedGenreIds = const {},
    this.minRating,
    this.duration = MovieDuration.all,
    this.originalLanguage,
    this.hideSeen = false,
    this.hideUnreleased = false,
  });

  /// Total count of active filters.
  int get activeCount {
    var count = 0;
    if (type != null) count++;
    if (sort != SearchSort.relevance) count++;
    if (period != SearchReleasePeriod.all || exactYear != null) count++;
    count += genreIds.length;
    count += excludedGenreIds.length;
    if (minRating != null) count++;
    if (duration != MovieDuration.all && type != MediaType.tv) count++;
    if (originalLanguage != null && originalLanguage!.isNotEmpty) count++;
    if (hideSeen) count++;
    if (hideUnreleased) count++;
    return count;
  }

  bool get isEmpty => activeCount == 0;
  bool get hasActiveFilters => isNotEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Whether results from text `/search` must be filtered client-side.
  bool get hasClientFilters =>
      sort != SearchSort.relevance ||
      period != SearchReleasePeriod.all ||
      exactYear != null ||
      genreIds.isNotEmpty ||
      excludedGenreIds.isNotEmpty ||
      minRating != null ||
      (duration != MovieDuration.all && type != MediaType.tv) ||
      (originalLanguage != null && originalLanguage!.isNotEmpty) ||
      hideSeen ||
      hideUnreleased;

  SearchFilters copyWith({
    MediaType? Function()? type,
    SearchSort? sort,
    SearchReleasePeriod? period,
    int? Function()? exactYear,
    Set<int>? genreIds,
    Set<int>? excludedGenreIds,
    double? Function()? minRating,
    MovieDuration? duration,
    String? Function()? originalLanguage,
    bool? hideSeen,
    bool? hideUnreleased,
  }) {
    return SearchFilters(
      type: type != null ? type() : this.type,
      sort: sort ?? this.sort,
      period: period ?? this.period,
      exactYear: exactYear != null ? exactYear() : this.exactYear,
      genreIds: genreIds ?? this.genreIds,
      excludedGenreIds: excludedGenreIds ?? this.excludedGenreIds,
      minRating: minRating != null ? minRating() : this.minRating,
      duration: duration ?? this.duration,
      originalLanguage: originalLanguage != null
          ? originalLanguage()
          : this.originalLanguage,
      hideSeen: hideSeen ?? this.hideSeen,
      hideUnreleased: hideUnreleased ?? this.hideUnreleased,
    );
  }

  /// Serializes this filter state into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final sortedGenres = genreIds.toList()..sort();
    final sortedExcluded = excludedGenreIds.toList()..sort();
    return {
      if (type != null) 'type': type!.name,
      'sort': sort.name,
      'period': period.name,
      if (exactYear != null) 'exactYear': exactYear,
      'genreIds': sortedGenres,
      'excludedGenreIds': sortedExcluded,
      if (minRating != null) 'minRating': minRating,
      'duration': duration.name,
      if (originalLanguage != null && originalLanguage!.isNotEmpty)
        'originalLanguage': originalLanguage,
      'hideSeen': hideSeen,
      'hideUnreleased': hideUnreleased,
    };
  }

  /// Restores a [SearchFilters] instance from a JSON map.
  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final parsedType = typeName == null
        ? null
        : MediaType.values.where((t) => t.name == typeName).firstOrNull;

    final sortName = json['sort'] as String?;
    final parsedSort = SearchSort.values.firstWhere(
      (s) => s.name == sortName,
      orElse: () => SearchSort.relevance,
    );

    final periodName = json['period'] as String?;
    final parsedPeriod = SearchReleasePeriod.values.firstWhere(
      (p) => p.name == periodName,
      orElse: () => SearchReleasePeriod.all,
    );

    final durationName = json['duration'] as String?;
    final parsedDuration = MovieDuration.values.firstWhere(
      (d) => d.name == durationName,
      orElse: () => MovieDuration.all,
    );

    final rawGenres = json['genreIds'] as List<dynamic>?;
    final parsedGenres =
        rawGenres?.whereType<num>().map((e) => e.toInt()).toSet() ?? const {};

    final rawExcluded = json['excludedGenreIds'] as List<dynamic>?;
    final parsedExcluded =
        rawExcluded?.whereType<num>().map((e) => e.toInt()).toSet() ?? const {};

    final rawRating = json['minRating'] as num?;
    final rawLang = json['originalLanguage'] as String?;

    return SearchFilters(
      type: parsedType,
      sort: parsedSort,
      period: parsedPeriod,
      exactYear: (json['exactYear'] as num?)?.toInt(),
      genreIds: parsedGenres,
      excludedGenreIds: parsedExcluded,
      minRating: rawRating?.toDouble(),
      duration: parsedDuration,
      originalLanguage: (rawLang != null && rawLang.isNotEmpty)
          ? rawLang
          : null,
      hideSeen: json['hideSeen'] as bool? ?? false,
      hideUnreleased: json['hideUnreleased'] as bool? ?? false,
    );
  }

  /// Builds query parameters for TMDB `/discover/movie` or `/discover/tv`.
  Map<String, dynamic> toDiscoverParams(
    MediaType mediaType, {
    int page = 1,
    String? originalLanguage,
    bool genresMatchAny = false,
    DateTime? now,
  }) {
    final params = <String, dynamic>{'page': page};

    // Sort
    switch (sort) {
      case SearchSort.relevance:
        params['sort_by'] = 'popularity.desc';
        break;
      case SearchSort.rating:
        params['sort_by'] = 'vote_average.desc';
        break;
      case SearchSort.releaseDateDesc:
        params['sort_by'] = mediaType == MediaType.tv
            ? 'first_air_date.desc'
            : 'primary_release_date.desc';
        break;
      case SearchSort.releaseDateAsc:
        params['sort_by'] = mediaType == MediaType.tv
            ? 'first_air_date.asc'
            : 'primary_release_date.asc';
        break;
    }

    // Rating & vote count floor
    if (minRating != null) {
      params['vote_average.gte'] = minRating;
    }
    if (minRating != null || sort == SearchSort.rating) {
      params['vote_count.gte'] = 50;
    }

    // Release date / period
    if (exactYear != null) {
      if (mediaType == MediaType.movie) {
        params['primary_release_year'] = exactYear;
      } else {
        params['first_air_date_year'] = exactYear;
      }
    } else {
      final isMovie = mediaType == MediaType.movie;
      final gteKey = isMovie
          ? 'primary_release_date.gte'
          : 'first_air_date.gte';
      final lteKey = isMovie
          ? 'primary_release_date.lte'
          : 'first_air_date.lte';

      switch (period) {
        case SearchReleasePeriod.before1990:
          params[lteKey] = '1989-12-31';
          break;
        case SearchReleasePeriod.d1990s:
          params[gteKey] = '1990-01-01';
          params[lteKey] = '1999-12-31';
          break;
        case SearchReleasePeriod.d2000s:
          params[gteKey] = '2000-01-01';
          params[lteKey] = '2009-12-31';
          break;
        case SearchReleasePeriod.d2010s:
          params[gteKey] = '2010-01-01';
          params[lteKey] = '2019-12-31';
          break;
        case SearchReleasePeriod.d2020plus:
          params[gteKey] = '2020-01-01';
          break;
        case SearchReleasePeriod.all:
          break;
      }
    }

    // Genres
    if (genreIds.isNotEmpty) {
      final sortedIds = genreIds.toList()..sort();
      params['with_genres'] = sortedIds.join(genresMatchAny ? '|' : ',');
    }
    if (excludedGenreIds.isNotEmpty) {
      final sortedExcluded = excludedGenreIds.toList()..sort();
      params['without_genres'] = sortedExcluded.join(',');
    }

    // Hide unreleased
    if (hideUnreleased) {
      final ref = now ?? DateTime.now();
      final todayStr =
          '${ref.year.toString().padLeft(4, '0')}-${ref.month.toString().padLeft(2, '0')}-${ref.day.toString().padLeft(2, '0')}';
      final lteKey = mediaType == MediaType.movie
          ? 'primary_release_date.lte'
          : 'first_air_date.lte';
      final existingLte = params[lteKey] as String?;
      if (existingLte == null || todayStr.compareTo(existingLte) < 0) {
        params[lteKey] = todayStr;
      }
    }

    // Runtime (movies only)
    if (mediaType == MediaType.movie && duration != MovieDuration.all) {
      switch (duration) {
        case MovieDuration.under105:
          params['with_runtime.lte'] = 104;
          break;
        case MovieDuration.between105And150:
          params['with_runtime.gte'] = 105;
          params['with_runtime.lte'] = 150;
          break;
        case MovieDuration.over150:
          params['with_runtime.gte'] = 151;
          break;
        case MovieDuration.all:
          break;
      }
    }

    // Language
    final effectiveLanguage = originalLanguage ?? this.originalLanguage;
    if (effectiveLanguage != null && effectiveLanguage.isNotEmpty) {
      params['with_original_language'] = effectiveLanguage;
    }

    return params;
  }

  @override
  List<Object?> get props => [
    type,
    sort,
    period,
    exactYear,
    genreIds,
    excludedGenreIds,
    minRating,
    duration,
    originalLanguage,
    hideSeen,
    hideUnreleased,
  ];
}

/// Checks whether [item] matches the criteria in [filters].
bool matchesSearchFilters(
  MediaItem item,
  SearchFilters filters, {
  bool Function(MediaItem item)? isSeen,
  DateTime? now,
}) {
  if (filters.type != null && item.mediaType != filters.type) {
    return false;
  }

  if (filters.hideSeen && isSeen != null && isSeen(item)) {
    return false;
  }

  if (filters.minRating != null) {
    final avg = item.voteAverage;
    if (avg == null || avg < filters.minRating!) return false;
  }

  if (item.mediaType == MediaType.movie &&
      filters.duration != MovieDuration.all) {
    final runtime = item.runtime;
    if (runtime == null) return false;
    switch (filters.duration) {
      case MovieDuration.under105:
        if (runtime >= 105) return false;
        break;
      case MovieDuration.between105And150:
        if (runtime < 105 || runtime > 150) return false;
        break;
      case MovieDuration.over150:
        if (runtime <= 150) return false;
        break;
      case MovieDuration.all:
        break;
    }
  }

  if (filters.exactYear != null) {
    if (item.releaseYearNumber != filters.exactYear) return false;
  } else if (filters.period != SearchReleasePeriod.all) {
    final year = item.releaseYearNumber;
    if (year == null) return false;
    switch (filters.period) {
      case SearchReleasePeriod.before1990:
        if (year >= 1990) return false;
        break;
      case SearchReleasePeriod.d1990s:
        if (year < 1990 || year > 1999) return false;
        break;
      case SearchReleasePeriod.d2000s:
        if (year < 2000 || year > 2009) return false;
        break;
      case SearchReleasePeriod.d2010s:
        if (year < 2010 || year > 2019) return false;
        break;
      case SearchReleasePeriod.d2020plus:
        if (year < 2020) return false;
        break;
      case SearchReleasePeriod.all:
        break;
    }
  }

  if (filters.genreIds.isNotEmpty) {
    final itemGenreIds = item.resolvedGenreIds;
    for (final gid in filters.genreIds) {
      if (!itemGenreIds.contains(gid)) return false;
    }
  }

  if (filters.excludedGenreIds.isNotEmpty) {
    final itemGenreIds = item.resolvedGenreIds;
    for (final gid in filters.excludedGenreIds) {
      if (itemGenreIds.contains(gid)) return false;
    }
  }

  if (filters.originalLanguage != null &&
      filters.originalLanguage!.isNotEmpty) {
    if (item.originalLanguage?.toLowerCase() !=
        filters.originalLanguage!.toLowerCase()) {
      return false;
    }
  }

  if (filters.hideUnreleased) {
    if (item.releaseDate.isEmpty) return false;
    final parsed = DateTime.tryParse(item.releaseDate);
    if (parsed == null) return false;
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    if (parsed.isAfter(today)) return false;
  }

  return true;
}

/// Sorts [items] in place according to [sort].
void sortMediaItems(List<MediaItem> items, SearchSort sort, {String? query}) {
  switch (sort) {
    case SearchSort.relevance:
      if (query != null && query.isNotEmpty) {
        sortMediaByRelevance(items, query);
      }
      break;
    case SearchSort.rating:
      items.sort((a, b) {
        final rA = a.voteAverage ?? 0.0;
        final rB = b.voteAverage ?? 0.0;
        final cmp = rB.compareTo(rA);
        if (cmp != 0) return cmp;
        return (b.voteCount ?? 0).compareTo(a.voteCount ?? 0);
      });
      break;
    case SearchSort.releaseDateDesc:
      items.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
      break;
    case SearchSort.releaseDateAsc:
      items.sort((a, b) {
        if (a.releaseDate.isEmpty && b.releaseDate.isEmpty) return 0;
        if (a.releaseDate.isEmpty) return 1;
        if (b.releaseDate.isEmpty) return -1;
        return a.releaseDate.compareTo(b.releaseDate);
      });
      break;
  }
}
