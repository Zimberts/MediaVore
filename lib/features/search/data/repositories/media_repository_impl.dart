import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/cache/cache_warmup_policy.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/services/cache_warmup_service.dart';
import 'package:mediavore/features/search/data/services/cached_title.dart';
import 'package:mediavore/features/search/data/services/import_export_service.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';
import 'package:mediavore/features/search/data/services/repository_lifecycle.dart';
import 'package:mediavore/features/search/data/services/seen_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Implementation of the [MediaRepository] that uses a remote and a local data source.
///
/// A facade: it waits for initialization, then delegates to one service per
/// concern (see `lib/features/search/data/services/`). Lists and likes, which
/// are thin wrappers over the local data source, stay here.
@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;

  /// Gates the automatic warm-up started on creation. `null` = always run.
  final CacheWarmupPolicy? warmupPolicy;

  /// App language; the TMDB cache is dropped when it changes so titles are
  /// never shown in a previous language. `null` disables the check.
  final LocaleService? localeService;

  /// TMDB credential; the automatic cache warm-up is skipped while none is
  /// set. `null` = always run.
  final TmdbCredentialStore? credentialStore;

  /// Max concurrent `/movie|tv/{id}` requests when enriching a result page.
  static const int enrichmentConcurrency =
      MediaDetailsService.enrichmentConcurrency;

  late final MediaDetailsService _details;
  late final QuickAddService _quickAdd;
  late final NotificationRefreshService _notifications;
  late final SeenService _seen;
  late final CacheWarmupService _warmup;
  late final ImportExportService _importExport;
  late final RepositoryLifecycle _lifecycle;

  /// Creates a new instance of [MediaRepositoryImpl].
  MediaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.cache,
    this.warmupPolicy,
    this.localeService,
    this.credentialStore,
    bool autoInit = true,
  }) {
    _details = MediaDetailsService(
      remoteDataSource: remoteDataSource,
      cache: cache,
    );
    final scanner = NextEpisodeScanner(_details);
    _quickAdd = QuickAddService(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      cache: cache,
      details: _details,
      scanner: scanner,
    );
    _notifications = NotificationRefreshService(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      cache: cache,
      details: _details,
      scanner: scanner,
      quickAdd: _quickAdd,
    );
    _seen = SeenService(
      localDataSource: localDataSource,
      cache: cache,
      details: _details,
      notifications: _notifications,
      quickAdd: _quickAdd,
    );
    _warmup = CacheWarmupService(
      localDataSource: localDataSource,
      cache: cache,
      details: _details,
      notifications: _notifications,
      hasCredential: credentialStore == null
          ? null
          : () => credentialStore!.hasCredential,
    );
    _importExport = ImportExportService(
      localDataSource: localDataSource,
      details: _details,
      localeService: localeService,
    );
    _lifecycle = RepositoryLifecycle(
      cache: cache,
      warmup: _warmup,
      warmupPolicy: warmupPolicy,
      localeService: localeService,
    );

    localeService?.addListener(_onLanguageChanged);
    if (autoInit) {
      _lifecycle.init();
    } else {
      _lifecycle.skipInit();
    }
  }

  Future<void> _ensureInitialized() => _lifecycle.ensureInitialized();

  void _onLanguageChanged() => unawaited(applyLanguageChange());

  @override
  Future<bool> applyLanguageChange() => _lifecycle.applyLanguageChange();

  /// Stops the in-flight cache warm-up after the current item.
  void cancelCacheWarmup() => _warmup.cancel();

  @override
  Future<List<MediaItem>> searchMedia(
    String query, {
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? originalLanguage,
    MediaType? type,
  }) async {
    await _ensureInitialized();
    // Remote errors (AppException) propagate so the UI can tell "no results"
    // apart from "offline" / "missing API key" / "server down".
    final results = await remoteDataSource.searchMedia(
      query,
      page: page,
      genreIds: genreIds,
      releaseYear: releaseYear,
      minRating: minRating,
      originalLanguage: originalLanguage,
      type: type,
    );
    final enriched = await _details.enrichItems(results);
    await _details.cacheItemsBestEffort(enriched, 'searchMedia');
    return enriched;
  }

  @override
  Future<List<MediaItem>> discoverMedia({
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? originalLanguage,
    MediaType type = MediaType.movie,
    String sortBy = 'popularity.desc',
  }) async {
    await _ensureInitialized();
    final results = await remoteDataSource.discoverMedia(
      page: page,
      genreIds: genreIds,
      releaseYear: releaseYear,
      minRating: minRating,
      originalLanguage: originalLanguage,
      type: type,
      sortBy: sortBy,
    );
    final enriched = await _details.enrichItems(results);
    await _details.cacheItemsBestEffort(enriched, 'discoverMedia');
    return enriched;
  }

  @override
  Future<void> validateTmdbCredential(String credential) =>
      remoteDataSource.validateCredential(credential);

  @override
  Future<MediaDetails> getMediaDetails(
    int id, {
    MediaType type = MediaType.movie,
  }) async {
    await _ensureInitialized();
    return _details.getMediaDetails(id, type: type);
  }

  @override
  Future<ActorDetails> getActorDetails(int actorId) async {
    await _ensureInitialized();
    return _details.getActorDetails(actorId);
  }

  @override
  Future<Map<String, dynamic>> getSeasonDetails(
    int tvId,
    int seasonNumber,
  ) async {
    await _ensureInitialized();
    return _details.getSeasonDetails(tvId, seasonNumber);
  }

  @override
  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) async {
    await _ensureInitialized();
    return _details.getSimilarMedia(id, type);
  }

  @override
  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) async {
    await _ensureInitialized();
    return _details.getRecommendedMedia(id, type);
  }

  @override
  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) async {
    await _ensureInitialized();
    return _details.getWatchProviders(id, type);
  }

  @override
  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) async {
    await _ensureInitialized();
    return _details.getVideos(id, type);
  }

  @override
  Future<DateTime?> getCacheUpdateDate(int tmdbId, MediaType type) async {
    await _ensureInitialized();
    return cache.getCacheUpdateDate(tmdbId, type);
  }

  // Lists

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
      final details = await _details.getMediaDetails(
        item.id,
        type: item.mediaType,
      );
      if (item.mediaType == MediaType.tv && details.item.seasons != null) {
        for (final season in details.item.seasons!) {
          await _details.getSeasonDetails(item.id, season.seasonNumber);
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
    final items = (await localDataSource.getListItems(
      listName,
    )).take(limit).toList();
    final cachedItems = await cache.getItems([
      for (final item in items)
        (item.id, item.type == 'movie' ? MediaType.movie : MediaType.tv),
    ]);
    return [
      for (var i = 0; i < items.length; i++)
        MediaItemPreview(
          id: items[i].id,
          title: preferCachedTitle(cachedItems[i], items[i].title),
          posterPath: cachedItems[i]?.posterPath,
          type: items[i].type,
        ),
    ];
  }

  // Seen history

  @override
  Future<void> markAsSeen(SeenItem item) async {
    await _ensureInitialized();
    return _seen.markAsSeen(item);
  }

  @override
  Future<void> removeFromSeen(
    int tmdbId,
    MediaType type, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _ensureInitialized();
    return _seen.removeFromSeen(
      tmdbId,
      type,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  @override
  Future<void> updateSeenEntry(SeenItem item) async {
    await _ensureInitialized();
    return _seen.updateSeenEntry(item);
  }

  @override
  Future<void> deleteSeenEntry(int id) async {
    await _ensureInitialized();
    return _seen.deleteSeenEntry(id);
  }

  @override
  Future<List<SeenItem>> getSeenItems() async {
    await _ensureInitialized();
    return _seen.getSeenItems();
  }

  @override
  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type) async {
    await _ensureInitialized();
    return _seen.getSeenStatus(tmdbId, type);
  }

  // Cache

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
      // Otherwise the warm-up would refill what is being cleared.
      cancelCacheWarmup();
      await cache.clearAll();
      // Refill on the next start instead of waiting out the 24 h throttle.
      await warmupPolicy?.reset();
    } else {
      await _warmup.run();
    }
  }

  @override
  Future<void> fillCache() async {
    await _ensureInitialized();
    await _warmup.run();
  }

  // Import / export

  @override
  Future<List<int>> exportAllData() async {
    await _ensureInitialized();
    return _importExport.exportAllData();
  }

  @override
  Future<void> importAllData(
    List<int> zipBytes, {
    ImportMode mode = ImportMode.append,
    Function(double, String)? onProgress,
  }) async {
    await _ensureInitialized();
    return _importExport.importAllData(
      zipBytes,
      mode: mode,
      onProgress: onProgress,
    );
  }

  // Likes

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

  // Releases (notifications)

  @override
  Future<void> toggleNotification(
    MediaItem item, {
    bool autoNotify = false,
  }) async {
    await _ensureInitialized();
    return _notifications.toggleNotification(item, autoNotify: autoNotify);
  }

  @override
  Future<bool> isNotified(int tmdbId, MediaType type) async {
    await _ensureInitialized();
    return localDataSource.isNotified(tmdbId, type.name);
  }

  @override
  Future<List<NotifiedItem>> getNotifiedItems() async {
    await _ensureInitialized();
    return _notifications.getNotifiedItems();
  }

  @override
  Stream<void> watchNotifiedItems() {
    return localDataSource.watchNotifiedItems();
  }

  @override
  Future<void> refreshNotifiedItems({bool force = false}) async {
    await _ensureInitialized();
    return _notifications.refreshNotifiedItems(force: force);
  }

  @override
  Future<void> refreshNotificationForSeries(
    int tmdbId,
    MediaType type, {
    bool force = false,
  }) async {
    await _ensureInitialized();
    return _notifications.refreshNotificationForSeries(
      tmdbId,
      type,
      force: force,
    );
  }

  @override
  Future<void> refreshReturningSeries(int tmdbId) async {
    await _ensureInitialized();
    return _notifications.refreshReturningSeries(tmdbId);
  }

  // Quick Add

  @override
  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _ensureInitialized();
    return _quickAdd.optOutSeries(
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
    return _quickAdd.clearOptOutSeries(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  @override
  Future<void> refreshQuickAddItems() async {
    await _ensureInitialized();
    return _quickAdd.refreshQuickAddItems();
  }

  @override
  Future<List<QuickAddItem>> getQuickAddItems() async {
    await _ensureInitialized();
    return _quickAdd.getQuickAddItems();
  }

  @override
  Future<List<QuickAddOmission>> getQuickAddOmissions({
    bool allowFetch = false,
  }) async {
    await _ensureInitialized();
    return _quickAdd.getQuickAddOmissions(allowFetch: allowFetch);
  }

  @override
  Future<void> addQuickAddItem(QuickAddItem item) async {
    await _ensureInitialized();
    return _quickAdd.addQuickAddItem(item);
  }

  @override
  Future<void> removeQuickAddItemById(int isarId) async {
    await _ensureInitialized();
    return _quickAdd.removeQuickAddItemById(isarId);
  }

  @override
  Future<void> populateQuickAddFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  }) async {
    await _ensureInitialized();
    return _quickAdd.populateFromSeenHistory(
      tmdbId: tmdbId,
      tailSeason: tailSeason,
      tailEpisode: tailEpisode,
    );
  }

  @override
  Future<void> clearQuickAddItems() async {
    await _ensureInitialized();
    return _quickAdd.clearQuickAddItems();
  }
}
