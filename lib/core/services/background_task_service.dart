import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/di/injection.config.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

const fetchTask = "dailySync";
const fetchTaskIdentifier = "fr.zimberts.mediavore.dailySync";
const refreshReturningSeriesTask = "refreshReturningSeries";
const refreshReturningSeriesPrefix = "refresh_";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("Native called background task: $task");
      
      // Initialize full DI safely so we can use locator<MediaRepository>() 
      // It includes opening Isar gracefully.
      await init(locator);
      final repo = locator<MediaRepository>();

      if (task == fetchTask || task == fetchTaskIdentifier || task == Workmanager.iOSBackgroundTask) {
        debugPrint("Running daily background sync...");
        final seenItems = await repo.getSeenItems();
        
        final Map<int, List> tvWatches = {};
        for (var item in seenItems) {
          if (item.type.name == 'tv') { // MediaType.tv
            tvWatches.putIfAbsent(item.tmdbId, () => []).add(item);
          }
        }

        for (final entry in tvWatches.entries) {
          final tmdbId = entry.key;
          final watches = entry.value;

          int maxSeason = 0;
          int maxEpisode = 0;
          for (var w in watches) {
            final s = w.seasonNumber ?? 0;
            final e = w.episodeNumber ?? 0;
            if (s > maxSeason) {
              maxSeason = s;
              maxEpisode = e;
            } else if (s == maxSeason && e > maxEpisode) {
              maxEpisode = e;
            }
          }

          try {
            final details = await repo.getMediaDetails(tmdbId, type: MediaType.values.firstWhere((t) => t.name == 'tv'));
            final mediaItem = details.item;
            
            final isReturning = mediaItem.status?.toLowerCase() == 'returning series';
            final isLastEpisode = mediaItem.lastSeasonNumber == maxSeason && mediaItem.lastEpisodeNumber == maxEpisode;

            if (isReturning && isLastEpisode) {
              final cacheDate = await repo.getCacheUpdateDate(tmdbId, MediaType.values.firstWhere((t) => t.name == 'tv'));
              if (cacheDate == null) continue;

              final age = DateTime.now().difference(cacheDate).inDays;
              bool shouldUpdate = false;

              if (age > 7) {
                if (mediaItem.lastEpisodeAirDate != null && mediaItem.lastEpisodeAirDate!.isNotEmpty) {
                  try {
                    final lastAir = DateTime.parse(mediaItem.lastEpisodeAirDate!);
                    if (lastAir.weekday == DateTime.now().weekday) {
                      shouldUpdate = true;
                    }
                  } catch (_) {}
                }
              } else if (age >= 1) {
                shouldUpdate = true;
              }

              if (shouldUpdate) {
                debugPrint("Daily sync refreshing returning series: $tmdbId");
                await repo.refreshReturningSeries(tmdbId);
              }
            }
          } catch (_) {}
        }
      } else if (task == refreshReturningSeriesTask || task.startsWith(refreshReturningSeriesPrefix)) {
        final int? id = inputData?['tmdbId'];
        if (id != null) {
          debugPrint("Running 1-off refresh for series ID: $id...");
          await repo.refreshReturningSeries(id);
        }
      }
      return Future.value(true);
    } catch (err, stack) {
      debugPrint("Background Task Failed: $err");
      debugPrint(stack.toString());
      return Future.value(false); // return false on failure
    }
  });
}

class BackgroundTaskService {
  static void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static void registerDailySync() {
    Workmanager().registerPeriodicTask(
      fetchTaskIdentifier,
      fetchTask,
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run on wifi/data
      ),
    );
  }

  static void dispatchOneOffRefresh(int tmdbId) {
    Workmanager().registerOneOffTask(
      "refresh_${tmdbId}_${DateTime.now().millisecondsSinceEpoch}", // Unique ID
      refreshReturningSeriesTask,
      inputData: {"tmdbId": tmdbId},
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
