import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/core/di/definitions_loader.dart';
import 'package:rxdart/rxdart.dart';

@LazySingleton(as: AchievementRepository)
class AchievementRepositoryImpl implements AchievementRepository {
  final Isar _isar;
  final MediaListLocalDataSource _localDataSource;
  final DefinitionsLoader? definitionsLoader;

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
        group: def['group'] as String?,
        tier: def['tier'] as int?,
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
        return await definitionsLoader!.load();
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
    final type = def['type'] as String? ?? '';
    final params = (def['params'] as Map?)?.cast<String, dynamic>() ?? {};
    final target = (params['target'] ?? params['targetMinutes']) as int? ?? 0;
    if (target <= 0) {
      debugPrint('Achievement ${def['id']}: missing or invalid target');
      return const _ProgressData(0.0, '0/0');
    }

    switch (type) {
      case 'count':
        final mediaType = params['mediaType'] as String? ?? 'movie';
        return _countMilestone(
          seenItems.where((i) => i.type == mediaType).toList(),
          target,
        );
      case 'genre':
        final genreId =
            params['genreId'] as int? ??
            GenreUtils.getGenreIdByName(params['genre'] as String? ?? '');
        if (genreId == null) break;
        final movies = seenItems.where((i) => i.type == 'movie').toList();
        return _genreMilestone(movies, genreId, target);
      case 'rewatch':
        final isTv = params['isTv'] == true;
        return _rewatchMilestone(
          seenItems.where((i) => i.type == (isTv ? 'tv' : 'movie')).toList(),
          target,
          isTv: isTv,
        );
      case 'loyalist':
        return _loyalistMilestone(
          seenItems.where((i) => i.type == 'tv').toList(),
          target,
        );
      case 'behavioral':
        switch (params['subtype']) {
          case 'night_owl':
            return _countMilestone(
              seenItems
                  .where((i) => i.seenDate.hour < 4 && !_isDateOnly(i.seenDate))
                  .toList(),
              target,
            );
          case 'weekend':
            // Sliding 72-hour window
            return _windowMilestone(
              seenItems,
              const Duration(hours: 72),
              target,
            );
        }
      case 'streak':
        return _streakMilestone(seenItems, target);
      case 'runtime':
        return _runtimeMilestone(seenItems, target);
      case 'marathon':
        return _marathonMilestone(
          seenItems.where((i) => i.type == 'tv').toList(),
          target,
        );
    }

    debugPrint('Achievement ${def['id']}: cannot evaluate type "$type"');
    return _ProgressData(0.0, '0/$target');
  }

  /// Views recorded without a time (e.g. imported history) land at exactly
  /// 00:00:00.000; they must not count as night-time views.
  bool _isDateOnly(DateTime d) =>
      d.hour == 0 &&
      d.minute == 0 &&
      d.second == 0 &&
      d.millisecond == 0 &&
      d.microsecond == 0;

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
    int genreId,
    int target,
  ) {
    final filtered = items
        .where(
          (i) =>
              i.genres?.any(
                (name) => GenreUtils.getGenreIdByName(name) == genreId,
              ) ??
              false,
        )
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
      '${Formatters.formatWatchTime(total)} / '
      '${Formatters.formatWatchTime(targetMinutes)}',
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

  _ProgressData _windowMilestone(
    List<SeenItemModel> items,
    Duration window,
    int target,
  ) {
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
      final dateKey =
          '${item.tmdbId}_${item.seenDate.year}-${item.seenDate.month}-${item.seenDate.day}';
      counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      if (counts[dateKey]! >= target && reachedAt == null) {
        reachedAt = item.seenDate;
      }
    }

    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);

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
