import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:rxdart/rxdart.dart';

@LazySingleton(as: AchievementRepository)
class AchievementRepositoryImpl implements AchievementRepository {
  final Isar _isar;
  final MediaListLocalDataSource _localDataSource;
  final Future<List<Map<String, dynamic>>> Function()? definitionsLoader;

  AchievementRepositoryImpl(
    this._isar,
    this._localDataSource, {
    this.definitionsLoader,
  });

  // Definitions moved to `assets/achievements/definitions.json`.
  // The file is the single source of truth; tests should inject a loader.

  @override
  Future<List<Achievement>> getAchievements() async {
    final seenItems = await _localDataSource.getAllSeenItems();
    final chronologicalItems = List<SeenItemModel>.from(seenItems)
      ..sort((a, b) => a.seenDate.compareTo(b.seenDate));

    final unlockedModels = await _isar.achievementModels.where().findAll();
    final unlockedMap = {
      for (var m in unlockedModels) m.achievementId: m.unlockedAt,
    };

    final defMaps = await _loadDefinitionMaps();

    return defMaps.map((def) {
      final id = def['id'] as String;
      final progressData = _calculateProgressFromDef(def, chronologicalItems);
      final persistedUnlockDate = unlockedMap[id];
      final calculatedUnlockDate = progressData.milestoneReachedAt;

      return Achievement(
        id: id,
        title: def['title'] as String,
        description: def['description'] as String,
        iconPath: def['iconPath'] as String,
        isUnlocked: calculatedUnlockDate != null,
        isPersisted: persistedUnlockDate != null,
        unlockedAt: persistedUnlockDate ?? calculatedUnlockDate,
        progress: progressData.progress,
        progressLabel: progressData.label,
      );
    }).toList();
  }

  @override
  Future<void> unlockAchievement(
    String achievementId,
    DateTime unlockedAt,
  ) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.achievementModels
          .filter()
          .achievementIdEqualTo(achievementId)
          .findFirst();

