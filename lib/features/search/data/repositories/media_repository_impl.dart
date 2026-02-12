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
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

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
          } catch (_) {}
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
          } catch (_) {}
        }
      }

      // 3. Liked items
      final likedItems = await localDataSource.getLikedItems();
      for (final liked in likedItems) {
        keysToKeep.add('${liked.type}:${liked.tmdbId}');
        final type = liked.type == 'movie' ? MediaType.movie : MediaType.tv;
        try {
          await getMediaDetails(liked.tmdbId, type: type);
        } catch (_) {}
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
    } catch (_) {}

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
        collectionParts = await remoteDataSource.getCollectionParts(item.collectionId!);
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

  Future<void> _refreshNotificationDate(MediaItem item) async {
    final isNotified = await localDataSource.isNotified(
      item.id,
      item.mediaType.name,
    );
    if (!isNotified) return;

    DateTime? releaseDate;
    int? seasonNum;
    int? episodeNum;

    if (item.mediaType == MediaType.tv) {
      // Logic: Find the FIRST unseen episode air date
      final seen = await localDataSource.getSeenStatus(
        item.id,
        MediaType.tv.name,
      );

      // Use cached details if possible to avoid loops
      MediaItem? detailsItem = cache.getItem(item.id, MediaType.tv);
      if (detailsItem == null || detailsItem.seasons == null) {
        try {
          detailsItem = await remoteDataSource.getMediaItem(
            item.id,
            type: MediaType.tv,
          );
          await cache.cacheItem(detailsItem);
        } catch (_) {
          detailsItem = item;
        }
      }

      if (detailsItem.seasons != null) {
        final sortedSeasons = List<TVSeason>.from(detailsItem.seasons!)
          ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

        for (final season in sortedSeasons) {
          if (season.seasonNumber == 0) continue;

          try {
            final seasonDetails = await getSeasonDetails(
              detailsItem.id,
              season.seasonNumber,
            );
            final episodes = seasonDetails['episodes'] as List;
            for (final ep in episodes) {
              final epNum = ep['episode_number'] as int;
              final airDateStr = ep['air_date'] as String?;
              if (airDateStr == null) continue;

              final isEpSeen = seen.any(
                (s) =>
                    s.seasonNumber == season.seasonNumber &&
                    s.episodeNumber == epNum,
              );
              if (!isEpSeen) {
                releaseDate = DateTime.parse(airDateStr);
                seasonNum = season.seasonNumber;
                episodeNum = epNum;
                break;
              }
            }
          } catch (_) {}
          if (releaseDate != null) break;
        }
      }
    }

    if (releaseDate == null) {
      if (item.mediaType == MediaType.movie) {
        if (item.releaseDate.isNotEmpty) {
          try {
            releaseDate = DateTime.parse(item.releaseDate);
          } catch (_) {}
        }
      } else {
        if (item.nextEpisodeAirDate != null) {
          try {
            releaseDate = DateTime.parse(item.nextEpisodeAirDate!);
            seasonNum = item.nextSeasonNumber;
            episodeNum = item.nextEpisodeNumber;
          } catch (_) {}
        }
      }
    }

    // IMPORTANT: If a movie was released more than 1 month ago, we remove it from notification list
    if (item.mediaType == MediaType.movie && releaseDate != null) {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      if (releaseDate.isBefore(oneMonthAgo)) {
        await localDataSource.toggleNotification(
          tmdbId: item.id,
          type: item.mediaType.name,
          title: item.title,
        );
        return;
      }
    }

    if (releaseDate != null) {
      await localDataSource.updateNotificationDate(
        item.id,
        item.mediaType.name,
        releaseDate,
        seasonNumber: seasonNum,
        episodeNumber: episodeNum,
      );
    }
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
    } catch (_) {}
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
      } catch (_) {}
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

    // Trigger update of notification date when progress changes
    unawaited(_refreshNotificationDateByTmdbId(item.tmdbId, item.type));

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
        } catch (_) {}

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
            mapForSeason[ep] = (prevSeen == null || prevSeen.isBefore(s.seenDate)) ? s.seenDate : prevSeen;
          }

          final sortedSeasons = List<TVSeason>.from(detailsItem!.seasons!)
            ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

          final startSeason = item.seasonNumber!;
          final startEpisode = item.episodeNumber! + 1;
          DateTime? foundAirDate;
          int? foundSeason;
          int? foundEpisode;

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

                if (season.seasonNumber == startSeason && epNum < startEpisode) {
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
                if (airDateStr != null) {
                  try {
                    final ad = DateTime.parse(airDateStr);
                    if (ad.isAfter(DateTime.now())) {
                      continue;
                    }
                    foundAirDate = ad;
                  } catch (_) {}
                }

                foundSeason = season.seasonNumber;
                foundEpisode = epNum;
                break;
              }
            } catch (_) {}
            if (foundSeason != null) break;
          }

          if (foundSeason != null && foundEpisode != null) {
            // Respect per-streak opt-out for the streak identified by the episode we just marked
            final optedOut = await localDataSource.isOptedOut(
              item.tmdbId,
              seasonNumber: item.seasonNumber,
              episodeNumber: item.episodeNumber,
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
                posterPath: detailsItem.posterPath,
              );
              await localDataSource.addQuickAddItem(quick);
            }
          }
        }
      }
    } catch (_) {}
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
    } catch (_) {}
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

  @override
  Future<List<Map<String, dynamic>>> exportSeenData({
    DateTime? start,
    DateTime? end,
    int? tmdbId,
    MediaType? type,
  }) async {
    await _ensureInitialized();
    final items = await localDataSource.getExportData(
      start: start,
      end: end,
      tmdbId: tmdbId,
      type: type?.name,
    );

    return items
        .map(
          (item) => {
            'tmdbId': item.tmdbId,
            'type': item.type,
            'title': item.title,
            'posterPath': item.posterPath,
            'seenDate': item.seenDate.toIso8601String(),
            'seasonNumber': item.seasonNumber,
            'episodeNumber': item.episodeNumber,
            'runtime': item.runtime,
            'genres': item.genres,
          },
        )
        .toList();
  }

  @override
  Future<void> importSeenData(
    List<Map<String, dynamic>> data, {
    ImportMode mode = ImportMode.append,
    Function(double progress, String status)? onProgress,
  }) async {
    await _ensureInitialized();

    final List<SeenItemModel> items = [];
    final total = data.length;

    for (int i = 0; i < total; i++) {
      final json = data[i];
      int? runtime = json['runtime'] as int?;
      List<String>? genres = (json['genres'] as List?)?.cast<String>();
      final tmdbId = json['tmdbId'] as int;
      final typeStr = json['type'] as String;
      final type = typeStr == 'movie' ? MediaType.movie : MediaType.tv;
      final seasonNumber = json['seasonNumber'] as int?;
      final episodeNumber = json['episodeNumber'] as int?;
      final title = json['title'] as String;

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
        } catch (_) {}
      }

      items.add(
        SeenItemModel(
          tmdbId: tmdbId,
          type: typeStr,
          title: title,
          posterPath: json['posterPath'] as String?,
          seenDate: DateTime.parse(json['seenDate'] as String),
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          runtime: runtime,
          genres: genres,
        ),
      );
    }

    if (onProgress != null) {
      onProgress(1.0, 'Saving entries...');
    }
    await localDataSource.importSeenItems(items, mode: mode);
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
            autoNotify: m.autoNotify,
          ),
        )
        .toList();
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
  Future<void> refreshNotifiedItems() async {
    await _ensureInitialized();
    final notifiedItems = await localDataSource.getNotifiedItems();

    for (final notified in notifiedItems) {
      final type = notified.type == 'movie' ? MediaType.movie : MediaType.tv;
      try {
        final item = await remoteDataSource.getMediaItem(
          notified.tmdbId,
          type: type,
        );
        await cache.cacheItem(item);
        await _refreshNotificationDate(item);
      } catch (_) {}
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
          ),
        )
        .toList();
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
            mapForSeason[ep] = (prevSeen == null || prevSeen.isBefore(s.seenDate)) ? s.seenDate : prevSeen;
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
                  // is strictly after the tail's seenDate.
                    final lastSeenForEp = lastSeenMap[season.seasonNumber]?[epNum];
                    final isEpSeenAfterTail =
                      lastSeenForEp != null &&
                      // Treat equal timestamps as "after" for tail grouping
                      !lastSeenForEp.isBefore(tailSeenDate);
                  if (isEpSeenAfterTail) {
                    continue;
                  }

                  final airDateStr = ep['air_date'] as String?;
                  if (airDateStr != null) {
                    try {
                      final ad = DateTime.parse(airDateStr);
                      if (ad.isAfter(DateTime.now())) {
                        // skip future episodes
                        continue;
                      }
                      foundAirDate = ad;
                    } catch (_) {}
                  }

                  foundSeason = season.seasonNumber;
                  foundEpisode = epNum;
                  break;
                }
              } catch (_) {}
              if (foundSeason != null) break;
            }

            if (foundSeason != null && foundEpisode != null) {
              final key = '$foundSeason:$foundEpisode';
              if (existingForId.contains(key) || addedKeysForId.contains(key)) {
                continue;
              }

              final optedOut = await localDataSource.isOptedOut(
                tmdbId,
                seasonNumber: localTailSeason,
                episodeNumber: localTailEpisode,
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
                posterPath: detailsItem.posterPath,
              );
              await localDataSource.addQuickAddItem(quick);
              addedKeysForId.add(key);
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> clearQuickAddItems() async {
    await _ensureInitialized();
    return localDataSource.clearQuickAddItems();
  }
}
