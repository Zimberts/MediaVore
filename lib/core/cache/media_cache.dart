import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

/// Isar-backed media cache with bounded in-memory LRU layers.
///
/// Entries are decoded lazily from Isar on first access, so startup cost and
/// memory no longer scale with the number of cached rows. Corrupted rows are
/// logged and deleted when encountered.
@lazySingleton
class MediaCache {
  static const int itemCapacity = 500;
  static const int detailsCapacity = 50;
  static const int seasonCapacity = 50;
  static const int actorCapacity = 500;

  final Isar _isar;
  final LruMap<String, MediaItem> _itemCache = LruMap(itemCapacity);
  final LruMap<String, MediaDetails> _detailsCache = LruMap(detailsCapacity);
  final LruMap<String, Map<String, dynamic>> _seasonCache = LruMap(
    seasonCapacity,
  );
  final LruMap<int, String?> _actorProfileCache = LruMap(actorCapacity);

  MediaCache(this._isar);

  /// No eager loading: entries are read from Isar on demand.
  Future<void> init() async {}

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<void> cacheDetails(MediaDetails details) async {
    final key = _getKey(details.item.id, details.item.mediaType);
    _detailsCache.put(key, details);
    _itemCache.put(key, details.item);

    final now = DateTime.now();
    final actors = <int, CachedActorProfile>{};
    for (final cast in details.cast) {
      if (cast.profilePath != null) {
        _actorProfileCache.put(cast.id, cast.profilePath);
      }
      actors[cast.id] = CachedActorProfile(
        actorId: cast.id,
        profilePath: cast.profilePath,
        updatedAt: now,
      );
    }

    await _isar.writeTxn(() async {
      await _isar.cachedMedias.putByTmdbIdType(
        CachedMedia(
          tmdbId: details.item.id,
          type: details.item.mediaType.name,
          mediaDetailsJson: jsonEncode(details.toJson()),
          mediaItemJson: jsonEncode(details.item.toJson()),
          updatedAt: now,
        ),
      );
      if (actors.isNotEmpty) {
        await _isar.cachedActorProfiles.putAllByActorId(actors.values.toList());
      }
    });
  }

  Future<void> cacheItem(MediaItem item) => cacheItems([item]);

  /// Caches [items] in a single write transaction.
  ///
  /// Already cached details JSON is preserved for each row.
  Future<void> cacheItems(List<MediaItem> items) async {
    if (items.isEmpty) return;

    // Deduplicate on the unique (tmdbId, type) key; the last occurrence wins.
    final byKey = <String, MediaItem>{};
    for (final item in items) {
      byKey[_getKey(item.id, item.mediaType)] = item;
    }
    final unique = byKey.values.toList();
    for (final item in unique) {
      _itemCache.put(_getKey(item.id, item.mediaType), item);
    }

    final now = DateTime.now();
    await _isar.writeTxn(() async {
      final existing = await _isar.cachedMedias.getAllByTmdbIdType(
        unique.map((i) => i.id).toList(),
        unique.map((i) => i.mediaType.name).toList(),
      );
      final rows = <CachedMedia>[
        for (var i = 0; i < unique.length; i++)
          CachedMedia(
            tmdbId: unique[i].id,
            type: unique[i].mediaType.name,
            mediaDetailsJson: existing[i]?.mediaDetailsJson,
            mediaItemJson: jsonEncode(unique[i].toJson()),
            updatedAt: now,
          ),
      ];
      await _isar.cachedMedias.putAllByTmdbIdType(rows);
    });
  }