      if (existing == null) {
        await _isar.achievementModels.put(
          AchievementModel(
            achievementId: achievementId,
            unlockedAt: unlockedAt,
          ),
        );
      }
    });
  }

  @override
  Future<void> clearAchievements() async {
    await _isar.writeTxn(() async {
      await _isar.achievementModels.where().deleteAll();
    });
  }

  @override
  Stream<List<Achievement>> watchAchievements() {
    return Rx.merge([
      _isar.achievementModels.watchLazy(),
      _isar.seenItemModels.watchLazy(),
    ]).asyncMap((_) => getAchievements());
  }

  static const _definitionsAssetPath = 'assets/achievements/definitions.json';

  Future<List<Map<String, dynamic>>> _loadDefinitionMaps() async {
    // If a loader was injected (tests or alternative runtime), use it first.
    if (definitionsLoader != null) {
      try {
        return await definitionsLoader!();
      } catch (_) {
        // fall through to asset loader
      }
    }

    final jsonStr = await rootBundle.loadString(_definitionsAssetPath);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  _ProgressData _calculateProgressFromDef(
    Map<String, dynamic> def,
    List<SeenItemModel> seenItems,
  ) {
    if (def.containsKey('type')) {
      final type = def['type'] as String;
      final params = (def['params'] as Map?)?.cast<String, dynamic>() ?? {};

      switch (type) {
        case 'count':
          final mediaType = params['mediaType'] as String? ?? 'movie';
          final target =
              params['target'] as int? ??
              int.tryParse((def['id'] as String).split('_').last) ??
              0;
          final items = mediaType == 'tv'
              ? seenItems.where((i) => i.type == 'tv').toList()
              : seenItems.where((i) => i.type == 'movie').toList();
          return _countMilestone(items, target);
        case 'genre':
          final genre = params['genre'] as String? ?? '';
          final targetG = params['target'] as int? ?? 0;
          final movies = seenItems.where((i) => i.type == 'movie').toList();
          return _genreMilestone(movies, genre, targetG);
        case 'rewatch':
          final isTv = params['isTv'] == true;
          final targetR = params['target'] as int? ?? 0;
          final itemsR = isTv
              ? seenItems.where((i) => i.type == 'tv').toList()
              : seenItems.where((i) => i.type == 'movie').toList();
          return _rewatchMilestone(itemsR, targetR, isTv: isTv);
        case 'loyalist':
          final targetL = params['target'] as int? ?? 0;
          final episodes = seenItems.where((i) => i.type == 'tv').toList();
          return _loyalistMilestone(episodes, targetL);
        case 'behavioral':
          final subtype = params['subtype'] as String? ?? '';
            if (subtype == 'night_owl') {
              final nightItems = seenItems
                  .where((i) => i.seenDate.hour >= 0 && i.seenDate.hour < 4)
                  .toList();
              final targetB = params['target'] as int? ?? 0;
              return _countMilestone(nightItems, targetB);
            }
            if (subtype == 'weekend') {
              final targetB = params['target'] as int? ?? 0;
              // Sliding 72-hour window
              return _windowMilestone(seenItems, const Duration(hours: 72), targetB);
            }
          break;
        case 'streak':
          final targetS = params['target'] as int? ?? 0;
          return _streakMilestone(seenItems, targetS);
        case 'runtime':
          final targetMin = params['targetMinutes'] as int? ?? 0;
          return _runtimeMilestone(seenItems, targetMin);
        case 'marathon':
            final targetM = params['target'] as int? ?? 0;
            return _marathonMilestone(seenItems.where((i) => i.type == 'tv').toList(), targetM);
      }
    }

    // Fallback to legacy id-based implementation
    return _calculateProgress(def['id'] as String, seenItems);
  }

  _ProgressData _calculateProgress(String id, List<SeenItemModel> seenItems) {
    final movies = seenItems.where((i) => i.type == 'movie').toList();
    final episodes = seenItems.where((i) => i.type == 'tv').toList();

    switch (id) {
      // --- Movies ---
      case 'movie_1':
        return _countMilestone(movies, 1);
      case 'movie_10':
        return _countMilestone(movies, 10);
      case 'movie_50':
        return _countMilestone(movies, 50);
      case 'movie_100':
        return _countMilestone(movies, 100);
      case 'movie_500':
        return _countMilestone(movies, 500);
      case 'movie_1000':
        return _countMilestone(movies, 1000);

      // --- TV ---
      case 'tv_1':
        return _countMilestone(episodes, 1);
      case 'tv_50':
        return _countMilestone(episodes, 50);
      case 'tv_250':
        return _countMilestone(episodes, 250);
      case 'tv_1000':
        return _countMilestone(episodes, 1000);
      case 'tv_5000':
        return _countMilestone(episodes, 5000);

      // --- Rewatches ---
      case 'rewatch_movie_2':
        return _rewatchMilestone(movies, 2);
      case 'rewatch_movie_5':
        return _rewatchMilestone(movies, 5);
      case 'rewatch_movie_10':
        return _rewatchMilestone(movies, 10);
      case 'rewatch_ep_2':
        return _rewatchMilestone(episodes, 2, isTv: true);
      case 'rewatch_ep_5':
        return _rewatchMilestone(episodes, 5, isTv: true);

      // --- Loyalists ---
      case 'loyalist_100':
        return _loyalistMilestone(episodes, 100);
      case 'loyalist_500':
        return _loyalistMilestone(episodes, 500);

      // --- Genres ---
      case 'genre_horror':
        return _genreMilestone(movies, 'Horror', 10);
      case 'genre_horror_50':
        return _genreMilestone(movies, 'Horror', 50);
      case 'genre_comedy':
        return _genreMilestone(movies, 'Comedy', 20);
      case 'genre_comedy_100':
        return _genreMilestone(movies, 'Comedy', 100);
      case 'genre_action':
        return _genreMilestone(movies, 'Action', 20);
      case 'genre_action_100':
        return _genreMilestone(movies, 'Action', 100);
      case 'genre_scifi':
        return _genreMilestone(movies, 'Science Fiction', 20);
      case 'genre_scifi_100':
        return _genreMilestone(movies, 'Science Fiction', 100);
      case 'genre_doc':
        return _genreMilestone(movies, 'Documentary', 10);
      case 'genre_doc_50':
        return _genreMilestone(movies, 'Documentary', 50);
      case 'genre_romance':
        return _genreMilestone(movies, 'Romance', 15);

      // --- Behavioral ---
      case 'night_owl':
        final nightItems = seenItems
            .where((i) => i.seenDate.hour >= 0 && i.seenDate.hour < 4)
            .toList();
        return _countMilestone(nightItems, 10);
      case 'night_owl_100':
        final nightItems = seenItems
            .where((i) => i.seenDate.hour >= 0 && i.seenDate.hour < 4)
            .toList();
        return _countMilestone(nightItems, 100);
      case 'streak_7':
        return _streakMilestone(seenItems, 7);
      case 'streak_30':
        return _streakMilestone(seenItems, 30);
      case 'streak_365':
        return _streakMilestone(seenItems, 365);

      // --- Runtime ---
      case 'runtime_1000':
        return _runtimeMilestone(seenItems, 1000);
      case 'runtime_hour_100':
        return _runtimeMilestone(seenItems, 100 * 60);
      case 'runtime_10000':
        return _runtimeMilestone(seenItems, 10000);
      case 'runtime_day_10':
        return _runtimeMilestone(seenItems, 10 * 24 * 60);
      case 'runtime_hour_1000':
        return _runtimeMilestone(seenItems, 1000 * 60);
      case 'runtime_100000':
        return _runtimeMilestone(seenItems, 100000);
      case 'runtime_year_1':
        return _runtimeMilestone(seenItems, 365 * 24 * 60);

      default:
        return const _ProgressData(0.0, '0/0');
    }
  }

  _ProgressData _countMilestone(List<SeenItemModel> items, int target) {
    final count = items.length;
    return _ProgressData(
      (count / target).clamp(0.0, 1.0),
      '$count/$target',
      milestoneReachedAt: count >= target ? items[target - 1].seenDate : null,
    );
  }

  _ProgressData _genreMilestone(
    List<SeenItemModel> items,
    String genre,
    int target,
  ) {
    final filtered = items
        .where((i) => i.genres?.contains(genre) ?? false)
        .toList();
    final count = filtered.length;
    return _ProgressData(
      (count / target).clamp(0.0, 1.0),
      '$count/$target',
      milestoneReachedAt: count >= target
          ? filtered[target - 1].seenDate
          : null,
    );
  }

  _ProgressData _runtimeMilestone(
    List<SeenItemModel> items,
    int targetMinutes,
  ) {
    int total = 0;
    DateTime? reachedAt;
    for (final item in items) {
      total += item.runtime ?? 0;
      if (total >= targetMinutes && reachedAt == null) {
        reachedAt = item.seenDate;
      }
    }
    return _ProgressData(
      (total / targetMinutes).clamp(0.0, 1.0),
      '$total/$targetMinutes min',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _rewatchMilestone(
    List<SeenItemModel> items,
    int target, {
    bool isTv = false,
  }) {
    final counts = <String, int>{};
    int maxCount = 0;
    DateTime? reachedAt;

    for (final item in items) {
      final key = isTv
          ? '${item.tmdbId}_${item.seasonNumber}_${item.episodeNumber}'
          : '${item.tmdbId}';
      counts[key] = (counts[key] ?? 0) + 1;
      if (counts[key]! >= target && reachedAt == null) {
        reachedAt = item.seenDate;
      }
      if (counts[key]! > maxCount) maxCount = counts[key]!;
    }

    return _ProgressData(
      (maxCount / target).clamp(0.0, 1.0),
      '$maxCount/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _loyalistMilestone(List<SeenItemModel> episodes, int target) {
    final counts = <int, int>{};
    int maxCount = 0;
    DateTime? reachedAt;

    for (final item in episodes) {
      counts[item.tmdbId] = (counts[item.tmdbId] ?? 0) + 1;
      if (counts[item.tmdbId]! >= target && reachedAt == null) {
        reachedAt = item.seenDate;
      }
      if (counts[item.tmdbId]! > maxCount) maxCount = counts[item.tmdbId]!;
    }

    return _ProgressData(
      (maxCount / target).clamp(0.0, 1.0),
      '$maxCount/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _streakMilestone(List<SeenItemModel> items, int target) {
    if (items.isEmpty) return const _ProgressData(0.0, '0/0');

    final dates =
        items
            .map(
              (i) =>
                  DateTime(i.seenDate.year, i.seenDate.month, i.seenDate.day),
            )
            .toSet()
            .toList()
          ..sort();

    int currentStreak = 1;
    int maxStreak = 1;
    DateTime? reachedAt;

    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        currentStreak++;
        if (currentStreak >= target && reachedAt == null) {
          reachedAt = dates[i];
        }
      } else {
        currentStreak = 1;
      }
      if (currentStreak > maxStreak) maxStreak = currentStreak;
    }

    return _ProgressData(
      (maxStreak / target).clamp(0.0, 1.0),
      '$maxStreak/$target days',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _windowMilestone(List<SeenItemModel> items, Duration window, int target) {
    if (items.isEmpty) return const _ProgressData(0.0, '0/0');
    final dates = items.map((i) => i.seenDate).toList()..sort();

    int maxCount = 0;
    DateTime? reachedAt;

    int start = 0;
    for (int end = 0; end < dates.length; end++) {
      while (dates[end].difference(dates[start]) > window) {
        start++;
      }
      final count = end - start + 1;
      if (count >= target && reachedAt == null) {
        reachedAt = dates[end];
      }
      if (count > maxCount) maxCount = count;
    }

    return _ProgressData(
      (maxCount / target).clamp(0.0, 1.0),
      '$maxCount/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _marathonMilestone(List<SeenItemModel> episodes, int target) {
    final counts = <String, int>{};
    DateTime? reachedAt;

    for (final item in episodes) {
      final dateKey = '${item.tmdbId}_${item.seenDate.year}-${item.seenDate.month}-${item.seenDate.day}';
      counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      if (counts[dateKey]! >= target && reachedAt == null) {
        reachedAt = item.seenDate;
      }
    }

    final maxCount = counts.values.isEmpty ? 0 : counts.values.reduce((a, b) => a > b ? a : b);

    return _ProgressData(
      (maxCount / target).clamp(0.0, 1.0),
      '$maxCount/$target',
      milestoneReachedAt: reachedAt,
    );
  }
}

class _ProgressData {
  final double progress;
  final String label;
  final DateTime? milestoneReachedAt;
  const _ProgressData(this.progress, this.label, {this.milestoneReachedAt});
}
