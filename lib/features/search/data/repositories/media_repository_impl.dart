import 'dart:async';
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
    await cache.init();
    await _initCache();
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  Future<void> _initCache() async {
    // 1. Populate/Refresh cache with items from all lists
    final allListNames = await localDataSource.getAllListNames();
    final Set<String> keysToKeep = {};

    for (final listName in allListNames) {
      final items = await localDataSource.getListItems(listName);
      for (final item in items) {
        final type = item.type == 'movie' ? MediaType.movie : MediaType.tv;
        keysToKeep.add('${type.name}:${item.id}');
        
        try {
          // Fetch details (returns cached if available)
          final details = await getMediaDetails(item.id, type: type);
          
          // If it's a TV show, pre-cache all season details
          if (type == MediaType.tv && details.item.seasons != null) {
            for (final season in details.item.seasons!) {
              await getSeasonDetails(item.id, season.seasonNumber);
            }
          }
        } catch (_) {
          // Ignore failures during background init/fill
        }
      }
    }

    // 2. Keep recently seen items in cache (e.g., seen in the last 30 days)
    final seenItems = await localDataSource.getAllSeenItems();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    for (final seen in seenItems) {
      if (seen.seenDate.isAfter(thirtyDaysAgo)) {
        keysToKeep.add('${seen.type}:${seen.tmdbId}');
        final type = seen.type == 'movie' ? MediaType.movie : MediaType.tv;

        try {
          await getMediaDetails(seen.tmdbId, type: type);
          
          // For TV shows in history, also ensure the relevant season is cached
          if (type == MediaType.tv && seen.seasonNumber != null) {
            await getSeasonDetails(seen.tmdbId, seen.seasonNumber!);
          }
        } catch (_) {}
      }
    }

    // 3. Perform cleanup of old, unused cache entries (older than 60 days)
    await cache.cleanup(
      keepKeys: keysToKeep,
      olderThan: const Duration(days: 60),
    );
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
    await cache.init();
    
    if (cache.areDetailsCached(id, type)) {
      return cache.getDetails(id, type)!;
    }

    final itemFuture = remoteDataSource.getMediaItem(id, type: type);
    final creditsFuture = remoteDataSource.getMediaCredits(id, type: type);

    final item = await itemFuture;
    final credits = await creditsFuture;

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
    return localDataSource.markAsSeen(SeenItemModel(
      tmdbId: item.tmdbId,
      type: item.type.name,
      title: item.title,
      seenDate: item.seenDate,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
    ));
  }

  @override
  Future<void> removeFromSeen(int tmdbId, MediaType type, {int? seasonNumber, int? episodeNumber}) async {
    await _ensureInitialized();
    return localDataSource.removeFromSeen(
      tmdbId,
      type.name,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  @override
  Future<void> deleteSeenEntry(int id) async {
    await _ensureInitialized();
    return localDataSource.deleteSeenEntry(id);
  }

  @override
  Future<List<SeenItem>> getSeenItems() async {
    await cache.init();
    final items = await localDataSource.getAllSeenItems();
    return items.map((m) {
      final type = m.type == 'movie' ? MediaType.movie : MediaType.tv;
      final cachedItem = cache.getItem(m.tmdbId, type);
      return SeenItem(
        id: m.isarId,
        tmdbId: m.tmdbId,
        type: type,
        title: m.title,
        posterPath: cachedItem?.posterPath,
        seenDate: m.seenDate,
        seasonNumber: m.seasonNumber,
        episodeNumber: m.episodeNumber,
      );
    }).toList();
  }

  @override
  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type) async {
    await cache.init();
    final items = await localDataSource.getSeenStatus(tmdbId, type.name);
    final cachedItem = cache.getItem(tmdbId, type);
    return items.map((m) => SeenItem(
      id: m.isarId,
      tmdbId: m.tmdbId,
      type: m.type == 'movie' ? MediaType.movie : MediaType.tv,
      title: m.title,
      posterPath: cachedItem?.posterPath,
      seenDate: m.seenDate,
      seasonNumber: m.seasonNumber,
      episodeNumber: m.episodeNumber,
    )).toList();
  }

  @override
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) async {
    await cache.init();
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
  Future<int> getCacheSize() {
    return cache.getCacheSize();
  }

  @override
  Future<void> clearCache({required bool complete}) async {
    if (complete) {
      await cache.clearAll();
    } else {
      await _initCache();
    }
  }

  @override
  Future<void> fillCache() async {
    await _initCache();
  }
}
