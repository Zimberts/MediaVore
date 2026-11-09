import 'package:injectable/injectable.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

/// Airing state of a series, as needed by the collection achievements.
class ShowInfo {
  /// TMDB status (`Returning Series`, `Ended`, `Canceled`, ...).
  final String? status;

  /// Episode count of each regular season (season 0, the specials, excluded).
  final Map<int, int> episodeCounts;

  /// Last aired episode, when TMDB reports one.
  final int? lastSeason;
  final int? lastEpisode;

  const ShowInfo({
    this.status,
    required this.episodeCounts,
    this.lastSeason,
    this.lastEpisode,
  });

  /// No episode will be added anymore.
  bool get isFinished => status == 'Ended' || status == 'Canceled';

  /// Aired episodes per regular season: seasons before the last aired episode
  /// count in full, its season up to that episode, later seasons not at all.
  /// Without a last aired episode, every listed episode counts.
  Map<int, int> get airedEpisodeCounts {
    final last = lastSeason;
    final lastEp = lastEpisode;
    if (last == null || lastEp == null) return episodeCounts;
    return {
      for (final e in episodeCounts.entries)
        if (e.key < last)
          e.key: e.value
        else if (e.key == last)
          e.key: lastEp < e.value ? lastEp : e.value,
    };
  }

  factory ShowInfo.fromItem(MediaItem item) => ShowInfo(
    status: item.status,
    episodeCounts: {
      for (final s in item.seasons ?? const <TVSeason>[])
        if (s.seasonNumber > 0 && s.episodeCount > 0)
          s.seasonNumber: s.episodeCount,
    },
    lastSeason: item.lastSeasonNumber,
    lastEpisode: item.lastEpisodeNumber,
  );
}

/// Title metadata used by the diversity and app usage achievements.
class TitleInfo {
  /// `yyyy-mm-dd` (first air date for a series), empty when unknown.
  final String releaseDate;

  /// ISO 3166-1 codes; null when unknown (cached before they were stored).
  final List<String>? originCountries;
  final double? voteAverage;
  final int? voteCount;

  /// ISO 639-1 code; null when unknown (cached before it was stored).
  final String? originalLanguage;

  const TitleInfo({
    this.releaseDate = '',
    this.originCountries,
    this.voteAverage,
    this.voteCount,
    this.originalLanguage,
  });

  factory TitleInfo.fromItem(MediaItem item) => TitleInfo(
    releaseDate: item.releaseDate,
    originCountries: item.originCountries,
    voteAverage: item.voteAverage,
    voteCount: item.voteCount,
    originalLanguage: item.originalLanguage,
  );

  /// Release year, or null when the date is unknown or malformed.
  int? get year => DateTime.tryParse(releaseDate)?.year;

  /// Every field the diversity types read is known.
  bool get isComplete =>
      year != null &&
      originCountries != null &&
      voteAverage != null &&
      voteCount != null &&
      originalLanguage != null;
}

/// TMDB data the history alone cannot provide (season sizes, sagas, title
/// metadata, air dates).
///
/// Only local data is read: achievements never trigger network calls, so a
/// title missing from the cache simply does not count yet.
abstract class AchievementMediaSource {
  /// Known series among [tvIds].
  Future<Map<int, ShowInfo>> shows(Set<int> tvIds);

  /// For each movie of [movieIds] that belongs to a saga, the ids and release
  /// dates of all the saga's parts.
  Future<Map<int, List<SagaPart>>> sagas(Set<int> movieIds);

  /// Known titles among [keys] (`(tmdbId, 'movie' | 'tv')`).
  Future<Map<(int, String), TitleInfo>> titles(Set<(int, String)> keys);

  /// Air date (`yyyy-mm-dd`) of each episode of the cached [season] of series
  /// [tvId], by episode number; null when the season is not cached.
  Future<Map<int, String>?> episodeAirDates(int tvId, int season);
}

class SagaPart {
  final int id;

  /// `yyyy-mm-dd`, empty when unknown.
  final String releaseDate;

  const SagaPart(this.id, this.releaseDate);
}

@LazySingleton(as: AchievementMediaSource)
class CachedAchievementMediaSource implements AchievementMediaSource {
  final MediaCache _cache;

  /// Saga membership never changes; decoded once per session per movie.
  final Map<int, List<SagaPart>> _sagaMemo = {};

  /// Complete title metadata, decoded once per session. Votes drift slowly;
  /// the sticky unlocks make a stale value harmless.
  final Map<(int, String), TitleInfo> _titleMemo = {};

  CachedAchievementMediaSource(this._cache);

  @override
  Future<Map<int, ShowInfo>> shows(Set<int> tvIds) async {
    final keys = [for (final id in tvIds) (id, MediaType.tv)];
    final items = await _cache.getItems(keys);
    final result = <int, ShowInfo>{};
    for (var i = 0; i < keys.length; i++) {
      var item = items[i];
      // A list row (search, discover) has no seasons: use the details.
      if (item?.seasons == null) {
        item = (await _cache.getDetails(keys[i].$1, MediaType.tv))?.item;
      }
      if (item?.seasons != null) result[keys[i].$1] = ShowInfo.fromItem(item!);
    }
    return result;
  }

  @override
  Future<Map<(int, String), TitleInfo>> titles(Set<(int, String)> keys) async {
    final missing = [
      for (final k in keys)
        if (!_titleMemo.containsKey(k)) k,
    ];
    if (missing.isEmpty) return {for (final k in keys) k: _titleMemo[k]!};
    final items = await _cache.getItems([
      for (final (id, type) in missing) (id, _mediaType(type)),
    ]);
    final partial = <(int, String), TitleInfo>{};
    for (var i = 0; i < missing.length; i++) {
      var info = items[i] == null ? null : TitleInfo.fromItem(items[i]!);
      // A list row (discover movies) lacks the countries: use the details.
      if (info == null || !info.isComplete) {
        final (id, type) = missing[i];
        final details = (await _cache.getDetails(id, _mediaType(type)))?.item;
        if (details != null) info = TitleInfo.fromItem(details);
      }
      if (info == null) continue;
      partial[missing[i]] = info;
      // Incomplete entries are re-read: a later refresh may fill them.
      if (info.isComplete) _titleMemo[missing[i]] = info;
    }
    return {
      for (final k in keys)
        if (_titleMemo[k] ?? partial[k] case final info?) k: info,
    };
  }

  @override
  Future<Map<int, String>?> episodeAirDates(int tvId, int season) async {
    final json = await _cache.getSeason(tvId, season);
    final episodes = json?['episodes'];
    if (episodes is! List) return null;
    return {
      for (final e in episodes)
        if (e is Map &&
            e['episode_number'] is int &&
            e['air_date'] is String &&
            (e['air_date'] as String).isNotEmpty)
          e['episode_number'] as int: e['air_date'] as String,
    };
  }

  static MediaType _mediaType(String type) =>
      type == 'tv' ? MediaType.tv : MediaType.movie;

  @override
  Future<Map<int, List<SagaPart>>> sagas(Set<int> movieIds) async {
    final result = <int, List<SagaPart>>{};
    for (final id in movieIds) {
      var parts = _sagaMemo[id];
      if (parts == null) {
        final items = await _cache.getCollectionParts(id);
        if (items == null) continue; // not cached: retried next time
        parts = _sagaMemo[id] = [
          for (final p in items) SagaPart(p.id, p.releaseDate),
        ];
      }
      if (parts.isNotEmpty) result[id] = parts;
    }
    return result;
  }
}