  Future<void> cacheSeason(
    int tvId,
    int seasonNumber,
    Map<String, dynamic> seasonData,
  ) async {
    _seasonCache.put(_getSeasonKey(tvId, seasonNumber), seasonData);

    await _isar.writeTxn(() async {
      await _isar.cachedSeasons.putByTvIdSeasonNumber(
        CachedSeason(
          tvId: tvId,
          seasonNumber: seasonNumber,
          json: jsonEncode(seasonData),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> cacheActorProfile(int actorId, String? profilePath) async {
    _actorProfileCache.put(actorId, profilePath);
    await _isar.writeTxn(() async {
      await _isar.cachedActorProfiles.putByActorId(
        CachedActorProfile(
          actorId: actorId,
          profilePath: profilePath,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<MediaDetails?> getDetails(int id, MediaType type) async {
    final key = _getKey(id, type);
    final hit = _detailsCache.get(key);
    if (hit != null) return hit;

    final row = await _isar.cachedMedias.getByTmdbIdType(id, type.name);
    final json = row?.mediaDetailsJson;
    if (row == null || json == null) return null;

    final details = await _decodeOrPurge(
      row,
      () => MediaDetails.fromJson(jsonDecode(json)),
    );
    if (details == null) return null;
    return _detailsCache.remember(key, details);
  }

  Future<MediaItem?> getItem(int id, MediaType type) async {
    final key = _getKey(id, type);
    final hit = _itemCache.get(key);
    if (hit != null) return hit;

    final row = await _isar.cachedMedias.getByTmdbIdType(id, type.name);
    if (row == null) return null;
    return _itemFromRow(key, row);
  }

  /// Batch variant of [getItem]: one Isar read for all cache misses.
  ///
  /// The result is aligned with [keys].
  Future<List<MediaItem?>> getItems(List<(int, MediaType)> keys) async {
    final result = List<MediaItem?>.filled(keys.length, null);
    final missIdx = <int>[];
    for (var i = 0; i < keys.length; i++) {
      final hit = _itemCache.get(_getKey(keys[i].$1, keys[i].$2));
      if (hit != null) {
        result[i] = hit;
      } else {
        missIdx.add(i);
      }
    }
    if (missIdx.isEmpty) return result;

    final rows = await _isar.cachedMedias.getAllByTmdbIdType(
      missIdx.map((i) => keys[i].$1).toList(),
      missIdx.map((i) => keys[i].$2.name).toList(),
    );
    for (var j = 0; j < missIdx.length; j++) {
      final row = rows[j];
      if (row == null) continue;
      final i = missIdx[j];
      result[i] = await _itemFromRow(_getKey(keys[i].$1, keys[i].$2), row);
    }
    return result;
  }

  Future<Map<String, dynamic>?> getSeason(int tvId, int seasonNumber) async {
    final key = _getSeasonKey(tvId, seasonNumber);
    final hit = _seasonCache.get(key);
    if (hit != null) return hit;

    final row = await _isar.cachedSeasons.getByTvIdSeasonNumber(
      tvId,
      seasonNumber,
    );
    if (row == null) return null;

    final season = await _decodeOrPurge(
      row,
      () => jsonDecode(row.json) as Map<String, dynamic>,
    );
    if (season == null) return null;
    return _seasonCache.remember(key, season);
  }

  Future<String?> getActorProfile(int actorId) async {
    if (_actorProfileCache.containsKey(actorId)) {
      return _actorProfileCache.get(actorId);
    }
    final row = await _isar.cachedActorProfiles.getByActorId(actorId);
    if (row == null) return null;
    _actorProfileCache.put(actorId, row.profilePath);
    return row.profilePath;
  }

  Future<DateTime?> getCacheUpdateDate(int tmdbId, MediaType type) async {
    final row = await _isar.cachedMedias.getByTmdbIdType(tmdbId, type.name);
    return row?.updatedAt;
  }

  // ---------------------------------------------------------------------------
  // Maintenance
  // ---------------------------------------------------------------------------

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
          .where(
            (m) => !keepKeys.contains(
              _getKey(
                m.tmdbId,
                m.type == 'movie' ? MediaType.movie : MediaType.tv,
              ),
            ),
          )
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

    _clearInMemory();
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.cachedMedias.clear();
      await _isar.cachedSeasons.clear();
      await _isar.cachedActorProfiles.clear();
    });
    _clearInMemory();
  }

  Future<int> getCacheSize() async {
    return await _isar.getSize();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _clearInMemory() {
    _detailsCache.clear();
    _itemCache.clear();
    _actorProfileCache.clear();
    _seasonCache.clear();
  }

  Future<MediaItem?> _itemFromRow(String key, CachedMedia row) async {
    final json = row.mediaItemJson;
    if (json == null) return null;
    final item = await _decodeOrPurge(
      row,
      () => MediaItem.fromJson(jsonDecode(json)),
    );
    if (item == null) return null;
    return _itemCache.remember(key, item);
  }

  /// Decodes a row; on failure logs it and deletes the row so it is refetched
  /// instead of failing silently on every access.
  Future<T?> _decodeOrPurge<T>(Object row, T Function() decode) async {
    try {
      return decode();
    } catch (e) {
      debugPrint('[MediaCache] Deleting corrupted row $row: $e');
      try {
        await _isar.writeTxn(() async {
          if (row is CachedMedia && row.isarId != null) {
            await _isar.cachedMedias.delete(row.isarId!);
          } else if (row is CachedSeason && row.isarId != null) {
            await _isar.cachedSeasons.delete(row.isarId!);
          }
        });
      } catch (e) {
        debugPrint('[MediaCache] Failed to delete corrupted row: $e');
      }
      return null;
    }
  }

  String _getKey(int id, MediaType type) => '${type.name}:$id';
  String _getSeasonKey(int tvId, int seasonNumber) => '$tvId:$seasonNumber';
}

/// Minimal LRU map: access order is the [LinkedHashMap] insertion order.
class LruMap<K, V> {
  LruMap(this.capacity) : assert(capacity > 0);

  final int capacity;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  int get length => _map.length;

  bool containsKey(K key) => _map.containsKey(key);

  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > capacity) _map.remove(_map.keys.first);
  }

  /// Stores a value read from storage, unless [key] was written while the
  /// read was in flight (that write is newer). Returns the retained value.
  V remember(K key, V value) {
    if (_map.containsKey(key)) return get(key) as V;
    put(key, value);
    return value;
  }

  void clear() => _map.clear();
}
