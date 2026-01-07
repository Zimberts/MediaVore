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
  }) {
    _init();
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
              await localDataSource.updatePosterPath(seen.tmdbId, seen.type, details.item.posterPath!);
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
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async {
    await _ensureInitialized();
    final results = await remoteDataSource.searchMedia(query, page: page);
    for (final item in results) {
      await cache.cacheItem(item);
    }
    return results;
  }

  @override
  Future<MediaDetails> getMediaDetails(int id, {MediaType type = MediaType.movie}) async {
    await _ensureInitialized();
    
    if (cache.areDetailsCached(id, type)) {
      return cache.getDetails(id, type)!;
    }

    final itemFuture = remoteDataSource.getMediaItem(id, type: type);
    final creditsFuture = remoteDataSource.getMediaCredits(id, type: type);

    final item = await itemFuture;
    
    Map<String, dynamic> credits = {'cast': [], 'crew': []};
    try {
      credits = await creditsFuture;
    } catch (_) {}

    final List castResults = credits['cast'] ?? [];
    final List crewResults = credits['crew'] ?? [];

    final List<CastMember> cast =
        castResults.map((c) => CastMember.fromJson(c)).toList();
    
    final CrewMember director = crewResults
        .map((c) => CrewMember.fromJson(c))
        .firstWhere(
          (member) => member.job == 'Director' || member.job == 'Executive Producer', 
          orElse: () => CrewMember(name: 'N/A', job: 'Director'),
        );

    final details = MediaDetails(
      item: item,
      cast: cast,
      director: director,
    );
    
    await cache.cacheDetails(details);
    return details;
  }

  Future<void> _refreshNotificationDate(MediaItem item) async {
    final isNotified = await localDataSource.isNotified(item.id, item.mediaType.name);
    if (!isNotified) return;

    DateTime? releaseDate;
    int? seasonNum;
    int? episodeNum;

    if (item.mediaType == MediaType.tv) {
      // Logic: Find the FIRST unseen episode air date
      final seen = await localDataSource.getSeenStatus(item.id, MediaType.tv.name);
      
      // Use cached details if possible to avoid loops
      MediaItem? detailsItem = cache.getItem(item.id, MediaType.tv);
      if (detailsItem == null || detailsItem.seasons == null) {
        try {
          detailsItem = await remoteDataSource.getMediaItem(item.id, type: MediaType.tv);
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
            final seasonDetails = await getSeasonDetails(detailsItem.id, season.seasonNumber);
            final episodes = seasonDetails['episodes'] as List;
            for (final ep in episodes) {
              final epNum = ep['episode_number'] as int;
              final airDateStr = ep['air_date'] as String?;
              if (airDateStr == null) continue;

              final isEpSeen = seen.any((s) => s.seasonNumber == season.seasonNumber && s.episodeNumber == epNum);
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
          try { releaseDate = DateTime.parse(item.releaseDate); } catch (_) {}
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
        await localDataSource.toggleNotification(tmdbId: item.id, type: item.mediaType.name, title: item.title);
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
  Future<List<MediaItemPreview>> getListPreviews(String listName, {int limit = 4}) async {
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
    await localDataSource.markAsSeen(SeenItemModel(
      tmdbId: item.tmdbId,
      type: item.type.name,
      title: item.title,
      posterPath: item.posterPath,
      seenDate: item.seenDate,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
    ));
    // Trigger update of notification date when progress changes
    unawaited(_refreshNotificationDateByTmdbId(item.tmdbId, item.type));
  }

  Future<void> _refreshNotificationDateByTmdbId(int tmdbId, MediaType type) async {
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
  Future<void> removeFromSeen(int tmdbId, MediaType type, {int? seasonNumber, int? episodeNumber}) async {
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
        unawaited(localDataSource.updatePosterPath(m.tmdbId, m.type, posterPath));
      }

      results.add(SeenItem(
        id: m.isarId,
        tmdbId: m.tmdbId,
        type: type,
        title: m.title,
        posterPath: posterPath,
        seenDate: m.seenDate,
        seasonNumber: m.seasonNumber,
        episodeNumber: m.episodeNumber,
      ));
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

      results.add(SeenItem(
        id: m.isarId,
        tmdbId: m.tmdbId,
        type: m.type == 'movie' ? MediaType.movie : MediaType.tv,
        title: m.title,
        posterPath: posterPath,
        seenDate: m.seenDate,
        seasonNumber: m.seasonNumber,
        episodeNumber: m.episodeNumber,
      ));
    }
    return results;
  }

  @override
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) async {
    await _ensureInitialized();
    if (cache.isSeasonCached(tvId, seasonNumber)) {
      return cache.getSeason(tvId, seasonNumber)!;
    }
    
    try {
      final details = await remoteDataSource.getSeasonDetails(tvId, seasonNumber);
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

    return items.map((item) => {
      'tmdbId': item.tmdbId,
      'type': item.type,
      'title': item.title,
      'posterPath': item.posterPath,
      'seenDate': item.seenDate.toIso8601String(),
      'seasonNumber': item.seasonNumber,
      'episodeNumber': item.episodeNumber,
    }).toList();
  }

  @override
  Future<void> importSeenData(List<Map<String, dynamic>> data, {ImportMode mode = ImportMode.append}) async {
    await _ensureInitialized();

    final items = data.map((json) => SeenItemModel(
      tmdbId: json['tmdbId'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      posterPath: json['posterPath'] as String?,
      seenDate: DateTime.parse(json['seenDate'] as String),
      seasonNumber: json['seasonNumber'] as int?,
      episodeNumber: json['episodeNumber'] as int?,
    )).toList();
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
  Future<void> toggleNotification(MediaItem item, {bool autoNotify = false}) async {
    await _ensureInitialized();
    
    final isNotified = await localDataSource.isNotified(item.id, item.mediaType.name);
    
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
    return items.map((m) => NotifiedItem(
      tmdbId: m.tmdbId,
      type: m.type == 'movie' ? MediaType.movie : MediaType.tv,
      title: m.title,
      posterPath: m.posterPath,
      releaseDate: m.releaseDate,
      seasonNumber: m.seasonNumber,
      episodeNumber: m.episodeNumber,
      autoNotify: m.autoNotify,
    )).toList();
  }

  @override
  Future<void> refreshNotifiedItems() async {
    await _ensureInitialized();
    final notifiedItems = await localDataSource.getNotifiedItems();
    
    for (final notified in notifiedItems) {
      final type = notified.type == 'movie' ? MediaType.movie : MediaType.tv;
      try {
        final item = await remoteDataSource.getMediaItem(notified.tmdbId, type: type);
        await cache.cacheItem(item); 
        await _refreshNotificationDate(item); 
      } catch (_) {}
    }
  }
}
