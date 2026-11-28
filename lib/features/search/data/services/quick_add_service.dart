import 'package:flutter/foundation.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/json_maps.dart';
import 'package:mediavore/core/utils/watch_tail.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/services/cached_title.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// The Quick Add queue: next aired episode of each viewing streak, opt-outs
/// and the omission diagnostics.
///
/// Part of `MediaRepositoryImpl`; callers are expected to have awaited the
/// repository's initialization.
class QuickAddService {
  final MediaRemoteDataSource remoteDataSource;
  final MediaListLocalDataSource localDataSource;
  final MediaCache cache;
  final MediaDetailsService details;
  final NextEpisodeScanner scanner;

  QuickAddService({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.cache,
    required this.details,
    required this.scanner,
  });

  /// After a TV episode is marked seen, replaces its quick-add entry with the
  /// next aired episode of the same streak.
  ///
  /// The streak starts at [item]: candidates follow it, and episodes already
  /// seen at or after [SeenItem.seenDate] are skipped. Episodes without an air
  /// date, or airing in the future, are not proposed. The opt-out recorded when
  /// the user dismissed an episode is respected.
  Future<void> queueNextAfterSeen(SeenItem item) async {
    final seasonNumber = item.seasonNumber;
    final episodeNumber = item.episodeNumber;
    if (item.type != MediaType.tv ||
        seasonNumber == null ||
        episodeNumber == null) {
      return;
    }

    try {
      // remove any quick-add that referred to the episode we just marked as seen
      try {
        await localDataSource.removeQuickAddItemByTmdbSeasonEpisode(
          item.tmdbId,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
        );
      } catch (e) {
        debugPrint('[Repo] markAsSeen quick-add removal failed: $e');
      }

      final seen = await localDataSource.getSeenStatus(item.tmdbId, 'tv');

      MediaItem? detailsItem = await cache.getItem(item.tmdbId, MediaType.tv);
      if (detailsItem == null) {
        try {
          if (item.tmdbId < 0) {
            detailsItem = (await details.getMediaDetails(
              item.tmdbId,
              type: MediaType.tv,
            )).item;
          } else {
            detailsItem = await remoteDataSource.getMediaItem(
              item.tmdbId,
              type: MediaType.tv,
            );
            await cache.cacheItem(detailsItem);
          }
        } catch (_) {
          return;
        }
      }

      final now = DateTime.now();
      final scan = await scanner.scan(
        detailsItem,
        WatchTail(
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          seenDate: item.seenDate,
        ),
        seenEpisodeKeys(seen, seenSince: item.seenDate),
        forceRemote: false,
        now: now,
        where: (episode) => isAired(episode, now),
      );
      final next = scan.episode;
      if (next == null) return;

      // Respect the opt-out recorded when the user dismissed this episode
      // (the UI keys it by the dismissed episode, not the streak tail).
      final optedOut = await localDataSource.isOptedOut(
        item.tmdbId,
        seasonNumber: next.seasonNumber,
        episodeNumber: next.episodeNumber,
      );
      if (optedOut) return;

      await localDataSource.addQuickAddItem(
        QuickAddItemModel(
          tmdbId: item.tmdbId,
          type: 'tv',
          seasonNumber: next.seasonNumber,
          episodeNumber: next.episodeNumber,
          insertedAt: item.seenDate,
          airDate: next.airDate,
          title: detailsItem.title,
          runtime: next.runtime,
          posterPath: detailsItem.posterPath,
        ),
      );
    } catch (e) {
      debugPrint('[Repo] markAsSeen next-episode computation failed: $e');
    }
  }

  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) {
    return localDataSource.addOptOut(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  Future<void> clearOptOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) {
    return localDataSource.removeOptOut(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  /// Opt-outs of Quick Add, most recent first. The title comes from the
  /// cached series, else from a viewing of it: local data only.
  Future<List<QuickAddOptOut>> getQuickAddOptOuts() async {
    final optOuts = await localDataSource.getOptOuts();
    if (optOuts.isEmpty) return const [];

    final cached = await cache.getItems([
      for (final optOut in optOuts) (optOut.tmdbId, MediaType.tv),
    ]);

    final result = <QuickAddOptOut>[];
    for (var i = 0; i < optOuts.length; i++) {
      final optOut = optOuts[i];
      String? storedTitle;
      String? storedPoster;
      if (cached[i] == null) {
        final viewings = await localDataSource.getSeenStatus(
          optOut.tmdbId,
          'tv',
        );
        if (viewings.isNotEmpty) {
          storedTitle = viewings.first.title;
          storedPoster = viewings.first.posterPath;
        }
      }
      final title = preferCachedTitle(cached[i], storedTitle);
      result.add(
        QuickAddOptOut(
          tmdbId: optOut.tmdbId,
          seasonNumber: optOut.seasonNumber,
          episodeNumber: optOut.episodeNumber,
          optedOutAt: optOut.optedOutAt,
          title: title == null || title.isEmpty ? null : title,
          posterPath: cached[i]?.posterPath ?? storedPoster,
        ),
      );
    }

    result.sort((a, b) {
      final byDate = b.optedOutAt.compareTo(a.optedOutAt);
      return byDate != 0 ? byDate : a.tmdbId.compareTo(b.tmdbId);
    });
    return result;
  }

  /// Fills the missing runtime of TV quick-add entries from season details.
  Future<void> refreshQuickAddItems() async {
    final items = await localDataSource.getQuickAddItems();

    for (final item in items) {
      if (item.runtime != null) continue;
      if (item.type != 'tv') continue;
      final seasonNumber = item.seasonNumber;
      final episodeNumber = item.episodeNumber;
      if (seasonNumber == null ||
          episodeNumber == null ||
          item.isarId == null) {
        continue;
      }

      try {
        final seasonDetails = await details.getSeasonDetails(
          item.tmdbId,
          seasonNumber,
        );
        int? runtime;
        for (final ep in jsonObjectList(seasonDetails['episodes'])) {
          if (ep['episode_number'] == episodeNumber) {
            runtime = ep['runtime'] as int?;
            break;
          }
        }
        if (runtime != null) {
          await localDataSource.updateQuickAddItemRuntime(
            item.isarId!,
            runtime,
          );
        }
      } catch (e) {
        debugPrint('[Repo] refreshQuickAddItems runtime update failed: $e');
      }
    }
  }

  Future<List<QuickAddItem>> getQuickAddItems() async {
    final items = await localDataSource.getQuickAddItems();
    final cached = await cache.getItems([
      for (final m in items)
        (m.tmdbId, m.type == 'movie' ? MediaType.movie : MediaType.tv),
    ]);
    return [
      for (var i = 0; i < items.length; i++)
        QuickAddItem(
          isarId: items[i].isarId,
          tmdbId: items[i].tmdbId,
          type: items[i].type == 'movie' ? MediaType.movie : MediaType.tv,
          seasonNumber: items[i].seasonNumber,
          episodeNumber: items[i].episodeNumber,
          insertedAt: items[i].insertedAt,
          airDate: items[i].airDate,
          title: preferCachedTitle(cached[i], items[i].title),
          posterPath: items[i].posterPath,
          runtime: items[i].runtime,
        ),
    ];
  }

  Future<List<QuickAddOmission>> getQuickAddOmissions({
    bool allowFetch = false,
  }) async {
    final omissions = <QuickAddOmission>[];
    final seenOmissionKeys = <String>{};

    try {
      final seenItems = await localDataSource.getAllSeenItems();
      final tvIds = seenItems
          .where((s) => s.type == 'tv')
          .map((s) => s.tmdbId)
          .toSet();
      if (tvIds.isEmpty) return omissions;

      final existingQuick = await localDataSource.getQuickAddItems();
      final existingKeysByTv = <int, Set<String>>{};
      for (final q in existingQuick) {
        existingKeysByTv
            .putIfAbsent(q.tmdbId, () => <String>{})
            .add('${q.seasonNumber}:${q.episodeNumber}');
      }

      for (final tmdbId in tvIds) {
        final seen = await localDataSource.getSeenStatus(tmdbId, 'tv');
        if (seen.isEmpty) continue;

        MediaItem? resolved = await cache.getItem(tmdbId, MediaType.tv);
        if (resolved?.seasons == null && (allowFetch || tmdbId < 0)) {
          try {
            if (tmdbId < 0) {
              resolved = (await details.getMediaDetails(
                tmdbId,
                type: MediaType.tv,
              )).item;
            } else {
              resolved = await remoteDataSource.getMediaItem(
                tmdbId,
                type: MediaType.tv,
              );
              await cache.cacheItem(resolved);
            }
          } catch (e) {
            debugPrint('[Repo] getQuickAddOmissions item resolve failed: $e');
          }
        }

        final seasons = resolved?.seasons;
        final title =
            resolved?.title ?? (seen.isNotEmpty ? seen.first.title : 'Unknown');
        final posterPath = resolved?.posterPath;

        if (seasons == null) {
          if (seenOmissionKeys.add('noCacheData|$tmdbId')) {
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                reason: QuickAddOmissionReason.noCacheData,
              ),
            );
          }
          continue;
        }

        // Latest seen date per (season, episode).
        final lastSeenMap = <int, Map<int, DateTime>>{};
        for (final s in seen) {
          final season = s.seasonNumber;
          final ep = s.episodeNumber;
          if (season == null || ep == null) continue;
          final mapForSeason = lastSeenMap.putIfAbsent(season, () => {});
          final prev = mapForSeason[ep];
          mapForSeason[ep] = (prev == null || prev.isBefore(s.seenDate))
              ? s.seenDate
              : prev;
        }

        final sortedSeasons = List<TVSeason>.from(seasons)
          ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

        // Season lookup is cache-first. Only [allowFetch] triggers a network
        // call, and each season is fetched at most once per show.
        final seasonMemo = <int, Map<String, dynamic>?>{};
        Future<Map<String, dynamic>?> seasonFor(int seasonNumber) async {
          if (seasonMemo.containsKey(seasonNumber)) {
            return seasonMemo[seasonNumber];
          }
          Map<String, dynamic>? data = await cache.getSeason(
            tmdbId,
            seasonNumber,
          );
          if (data == null && allowFetch) {
            try {
              data = await details.getSeasonDetails(tmdbId, seasonNumber);
            } catch (_) {
              data = null;
            }
          }
          seasonMemo[seasonNumber] = data;
          return data;
        }

        final existingForTv = existingKeysByTv[tmdbId] ?? const <String>{};

        final seenSorted = [...seen]
          ..sort((a, b) {
            final dateCmp = b.seenDate.compareTo(a.seenDate);
            if (dateCmp != 0) return dateCmp;
            final aSeason = a.seasonNumber ?? 0;
            final bSeason = b.seasonNumber ?? 0;
            if (aSeason != bSeason) return aSeason.compareTo(bSeason);
            return (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0);
          });

        for (final s in seenSorted) {
          final tailSeason = s.seasonNumber;
          final tailEpisode = s.episodeNumber;
          if (tailSeason == null || tailEpisode == null) continue;

          final tailSeenDate = s.seenDate;
          final startEpisode = tailEpisode + 1;

          int? foundSeason;
          int? foundEpisode;
          DateTime? foundAirDate;
          DateTime? firstFutureAirDate;
          int? futureSeason;
          int? futureEpisode;
          int? noAirDateSeason;
          int? noAirDateEpisode;
          var hadNoAirDate = false;
          var cacheMiss = false;

          for (final season in sortedSeasons) {
            if (season.seasonNumber == 0) continue;
            if (season.seasonNumber < tailSeason) continue;

            final seasonData = await seasonFor(season.seasonNumber);
            if (seasonData == null) {
              // Can't inspect this season without a fetch; stop scanning.
              cacheMiss = true;
              break;
            }

            final episodes = jsonObjectList(seasonData['episodes']);
            // Ignore seasons with no dated episodes at all (e.g. an announced but
            // unscheduled next season): they are not actionable in Quick Add and
            // must not surface as "no air date".
            final hasDatedEpisode = episodes.any((ep) {
              final airDate = ep['air_date'] as String?;
              return airDate != null &&
                  airDate.isNotEmpty &&
                  DateTime.tryParse(airDate) != null;
            });
            if (!hasDatedEpisode) continue;

            for (final ep in episodes) {
              final epNum = ep['episode_number'] as int?;
              if (epNum == null) continue;
              if (season.seasonNumber == tailSeason && epNum < startEpisode) {
                continue;
              }

              final lastSeenForEp = lastSeenMap[season.seasonNumber]?[epNum];
              final isEpSeenAfterTail =
                  lastSeenForEp != null &&
                  !lastSeenForEp.isBefore(tailSeenDate);
              if (isEpSeenAfterTail) continue;

              final airDateStr = ep['air_date'] as String?;
              if (airDateStr == null || airDateStr.isEmpty) {
                hadNoAirDate = true;
                noAirDateSeason ??= season.seasonNumber;
                noAirDateEpisode ??= epNum;
                continue;
              }

              DateTime ad;
              try {
                ad = DateTime.parse(airDateStr);
              } catch (_) {
                hadNoAirDate = true;
                continue;
              }

              if (ad.isAfter(DateTime.now())) {
                if (firstFutureAirDate == null ||
                    ad.isBefore(firstFutureAirDate)) {
                  firstFutureAirDate = ad;
                  futureSeason = season.seasonNumber;
                  futureEpisode = epNum;
                }
                continue;
              }

              foundSeason = season.seasonNumber;
              foundEpisode = epNum;
              foundAirDate = ad;
              break;
            }

            if (foundSeason != null) break;
          }

          if (foundSeason != null && foundEpisode != null) {
            final key = '$foundSeason:$foundEpisode';
            if (existingForTv.contains(key)) {
              continue; // Already shown in Quick Add.
            }

            final optedOut = await localDataSource.isOptedOut(
              tmdbId,
              seasonNumber: foundSeason,
              episodeNumber: foundEpisode,
            );
            final reason = optedOut
                ? QuickAddOmissionReason.optedOut
                : QuickAddOmissionReason.notPopulated;
            if (!seenOmissionKeys.add(
              '${reason.name}|$tmdbId|$foundSeason|$foundEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                seasonNumber: foundSeason,
                episodeNumber: foundEpisode,
                airDate: foundAirDate,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: reason,
              ),
            );
            continue;
          }

          if (firstFutureAirDate != null) {
            if (!seenOmissionKeys.add(
              'notReleased|$tmdbId|$futureSeason|$futureEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                seasonNumber: futureSeason,
                episodeNumber: futureEpisode,
                airDate: firstFutureAirDate,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: QuickAddOmissionReason.notReleased,
              ),
            );
            continue;
          }

          if (cacheMiss) {
            if (!seenOmissionKeys.add(
              'noCacheData|$tmdbId|$tailSeason|$tailEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: QuickAddOmissionReason.noCacheData,
              ),
            );
            continue;
          }

          if (hadNoAirDate) {
            if (!seenOmissionKeys.add(
              'noAirDate|$tmdbId|$noAirDateSeason|$noAirDateEpisode',
            )) {
              continue;
            }
            omissions.add(
              QuickAddOmission(
                tmdbId: tmdbId,
                title: title,
                posterPath: posterPath,
                seasonNumber: noAirDateSeason,
                episodeNumber: noAirDateEpisode,
                tailSeason: tailSeason,
                tailEpisode: tailEpisode,
                reason: QuickAddOmissionReason.noAirDate,
              ),
            );
          }
          // Otherwise the show is fully caught up: nothing expected.
        }
      }
    } catch (e) {
      debugPrint('[Repo] getQuickAddOmissions error: $e');
    }

    return omissions;
  }

  Future<void> addQuickAddItem(QuickAddItem item) {
    final model = QuickAddItemModel(
      tmdbId: item.tmdbId,
      type: item.type == MediaType.movie ? 'movie' : 'tv',
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
      insertedAt: item.insertedAt,
      airDate: item.airDate,
      title: item.title,
      posterPath: item.posterPath,
      runtime: item.runtime,
    );
    return localDataSource.addQuickAddItem(model);
  }

  Future<void> removeQuickAddItemById(int isarId) {
    return localDataSource.removeQuickAddItemById(isarId);
  }

  Future<void> clearQuickAddItems() => localDataSource.clearQuickAddItems();

  /// Queues, for each seen episode of each TV series (or only [tmdbId] /
  /// the given tail), the next aired episode not seen since that viewing.
  Future<void> populateFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  }) async {
    try {
      final seenItems = await localDataSource.getAllSeenItems();
      var tvIds = seenItems
          .where((s) => s.type == 'tv')
          .map((s) => s.tmdbId)
          .toSet();

      // If caller requested a specific tmdbId, restrict to it (if present in seen)
      if (tmdbId != null) {
        if (tvIds.contains(tmdbId)) {
          tvIds = {tmdbId};
        } else {
          // nothing to do
          return;
        }
      }

      final existingQuick = await localDataSource.getQuickAddItems();

      for (final tmdbId in tvIds) {
        final seen = await localDataSource.getSeenStatus(tmdbId, 'tv');

        MediaItem? detailsItem = await cache.getItem(tmdbId, MediaType.tv);
        if (detailsItem == null) {
          try {
            if (tmdbId < 0) {
              detailsItem = (await details.getMediaDetails(
                tmdbId,
                type: MediaType.tv,
              )).item;
            } else {
              detailsItem = await remoteDataSource.getMediaItem(
                tmdbId,
                type: MediaType.tv,
              );
              await cache.cacheItem(detailsItem);
            }
          } catch (_) {
            detailsItem = null;
          }
        }

        if (detailsItem?.seasons != null) {
          // Build a map of the latest seen date per episode for quick timestamped lookup
          final Map<int, Map<int, DateTime>> lastSeenMap = {};
          for (final s in seen) {
            if (s.seasonNumber == null || s.episodeNumber == null) continue;
            final season = s.seasonNumber!;
            final ep = s.episodeNumber!;
            final mapForSeason = lastSeenMap.putIfAbsent(season, () => {});
            final prevSeen = mapForSeason[ep];
            mapForSeason[ep] =
                (prevSeen == null || prevSeen.isBefore(s.seenDate))
                ? s.seenDate
                : prevSeen;
          }

          // Existing quick-add candidates for this tmdbId
          final existingForId = existingQuick
              .where((q) => q.tmdbId == tmdbId)
              .map((q) => '${q.seasonNumber}:${q.episodeNumber}')
              .toSet();

          final sortedSeasons = List<TVSeason>.from(detailsItem!.seasons!)
            ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

          // For each seen episode (treated as a tail candidate), compute the next episode
          // that has NOT been seen after that seenDate. This respects chronological
          // order: if the successor was seen earlier but not after this seenDate, it
          // still counts as unseen for this tail.
          final Set<String> addedKeysForId = {};
          // iterate seen in reverse chronological order so most recent tails win for insertedAt
          final seenSorted = [...seen]
            ..sort((a, b) {
              final dateCmp = b.seenDate.compareTo(a.seenDate);
              if (dateCmp != 0) return dateCmp;
              // If seenDate is equal, order by season (ascending) then episode (ascending)
              final aSeason = a.seasonNumber ?? 0;
              final bSeason = b.seasonNumber ?? 0;
              if (aSeason != bSeason) return aSeason.compareTo(bSeason);
              final aEp = a.episodeNumber ?? 0;
              final bEp = b.episodeNumber ?? 0;
              return aEp.compareTo(bEp);
            });
          for (final s in seenSorted) {
            if (s.seasonNumber == null || s.episodeNumber == null) {
              continue;
            }
            // If caller requested a specific tail, skip other seen entries
            if (tailSeason != null && tailEpisode != null) {
              if (s.seasonNumber != tailSeason ||
                  s.episodeNumber != tailEpisode) {
                continue;
              }
            }
            final localTailSeason = s.seasonNumber!;
            final localTailEpisode = s.episodeNumber!;
            final tailSeenDate = s.seenDate;

            final int startSeason = localTailSeason;
            final int startEpisode = localTailEpisode + 1;

            DateTime? foundAirDate;
            int? foundSeason;
            int? foundEpisode;
            int? foundRuntime;

            for (final season in sortedSeasons) {
              if (season.seasonNumber == 0) {
                continue;
              }
              if (season.seasonNumber < startSeason) {
                continue;
              }

              try {
                final seasonDetails = await details.getSeasonDetails(
                  detailsItem.id,
                  season.seasonNumber,
                );
                final episodes = jsonObjectList(seasonDetails['episodes']);
                for (final ep in episodes) {
                  final epNum = ep['episode_number'] as int;

                  if (season.seasonNumber == startSeason &&
                      epNum < startEpisode) {
                    continue;
                  }

                  // Consider episode as "seen after tail" only if its last seen date
                  // is strictly after the tail's seenDate, which preserves
                  // re-watch streaks (a later tail can legitimately point at an
                  // episode seen earlier in a previous pass).
                  final lastSeenForEp =
                      lastSeenMap[season.seasonNumber]?[epNum];
                  final isEpSeenAfterTail =
                      lastSeenForEp != null &&
                      // Treat equal timestamps as "after" for tail grouping
                      !lastSeenForEp.isBefore(tailSeenDate);
                  if (isEpSeenAfterTail) {
                    continue;
                  }

                  final airDateStr = ep['air_date'] as String?;
                  if (airDateStr == null || airDateStr.isEmpty) {
                    continue;
                  }

                  try {
                    final ad = DateTime.parse(airDateStr);
                    if (ad.isAfter(DateTime.now())) {
                      // skip future episodes
                      continue;
                    }
                    foundAirDate = ad;
                  } catch (_) {
                    continue;
                  }

                  foundSeason = season.seasonNumber;
                  foundEpisode = epNum;
                  foundRuntime = ep['runtime'] as int?;
                  break;
                }
              } catch (e) {
                debugPrint(
                  '[Repo] populateQuickAddFromSeenHistory season scan failed: $e',
                );
              }
              if (foundSeason != null) break;
            }

            if (foundSeason != null && foundEpisode != null) {
              final key = '$foundSeason:$foundEpisode';
              if (existingForId.contains(key) || addedKeysForId.contains(key)) {
                continue;
              }

              final optedOut = await localDataSource.isOptedOut(
                tmdbId,
                seasonNumber: foundSeason,
                episodeNumber: foundEpisode,
              );
              if (optedOut) {
                continue;
              }

              final quick = QuickAddItemModel(
                tmdbId: tmdbId,
                type: 'tv',
                seasonNumber: foundSeason,
                episodeNumber: foundEpisode,
                insertedAt: tailSeenDate,
                airDate: foundAirDate,
                title: detailsItem.title,
                runtime: foundRuntime,
                posterPath: detailsItem.posterPath,
              );
              await localDataSource.addQuickAddItem(quick);
              addedKeysForId.add(key);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Repo] populateQuickAddFromSeenHistory failed: $e');
    }
  }
}
