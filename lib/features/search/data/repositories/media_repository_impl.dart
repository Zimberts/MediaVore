import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/core/utils/watch_tail.dart';

/// Implementation of the [MediaRepository] that uses a remote and a local data source.
@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;
  final Completer<void> _initCompleter = Completer<void>();

  /// Creates a new instance of [MediaRepositoryImpl].
  MediaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.cache,
    bool autoInit = true,
  }) {
    if (autoInit) {
      _init();
    } else {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<void> _init() async {
    try {
      debugPrint('[Repo] Starting Cache Init...');
      await cache.init();
      debugPrint('[Repo] Cache Init Done.');
    } catch (e) {
      debugPrint('[Repo] Cache Init Error: $e');
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }

    // Background cache filling/refreshing.
    unawaited(_initCache());
  }

  Future<void> _initCache() async {
    try {
      debugPrint('[Repo] Starting background _initCache...');
      // 1. Populate/Refresh cache with items from all lists
      final allListNames = await localDataSource.getAllListNames();
      final Set<String> keysToKeep = {};

      for (final listName in allListNames) {
        final items = await localDataSource.getListItems(listName);
        for (final item in items) {
          final type = item.type == 'movie' ? MediaType.movie : MediaType.tv;
          keysToKeep.add('${type.name}:${item.id}');

          try {
            final details = await getMediaDetails(item.id, type: type);
            if (type == MediaType.tv && details.item.seasons != null) {
              for (final season in details.item.seasons!) {
                await getSeasonDetails(item.id, season.seasonNumber);
              }
            }
          } catch (e) {
            debugPrint('[Repo] _initCache list item refresh failed: $e');
          }
        }
      }

      // 2. Seen items logic
      final seenItems = await localDataSource.getAllSeenItems();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (final seen in seenItems) {
        final type = seen.type == 'movie' ? MediaType.movie : MediaType.tv;
        final isRecent = seen.seenDate.isAfter(thirtyDaysAgo);
        final isMissingPoster = seen.posterPath == null;

        if (isRecent || isMissingPoster) {
          keysToKeep.add('${seen.type}:${seen.tmdbId}');
          try {
            final details = await getMediaDetails(seen.tmdbId, type: type);
            if (isMissingPoster && details.item.posterPath != null) {
              await localDataSource.updatePosterPath(
                seen.tmdbId,
                seen.type,
                details.item.posterPath!,
              );
            }
            if (isRecent && type == MediaType.tv && seen.seasonNumber != null) {
              await getSeasonDetails(seen.tmdbId, seen.seasonNumber!);
            }
          } catch (e) {
            debugPrint('[Repo] _initCache seen item refresh failed: $e');
          }
        }
      }

      // 3. Liked items
      final likedItems = await localDataSource.getLikedItems();
      for (final liked in likedItems) {
        keysToKeep.add('${liked.type}:${liked.tmdbId}');
        final type = liked.type == 'movie' ? MediaType.movie : MediaType.tv;
        try {
          await getMediaDetails(liked.tmdbId, type: type);
        } catch (e) {
          debugPrint('[Repo] _initCache liked item refresh failed: $e');
        }
      }

      // 4. Refresh notification dates from network in the background
      await refreshNotifiedItems();

      // 5. Perform cleanup
      await cache.cleanup(
        keepKeys: keysToKeep,
        olderThan: const Duration(days: 60),
      );
      debugPrint('[Repo] Background _initCache completed.');
    } catch (e) {
      debugPrint('[Repo] Background _initCache error: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
  }

  @override
  Future<List<MediaItem>> searchMedia(
    String query, {
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType? type,
  }) async {
    await _ensureInitialized();
    try {
      final results = await remoteDataSource.searchMedia(
        query,
        page: page,
        genreIds: genreIds,
        releaseYear: releaseYear,
        minRating: minRating,
        language: language,
        type: type,
      );
      for (final item in results) {
        await cache.cacheItem(item);
      }
      return results;
    } catch (e) {
      debugPrint('[Repo] searchMedia error: $e');
      return [];
    }
  }

  @override
  Future<List<MediaItem>> discoverMedia({
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType type = MediaType.movie,
    String sortBy = 'popularity.desc',
  }) async {
    await _ensureInitialized();
    try {
      final results = await remoteDataSource.discoverMedia(
        page: page,
        genreIds: genreIds,
        releaseYear: releaseYear,
        minRating: minRating,
        language: language,
        type: type,
        sortBy: sortBy,
      );
      for (final item in results) {
        await cache.cacheItem(item);
      }
      return results;
    } catch (e) {
      debugPrint('[Repo] discoverMedia error: $e');
      return [];
    }
  }

  @override
  Future<MediaDetails> getMediaDetails(
    int id, {
    MediaType type = MediaType.movie,
  }) async {
    await _ensureInitialized();

    if (cache.areDetailsCached(id, type)) {
      return cache.getDetails(id, type)!;
    }

    final itemFuture = remoteDataSource.getMediaItem(id, type: type);
    final creditsFuture = remoteDataSource.getMediaCredits(id, type: type);
    final similarFuture = remoteDataSource.getSimilarMedia(id, type);
    final recommendationsFuture = remoteDataSource.getRecommendedMedia(
      id,
      type,
    );
    final watchProvidersFuture = remoteDataSource.getWatchProviders(id, type);
    final videosFuture = remoteDataSource.getVideos(id, type);

    final item = await itemFuture;

    Map<String, dynamic> credits = {'cast': [], 'crew': []};
    try {
      credits = await creditsFuture;
    } catch (e) {
      debugPrint('[Repo] getMediaDetails credits failed: $e');
    }

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

  /// Reconciles a notified item's stored release with the viewer's latest
  /// watching streak.
  ///
  /// For TV this anchors Releases to the next unseen episode after the most
  /// recently watched episode (never an older gap), removes the series when it
  /// is finished and fully watched, and downgrades it to "Returning" when a new
  /// season is planned without a date. Movies keep their 30-day stale rule.
  ///
  /// Set [forceRemoteSeasons] to bypass the season cache so newly released
  /// episodes are discovered.
  Future<void> _refreshNotificationDate(
    MediaItem item, {
    bool forceRemoteSeasons = false,
  }) async {
    final isNotified = await localDataSource.isNotified(
      item.id,
      item.mediaType.name,
    );
    if (!isNotified) return;

    if (item.mediaType == MediaType.movie) {
      return _refreshMovieNotificationDate(item);
    }

    final seen = await localDataSource.getSeenStatus(item.id, MediaType.tv.name);
    final tail = findLatestTail(seen);

    // No watch history yet: fall back to TMDB's next-episode metadata.
    if (tail == null) {
      await _applyNextEpisodeFallback(item);
      return;
    }

    final detailsItem = await _detailsItemWithSeasons(item);

    final scan = await _scanForNextEpisode(
      detailsItem,
      tail,
      seen,
      forceRemote: forceRemoteSeasons,
    );

    final nextEpisode = scan.episode;
    if (nextEpisode != null) {
      await localDataSource.setNotificationEpisode(
        item.id,
        item.mediaType.name,
        seasonNumber: nextEpisode.seasonNumber,
        episodeNumber: nextEpisode.episodeNumber,
        releaseDate: nextEpisode.airDate,
        runtime: nextEpisode.runtime,
      );
      return;
    }

    // Prefer TMDB's explicit next-episode metadata when it is available.
    if (await _applyNextEpisodeFallback(item)) return;

    final status = (detailsItem?.status ?? item.status)?.toLowerCase();
    final isFinished = status == 'ended' || status == 'canceled';

    // Finished and fully watched: stop tracking it. Only drop the series when
    // the scan was complete; a transient season-fetch failure must not remove it.
    if (isFinished) {
      if (!scan.complete) return;
      await localDataSource.toggleNotification(
        tmdbId: item.id,
        type: item.mediaType.name,
        title: item.title,
      );
      return;
    }

    // No concrete next episode. On a partial scan, only reconcile a record that
    // already points at a watched episode (it is stale, e.g. the episode just
    // marked seen); never clobber a record still pointing at an unseen release.
    if (!scan.complete) {
      final stored = await localDataSource.getNotifiedItem(
        item.id,
        item.mediaType.name,
      );
      if (!_recordPointsAtSeenEpisode(stored, seen)) return;
    }

    await localDataSource.markNotificationAsReturning(
      item.id,
      item.mediaType.name,
    );
  }

  /// Whether the stored notified record already points at an episode present in
  /// [seen] (i.e. it is stale and safe to downgrade to "Returning").
  bool _recordPointsAtSeenEpisode(
    NotifiedItemModel? record,
    List<SeenItemModel> seen,
  ) {
    final season = record?.seasonNumber;
    final episode = record?.episodeNumber;
    if (season == null || episode == null) return false;
    final key = episodeKey(season, episode);
    return seen.any(
      (s) =>
          s.seasonNumber != null &&
          s.episodeNumber != null &&
          episodeKey(s.seasonNumber!, s.episodeNumber!) == key,
    );
  }

  /// Movie counterpart of [_refreshNotificationDate]: keeps the release date and
  /// drops the notification once the movie has been out for more than a month.
  Future<void> _refreshMovieNotificationDate(MediaItem item) async {
    if (item.releaseDate.isEmpty) return;

    final DateTime releaseDate;
    try {
      releaseDate = DateTime.parse(item.releaseDate);
    } catch (_) {
      return;
    }

    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    if (releaseDate.isBefore(oneMonthAgo)) {
      await localDataSource.toggleNotification(
        tmdbId: item.id,
        type: item.mediaType.name,
        title: item.title,
      );
      return;
    }

    await localDataSource.updateNotificationDate(
      item.id,
      item.mediaType.name,
      releaseDate,
      runtime: item.runtime,
    );
  }

  /// Applies TMDB's `next_episode_to_air` metadata when present.
  ///
  /// Returns `true` when a release date was written.
  Future<bool> _applyNextEpisodeFallback(MediaItem item) async {
    final raw = item.nextEpisodeAirDate;
    if (raw == null || raw.isEmpty) return false;

    final DateTime next;
    try {
      next = DateTime.parse(raw);
    } catch (_) {
      return false;
    }

    await localDataSource.setNotificationEpisode(
      item.id,
      item.mediaType.name,
      seasonNumber: item.nextSeasonNumber,
      episodeNumber: item.nextEpisodeNumber,
      releaseDate: next,
    );
    return true;
  }

  /// Cache-first details fetch that guarantees a season list when possible.
  ///
  /// Callers that need freshly aired episodes force the *season* fetch instead
  /// (see `_seasonDetailsForRefresh`); the item itself is acceptable from cache.
  Future<MediaItem?> _detailsItemWithSeasons(MediaItem item) async {
    final cached = cache.getItem(item.id, MediaType.tv);
    if (cached?.seasons != null) return cached;

    try {
      final fresh = await remoteDataSource.getMediaItem(
        item.id,
        type: MediaType.tv,
      );
      await cache.cacheItem(fresh);
      return fresh;
    } catch (_) {
      return cached ?? item;
    }
  }

  /// Finds the next unseen episode after [tail] using season/episode data.
  ///
  /// [complete] is `false` when a season could not be evaluated, so the caller
  /// can avoid destructive reconciliation on partial data.
  Future<({EpisodeRef? episode, bool complete})> _scanForNextEpisode(
    MediaItem? detailsItem,
    WatchTail tail,
    List<SeenItemModel> seen, {
    required bool forceRemote,
  }) async {
    final details = detailsItem;
    if (details == null) return (episode: null, complete: false);

    final seasons = details.seasons;
    if (seasons == null || seasons.isEmpty) {
      return (episode: null, complete: false);
    }

    final seenKeys = <String>{
      for (final s in seen)
        if (s.seasonNumber != null && s.episodeNumber != null)
          episodeKey(s.seasonNumber!, s.episodeNumber!),
    };

    final sortedSeasons = List<TVSeason>.from(seasons)
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    final episodes = <EpisodeRef>[];
    var complete = true;

    for (final season in sortedSeasons) {
      if (season.seasonNumber == 0) continue;
      if (season.seasonNumber < tail.seasonNumber) continue;

      final Map<String, dynamic> seasonDetails;
      try {
        seasonDetails = await _seasonDetailsForRefresh(
          details.id,
          season.seasonNumber,
          forceRemote: forceRemote,
        );
      } catch (_) {
        // A season with no known episodes (e.g. an announced but unscheduled
        // next season) cannot contain a candidate, so its absence is not
        // "incomplete" data. Seasons that claim episodes make the scan partial.
        if (season.episodeCount > 0) complete = false;
        continue;
      }

      final rawEpisodes = seasonDetails['episodes'];
      if (rawEpisodes is! List) {
        if (season.episodeCount > 0) complete = false;
        continue;
      }

      for (final raw in rawEpisodes) {
        if (raw is! Map) continue;
        final epNum = raw['episode_number'] as int?;
        if (epNum == null) continue;
        final airDateStr = raw['air_date'] as String?;
        episodes.add(
          EpisodeRef(
            seasonNumber: season.seasonNumber,
            episodeNumber: epNum,
            airDate: (airDateStr == null || airDateStr.isEmpty)
                ? null
                : DateTime.tryParse(airDateStr),
            runtime: raw['runtime'] as int?,
          ),
        );
      }

      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: episodes,
        seenEpisodeKeys: seenKeys,
      );
      if (next != null) return (episode: next, complete: true);
    }

    return (episode: null, complete: complete);
  }

  /// Fetches season details, bypassing the cache when [forceRemote] is set so
  /// newly aired episodes are discovered.
  Future<Map<String, dynamic>> _seasonDetailsForRefresh(
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

  @override
  Future<ActorDetails> getActorDetails(int actorId) async {
    await _ensureInitialized();
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

  @override
  Future<void> addToList(MediaItem item, String listName) async {
    await _ensureInitialized();
    await cache.cacheItem(item);
    await localDataSource.addToList(
      id: item.id,
      type: item.mediaType.name,
      listName: listName,
      title: item.title,
    );
    try {
      final details = await getMediaDetails(item.id, type: item.mediaType);
      if (item.mediaType == MediaType.tv && details.item.seasons != null) {
        for (final season in details.item.seasons!) {
          await getSeasonDetails(item.id, season.seasonNumber);
        }
      }
    } catch (e) {
      debugPrint('[Repo] addToList details prefetch failed: $e');
    }
  }

  @override
  Future<void> removeFromList(int id, MediaType type, String listName) async {
    await _ensureInitialized();
    return localDataSource.removeFromList(id, type.name, listName);
  }

  @override
  Future<List<String>> getListEntries(String listName) async {
    await _ensureInitialized();
    return localDataSource.getListEntries(listName);
  }

  @override
  Future<bool> isInList(int id, MediaType type, String listName) async {
    await _ensureInitialized();
    final entries = await localDataSource.getListEntries(listName);
    return entries.contains('$id:${type.name}');
  }

  @override
  Future<List<String>> getAllListNames() async {
    await _ensureInitialized();
    return localDataSource.getAllListNames();
  }

  @override
  Future<void> createList(String name) async {
    await _ensureInitialized();
    return localDataSource.createList(name);
  }

  @override
  Future<void> deleteList(String name) async {
    await _ensureInitialized();
    return localDataSource.deleteList(name);
  }

  @override
  Future<void> updateListOrder(
    String listName,
    List<String> orderedEntries,
  ) async {
    await _ensureInitialized();
    return localDataSource.updateListOrder(listName, orderedEntries);
  }

  @override
  Future<void> addToWatchlist(MediaItem item) {
    return addToList(item, 'watchlist');
  }

  @override
  Future<void> removeFromWatchlist(int id, MediaType type) {
    return removeFromList(id, type, 'watchlist');
  }

  @override
  Future<List<String>> getWatchlistEntries() {
    return getListEntries('watchlist');
  }

  @override
  Future<bool> isInWatchlist(int id, MediaType type) {
    return isInList(id, type, 'watchlist');
  }

  @override
  Future<List<MediaItemPreview>> getListPreviews(
    String listName, {
    int limit = 4,
  }) async {
    await _ensureInitialized();
    final items = await localDataSource.getListItems(listName);
    return items.take(limit).map((item) {
      final type = item.type == 'movie' ? MediaType.movie : MediaType.tv;
      final cachedItem = cache.getItem(item.id, type);
      return MediaItemPreview(
        id: item.id,
        title: item.title,
        posterPath: cachedItem?.posterPath,
        type: item.type,
      );
    }).toList();
  }

  @override
  Future<void> markAsSeen(SeenItem item) async {
    await _ensureInitialized();

    int? runtime = item.runtime;
    List<String>? genres = item.genres;

    if (runtime == null || genres == null) {
      try {
        final details = await getMediaDetails(item.tmdbId, type: item.type);
        genres ??= details.item.genres;
        if (item.type == MediaType.movie) {
          runtime = details.item.runtime;
        } else if (item.seasonNumber != null && item.episodeNumber != null) {
          final seasonDetails = await getSeasonDetails(
            item.tmdbId,
            item.seasonNumber!,
          );
          final episodes = seasonDetails['episodes'] as List?;
          final episode = episodes?.firstWhere(
            (e) => e['episode_number'] == item.episodeNumber,
            orElse: () => null,
          );
          if (episode != null) {
            runtime = episode['runtime'] as int?;
          }
        }
      } catch (e) {
        debugPrint('[Repo] markAsSeen runtime lookup failed: $e');
      }
    }

    await localDataSource.markAsSeen(
      SeenItemModel(
        tmdbId: item.tmdbId,
        type: item.type.name,
        title: item.title,
        posterPath: item.posterPath,
        seenDate: item.seenDate,
        seasonNumber: item.seasonNumber,
        episodeNumber: item.episodeNumber,
        runtime: runtime,
        genres: genres,
      ),
    );

    // If it's a movie, remove it from watchlist (not other lists as per requirement)
    if (item.type == MediaType.movie) {
      await removeFromWatchlist(item.tmdbId, item.type);
    }

    // Trigger update of notification date when progress changes. If the episode
    // just marked is the latest of the streak, refresh from the network
    // (bypassing caches) so newly released episodes show up immediately. This is
    // awaited so callers reloading notified items observe the reconciled state.
    await _refreshNotificationAfterSeen(item);

    // After marking as seen, for TV items compute next unseen episode for THIS streak
    try {
      if (item.type == MediaType.tv &&
          item.seasonNumber != null &&
          item.episodeNumber != null) {
        // remove any quick-add that referred to the episode we just marked as seen
        try {
          await localDataSource.removeQuickAddItemByTmdbSeasonEpisode(
            item.tmdbId,
            seasonNumber: item.seasonNumber,
            episodeNumber: item.episodeNumber,
          );
        } catch (e) {
          debugPrint('[Repo] markAsSeen quick-add removal failed: $e');
        }

        // compute next unseen episode starting after the one just marked
        final seen = await localDataSource.getSeenStatus(item.tmdbId, 'tv');

        MediaItem? detailsItem = cache.getItem(item.tmdbId, MediaType.tv);
        if (detailsItem == null) {
          try {
            detailsItem = await remoteDataSource.getMediaItem(
              item.tmdbId,
              type: MediaType.tv,
            );
            await cache.cacheItem(detailsItem);
          } catch (_) {
            detailsItem = null;
          }
        }

        if (detailsItem?.seasons != null) {
          // Build map of last seen timestamp per episode so we can determine
          // if an episode was seen after the one we just marked (chronological).
          final Map<int, Map<int, DateTime>> lastSeenMap = {};
          for (final s in seen) {
            if (s.seasonNumber == null || s.episodeNumber == null) continue;
            final season = s.seasonNumber!;
            final ep = s.episodeNumber!;
            final mapForSeason = lastSeenMap.putIfAbsent(season, () => {});
            final prevSeen = mapForSeason[ep];
            mapForSeason[ep] =
                (prevSeen == null || prevSeen.isBefore(s.seenDate))
                ? s.seenDate
                : prevSeen;
          }

          final sortedSeasons = List<TVSeason>.from(detailsItem!.seasons!)
            ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

          final startSeason = item.seasonNumber!;
          final startEpisode = item.episodeNumber! + 1;
          DateTime? foundAirDate;
          int? foundSeason;
          int? foundEpisode;
          int? foundRuntime;

          for (final season in sortedSeasons) {
            if (season.seasonNumber == 0) continue;
            if (season.seasonNumber < startSeason) continue;

            try {
              final seasonDetails = await getSeasonDetails(
                detailsItem.id,
                season.seasonNumber,
              );
              final episodes = seasonDetails['episodes'] as List?;
              for (final ep in episodes ?? []) {
                final epNum = ep['episode_number'] as int;

                if (season.seasonNumber == startSeason &&
                    epNum < startEpisode) {
                  continue;
                }

                final lastSeenForEp = lastSeenMap[season.seasonNumber]?[epNum];
                final isEpSeenAfterMark =
                    lastSeenForEp != null &&
                    // Treat equal timestamps as "after" for tail grouping
                    !lastSeenForEp.isBefore(item.seenDate);
                if (isEpSeenAfterMark) {
                  continue;
                }

                final airDateStr = ep['air_date'] as String?;
                if (airDateStr == null || airDateStr.isEmpty) {
                  continue;
                }

                try {
                  final ad = DateTime.parse(airDateStr);
                  if (ad.isAfter(DateTime.now())) {
                    continue;
                  }
                  foundAirDate = ad;
                } catch (_) {
                  continue;
                }

                foundSeason = season.seasonNumber;
                foundEpisode = epNum;
                foundRuntime = ep['runtime'] as int?;
                break;
              }
            } catch (e) {
              debugPrint('[Repo] markAsSeen season scan failed: $e');
            }
            if (foundSeason != null) break;
          }

          if (foundSeason != null && foundEpisode != null) {
            // Respect the opt-out recorded when the user dismissed this episode
            // (the UI keys it by the dismissed episode, not the streak tail).
            final optedOut = await localDataSource.isOptedOut(
              item.tmdbId,
              seasonNumber: foundSeason,
              episodeNumber: foundEpisode,
            );
            if (!optedOut) {
              final quick = QuickAddItemModel(
                tmdbId: item.tmdbId,
                type: 'tv',
                seasonNumber: foundSeason,
                episodeNumber: foundEpisode,
                insertedAt: item.seenDate,
                airDate: foundAirDate,
                title: detailsItem.title,
                runtime: foundRuntime,
                posterPath: detailsItem.posterPath,
              );
              await localDataSource.addQuickAddItem(quick);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Repo] markAsSeen next-episode computation failed: $e');
    }
  }

  /// Reconciles the notification for a just-seen episode.
  ///
  /// When it is the latest episode of the streak a forced network refresh is
  /// used so the Releases entry advances to newly aired episodes; otherwise the
  /// cached details are enough.
  Future<void> _refreshNotificationAfterSeen(SeenItem item) async {
    try {
      if (item.type == MediaType.tv &&
          item.seasonNumber != null &&
          item.episodeNumber != null) {
        final seen = await localDataSource.getSeenStatus(item.tmdbId, 'tv');
        final tail = findLatestTail(seen);
        final isTail =
            tail != null &&
            tail.seasonNumber == item.seasonNumber &&
            tail.episodeNumber == item.episodeNumber;
        if (isTail) {
          await refreshNotificationForSeries(
            item.tmdbId,
            MediaType.tv,
            force: true,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('[Repo] _refreshNotificationAfterSeen failed: $e');
    }
    await _refreshNotificationDateByTmdbId(item.tmdbId, item.type);
  }

  Future<void> _refreshNotificationDateByTmdbId(
    int tmdbId,
    MediaType type,
  ) async {
    try {
      final item = cache.getItem(tmdbId, type);
      if (item != null) {
        await _refreshNotificationDate(item);
      } else {
        final details = await getMediaDetails(tmdbId, type: type);
        await _refreshNotificationDate(details.item);
      }
    } catch (e) {
      debugPrint('[Repo] _refreshNotificationDateByTmdbId failed: $e');
    }
  }

  @override
  Future<void> removeFromSeen(
    int tmdbId,
    MediaType type, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _ensureInitialized();
    await localDataSource.removeFromSeen(
      tmdbId,
      type.name,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    unawaited(_refreshNotificationDateByTmdbId(tmdbId, type));
  }

  @override
  Future<void> updateSeenEntry(SeenItem item) async {
    await _ensureInitialized();
    final model = SeenItemModel(
      tmdbId: item.tmdbId,
      type: item.type.name,
      title: item.title,
      posterPath: item.posterPath,
      seenDate: item.seenDate,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
      runtime: item.runtime,
      genres: item.genres,
    );
    model.isarId = item.id;
    await localDataSource.markAsSeen(model);
  }

  @override
  Future<void> deleteSeenEntry(int id) async {
    await _ensureInitialized();
    final entry = await localDataSource.getSeenEntryByIsarId(id);
    if (entry != null) {
      final tmdbId = entry.tmdbId;
      final type = entry.type == 'movie' ? MediaType.movie : MediaType.tv;
      await localDataSource.deleteSeenEntry(id);
      unawaited(_refreshNotificationDateByTmdbId(tmdbId, type));
    }
  }

  @override
  Future<List<SeenItem>> getSeenItems() async {
    await _ensureInitialized();
    final items = await localDataSource.getAllSeenItems();
    final List<SeenItem> results = [];

    for (final m in items) {
      final type = m.type == 'movie' ? MediaType.movie : MediaType.tv;
      final cachedItem = cache.getItem(m.tmdbId, type);
      String? posterPath = m.posterPath;
      final cachedPoster = cachedItem?.posterPath;

      if (posterPath == null && cachedPoster != null) {
        posterPath = cachedPoster;
        unawaited(
          localDataSource.updatePosterPath(m.tmdbId, m.type, posterPath),
        );
      }

      results.add(
        SeenItem(
          id: m.isarId,
          tmdbId: m.tmdbId,
          type: type,
          title: m.title,
          posterPath: posterPath,
          seenDate: m.seenDate,
          seasonNumber: m.seasonNumber,
          episodeNumber: m.episodeNumber,
          runtime: m.runtime,
          genres: m.genres,
        ),
      );
    }
    return results;
  }

  @override
  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type) async {
    await _ensureInitialized();
    final items = await localDataSource.getSeenStatus(tmdbId, type.name);
    final cachedItem = cache.getItem(tmdbId, type);

    final List<SeenItem> results = [];
    for (final m in items) {
      String? posterPath = m.posterPath;
      final cachedPoster = cachedItem?.posterPath;

      if (posterPath == null && cachedPoster != null) {
        posterPath = cachedPoster;
        unawaited(localDataSource.updatePosterPath(tmdbId, m.type, posterPath));
      }

      results.add(
        SeenItem(
          id: m.isarId,
          tmdbId: m.tmdbId,
          type: m.type == 'movie' ? MediaType.movie : MediaType.tv,
          title: m.title,
          posterPath: posterPath,
          seenDate: m.seenDate,
          seasonNumber: m.seasonNumber,
          episodeNumber: m.episodeNumber,
          runtime: m.runtime,
          genres: m.genres,
        ),
      );
    }
    return results;
  }

  @override
  Future<Map<String, dynamic>> getSeasonDetails(
    int tvId,
    int seasonNumber,
  ) async {
    await _ensureInitialized();
    if (cache.isSeasonCached(tvId, seasonNumber)) {
      return cache.getSeason(tvId, seasonNumber)!;
    }

    try {
      final details = await remoteDataSource.getSeasonDetails(
        tvId,
        seasonNumber,
      );
      await cache.cacheSeason(tvId, seasonNumber, details);
      return details;
    } catch (e) {
      return cache.getSeason(tvId, seasonNumber) ?? (throw e);
    }
  }

  @override
  Future<int> getCacheSize() async {
    await _ensureInitialized();
    return cache.getCacheSize();
  }

  @override
  Future<int> getSeenDbSize() async {
    await _ensureInitialized();
    return localDataSource.getSeenDbSize();
  }

  @override
  Future<void> clearCache({required bool complete}) async {
    await _ensureInitialized();
    if (complete) {
      await cache.clearAll();
    } else {
      await _initCache();
    }
  }

  @override
  Future<void> fillCache() async {
    await _ensureInitialized();
    await _initCache();
  }

  /// Fills missing runtime/genres from TMDB. Network only: writes nothing, so
  /// it can run before the import transaction.
  Future<List<SeenItemModel>> _enrichSeenData(
    List<SeenItemModel> data, {
    Function(double progress, String status)? onProgress,
  }) async {
    final List<SeenItemModel> items = [];
    final total = data.length;

    for (int i = 0; i < total; i++) {
      final model = data[i];
      int? runtime = model.runtime;
      List<String>? genres = model.genres;
      final tmdbId = model.tmdbId;
      final typeStr = model.type;
      final type = typeStr == 'movie' ? MediaType.movie : MediaType.tv;
      final seasonNumber = model.seasonNumber;
      final episodeNumber = model.episodeNumber;
      final title = model.title;

      if (onProgress != null) {
        onProgress(i / total, 'Processing $title...');
      }

      if (runtime == null || genres == null) {
        try {
          final details = await getMediaDetails(tmdbId, type: type);
          genres ??= details.item.genres;
          if (type == MediaType.movie) {
            runtime = details.item.runtime;
          } else if (seasonNumber != null && episodeNumber != null) {
            final seasonDetails = await getSeasonDetails(tmdbId, seasonNumber);
            final episodes = seasonDetails['episodes'] as List?;
            final episode = episodes?.firstWhere(
              (e) => e['episode_number'] == episodeNumber,
              orElse: () => null,
            );
            if (episode != null) {
              runtime = episode['runtime'] as int?;
            }
          }
        } catch (e) {
          debugPrint('[Repo] _importSeenData runtime enrichment failed: $e');
        }
      }

      items.add(
        SeenItemModel(
          tmdbId: tmdbId,
          type: typeStr,
          title: title,
          posterPath: model.posterPath,
          seenDate: model.seenDate,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          runtime: runtime,
          genres: genres,
        ),
      );
    }

    return items;
  }

  @override
  Future<List<int>> exportAllData() async {
    await _ensureInitialized();
    final seenModels = await localDataSource.getExportData();
    final likedModels = await localDataSource.getLikedItems();
    final notifiedModels = await localDataSource.getNotifiedItems();
    final quickAddModels = await localDataSource.getQuickAddItems();

    final names = await localDataSource.getAllListNames();
    final Map<String, List<MediaListItem>> lists = {};
    for (final name in names) {
      lists[name] = await localDataSource.getListItems(name);
    }

    final envelope = ExportEnvelope(
      version: 1,
      exportedAt: DateTime.now(),
      seen: seenModels,
      likes: likedModels,
      notifications: notifiedModels,
      quickAdd: quickAddModels,
      lists: lists,
    );

    return envelope.toZipBytes();
  }

  @override
  Future<void> importAllData(
    List<int> zipBytes, {
    ImportMode mode = ImportMode.append,
    Function(double, String)? onProgress,
  }) async {
    await _ensureInitialized();
    final envelope = ExportEnvelope.fromZipBytes(zipBytes);

    // Network enrichment first (no DB writes), then a single transaction for
    // every collection: a failure at any stage leaves the database unchanged.
    final seenItems = await _enrichSeenData(
      envelope.seen,
      onProgress: (p, s) => onProgress?.call(p * 0.9, s),
    );

    onProgress?.call(0.9, 'Saving entries...');
    await localDataSource.importAll(
      mode: mode,
      seen: seenItems,
      likes: envelope.likes,
      notifications: envelope.notifications,
      quickAdd: envelope.quickAdd,
      lists: envelope.lists,
    );
    onProgress?.call(1.0, 'Import complete');
  }

  @override
  Future<void> toggleLike(MediaItem item) async {
    await _ensureInitialized();
    await localDataSource.toggleLike(
      tmdbId: item.id,
      type: item.mediaType.name,
      title: item.title,
    );
    await cache.cacheItem(item);
  }

  @override
  Future<bool> isLiked(int tmdbId, MediaType type) async {
    await _ensureInitialized();
    return localDataSource.isLiked(tmdbId, type.name);
  }

  @override
  Future<List<String>> getLikedEntries() async {
    await _ensureInitialized();
    final items = await localDataSource.getLikedItems();
    return items.map((e) => '${e.tmdbId}:${e.type}').toList();
  }

  @override
  Future<void> toggleNotification(
    MediaItem item, {
    bool autoNotify = false,
  }) async {
    await _ensureInitialized();

    final isNotified = await localDataSource.isNotified(
      item.id,
      item.mediaType.name,
    );

    if (isNotified && !autoNotify) {
      await localDataSource.toggleNotification(
        tmdbId: item.id,
        type: item.mediaType.name,
        title: item.title,
      );
    } else {
      await localDataSource.toggleNotification(
        tmdbId: item.id,
        type: item.mediaType.name,
        title: item.title,
        posterPath: item.posterPath,
        runtime: item.runtime,
        autoNotify: autoNotify,
      );
      await _refreshNotificationDate(item);
    }

    await cache.cacheItem(item);
  }

  @override
  Future<bool> isNotified(int tmdbId, MediaType type) async {
    await _ensureInitialized();
    return localDataSource.isNotified(tmdbId, type.name);
  }

  @override
  Future<List<NotifiedItem>> getNotifiedItems() async {
    await _ensureInitialized();
    final items = await localDataSource.getNotifiedItems();
    return items
        .map(
          (m) => NotifiedItem(
            tmdbId: m.tmdbId,
            type: m.type == 'movie' ? MediaType.movie : MediaType.tv,
            title: m.title,
            posterPath: m.posterPath,
            releaseDate: m.releaseDate,
            seasonNumber: m.seasonNumber,
            episodeNumber: m.episodeNumber,
            runtime: m.runtime,
            autoNotify: m.autoNotify,
          ),
        )
        .toList();
  }

  @override
  Stream<void> watchNotifiedItems() {
    return localDataSource.watchNotifiedItems();
  }

  @override
  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _ensureInitialized();
    return localDataSource.addOptOut(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  @override
  Future<void> clearOptOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _ensureInitialized();
    return localDataSource.removeOptOut(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  @override
  Future<void> refreshNotifiedItems({bool force = false}) async {
    await _ensureInitialized();
    final notifiedItems = await localDataSource.getNotifiedItems();
    final now = DateTime.now();

    // Refresh one series at a time (never all at once) so the device is not
    // overloaded; yield between items to keep the UI responsive.
    for (final notified in notifiedItems) {
      final type = notified.type == 'movie' ? MediaType.movie : MediaType.tv;
      if (!force && !_needsNotificationRefresh(notified, now)) continue;
      await refreshNotificationForSeries(notified.tmdbId, type, force: force);
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<void> refreshNotificationForSeries(
    int tmdbId,
    MediaType type, {
    bool force = false,
  }) async {
    await _ensureInitialized();
    final notified = await localDataSource.getNotifiedItem(tmdbId, type.name);
    if (notified == null) return;

    final now = DateTime.now();
    if (!force && !_needsNotificationRefresh(notified, now)) return;

    try {
      final item = await remoteDataSource.getMediaItem(tmdbId, type: type);
      await cache.cacheItem(item);

      await _refreshNotificationDate(item, forceRemoteSeasons: force);

      // Keep Quick Add in sync in the same pass. populateQuickAddFromSeenHistory
      // is cache-first and reuses the seasons just fetched above, so returning
      // series pick up newly aired episodes without any extra network work.
      if (type == MediaType.tv) {
        await populateQuickAddFromSeenHistory(tmdbId: tmdbId);
      }

      await localDataSource.markNotifiedRefreshed(tmdbId, type.name, now);
    } catch (e) {
      debugPrint('[Repo] refreshNotificationForSeries failed: $e');
    }
  }

  /// Whether a notified entry is missing information and therefore worth a
  /// network refresh, respecting the once-a-day throttle unless forced.
  bool _needsNotificationRefresh(NotifiedItemModel notified, DateTime now) {
    final last = notified.lastRefreshedAt;
    if (last != null && now.difference(last) < const Duration(days: 1)) {
      return false;
    }

    final release = notified.releaseDate;
    return release == null || !release.isAfter(now);
  }

  @override
  Future<void> refreshQuickAddItems() async {
    await _ensureInitialized();
    final items = await localDataSource.getQuickAddItems();

    for (final item in items) {
      if (item.runtime != null) continue;
      if (item.type != 'tv') continue;
      final seasonNumber = item.seasonNumber;
      final episodeNumber = item.episodeNumber;
      if (seasonNumber == null ||
          episodeNumber == null ||
          item.isarId == null) {
        continue;
      }

      try {
        final seasonDetails = await getSeasonDetails(item.tmdbId, seasonNumber);
        final episodes = seasonDetails['episodes'] as List?;
        int? runtime;
        if (episodes != null) {
          for (final ep in episodes) {
            if (ep['episode_number'] == episodeNumber) {
              runtime = ep['runtime'] as int?;
              break;
            }
          }
        }
        if (runtime != null) {
          await localDataSource.updateQuickAddItemRuntime(
            item.isarId!,
            runtime,
          );
        }
      } catch (e) {
        debugPrint('[Repo] refreshQuickAddItems runtime update failed: $e');
      }
    }
  }

  @override
  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) async {
    await _ensureInitialized();
    try {
      final results = await remoteDataSource.getSimilarMedia(id, type);
      for (final item in results) {
        await cache.cacheItem(item);
      }
      return results;
    } catch (e) {
      debugPrint('[Repo] getSimilarMedia error: $e');
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) async {
    await _ensureInitialized();
    try {
      final results = await remoteDataSource.getRecommendedMedia(id, type);
      for (final item in results) {
        await cache.cacheItem(item);
      }
      return results;
    } catch (e) {
      debugPrint('[Repo] getRecommendedMedia error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) async {
    await _ensureInitialized();
    try {
      return await remoteDataSource.getWatchProviders(id, type);
    } catch (e) {
      debugPrint('[Repo] getWatchProviders error: $e');
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) async {
    await _ensureInitialized();
    try {
      return await remoteDataSource.getVideos(id, type);
    } catch (e) {
      debugPrint('[Repo] getVideos error: $e');
      return [];
    }
  }

  @override
  Future<List<QuickAddItem>> getQuickAddItems() async {
    await _ensureInitialized();
    final items = await localDataSource.getQuickAddItems();
    return items
        .map(
          (m) => QuickAddItem(
            isarId: m.isarId,
            tmdbId: m.tmdbId,
            type: m.type == 'movie' ? MediaType.movie : MediaType.tv,
            seasonNumber: m.seasonNumber,
            episodeNumber: m.episodeNumber,
            insertedAt: m.insertedAt,
            airDate: m.airDate,
            title: m.title,
            posterPath: m.posterPath,
            runtime: m.runtime,
          ),
        )
        .toList();
  }

  @override
  Future<List<QuickAddOmission>> getQuickAddOmissions({
    bool allowFetch = false,
  }) async {
    await _ensureInitialized();
    final omissions = <QuickAddOmission>[];
    final seenOmissionKeys = <String>{};

    try {
      final seenItems = await localDataSource.getAllSeenItems();
      final tvIds = seenItems
          .where((s) => s.type == 'tv')
          .map((s) => s.tmdbId)
          .toSet();
      if (tvIds.isEmpty) return omissions;

      final existingQuick = await localDataSource.getQuickAddItems();
      final existingKeysByTv = <int, Set<String>>{};
      for (final q in existingQuick) {
        existingKeysByTv
            .putIfAbsent(q.tmdbId, () => <String>{})
            .add('${q.seasonNumber}:${q.episodeNumber}');
      }

      for (final tmdbId in tvIds) {
        final seen = await localDataSource.getSeenStatus(tmdbId, 'tv');
        if (seen.isEmpty) continue;

        MediaItem? resolved = cache.getItem(tmdbId, MediaType.tv);
        if (resolved?.seasons == null && allowFetch) {
          try {
            resolved = await remoteDataSource.getMediaItem(
              tmdbId,
              type: MediaType.tv,
            );
            await cache.cacheItem(resolved);
          } catch (e) {
            debugPrint('[Repo] getQuickAddOmissions item resolve failed: $e');
          }
        }

        final seasons = resolved?.seasons;
        final title =
            resolved?.title ?? (seen.isNotEmpty ? seen.first.title : 'Unknown');
        final posterPath = resolved?.posterPath;

        if (seasons == null) {
          if (seenOmissionKeys.add('noCacheData|$tmdbId')) {
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                reason: QuickAddOmissionReason.noCacheData,
              ),
            );
          }
          continue;
        }

        // Latest seen date per (season, episode).
        final lastSeenMap = <int, Map<int, DateTime>>{};
        for (final s in seen) {
          final season = s.seasonNumber;
          final ep = s.episodeNumber;
          if (season == null || ep == null) continue;
          final mapForSeason = lastSeenMap.putIfAbsent(season, () => {});
          final prev = mapForSeason[ep];
          mapForSeason[ep] = (prev == null || prev.isBefore(s.seenDate))
              ? s.seenDate
              : prev;
        }

        final sortedSeasons = List<TVSeason>.from(seasons)
          ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

        // Season lookup is cache-first. Only [allowFetch] triggers a network
        // call, and each season is fetched at most once per show.
        final seasonMemo = <int, Map<String, dynamic>?>{};
        Future<Map<String, dynamic>?> seasonFor(int seasonNumber) async {
          if (seasonMemo.containsKey(seasonNumber)) {
            return seasonMemo[seasonNumber];
          }
          Map<String, dynamic>? data = cache.getSeason(tmdbId, seasonNumber);
          if (data == null && allowFetch) {
            try {
              data = await getSeasonDetails(tmdbId, seasonNumber);
            } catch (_) {
              data = null;
            }
          }
          seasonMemo[seasonNumber] = data;
          return data;
        }

        final existingForTv = existingKeysByTv[tmdbId] ?? const <String>{};

        final seenSorted = List.from(seen)
          ..sort((a, b) {
            final dateCmp = b.seenDate.compareTo(a.seenDate);
            if (dateCmp != 0) return dateCmp;
            final aSeason = a.seasonNumber ?? 0;
            final bSeason = b.seasonNumber ?? 0;
            if (aSeason != bSeason) return aSeason.compareTo(bSeason);
            return (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0);
          });

        for (final s in seenSorted) {
          final tailSeason = s.seasonNumber;
          final tailEpisode = s.episodeNumber;
          if (tailSeason == null || tailEpisode == null) continue;

          final tailSeenDate = s.seenDate;
          final startEpisode = tailEpisode + 1;

          int? foundSeason;
          int? foundEpisode;
          DateTime? foundAirDate;
          DateTime? firstFutureAirDate;
          int? futureSeason;
          int? futureEpisode;
          int? noAirDateSeason;
          int? noAirDateEpisode;
          var hadNoAirDate = false;
          var cacheMiss = false;

          for (final season in sortedSeasons) {
            if (season.seasonNumber == 0) continue;
            if (season.seasonNumber < tailSeason) continue;

            final seasonData = await seasonFor(season.seasonNumber);
            if (seasonData == null) {
              // Can't inspect this season without a fetch; stop scanning.
              cacheMiss = true;
              break;
            }

            final episodes = seasonData['episodes'] as List?;
            // Ignore seasons with no dated episodes at all (e.g. an announced but
            // unscheduled next season): they are not actionable in Quick Add and
            // must not surface as "no air date".
            final hasDatedEpisode = (episodes ?? const []).any((ep) {
              final airDate = (ep is Map) ? ep['air_date'] as String? : null;
              return airDate != null &&
                  airDate.isNotEmpty &&
                  DateTime.tryParse(airDate) != null;
            });
            if (!hasDatedEpisode) continue;

            for (final ep in episodes ?? []) {
              final epNum = ep['episode_number'] as int?;
              if (epNum == null) continue;
              if (season.seasonNumber == tailSeason && epNum < startEpisode) {
                continue;
              }

              final lastSeenForEp = lastSeenMap[season.seasonNumber]?[epNum];
              final isEpSeenAfterTail =
                  lastSeenForEp != null &&
                  !lastSeenForEp.isBefore(tailSeenDate);
              if (isEpSeenAfterTail) continue;

              final airDateStr = ep['air_date'] as String?;
              if (airDateStr == null || airDateStr.isEmpty) {
                hadNoAirDate = true;
                noAirDateSeason ??= season.seasonNumber;
                noAirDateEpisode ??= epNum;
                continue;
              }

              DateTime ad;
              try {
                ad = DateTime.parse(airDateStr);
              } catch (_) {
                hadNoAirDate = true;
                continue;
              }

              if (ad.isAfter(DateTime.now())) {
                if (firstFutureAirDate == null ||
                    ad.isBefore(firstFutureAirDate)) {
                  firstFutureAirDate = ad;
                  futureSeason = season.seasonNumber;
                  futureEpisode = epNum;
                }
                continue;
              }

              foundSeason = season.seasonNumber;
              foundEpisode = epNum;
              foundAirDate = ad;
              break;
            }

            if (foundSeason != null) break;
          }

          if (foundSeason != null && foundEpisode != null) {
            final key = '$foundSeason:$foundEpisode';
            if (existingForTv.contains(key)) {
              continue; // Already shown in Quick Add.
            }

            final optedOut = await localDataSource.isOptedOut(
              tmdbId,
              seasonNumber: foundSeason,
              episodeNumber: foundEpisode,
            );
            final reason = optedOut
                ? QuickAddOmissionReason.optedOut
                : QuickAddOmissionReason.notPopulated;
            if (!seenOmissionKeys.add(
              '${reason.name}|$tmdbId|$foundSeason|$foundEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                seasonNumber: foundSeason,
                episodeNumber: foundEpisode,
                airDate: foundAirDate,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: reason,
              ),
            );
            continue;
          }

          if (firstFutureAirDate != null) {
            if (!seenOmissionKeys.add(
              'notReleased|$tmdbId|$futureSeason|$futureEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                seasonNumber: futureSeason,
                episodeNumber: futureEpisode,
                airDate: firstFutureAirDate,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: QuickAddOmissionReason.notReleased,
              ),
            );
            continue;
          }

          if (cacheMiss) {
            if (!seenOmissionKeys.add(
              'noCacheData|$tmdbId|$tailSeason|$tailEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: QuickAddOmissionReason.noCacheData,
              ),
            );
            continue;
          }

          if (hadNoAirDate) {
            if (!seenOmissionKeys.add(
              'noAirDate|$tmdbId|$noAirDateSeason|$noAirDateEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                seasonNumber: noAirDateSeason,
                episodeNumber: noAirDateEpisode,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: QuickAddOmissionReason.noAirDate,
              ),
            );
          }
          // Otherwise the show is fully caught up: nothing expected.
        }
      }
    } catch (e) {
      debugPrint('[Repo] getQuickAddOmissions error: $e');
    }

    return omissions;
  }

  @override
  Future<void> refreshReturningSeries(int tmdbId) async {
    await _ensureInitialized();
    try {
      final type = MediaType.tv;

      // 1. Fetch TV details
      final itemFuture = remoteDataSource.getMediaItem(tmdbId, type: type);
      final creditsFuture = remoteDataSource.getMediaCredits(
        tmdbId,
        type: type,
      );
      final similarFuture = remoteDataSource.getSimilarMedia(tmdbId, type);
      final recommendationsFuture = remoteDataSource.getRecommendedMedia(
        tmdbId,
        type,
      );
      final watchProvidersFuture = remoteDataSource.getWatchProviders(
        tmdbId,
        type,
      );
      final videosFuture = remoteDataSource.getVideos(tmdbId, type);

      final item = await itemFuture;

      Map<String, dynamic> credits = {'cast': [], 'crew': []};
      try {
        credits = await creditsFuture;
      } catch (e) {
        debugPrint('[Repo] refreshReturningSeries credits failed: $e');
      }

      final List castResults = credits['cast'] ?? [];
      final List crewResults = credits['crew'] ?? [];
      final List<CastMember> cast = castResults
          .map((c) => CastMember.fromJson(c))
          .toList();
      final CrewMember? director =
          crewResults.firstWhere(
                (c) => c['job'] == 'Director',
                orElse: () => null,
              ) !=
              null
          ? CrewMember.fromJson(
              crewResults.firstWhere((c) => c['job'] == 'Director'),
            )
          : null;

      final similar = await similarFuture;
      final recommendations = await recommendationsFuture;
      final watchProviders = await watchProvidersFuture;
      final videos = await videosFuture;

      final details = MediaDetails(
        item: item,
        cast: cast,
        director: director,
        similar: similar,
        recommendations: recommendations,
        watchProviders: watchProviders,
        videos: videos,
      );

      // Overwrite the cache
      await cache.cacheItem(item);
      await cache.cacheDetails(details);

      // 2. Fetch latest season
      final lastSeasonNum = item.numberOfSeasons;
      if (lastSeasonNum != null && lastSeasonNum > 0) {
        final seasonDetails = await remoteDataSource.getSeasonDetails(
          tmdbId,
          lastSeasonNum,
        );
        await cache.cacheSeason(tmdbId, lastSeasonNum, seasonDetails);
      }

      // 3. Update Quick Add logic to pick up new episodes
      await populateQuickAddFromSeenHistory(tmdbId: tmdbId);

      // 4. Keep the Releases entry in sync, bypassing caches for fresh episodes.
      await _refreshNotificationDate(item, forceRemoteSeasons: true);
      await localDataSource.markNotifiedRefreshed(
        tmdbId,
        MediaType.tv.name,
        DateTime.now(),
      );
    } catch (e) {
      debugPrint("Failed to refresh returning series $tmdbId: $e");
    }
  }

  @override
  Future<void> addQuickAddItem(QuickAddItem item) async {
    await _ensureInitialized();
    final model = QuickAddItemModel(
      tmdbId: item.tmdbId,
      type: item.type == MediaType.movie ? 'movie' : 'tv',
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
      insertedAt: item.insertedAt,
      airDate: item.airDate,
      title: item.title,
      posterPath: item.posterPath,
      runtime: item.runtime,
    );
    return localDataSource.addQuickAddItem(model);
  }

  @override
  Future<void> removeQuickAddItemById(int isarId) async {
    await _ensureInitialized();
    return localDataSource.removeQuickAddItemById(isarId);
  }

  @override
  Future<void> populateQuickAddFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  }) async {
    await _ensureInitialized();
    try {
      final seenItems = await localDataSource.getAllSeenItems();
      var tvIds = seenItems
          .where((s) => s.type == 'tv')
          .map((s) => s.tmdbId)
          .toSet();

      // If caller requested a specific tmdbId, restrict to it (if present in seen)
      if (tmdbId != null) {
        if (tvIds.contains(tmdbId)) {
          tvIds = {tmdbId};
        } else {
          // nothing to do
          return;
        }
      }

      final existingQuick = await localDataSource.getQuickAddItems();

      for (final tmdbId in tvIds) {
        final seen = await localDataSource.getSeenStatus(tmdbId, 'tv');

        MediaItem? detailsItem = cache.getItem(tmdbId, MediaType.tv);
        if (detailsItem == null) {
          try {
            detailsItem = await remoteDataSource.getMediaItem(
              tmdbId,
              type: MediaType.tv,
            );
            await cache.cacheItem(detailsItem);
          } catch (_) {
            detailsItem = null;
          }
        }

        if (detailsItem?.seasons != null) {
          // Build a map of the latest seen date per episode for quick timestamped lookup
          final Map<int, Map<int, DateTime>> lastSeenMap = {};
          for (final s in seen) {
            if (s.seasonNumber == null || s.episodeNumber == null) continue;
            final season = s.seasonNumber!;
            final ep = s.episodeNumber!;
            final mapForSeason = lastSeenMap.putIfAbsent(season, () => {});
            final prevSeen = mapForSeason[ep];
            mapForSeason[ep] =
                (prevSeen == null || prevSeen.isBefore(s.seenDate))
                ? s.seenDate
                : prevSeen;
          }

          // Existing quick-add candidates for this tmdbId
          final existingForId = existingQuick
              .where((q) => q.tmdbId == tmdbId)
              .map((q) => '${q.seasonNumber}:${q.episodeNumber}')
              .toSet();

          final sortedSeasons = List<TVSeason>.from(detailsItem!.seasons!)
            ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

          // For each seen episode (treated as a tail candidate), compute the next episode
          // that has NOT been seen after that seenDate. This respects chronological
          // order: if the successor was seen earlier but not after this seenDate, it
          // still counts as unseen for this tail.
          final Set<String> addedKeysForId = {};
          // iterate seen in reverse chronological order so most recent tails win for insertedAt
          final seenSorted = List.from(seen)
            ..sort((a, b) {
              final dateCmp = b.seenDate.compareTo(a.seenDate);
              if (dateCmp != 0) return dateCmp;
              // If seenDate is equal, order by season (ascending) then episode (ascending)
              final aSeason = a.seasonNumber ?? 0;
              final bSeason = b.seasonNumber ?? 0;
              if (aSeason != bSeason) return aSeason.compareTo(bSeason);
              final aEp = a.episodeNumber ?? 0;
              final bEp = b.episodeNumber ?? 0;
              return aEp.compareTo(bEp);
            });
          for (final s in seenSorted) {
            if (s.seasonNumber == null || s.episodeNumber == null) {
              continue;
            }
            // If caller requested a specific tail, skip other seen entries
            if (tailSeason != null && tailEpisode != null) {
              if (s.seasonNumber != tailSeason ||
                  s.episodeNumber != tailEpisode) {
                continue;
              }
            }
            final localTailSeason = s.seasonNumber!;
            final localTailEpisode = s.episodeNumber!;
            final tailSeenDate = s.seenDate;

            int startSeason = localTailSeason;
            int startEpisode = localTailEpisode + 1;

            DateTime? foundAirDate;
            int? foundSeason;
            int? foundEpisode;
            int? foundRuntime;

            for (final season in sortedSeasons) {
              if (season.seasonNumber == 0) {
                continue;
              }
              if (season.seasonNumber < startSeason) {
                continue;
              }

              try {
                final seasonDetails = await getSeasonDetails(
                  detailsItem.id,
                  season.seasonNumber,
                );
                final episodes = seasonDetails['episodes'] as List?;
                for (final ep in episodes ?? []) {
                  final epNum = ep['episode_number'] as int;

                  if (season.seasonNumber == startSeason &&
                      epNum < startEpisode) {
                    continue;
                  }

                  // Consider episode as "seen after tail" only if its last seen date
                  // is strictly after the tail's seenDate, which preserves
                  // re-watch streaks (a later tail can legitimately point at an
                  // episode seen earlier in a previous pass).
                  final lastSeenForEp =
                      lastSeenMap[season.seasonNumber]?[epNum];
                  final isEpSeenAfterTail =
                      lastSeenForEp != null &&
                      // Treat equal timestamps as "after" for tail grouping
                      !lastSeenForEp.isBefore(tailSeenDate);
                  if (isEpSeenAfterTail) {
                    continue;
                  }

                  final airDateStr = ep['air_date'] as String?;
                  if (airDateStr == null || airDateStr.isEmpty) {
                    continue;
                  }

                  try {
                    final ad = DateTime.parse(airDateStr);
                    if (ad.isAfter(DateTime.now())) {
                      // skip future episodes
                      continue;
                    }
                    foundAirDate = ad;
                  } catch (_) {
                    continue;
                  }

                  foundSeason = season.seasonNumber;
                  foundEpisode = epNum;
                  foundRuntime = ep['runtime'] as int?;
                  break;
                }
              } catch (e) {
                debugPrint('[Repo] populateQuickAddFromSeenHistory season scan failed: $e');
              }
              if (foundSeason != null) break;
            }

            if (foundSeason != null && foundEpisode != null) {
              final key = '$foundSeason:$foundEpisode';
              if (existingForId.contains(key) || addedKeysForId.contains(key)) {
                continue;
              }

              final optedOut = await localDataSource.isOptedOut(
                tmdbId,
                seasonNumber: foundSeason,
                episodeNumber: foundEpisode,
              );
              if (optedOut) {
                continue;
              }

              final quick = QuickAddItemModel(
                tmdbId: tmdbId,
                type: 'tv',
                seasonNumber: foundSeason,
                episodeNumber: foundEpisode,
                insertedAt: tailSeenDate,
                airDate: foundAirDate,
                title: detailsItem.title,
                runtime: foundRuntime,
                posterPath: detailsItem.posterPath,
              );
              await localDataSource.addQuickAddItem(quick);
              addedKeysForId.add(key);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Repo] populateQuickAddFromSeenHistory failed: $e');
    }
  }

  @override
  Future<void> clearQuickAddItems() async {
    await _ensureInitialized();
    return localDataSource.clearQuickAddItems();
  }

  @override
  Future<DateTime?> getCacheUpdateDate(int tmdbId, MediaType type) async {
    await _ensureInitialized();
    return cache.getCacheUpdateDate(tmdbId, type);
  }
}
