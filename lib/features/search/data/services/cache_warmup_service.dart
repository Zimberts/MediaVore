import 'package:flutter/foundation.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';

/// Background filling/refreshing of the TMDB cache from the saved lists, seen
/// history and likes, followed by a cleanup of unused entries.
///
/// One run at a time; [cancel] stops the in-flight run after its current item.
class CacheWarmupService {
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;

  /// Whether a TMDB credential is set; the warm-up is skipped without one
  /// (every request would fail). `null` = assume one is set.
  final bool Function()? hasCredential;
  final MediaDetailsService details;
  final NotificationRefreshService notifications;

  /// In-flight warm-up, shared by concurrent callers.
  Future<bool>? _warmup;

  /// Bumped to cancel the in-flight warm-up between items.
  int _warmupGeneration = 0;

  /// Generation the in-flight warm-up was started with.
  int _warmupRunGeneration = 0;

  CacheWarmupService({
    required this.localDataSource,
    required this.cache,
    required this.details,
    required this.notifications,
    this.hasCredential,
  });

  /// Stops the in-flight cache warm-up after the current item.
  void cancel() => _warmupGeneration++;

  /// Runs the warm-up once at a time; returns whether this call started a
  /// run that reached the end. Joins a live run; waits out a cancelled one
  /// and starts afresh.
  Future<bool> run() async {
    final running = _warmup;
    if (running != null) {
      final cancelled = _warmupRunGeneration != _warmupGeneration;
      await running;
      return cancelled ? run() : false;
    }
    final generation = _warmupRunGeneration = _warmupGeneration;
    final future = _initCache(generation);
    _warmup = future;
    try {
      return await future;
    } finally {
      _warmup = null;
    }
  }

  /// Fills/refreshes the cache. Returns false if cancelled or failed.
  Future<bool> _initCache(int generation) async {
    bool cancelled() => generation != _warmupGeneration;
    if (hasCredential?.call() == false) {
      debugPrint('[Repo] No TMDB credential; skipping cache warm-up.');
      return false;
    }
    try {
      debugPrint('[Repo] Starting background _initCache...');
      // 1. Populate/Refresh cache with items from all lists
      final allListNames = await localDataSource.getAllListNames();
      final Set<String> keysToKeep = {};

      for (final listName in allListNames) {
        final items = await localDataSource.getListItems(listName);
        for (final item in items) {
          if (cancelled()) return false;
          final type = item.type == 'movie' ? MediaType.movie : MediaType.tv;
          keysToKeep.add('${type.name}:${item.id}');

          try {
            final mediaDetails = await details.getMediaDetails(
              item.id,
              type: type,
            );
            final seasons = mediaDetails.item.seasons;
            if (type == MediaType.tv && seasons != null && !cancelled()) {
              await details.prefetchSeasons(
                item.id,
                seasons.map((s) => s.seasonNumber),
              );
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
        if (cancelled()) return false;
        final type = seen.type == 'movie' ? MediaType.movie : MediaType.tv;
        final isRecent = seen.seenDate.isAfter(thirtyDaysAgo);
        final isMissingPoster = seen.posterPath == null;

        if (isRecent || isMissingPoster) {
          keysToKeep.add('${seen.type}:${seen.tmdbId}');
          try {
            final mediaDetails = await details.getMediaDetails(
              seen.tmdbId,
              type: type,
            );
            if (isMissingPoster && mediaDetails.item.posterPath != null) {
              await localDataSource.updatePosterPath(
                seen.tmdbId,
                seen.type,
                mediaDetails.item.posterPath!,
              );
            }
            if (isRecent && type == MediaType.tv && seen.seasonNumber != null) {
              await details.getSeasonDetails(seen.tmdbId, seen.seasonNumber!);
            }
          } catch (e) {
            debugPrint('[Repo] _initCache seen item refresh failed: $e');
          }
        }
      }

      // 3. Liked items
      final likedItems = await localDataSource.getLikedItems();
      for (final liked in likedItems) {
        if (cancelled()) return false;
        keysToKeep.add('${liked.type}:${liked.tmdbId}');
        final type = liked.type == 'movie' ? MediaType.movie : MediaType.tv;
        try {
          await details.getMediaDetails(liked.tmdbId, type: type);
        } catch (e) {
          debugPrint('[Repo] _initCache liked item refresh failed: $e');
        }
      }

      // 4. Refresh notification dates from network in the background
      if (cancelled()) return false;
      await notifications.refreshNotifiedItems();
      if (cancelled()) return false;

      // 5. Perform cleanup
      await cache.cleanup(
        keepKeys: keysToKeep,
        olderThan: const Duration(days: 60),
      );
      debugPrint('[Repo] Background _initCache completed.');
      return true;
    } catch (e) {
      debugPrint('[Repo] Background _initCache error: $e');
      return false;
    }
  }
}
