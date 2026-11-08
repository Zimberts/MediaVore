import 'package:flutter/foundation.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/bounded_concurrency.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';

/// Cache-first loading of TMDB data: media details, seasons, actors and the
/// optional detail endpoints.
///
/// Part of `MediaRepositoryImpl`; callers are expected to have awaited the
/// repository's initialization.
class MediaDetailsService {
  final MediaRemoteDataSource remoteDataSource;
  final MediaCache cache;

  /// Max concurrent `/movie|tv/{id}` requests when enriching a result page.
  static const int enrichmentConcurrency = 4;

  /// In-flight [getMediaDetails] requests keyed by `type_id`, so concurrent
  /// callers (UI + background cache warm-up) share one set of remote calls.
  final Map<String, Future<MediaDetails>> _inFlightDetails = {};

  MediaDetailsService({required this.remoteDataSource, required this.cache});

  /// Replaces search/discover rows by their full `/movie|tv/{id}` item
  /// (runtime, seasons, genres). Cached details are used first; misses are
  /// fetched with at most [enrichmentConcurrency] requests in flight, and a
  /// failed fetch keeps the original row.
  Future<List<MediaItem>> enrichItems(List<MediaItem> items) {
    return mapWithConcurrency(items, enrichmentConcurrency, (item) async {
      final cached = (await cache.getDetails(item.id, item.mediaType))?.item;
      if (cached != null) return cached;
      try {
        return await remoteDataSource.getMediaItem(
          item.id,
          type: item.mediaType,
        );
      } catch (_) {
        return item;
      }
    });
  }

  /// Caching is an optimisation: a cache failure must not hide fetched results.
  Future<void> cacheItemsBestEffort(List<MediaItem> items, String from) async {
    try {
      await cache.cacheItems(items);
    } catch (e) {
      debugPrint('[Repo] $from cache error: $e');
    }
  }

  Future<MediaDetails> getMediaDetails(
    int id, {
    MediaType type = MediaType.movie,
  }) async {
    final cachedDetails = await cache.getDetails(id, type);
    if (cachedDetails != null) return cachedDetails;

    final key = '${type.name}_$id';
    final pending = _inFlightDetails[key];
    if (pending != null) return pending;

    final future = _fetchMediaDetails(id, type);
    _inFlightDetails[key] = future;
    try {
      return await future;
    } finally {
      _inFlightDetails.remove(key);
    }
  }

