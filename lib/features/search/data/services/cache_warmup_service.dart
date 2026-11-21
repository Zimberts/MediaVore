import 'package:flutter/foundation.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/bounded_concurrency.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Background filling/refreshing of the TMDB cache from the saved lists, seen
/// history and likes, followed by a cleanup of unused entries.
///
/// One run at a time; [cancel] stops the in-flight run once the titles
/// being refreshed are done.
class CacheWarmupService {
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;

  /// Whether a TMDB credential is set; the warm-up is skipped without one
  /// (every request would fail). `null` = assume one is set.
  final bool Function()? hasCredential;
  final MediaDetailsService details;
  final NotificationRefreshService notifications;

  /// Progress of the running warm-up; `null` when none is running.
  final ValueNotifier<CacheWarmupProgress?> progress = ValueNotifier(null);

  /// Titles refreshed in parallel during a warm-up.
  static const int concurrency = 6;

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

  /// Stops the in-flight cache warm-up once the titles in progress are done.
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

  /// Builds the deduplicated work list (one task per title), in the order
  /// lists, seen history, likes, and fills [keysToKeep] with the cache keys
  /// the cleanup must keep.
  Future<List<_WarmupTask>> _planTasks(Set<String> keysToKeep) async {
    final tasks = <String, _WarmupTask>{};
    _WarmupTask task(int id, String type) {
      final mediaType = type == 'movie' ? MediaType.movie : MediaType.tv;
      return tasks.putIfAbsent(
        '${mediaType.name}:$id',
        () => _WarmupTask(id, mediaType),
      );
    }

    // 1. Every saved list item, with all its seasons.
    for (final listName in await localDataSource.getAllListNames()) {
      for (final item in await localDataSource.getListItems(listName)) {
        final t = task(item.id, item.type);
        keysToKeep.add('${t.type.name}:${item.id}');
        t.allSeasons = true;
      }
    }

    // 2. Seen items: recent ones (with their season), those missing a
    // poster, and older ones with incomplete cached metadata.
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final checkedSeenTitles = <String>{};
    for (final seen in await localDataSource.getAllSeenItems()) {
      keysToKeep.add('${seen.type}:${seen.tmdbId}');
      final isRecent = seen.seenDate.isAfter(thirtyDaysAgo);
      final isMissingPoster = seen.posterPath == null;
      if (isRecent || isMissingPoster) {
        final t = task(seen.tmdbId, seen.type);
        if (isMissingPoster) t.fixPoster = true;
        if (isRecent && t.type == MediaType.tv && seen.seasonNumber != null) {
          t.seasons.add(seen.seasonNumber!);
        }
      } else if (checkedSeenTitles.add('${seen.type}:${seen.tmdbId}')) {
        final type = seen.type == 'movie' ? MediaType.movie : MediaType.tv;
        final cached = await cache.getDetails(seen.tmdbId, type);
        if (cached == null || !cached.item.isComplete) {
          task(seen.tmdbId, seen.type);
        }
      }
    }

    // 3. Liked items.
    for (final liked in await localDataSource.getLikedItems()) {
      keysToKeep.add('${liked.type}:${liked.tmdbId}');
      task(liked.tmdbId, liked.type);
    }
    return tasks.values.toList();
  }

  /// Refreshes one title: details, missing poster in the seen history, then
  /// its seasons. Failures are logged and skip the rest of the title.
  Future<void> _refresh(_WarmupTask task) async {
    try {
      final mediaDetails = await details.getMediaDetails(
        task.id,
        type: task.type,
      );
      final posterPath = mediaDetails.item.posterPath;
      if (task.fixPoster && posterPath != null) {
        await localDataSource.updatePosterPath(
          task.id,
          task.type.name,
          posterPath,
        );
      }
      if (task.type != MediaType.tv) return;
      final seasons = {
        if (task.allSeasons)
          ...?mediaDetails.item.seasons?.map((s) => s.seasonNumber),
        ...task.seasons,
      };
      if (seasons.isNotEmpty) {
        await details.prefetchSeasons(task.id, seasons);
      }
    } catch (e) {
      debugPrint(
        '[Repo] _initCache refresh of ${task.type.name} '
        '${task.id} failed: $e',
      );
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
      final keysToKeep = <String>{};
      final tasks = await _planTasks(keysToKeep);
      if (cancelled()) return false;
      var done = 0;
      progress.value = CacheWarmupProgress(0, tasks.length);

      // Titles are refreshed [concurrency] at a time; the TMDB Dio keeps the
      // request rate under the API limit (RateLimitInterceptor).
      await mapWithConcurrency(tasks, concurrency, (task) async {
        if (cancelled()) return;
        await _refresh(task);
        progress.value = CacheWarmupProgress(++done, tasks.length);
      });
      if (cancelled()) return false;

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
    } finally {
      progress.value = null;
    }
  }
}

/// One title to refresh during a warm-up, merged across lists, seen history
/// and likes.
class _WarmupTask {
  final int id;
  final MediaType type;

  /// Refresh every season listed in the details (saved list items).
  bool allSeasons = false;

  /// Seasons to refresh in any case (recently seen episodes).
  final Set<int> seasons = {};

  /// Copy the poster to seen-history rows that lack one.
  bool fixPoster = false;

  _WarmupTask(this.id, this.type);
}
