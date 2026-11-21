import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/services/cached_title.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';

/// Seen history and the progression it drives (Releases anchor, Quick Add
/// queue, watchlist cleanup).
///
/// Part of `MediaRepositoryImpl`; callers are expected to have awaited the
/// repository's initialization.
class SeenService {
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;
  final MediaDetailsService details;
  final NotificationRefreshService notifications;
  final QuickAddService quickAdd;

  SeenService({
    required this.localDataSource,
    required this.cache,
    required this.details,
    required this.notifications,
    required this.quickAdd,
  });

  Future<void> markAsSeen(SeenItem item) async {
    final enriched = await details.resolveRuntimeAndGenres(
      tmdbId: item.tmdbId,
      type: item.type,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
      runtime: item.runtime,
      genres: item.genres,
    );

    await localDataSource.markAsSeen(
      SeenItemModel(
        tmdbId: item.tmdbId,
        type: item.type.name,
        title: item.title,
        posterPath: item.posterPath,
        seenDate: item.seenDate,
        seasonNumber: item.seasonNumber,
        episodeNumber: item.episodeNumber,
        runtime: enriched.runtime,
        genres: enriched.genres,
      ),
    );

    // If it's a movie, remove it from watchlist (not other lists as per requirement)
    if (item.type == MediaType.movie) {
      await localDataSource.removeFromList(
        item.tmdbId,
        item.type.name,
        'watchlist',
      );
    }

    // Trigger update of notification date when progress changes. If the episode
    // just marked is the latest of the streak, refresh from the network
    // (bypassing caches) so newly released episodes show up immediately. This is
    // awaited so callers reloading notified items observe the reconciled state.
    await notifications.refreshAfterSeen(item);

    await quickAdd.queueNextAfterSeen(item);
  }

  Future<void> markManyAsSeen(List<SeenItem> items) async {
    if (items.isEmpty) return;

    final detailsCache = <String, MediaDetails?>{};
    final seasonCache = <String, Map<String, dynamic>?>{};

    Future<MediaDetails?> getCachedDetails(int id, MediaType type) async {
      final key = '$id:${type.name}';
      if (!detailsCache.containsKey(key)) {
        detailsCache[key] = await details.getMediaDetails(id, type: type);
      }
      return detailsCache[key];
    }

    Future<Map<String, dynamic>?> getCachedSeason(int id, int season) async {
      final key = '$id:$season';
      if (!seasonCache.containsKey(key)) {
        seasonCache[key] = await details.getSeasonDetails(id, season);
      }
      return seasonCache[key];
    }

    final models = <SeenItemModel>[];
    for (final item in items) {
      final enriched = await details.resolveRuntimeAndGenres(
        tmdbId: item.tmdbId,
        type: item.type,
        seasonNumber: item.seasonNumber,
        episodeNumber: item.episodeNumber,
        runtime: item.runtime,
        genres: item.genres,
        fetchDetails: getCachedDetails,
        fetchSeason: getCachedSeason,
      );
      models.add(
        SeenItemModel(
          tmdbId: item.tmdbId,
          type: item.type.name,
          title: item.title,
          posterPath: item.posterPath,
          seenDate: item.seenDate,
          seasonNumber: item.seasonNumber,
          episodeNumber: item.episodeNumber,
          runtime: enriched.runtime,
          genres: enriched.genres,
        ),
      );
    }

    await localDataSource.markManyAsSeen(models);

    final lastItem = items.last;
    unawaited(() async {
      try {
        await notifications.refreshAfterSeen(lastItem);
        await quickAdd.queueNextAfterSeen(lastItem);
      } catch (e) {
        debugPrint('[SeenService] post-mark refresh failed: $e');
      }
    }());
  }

  Future<void> removeFromSeen(
    int tmdbId,
    MediaType type, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await localDataSource.removeFromSeen(
      tmdbId,
      type.name,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    unawaited(notifications.refreshNotificationDateByTmdbId(tmdbId, type));
  }

  Future<void> updateSeenEntry(SeenItem item) async {
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

  Future<void> deleteSeenEntry(int id) async {
    final entry = await localDataSource.getSeenEntryByIsarId(id);
    if (entry != null) {
      final tmdbId = entry.tmdbId;
      final type = entry.type == 'movie' ? MediaType.movie : MediaType.tv;
      await localDataSource.deleteSeenEntry(id);
      unawaited(notifications.refreshNotificationDateByTmdbId(tmdbId, type));
    }
  }

  Future<List<SeenItem>> getSeenItems() async {
    final items = await localDataSource.getAllSeenItems();
    final List<SeenItem> results = [];

    // One batched cache read: localized titles, and posters for rows
    // saved without one.
    final cached = await cache.getItems([
      for (final m in items)
        (m.tmdbId, m.type == 'movie' ? MediaType.movie : MediaType.tv),
    ]);

    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      final type = m.type == 'movie' ? MediaType.movie : MediaType.tv;
      String? posterPath = m.posterPath;
      final cachedPoster = cached[i]?.posterPath;

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
          title: preferCachedTitle(cached[i], m.title),
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

  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type) async {
    final items = await localDataSource.getSeenStatus(tmdbId, type.name);
    final cachedItem = await cache.getItem(tmdbId, type);

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
          title: preferCachedTitle(cachedItem, m.title),
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
}
