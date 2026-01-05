import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

@lazySingleton
class MediaCache {
  final Isar _isar;
  final Map<String, MediaDetails> _detailsCache = {};
  final Map<String, MediaItem> _itemCache = {};
  final Map<int, String?> _actorProfileCache = {};
  final Map<String, Map<String, dynamic>> _seasonCache = {};
  
  Completer<void>? _initCompleter;

  MediaCache(this._isar);

  Future<void> init() async {
    if (_initCompleter != null) return _initCompleter!.future;
    
    _initCompleter = Completer<void>();
    try {
      await _loadFromDb();
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Allow retry on failure
      rethrow;
    }
  }

  Future<void> _loadFromDb() async {
    final cachedMedias = await _isar.cachedMedias.where().findAll();
    for (final cached in cachedMedias) {
      final type = cached.type == 'movie' ? MediaType.movie : MediaType.tv;
      final key = _getKey(cached.tmdbId, type);
      
      try {
        if (cached.mediaItemJson != null) {
          _itemCache[key] = MediaItem.fromJson(jsonDecode(cached.mediaItemJson!));
        }
        if (cached.mediaDetailsJson != null) {
          _detailsCache[key] = MediaDetails.fromJson(jsonDecode(cached.mediaDetailsJson!));
        }
      } catch (e) {
        // Skip corrupted entries
      }
    }

    final cachedActors = await _isar.cachedActorProfiles.where().findAll();
    for (final actor in cachedActors) {
      _actorProfileCache[actor.actorId] = actor.profilePath;
    }

    final cachedSeasons = await _isar.cachedSeasons.where().findAll();
    for (final season in cachedSeasons) {
      _seasonCache[_getSeasonKey(season.tvId, season.seasonNumber)] = jsonDecode(season.json);
    }
  }

