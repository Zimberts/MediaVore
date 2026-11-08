import 'package:flutter/foundation.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/watch_tail.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/services/cached_title.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Releases ("notified" items): toggling, listing, and keeping each entry's
/// release date anchored to the viewer's progress.
///
/// Part of `MediaRepositoryImpl`; callers are expected to have awaited the
/// repository's initialization.
class NotificationRefreshService {
  final MediaRemoteDataSource remoteDataSource;
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;
  final MediaDetailsService details;
  final NextEpisodeScanner scanner;
  final QuickAddService quickAdd;

  NotificationRefreshService({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.cache,
    required this.details,
    required this.scanner,
    required this.quickAdd,
  });

  Future<void> toggleNotification(
    MediaItem item, {
    bool autoNotify = false,
  }) async {
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
      await refreshNotificationDate(item);
    }

    await cache.cacheItem(item);
  }

  Future<List<NotifiedItem>> getNotifiedItems() async {
    final items = await localDataSource.getNotifiedItems();
    final cached = await cache.getItems([
      for (final m in items)
        (m.tmdbId, m.type == 'movie' ? MediaType.movie : MediaType.tv),
    ]);
    return [
      for (var i = 0; i < items.length; i++)
        NotifiedItem(
          tmdbId: items[i].tmdbId,
          type: items[i].type == 'movie' ? MediaType.movie : MediaType.tv,
          title: preferCachedTitle(cached[i], items[i].title),
          posterPath: items[i].posterPath,
          releaseDate: items[i].releaseDate,
          seasonNumber: items[i].seasonNumber,
          episodeNumber: items[i].episodeNumber,
          runtime: items[i].runtime,
          autoNotify: items[i].autoNotify,
        ),
    ];
  }

  Future<void> refreshNotifiedItems({bool force = false}) async {
    final notifiedItems = await localDataSource.getNotifiedItems();
    final now = DateTime.now();

    // Refresh one series at a time (never all at once) so the device is not
    // overloaded; yield between items to keep the UI responsive.
    for (final notified in notifiedItems) {
      final type = notified.type == 'movie' ? MediaType.movie : MediaType.tv;
      if (!force && !await _shouldRefreshNotification(notified, now)) continue;
      await refreshNotificationForSeries(notified.tmdbId, type, force: force);
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> refreshNotificationForSeries(
    int tmdbId,
    MediaType type, {
    bool force = false,
  }) async {
    final notified = await localDataSource.getNotifiedItem(tmdbId, type.name);
    if (notified == null) return;

    final now = DateTime.now();
    if (!force && !await _shouldRefreshNotification(notified, now)) return;

    try {
      final item = await remoteDataSource.getMediaItem(tmdbId, type: type);
      await cache.cacheItem(item);

      // TV seasons are cached without expiry, so bypass them here (already
      // throttled to once a day) to discover newly published episodes.
      await refreshNotificationDate(
        item,
        forceRemoteSeasons: force || type == MediaType.tv,
      );

      // Keep Quick Add in sync in the same pass. populateFromSeenHistory is
      // cache-first and reuses the seasons just fetched above, so returning
      // series pick up newly aired episodes without any extra network work.
      if (type == MediaType.tv) {
        await quickAdd.populateFromSeenHistory(tmdbId: tmdbId);
      }

      await localDataSource.markNotifiedRefreshed(tmdbId, type.name, now);
    } catch (e) {
      debugPrint('[Repo] refreshNotificationForSeries failed: $e');
    }
  }

  /// Re-fetches a returning series (details, latest season) bypassing the
  /// cache, then resyncs its Quick Add and Releases entries.
  Future<void> refreshReturningSeries(int tmdbId) async {
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

      final mediaDetails = MediaDetails(
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
      await cache.cacheDetails(mediaDetails);

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
      await quickAdd.populateFromSeenHistory(tmdbId: tmdbId);

      // 4. Keep the Releases entry in sync, bypassing caches for fresh episodes.
      await refreshNotificationDate(item, forceRemoteSeasons: true);
      await localDataSource.markNotifiedRefreshed(
        tmdbId,
        MediaType.tv.name,
        DateTime.now(),
      );
    } catch (e) {
      debugPrint("Failed to refresh returning series $tmdbId: $e");
    }
  }

  /// Reconciles the notification for a just-seen episode.
  ///
  /// When it is the latest episode of the streak a forced network refresh is
  /// used so the Releases entry advances to newly aired episodes; otherwise the
  /// cached details are enough.
  Future<void> refreshAfterSeen(SeenItem item) async {
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
    await refreshNotificationDateByTmdbId(item.tmdbId, item.type);
  }

  /// [refreshNotificationDate] for an id, from the cached item when present.
  /// Errors are logged, never thrown.
  Future<void> refreshNotificationDateByTmdbId(
    int tmdbId,
    MediaType type,
  ) async {
    try {
      final item = await cache.getItem(tmdbId, type);
      if (item != null) {
        await refreshNotificationDate(item);
      } else {
        final mediaDetails = await details.getMediaDetails(tmdbId, type: type);
        await refreshNotificationDate(mediaDetails.item);
      }
    } catch (e) {
      debugPrint('[Repo] _refreshNotificationDateByTmdbId failed: $e');
    }
  }

  /// Reconciles a notified item's stored release with the viewer's progress.
  ///
  /// For TV this anchors Releases to the first episode after the viewer's tail
  /// (the furthest-along seen episode) that has already aired and has not been
  /// seen, so an episode that is merely announced can never shadow the aired
  /// backlog. Only once everything aired is seen does it surface TMDB's
  /// `next_episode_to_air`. With no episode history at all, every aired episode
  /// counts as unwatched and the series starts from its first aired episode.
  /// Finished, fully watched series are removed and ones whose next season is
  /// planned without a date are downgraded to "Returning". Movies keep their
  /// 30-day stale rule.
  ///
  /// Set [forceRemoteSeasons] to bypass the season cache so newly released
  /// episodes are discovered.
  Future<void> refreshNotificationDate(
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

    final seen = await localDataSource.getSeenStatus(
      item.id,
      MediaType.tv.name,
    );

    // The tail is the furthest-along seen episode; without episode history the
    // series starts before its first episode, so every aired episode counts as
    // unwatched.
    final tail = findLatestTail(seen) ?? seriesStartTail();
    final seenKeys = seenEpisodeKeys(seen);
    final now = DateTime.now();

    final detailsItem = await _detailsItemWithSeasons(item);
    var scan = await scanner.scan(
      detailsItem,
      tail,
      seenKeys,
      forceRemote: forceRemoteSeasons,
      now: now,
    );

    // A stale season cache (an old season payload kept from before the episodes
    // aired) hides aired candidates. When TMDB metadata says an aired episode
    // after the tail is still unseen, re-scan from the network so the aired
    // backlog wins over the announced next episode.
    if (scan.episode == null &&
        !forceRemoteSeasons &&
        hasAiredUnseenEpisode(item, tail, seenKeys)) {
      scan = await scanner.scan(
        detailsItem,
        tail,
        seenKeys,
        forceRemote: true,
        now: now,
      );
    }

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

    // Everything aired is seen: TMDB's upcoming episode anchors next, and only
    // when there is none does the series become "Returning" or stop being
    // tracked.
    if (await _applyNextEpisodeFallback(item, seen: seen, tail: tail)) return;

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

  /// Movie counterpart of [refreshNotificationDate]: keeps the release date and
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
  /// Only used once everything aired has been seen: the episode must sit after
  /// [tail] and not already be in the seen history. Returns `true` when a
  /// release date was written.
  Future<bool> _applyNextEpisodeFallback(
    MediaItem item, {
    required List<SeenItemModel> seen,
    required WatchTail tail,
  }) async {
    final raw = item.nextEpisodeAirDate;
    if (raw == null || raw.isEmpty) return false;

    final DateTime next;
    try {
      next = DateTime.parse(raw);
    } catch (_) {
      return false;
    }

    final seasonNumber = item.nextSeasonNumber;
    final episodeNumber = item.nextEpisodeNumber;
    if (seasonNumber != null && episodeNumber != null) {
      final candidate = EpisodeRef(
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );
      if (!isEpisodeAfterTail(candidate, tail)) return false;
      final seenKeys = seenEpisodeKeys(seen);
      if (seenKeys.contains(episodeKey(seasonNumber, episodeNumber))) {
        return false;
      }
    }

    await localDataSource.setNotificationEpisode(
      item.id,
      item.mediaType.name,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      releaseDate: next,
    );
    return true;
  }

  /// Whether TMDB's `last_episode_to_air` is an aired episode after [tail] that
  /// is still missing from the seen history.
  ///
  /// A cheap, network-free signal that the series has an aired backlog waiting,
  /// used to retry a stale season-cache scan.
  @visibleForTesting
  bool hasAiredUnseenEpisode(
    MediaItem item,
    WatchTail tail,
    Set<String> seenKeys,
  ) {
    final seasonNumber = item.lastSeasonNumber;
    final episodeNumber = item.lastEpisodeNumber;
    if (seasonNumber == null || episodeNumber == null) return false;

    final aired = EpisodeRef(
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      airDate: _parseAirDate(item.lastEpisodeAirDate),
    );
    if (aired.airDate == null || !isEpisodeAfterTail(aired, tail)) {
      return false;
    }

    return !seenKeys.contains(episodeKey(seasonNumber, episodeNumber));
  }

  DateTime? _parseAirDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Details fetch that keeps a usable season list, preferring the caller's
  /// [item] (which the notification paths fetch from the network first) so a
  /// stale cached copy cannot shadow it.
  ///
  /// Callers that need freshly aired *episodes* force the season fetch instead
  /// (see [MediaDetailsService.seasonDetailsForRefresh]).
  Future<MediaItem?> _detailsItemWithSeasons(MediaItem item) async {
    if (item.seasons != null && item.seasons!.isNotEmpty) {
      await cache.cacheItem(item);
      return item;
    }

    final cached = await cache.getItem(item.id, MediaType.tv);
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

  /// Whether a notified entry is worth refreshing from the network, respecting
  /// the once-a-day throttle unless forced.
  ///
  /// Entries with a missing or already aired release date always qualify. TV
  /// entries pointing at a *future* episode normally do not, but they do when the
  /// cached series data reports an aired episode that is not in the seen history:
  /// such an entry is either stale or was anchored to the next announcement while
  /// an aired backlog was waiting, which is exactly what the anchor must fix.
  Future<bool> _shouldRefreshNotification(
    NotifiedItemModel notified,
    DateTime now,
  ) async {
    final last = notified.lastRefreshedAt;
    if (last != null && now.difference(last) < const Duration(days: 1)) {
      return false;
    }

    final release = notified.releaseDate;
    if (release == null || !release.isAfter(now)) return true;
    if (notified.type != MediaType.tv.name) return false;

    return _hasAiredUnseenBacklog(notified);
  }

  /// Whether the cached series data reports an aired episode the viewer has not
  /// seen, so the entry's future release date hides aired content.
  ///
  /// A missing cache entry is fetched once so the check stays reliable; the
  /// once-a-day throttle in [_shouldRefreshNotification] bounds the cost.
  Future<bool> _hasAiredUnseenBacklog(NotifiedItemModel notified) async {
    try {
      var item = await cache.getItem(notified.tmdbId, MediaType.tv);
      if (item == null) {
        item = await remoteDataSource.getMediaItem(
          notified.tmdbId,
          type: MediaType.tv,
        );
        await cache.cacheItem(item);
      }

      final seen = await localDataSource.getSeenStatus(
        notified.tmdbId,
        MediaType.tv.name,
      );
      final tail = findLatestTail(seen) ?? seriesStartTail();
      return hasAiredUnseenEpisode(item, tail, seenEpisodeKeys(seen));
    } catch (_) {
      return false;
    }
  }
}
