import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/search/data/services/cached_title.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Series in progress, for the Home screen: one entry per series that has a
/// next aired episode waiting in the Quick Add queue, with how far the viewer
/// is and when they last watched it.
///
/// Reads local data only (Quick Add queue, seen history, cached titles): it
/// never reaches the network.
///
/// Part of `MediaRepositoryImpl`; callers are expected to have awaited the
/// repository's initialization.
class InProgressService {
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;

  InProgressService({required this.localDataSource, required this.cache});

  /// Series in progress, most recent activity first.
  Future<List<InProgressItem>> getInProgressItems({DateTime? now}) async {
    final reference = now ?? DateTime.now();

    // One entry per series: the streak watched most recently.
    final nextBySeries = <int, QuickAddItemModel>{};
    for (final entry in await localDataSource.getQuickAddItems()) {
      if (entry.type != 'tv' ||
          entry.seasonNumber == null ||
          entry.episodeNumber == null) {
        continue;
      }
      final kept = nextBySeries[entry.tmdbId];
      if (kept == null || entry.insertedAt.isAfter(kept.insertedAt)) {
        nextBySeries[entry.tmdbId] = entry;
      }
    }
    if (nextBySeries.isEmpty) return const [];

    final lastSeen = <int, DateTime>{};
    final seenEpisodes = <int, Set<(int, int)>>{};
    for (final seen in await localDataSource.getAllSeenItems()) {
      if (seen.type != 'tv' || !nextBySeries.containsKey(seen.tmdbId)) continue;
      final previous = lastSeen[seen.tmdbId];
      if (previous == null || seen.seenDate.isAfter(previous)) {
        lastSeen[seen.tmdbId] = seen.seenDate;
      }
      final season = seen.seasonNumber;
      final episode = seen.episodeNumber;
      // Specials (season 0) are not part of TMDB's episode count.
      if (season != null && episode != null && season > 0) {
        seenEpisodes.putIfAbsent(seen.tmdbId, () => {}).add((season, episode));
      }
    }

    final entries = nextBySeries.values.toList();
    final cached = await cache.getItems([
      for (final entry in entries) (entry.tmdbId, MediaType.tv),
    ]);

    final items = <InProgressItem>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final seenCount = seenEpisodes[entry.tmdbId]?.length ?? 0;
      final total = cached[i]?.numberOfEpisodes;
      final hasTotal = total != null && total > 0;
      final lastActivity = lastSeen[entry.tmdbId] ?? entry.insertedAt;

      items.add(
        InProgressItem(
          next: QuickAddItem(
            isarId: entry.isarId,
            tmdbId: entry.tmdbId,
            type: MediaType.tv,
            seasonNumber: entry.seasonNumber,
            episodeNumber: entry.episodeNumber,
            insertedAt: entry.insertedAt,
            airDate: entry.airDate,
            title: preferCachedTitle(cached[i], entry.title),
            posterPath: entry.posterPath ?? cached[i]?.posterPath,
            runtime: entry.runtime,
          ),
          seenEpisodes: seenCount,
          totalEpisodes: hasTotal ? total : null,
          progress: hasTotal ? (seenCount / total).clamp(0.0, 1.0) : null,
          lastActivity: lastActivity,
          paused:
              reference.difference(lastActivity) > InProgressItem.pauseAfter,
        ),
      );
    }

    items.sort((a, b) {
      final byDate = b.lastActivity.compareTo(a.lastActivity);
      return byDate != 0 ? byDate : a.tmdbId.compareTo(b.tmdbId);
    });
    return items;
  }
}
