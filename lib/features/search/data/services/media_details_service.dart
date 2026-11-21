import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/bounded_concurrency.dart';
import 'package:mediavore/core/utils/json_maps.dart';
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

  /// In-flight [getCollectionParts] requests keyed by `collectionId`, so
  /// films of the same saga share one collection lookup.
  final Map<int, Future<List<MediaItem>?>> _inFlightCollections = {};

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
    bool forceRefresh = false,
  }) async {
    final cachedDetails = await cache.getDetails(id, type);
    if (cachedDetails != null && !forceRefresh) {
      if (cachedDetails.item.isComplete) {
        return cachedDetails;
      }
      try {
        return await _fetchMediaDetailsWithFlight(id, type);
      } catch (e) {
        debugPrint(
          '[MediaDetailsService] Failed to refresh incomplete metadata for $id: $e',
        );
        return cachedDetails;
      }
    }

    return _fetchMediaDetailsWithFlight(id, type);
  }

  Future<MediaDetails> _fetchMediaDetailsWithFlight(
    int id,
    MediaType type,
  ) async {
    final key = '${type.name}_$id';
    final pending = _inFlightDetails[key];
    if (pending != null) return pending;

    final future = _fetchMediaDetails(id, type);
    _inFlightDetails[key] = future;
    try {
      return await future;
    } finally {
      // The removed entry is the future awaited just above.
      unawaited(_inFlightDetails.remove(key));
    }
  }

  Future<MediaDetails> _fetchMediaDetails(int id, MediaType type) async {
    // One request for the item and its optional parts (append_to_response);
    // only the item is fatal, unreadable parts fall back to empty values.
    final bundle = await remoteDataSource.getMediaDetailsBundle(id, type: type);
    final item = bundle.item;
    final credits = bundle.credits;

    final castResults = (credits['cast'] as List<dynamic>?) ?? const [];
    final crewResults = (credits['crew'] as List<dynamic>?) ?? const [];

    final List<CastMember> cast = castResults
        .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
        .toList();

    final CrewMember director = crewResults
        .whereType<Map<dynamic, dynamic>>()
        .map((c) => CrewMember.fromJson(Map<String, dynamic>.from(c)))
        .firstWhere(
          (member) =>
              member.job == 'Director' ||
              member.job == 'Creator' ||
              member.job == 'Executive Producer',
          orElse: () => const CrewMember(name: 'N/A', job: 'Director'),
        );

    // If this item belongs to a collection, fetch collection parts (saga)
    List<MediaItem>? collectionParts;
    final collectionId = item.collectionId;
    if (collectionId != null) {
      collectionParts = cache.getCachedCollection(collectionId);
      if (collectionParts == null) {
        final future = _inFlightCollections.putIfAbsent(collectionId, () async {
          try {
            final parts = await remoteDataSource.getCollectionParts(
              collectionId,
            );
            cache.cacheCollectionParts(collectionId, parts);
            return parts;
          } catch (_) {
            return null;
          }
        });
        try {
          collectionParts = await future;
        } finally {
          // The removed entry is the future awaited just above.
          unawaited(_inFlightCollections.remove(collectionId));
        }
      }
    }

    final details = MediaDetails(
      item: item,
      cast: cast,
      director: director,
      similar: bundle.similar,
      recommendations: bundle.recommendations,
      collection: collectionParts,
      watchProviders: bundle.watchProviders,
      videos: bundle.videos,
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

  /// Caches the given seasons of [tvId], fetching the missing or stale ones
  /// in as few requests as possible (`append_to_response`, see
  /// [MediaRemoteDataSource.getSeasonsDetails]). Used by the cache warm-up;
  /// throws on a network failure.
  Future<void> prefetchSeasons(int tvId, Iterable<int> seasonNumbers) async {
    final missing = <int>[];
    for (final n in seasonNumbers) {
      final cached = await cache.getSeason(tvId, n);
      if (cached == null || await _isOngoingSeasonStale(tvId, n)) {
        missing.add(n);
      }
    }
    if (missing.isEmpty) return;
    final fetched = await remoteDataSource.getSeasonsDetails(tvId, missing);
    for (final entry in fetched.entries) {
      await cache.cacheSeason(tvId, entry.key, entry.value);
    }
  }

  /// Seasons of ongoing series gain episodes over time, so a cached copy older
  /// than a day is re-fetched (the stale copy remains the offline fallback).
  /// Older completed seasons without recently aired or undated episodes are kept.
  Future<bool> _isOngoingSeasonStale(int tvId, int seasonNumber) async {
    final item = await cache.getItem(tvId, MediaType.tv);
    final status = item?.status?.toLowerCase();
    if (status != 'returning series' && status != 'in production') {
      return false;
    }
    final updatedAt = await cache.getSeasonUpdateDate(tvId, seasonNumber);
    if (updatedAt == null) return false;
    if (DateTime.now().difference(updatedAt) < const Duration(days: 1)) {
      return false;
    }
    // Only the latest season or seasons with recent/undated episodes are stale
    final seasons = item?.seasons?.where((s) => s.seasonNumber > 0).toList();
    if (seasons != null && seasons.isNotEmpty) {
      if (seasonNumber >= seasons.last.seasonNumber) {
        return true;
      }
    }
    final cached = await cache.getSeason(tvId, seasonNumber);
    final episodes = cached?['episodes'] as List?;
    if (episodes == null || episodes.isEmpty) return true;
    final now = DateTime.now();
    for (final ep in episodes) {
      if (ep is Map) {
        final airDateStr = ep['air_date'] as String?;
        if (airDateStr == null || airDateStr.isEmpty) {
          return true;
        }
        final airDate = DateTime.tryParse(airDateStr);
        if (airDate == null || now.difference(airDate).inDays <= 30) {
          return true;
        }
      }
    }
    return false;
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
        final episode = jsonObjectList(
          seasonDetails?['episodes'],
        ).where((e) => e['episode_number'] == episodeNumber).firstOrNull;
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
    try {
      final actorDetailsFuture = remoteDataSource.getActorDetails(actorId);
      final personCreditsFuture = remoteDataSource.getPersonCredits(actorId);

      final actorDetails = await actorDetailsFuture;
      final credits = await personCreditsFuture;

      final fullDetails = ActorDetails(
        id: actorDetails.id,
        name: actorDetails.name,
        biography: actorDetails.biography,
        birthday: actorDetails.birthday,
        placeOfBirth: actorDetails.placeOfBirth,
        profilePath: actorDetails.profilePath,
        items: credits.cast,
        crewItems: credits.crew,
      );

      await cache.cacheActorDetails(fullDetails);
      return fullDetails;
    } catch (e) {
      final cached = await cache.getActorDetails(actorId);
      if (cached != null) return cached;
      rethrow;
    }
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
