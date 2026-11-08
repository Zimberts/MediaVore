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

/// TMDB data the history alone cannot provide (season sizes, sagas).
///
/// Only local data is read: achievements never trigger network calls, so a
/// title missing from the cache simply does not count yet.
abstract class AchievementMediaSource {
  /// Known series among [tvIds].
  Future<Map<int, ShowInfo>> shows(Set<int> tvIds);

  /// For each movie of [movieIds] that belongs to a saga, the ids and release
  /// dates of all the saga's parts.
  Future<Map<int, List<SagaPart>>> sagas(Set<int> movieIds);
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