  Future<void> cacheDetails(MediaDetails details) async {
    final key = _getKey(details.item.id, details.item.mediaType);
    _detailsCache[key] = details;
    _itemCache[key] = details.item;
    
    for (final cast in details.cast) {
      if (cast.profilePath != null) {
        _actorProfileCache[cast.id] = cast.profilePath;
      }
    }

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedMedias
          .filter()
          .tmdbIdEqualTo(details.item.id)
          .typeEqualTo(details.item.mediaType.name)
          .findFirst();
      
      final updated = CachedMedia(
        tmdbId: details.item.id,
        type: details.item.mediaType.name,
        mediaDetailsJson: jsonEncode(details.toJson()),
        mediaItemJson: jsonEncode(details.item.toJson()),
        updatedAt: DateTime.now(),
      );
      if (existing != null) updated.isarId = existing.isarId;
      await _isar.cachedMedias.put(updated);

      for (final cast in details.cast) {
         final existingActor = await _isar.cachedActorProfiles
            .filter()
            .actorIdEqualTo(cast.id)
            .findFirst();
         
         final actorUpdate = CachedActorProfile(
            actorId: cast.id,
            profilePath: cast.profilePath,
            updatedAt: DateTime.now(),
         );
         if (existingActor != null) actorUpdate.isarId = existingActor.isarId;
         await _isar.cachedActorProfiles.put(actorUpdate);
      }
    });
  }

  Future<void> cacheItem(MediaItem item) async {
    final key = _getKey(item.id, item.mediaType);
    _itemCache[key] = item;

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedMedias
          .filter()
          .tmdbIdEqualTo(item.id)
          .typeEqualTo(item.mediaType.name)
          .findFirst();
      
      final updated = CachedMedia(
        tmdbId: item.id,
        type: item.mediaType.name,
        mediaDetailsJson: existing?.mediaDetailsJson,
        mediaItemJson: jsonEncode(item.toJson()),
        updatedAt: DateTime.now(),
      );
      if (existing != null) updated.isarId = existing.isarId;
      await _isar.cachedMedias.put(updated);
    });
  }

  Future<void> cacheSeason(int tvId, int seasonNumber, Map<String, dynamic> seasonData) async {
    final key = _getSeasonKey(tvId, seasonNumber);
    _seasonCache[key] = seasonData;

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedSeasons
          .filter()
          .tvIdEqualTo(tvId)
          .seasonNumberEqualTo(seasonNumber)
          .findFirst();

      final updated = CachedSeason(
        tvId: tvId,
        seasonNumber: seasonNumber,
        json: jsonEncode(seasonData),
        updatedAt: DateTime.now(),
      );
      if (existing != null) updated.isarId = existing.isarId;
      await _isar.cachedSeasons.put(updated);
    });
  }

  MediaDetails? getDetails(int id, MediaType type) => _detailsCache[_getKey(id, type)];
  
  MediaItem? getItem(int id, MediaType type) => _itemCache[_getKey(id, type)];
  
  String? getActorProfile(int actorId) => _actorProfileCache[actorId];

  Map<String, dynamic>? getSeason(int tvId, int seasonNumber) => _seasonCache[_getSeasonKey(tvId, seasonNumber)];

  Future<void> cacheActorProfile(int actorId, String? profilePath) async {
    _actorProfileCache[actorId] = profilePath;
    await _isar.writeTxn(() async {
      final existing = await _isar.cachedActorProfiles
          .filter()
          .actorIdEqualTo(actorId)
          .findFirst();
      
      final update = CachedActorProfile(
        actorId: actorId,
        profilePath: profilePath,
        updatedAt: DateTime.now(),
      );
      if (existing != null) update.isarId = existing.isarId;
      await _isar.cachedActorProfiles.put(update);
    });
  }

  /// Clears items from the cache that are not in the [keepKeys] list
  /// and haven't been updated for more than [olderThan] duration.
  Future<void> cleanup({
    required Set<String> keepKeys,
    required Duration olderThan,
  }) async {
    final threshold = DateTime.now().subtract(olderThan);

    await _isar.writeTxn(() async {
      // 1. Media Cleanup
      final mediaToDelete = await _isar.cachedMedias
          .filter()
          .updatedAtLessThan(threshold)
          .findAll();
      
      final actualMediaToDeleteIds = mediaToDelete
          .where((m) => !keepKeys.contains(_getKey(m.tmdbId, m.type == 'movie' ? MediaType.movie : MediaType.tv)))
          .map((m) => m.isarId!)
          .toList();

      await _isar.cachedMedias.deleteAll(actualMediaToDeleteIds);

      // 2. Season Cleanup
      final seasonsToDelete = await _isar.cachedSeasons
          .filter()
          .updatedAtLessThan(threshold)
          .findAll();
      
      final actualSeasonToDeleteIds = seasonsToDelete
          .where((s) => !keepKeys.contains(_getKey(s.tvId, MediaType.tv)))
          .map((s) => s.isarId!)
          .toList();

      await _isar.cachedSeasons.deleteAll(actualSeasonToDeleteIds);

      // 3. Actor Profile Cleanup
      await _isar.cachedActorProfiles
          .filter()
          .updatedAtLessThan(threshold)
          .deleteAll();
    });

    await _refreshInMemory();
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.cachedMedias.clear();
      await _isar.cachedSeasons.clear();
      await _isar.cachedActorProfiles.clear();
    });
    await _refreshInMemory();
  }

  Future<void> _refreshInMemory() async {
    _detailsCache.clear();
    _itemCache.clear();
    _actorProfileCache.clear();
    _seasonCache.clear();
    await _loadFromDb();
  }

  Future<int> getCacheSize() async {
    return await _isar.getSize();
  }

  String _getKey(int id, MediaType type) => '${type.name}:$id';
  String _getSeasonKey(int tvId, int seasonNumber) => '$tvId:$seasonNumber';
  
  bool isItemCached(int id, MediaType type) => _itemCache.containsKey(_getKey(id, type));
  bool areDetailsCached(int id, MediaType type) => _detailsCache.containsKey(_getKey(id, type));
  bool isSeasonCached(int tvId, int seasonNumber) => _seasonCache.containsKey(_getSeasonKey(tvId, seasonNumber));
}