  /// Runs [call] and returns [fallback] on any error (sync or async), logging
  /// it. Used for optional detail endpoints so they never fail the whole page
  /// nor leak unhandled asynchronous errors.
  Future<T> _optional<T>(
    String label,
    Future<T> Function() call,
    T fallback,
  ) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('[Repo] getMediaDetails optional $label failed: $e');
      return fallback;
    }
  }

  Future<MediaDetails> _fetchMediaDetails(int id, MediaType type) async {
    // Optional requests are started before awaiting the main item and each
    // has its error handler attached immediately: if the main item fails,
    // their failures are still handled. Only the main item is fatal.
    final creditsFuture = _optional<Map<String, dynamic>>(
      'credits',
      () => remoteDataSource.getMediaCredits(id, type: type),
      {'cast': [], 'crew': []},
    );
    final similarFuture = _optional<List<MediaItem>>(
      'similar',
      () => remoteDataSource.getSimilarMedia(id, type),
      [],
    );
    final recommendationsFuture = _optional<List<MediaItem>>(
      'recommendations',
      () => remoteDataSource.getRecommendedMedia(id, type),
      [],
    );
    final watchProvidersFuture = _optional<Map<String, dynamic>>(
      'watchProviders',
      () => remoteDataSource.getWatchProviders(id, type),
      {},
    );
    final videosFuture = _optional<List<Map<String, dynamic>>>(
      'videos',
      () => remoteDataSource.getVideos(id, type),
      [],
    );

    final item = await remoteDataSource.getMediaItem(id, type: type);
    final credits = await creditsFuture;

    final List castResults = credits['cast'] ?? [];
    final List crewResults = credits['crew'] ?? [];

    final List<CastMember> cast = castResults
        .map((c) => CastMember.fromJson(c))
        .toList();

    final CrewMember director = crewResults
        .map((c) => CrewMember.fromJson(c))
        .firstWhere(
          (member) =>
              member.job == 'Director' || member.job == 'Executive Producer',
          orElse: () => CrewMember(name: 'N/A', job: 'Director'),
        );

    final List<MediaItem> similar = await similarFuture;
    final List<MediaItem> recommendations = await recommendationsFuture;
    final Map<String, dynamic> watchProviders = await watchProvidersFuture;
    final List<Map<String, dynamic>> videos = await videosFuture;

    // If this item belongs to a collection, fetch collection parts (saga)
    List<MediaItem>? collectionParts;
    if (item.collectionId != null) {
      try {
        collectionParts = await remoteDataSource.getCollectionParts(
          item.collectionId!,
        );
      } catch (_) {
        collectionParts = null;
      }
    }

    final details = MediaDetails(
      item: item,
      cast: cast,
      director: director,
      similar: similar,
      recommendations: recommendations,
      collection: collectionParts,
      watchProviders: watchProviders,
      videos: videos,
    );

    await cache.cacheDetails(details);
    return details;
  }

  /// Season details, cache-first. On a network failure the cache is read
  /// again (another caller may have filled it) before rethrowing.
  Future<Map<String, dynamic>> getSeasonDetails(
    int tvId,
    int seasonNumber,
  ) async {
    final cachedSeason = await cache.getSeason(tvId, seasonNumber);
    if (cachedSeason != null &&
        !await _isOngoingSeasonStale(tvId, seasonNumber)) {
      return cachedSeason;
    }

    try {
      final details = await remoteDataSource.getSeasonDetails(
        tvId,
        seasonNumber,
      );
      await cache.cacheSeason(tvId, seasonNumber, details);
      return details;
    } catch (e) {
      return await cache.getSeason(tvId, seasonNumber) ?? (throw e);
    }
  }

  /// Seasons of ongoing series gain episodes over time, so a cached copy older
  /// than a day is re-fetched (the stale copy remains the offline fallback).
  Future<bool> _isOngoingSeasonStale(int tvId, int seasonNumber) async {
    final item = await cache.getItem(tvId, MediaType.tv);
    final status = item?.status?.toLowerCase();
    if (status != 'returning series' && status != 'in production') {
      return false;
    }
    final updatedAt = await cache.getSeasonUpdateDate(tvId, seasonNumber);
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) >= const Duration(days: 1);
  }

  /// Fetches season details, bypassing the cache when [forceRemote] is set so
  /// newly aired episodes are discovered.
  Future<Map<String, dynamic>> seasonDetailsForRefresh(
    int tvId,
    int seasonNumber, {
    required bool forceRemote,
  }) async {
    if (!forceRemote) {
      return getSeasonDetails(tvId, seasonNumber);
    }
    final details = await remoteDataSource.getSeasonDetails(tvId, seasonNumber);
    await cache.cacheSeason(tvId, seasonNumber, details);
    return details;
  }

  /// Fills a missing [runtime] / [genres] from TMDB details (episode runtime
  /// for TV episodes, movie runtime for movies). Lookup failures are ignored and
  /// the given values are returned unchanged.
  ///
  /// [fetchDetails] / [fetchSeason] replace the default lookups (e.g. to share
  /// one lookup per show/season across an import); a `null` result counts as
  /// a failed lookup.
  Future<({int? runtime, List<String>? genres})> resolveRuntimeAndGenres({
    required int tmdbId,
    required MediaType type,
    int? seasonNumber,
    int? episodeNumber,
    int? runtime,
    List<String>? genres,
    Future<MediaDetails?> Function(int id, MediaType type)? fetchDetails,
    Future<Map<String, dynamic>?> Function(int id, int season)? fetchSeason,
  }) async {
    if (runtime != null && genres != null) {
      return (runtime: runtime, genres: genres);
    }
    try {
      final details = fetchDetails != null
          ? await fetchDetails(tmdbId, type)
          : await getMediaDetails(tmdbId, type: type);
      if (details == null) return (runtime: runtime, genres: genres);
      genres ??= details.item.genres;
      if (type == MediaType.movie) {
        runtime = details.item.runtime;
      } else if (seasonNumber != null && episodeNumber != null) {
        final seasonDetails = fetchSeason != null
            ? await fetchSeason(tmdbId, seasonNumber)
            : await getSeasonDetails(tmdbId, seasonNumber);
        final episodes = seasonDetails?['episodes'] as List?;
        final episode = episodes?.firstWhere(
          (e) => e['episode_number'] == episodeNumber,
          orElse: () => null,
        );
        if (episode != null) {
          runtime = episode['runtime'] as int?;
        }
      }
    } catch (e) {
      debugPrint('[Repo] runtime/genres lookup failed: $e');
    }
    return (runtime: runtime, genres: genres);
  }

  Future<ActorDetails> getActorDetails(int actorId) async {
    final actorDetailsFuture = remoteDataSource.getActorDetails(actorId);
    final actorMediasFuture = remoteDataSource.getActorMediaCredits(actorId);

    final actorDetails = await actorDetailsFuture;
    final items = await actorMediasFuture;

    await cache.cacheActorProfile(actorId, actorDetails.profilePath);

    return ActorDetails(
      id: actorDetails.id,
      name: actorDetails.name,
      biography: actorDetails.biography,
      birthday: actorDetails.birthday,
      placeOfBirth: actorDetails.placeOfBirth,
      profilePath: actorDetails.profilePath,
      items: items,
    );
  }

  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) async {
    try {
      final results = await remoteDataSource.getSimilarMedia(id, type);
      await cache.cacheItems(results);
      return results;
    } catch (e) {
      debugPrint('[Repo] getSimilarMedia error: $e');
      return [];
    }
  }

  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) async {
    try {
      final results = await remoteDataSource.getRecommendedMedia(id, type);
      await cache.cacheItems(results);
      return results;
    } catch (e) {
      debugPrint('[Repo] getRecommendedMedia error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) async {
    try {
      return await remoteDataSource.getWatchProviders(id, type);
    } catch (e) {
      debugPrint('[Repo] getWatchProviders error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) async {
    try {
      return await remoteDataSource.getVideos(id, type);
    } catch (e) {
      debugPrint('[Repo] getVideos error: $e');
      return [];
    }
  }
}
