import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/achievements/data/datasources/achievement_media_source.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/di/definitions_loader.dart';
import 'package:rxdart/rxdart.dart';

@LazySingleton(as: AchievementRepository)
class AchievementRepositoryImpl implements AchievementRepository {
  final Isar _isar;
  final MediaListLocalDataSource _localDataSource;
  final DefinitionsLoader? definitionsLoader;

  /// Cached TMDB data for the collection types; without it they stay at 0.
  final AchievementMediaSource? mediaSource;

  AchievementRepositoryImpl(
    this._isar,
    this._localDataSource, {
    this.definitionsLoader,
    this.mediaSource,
  });

  /// Types that depend on cached TMDB data or on the current watchlist rather
  /// than on the history alone: they can regress (new episode aired, cache
  /// purged), so once persisted their unlock is kept.
  static const _stickyTypes = {
    'season_complete',
    'series_complete',
    'up_to_date',
    'saga_complete',
    'watchlist_clear',
    ..._titleTypes,
  };

  /// Diversity types reading cached title metadata (countries, release date,
  /// votes, air dates). Votes drift and cache entries can be purged, so they
  /// are sticky too.
  static const _titleTypes = {
    'distinct_countries',
    'distinct_decades',
    'released_before',
    'tmdb_rating',
    'day_one',
  };

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
    final completions = defMaps.any((d) => _stickyTypes.contains(d['type']))
        ? await _buildCompletions(chronologicalItems)
        : null;
    final types = {for (final d in defMaps) d['type']};
    final titles = types.any(_titleTypes.contains)
        ? await _buildTitleData(
            chronologicalItems,
            withAirDates: types.contains('day_one'),
          )
        : null;

    return defMaps.map((def) {
      final id = def['id'] as String;
      final progressData = _calculateProgressFromDef(
        def,
        chronologicalItems,
        completions,
        titles,
      );
      final persistedUnlockDate = unlockedMap[id];
      final calculatedUnlockDate = progressData.milestoneReachedAt;
      final isUnlocked =
          calculatedUnlockDate != null ||
          (persistedUnlockDate != null && _stickyTypes.contains(def['type']));

      return Achievement(
        id: id,
        title: def['title'] as String,
        description: def['description'] as String,
        iconPath: def['iconPath'] as String,
        isUnlocked: isUnlocked,
        isPersisted: persistedUnlockDate != null,
        unlockedAt: persistedUnlockDate ?? calculatedUnlockDate,
        progress: isUnlocked ? 1.0 : progressData.progress,
        progressLabel: progressData.label,
        translations: _parseTranslations(def['translations']),
        group: def['group'] as String?,
        tier: def['tier'] as int?,
        groupTitle: def['groupTitle'] as String?,
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
      _isar.mediaListItems.watchLazy(), // watchlist_clear
    ]).asyncMap((_) => getAchievements());
  }

  /// Parses the optional `translations` block of a definition.
  static Map<String, Map<String, String>> _parseTranslations(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.value is Map)
          entry.key as String: {
            for (final field in (entry.value as Map).entries)
              if (field.value is String)
                field.key as String: field.value as String,
          },
    };
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
    _Completions? completions,
    _TitleData? titles,
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
          case 'early_bird':
            return _countMilestone(
              seenItems
                  .where((i) => i.seenDate.hour >= 5 && i.seenDate.hour < 9)
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
      case 'season_complete':
        return _datesMilestone(completions?.seasons ?? const [], target);
      case 'series_complete':
        return _datesMilestone(completions?.endedSeries ?? const [], target);
      case 'up_to_date':
        return _datesMilestone(completions?.runningSeries ?? const [], target);
      case 'saga_complete':
        return _datesMilestone(completions?.sagas ?? const [], target);
      case 'watchlist_clear':
        if (completions == null) break;
        return _watchlistMilestone(completions, target);
      case 'distinct_genres':
        return _distinctMilestone([
          for (final i in seenItems)
            (
              i.seenDate,
              [
                for (final name in i.genres ?? const <String>[])
                  ?GenreUtils.getGenreIdByName(name),
              ],
            ),
        ], target);
      case 'distinct_countries':
        return _distinctMilestone([
          for (final t in titles?.titles ?? const <_SeenTitle>[])
            (t.firstSeen, t.info.originCountries ?? const <String>[]),
        ], target);
      case 'distinct_decades':
        return _distinctMilestone([
          for (final t in titles?.titles ?? const <_SeenTitle>[])
            (t.firstSeen, [if (t.info.year case final y?) y ~/ 10]),
        ], target);
      case 'released_before':
        final year = params['year'] as int?;
        if (year == null) break;
        return _datesMilestone([
          for (final t in titles?.titles ?? const <_SeenTitle>[])
            if ((t.info.year ?? year) < year) t.firstSeen,
        ], target);
      case 'tmdb_rating':
        final minRating = (params['minRating'] as num?)?.toDouble();
        final minVotes = params['minVotes'] as int?;
        final maxVotes = params['maxVotes'] as int?;
        bool matches(TitleInfo i) {
          final rating = i.voteAverage;
          final votes = i.voteCount;
          if (rating == null || votes == null) return false;
          return (minRating == null || rating >= minRating) &&
              (minVotes == null || votes >= minVotes) &&
              (maxVotes == null || votes <= maxVotes);
        }
        return _datesMilestone([
          for (final t in titles?.titles ?? const <_SeenTitle>[])
            if (matches(t.info)) t.firstSeen,
        ], target);
      case 'day_one':
        final maxDelay = params['maxDelayDays'] as int? ?? 0;
        return _datesMilestone([
          for (final (release, seen)
              in titles?.releases ?? const <(String, DateTime)>[])
            if (_isWithinDays(release, seen, maxDelay)) seen,
        ], target);
      case 'double_feature':
        return _sameDayMilestone(
          seenItems.where((i) => i.type == 'movie').toList(),
          params['minMovies'] as int? ?? 2,
          target,
        );
      case 'every_weekday':
        return _everyWeekdayMilestone(seenItems, target);
      case 'monthly_streak':
        return _monthlyStreakMilestone(seenItems, target);
      case 'anniversary':
        return _anniversaryMilestone(seenItems, target, DateTime.now());
      case 'calendar_date':
        final dates = {
          for (final d in params['dates'] as List? ?? const []) '$d',
        };
        String monthDay(DateTime d) =>
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
        return _distinctMilestone([
          for (final i in seenItems)
            if (dates.contains(monthDay(i.seenDate)))
              (i.seenDate, [i.seenDate.year]),
        ], target);
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
    // Genre names are stored in the app language at the time they were seen
    // (TMDB localizes them), so compare by TMDB id.
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

  /// [target] calendar days with at least [minTitles] distinct titles among
  /// [items] (chronological); a day is dated by the view reaching
  /// [minTitles].
  _ProgressData _sameDayMilestone(
    List<SeenItemModel> items,
    int minTitles,
    int target,
  ) {
    final titlesByDay = <DateTime, Set<int>>{};
    final days = <DateTime>[];
    for (final i in items) {
      final d = i.seenDate;
      final titles = titlesByDay.putIfAbsent(
        DateTime(d.year, d.month, d.day),
        () => {},
      );
      if (titles.add(i.tmdbId) && titles.length == minTitles) days.add(d);
    }
    return _datesMilestone(days, target);
  }

  /// At least [target] views on each of the seven days of the week.
  _ProgressData _everyWeekdayMilestone(List<SeenItemModel> items, int target) {
    final counts = List.filled(7, 0);
    DateTime? reachedAt;
    for (final i in items) {
      counts[i.seenDate.weekday - 1]++;
      if (reachedAt == null && counts.every((c) => c >= target)) {
        reachedAt = i.seenDate;
      }
    }
    final min = counts.reduce((a, b) => a < b ? a : b);
    return _ProgressData(
      (min / target).clamp(0.0, 1.0),
      '$min/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  /// [target] consecutive calendar months with at least one view, reached at
  /// the first view of the [target]-th month of the run.
  _ProgressData _monthlyStreakMilestone(List<SeenItemModel> items, int target) {
    // First view of each month, keyed by a month index (items are
    // chronological, so keys are inserted in increasing order).
    final months = <int, DateTime>{};
    for (final i in items) {
      months.putIfAbsent(
        i.seenDate.year * 12 + i.seenDate.month - 1,
        () => i.seenDate,
      );
    }
    var run = 0;
    var maxRun = 0;
    int? previous;
    DateTime? reachedAt;
    for (final MapEntry(key: month, value: date) in months.entries) {
      run = previous != null && month == previous + 1 ? run + 1 : 1;
      previous = month;
      if (run > maxRun) maxRun = run;
      if (reachedAt == null && run >= target) reachedAt = date;
    }
    return _ProgressData(
      (maxRun / target).clamp(0.0, 1.0),
      '$maxRun/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  /// [targetYears] years since the first view in the history (imported views
  /// included), dated at that anniversary.
  static _ProgressData _anniversaryMilestone(
    List<SeenItemModel> items,
    int targetYears,
    DateTime now,
  ) {
    if (items.isEmpty) return _ProgressData(0.0, '0/$targetYears');
    final first = items.first.seenDate;
    final anniversary = DateTime(
      first.year + targetYears,
      first.month,
      first.day,
      first.hour,
      first.minute,
    );
    var years = now.year - first.year;
    if (DateTime(
      now.year,
      first.month,
      first.day,
      first.hour,
      first.minute,
    ).isAfter(now)) {
      years--;
    }
    final reached = !anniversary.isAfter(now);
    final total = anniversary.difference(first).inMinutes;
    final elapsed = now.difference(first).inMinutes;
    return _ProgressData(
      total <= 0 ? 0.0 : (elapsed / total).clamp(0.0, 1.0),
      '${years.clamp(0, targetYears)}/$targetYears',
      milestoneReachedAt: reached ? anniversary : null,
    );
  }

  /// Completion dates of seasons, series and sagas, computed once per
  /// evaluation from the history and the cached TMDB data.
  Future<_Completions> _buildCompletions(List<SeenItemModel> items) async {
    // First view of each episode / movie (items are chronological).
    final episodes = <int, Map<(int, int), DateTime>>{};
    final movies = <int, DateTime>{};
    for (final i in items) {
      if (i.type == 'movie') {
        movies.putIfAbsent(i.tmdbId, () => i.seenDate);
      } else if (i.type == 'tv' &&
          i.seasonNumber != null &&
          i.episodeNumber != null) {
        episodes.putIfAbsent(i.tmdbId, () => {}).putIfAbsent((
          i.seasonNumber!,
          i.episodeNumber!,
        ), () => i.seenDate);
      }
    }
    final seenTitles = {for (final i in items) '${i.type}:${i.tmdbId}'};

    List<MediaListItem> watchlist;
    try {
      watchlist = await _localDataSource.getListItems('watchlist');
    } catch (e) {
      debugPrint('Achievements: watchlist unavailable: $e');
      watchlist = const [];
    }

    final source = mediaSource;
    final shows = source == null
        ? const <int, ShowInfo>{}
        : await source.shows({
            ...episodes.keys,
            for (final w in watchlist)
              if (w.type == 'tv') w.id,
          });
    final sagaParts = source == null
        ? const <int, List<SagaPart>>{}
        : await source.sagas(movies.keys.toSet());

    final seasons = <DateTime>[];
    final ended = <DateTime>[];
    final running = <DateTime>[];
    final caughtUp = <int>{};
    for (final MapEntry(key: id, value: info) in shows.entries) {
      final seen = episodes[id] ?? const {};
      final aired = info.airedEpisodeCounts;
      DateTime? showDate;
      var complete = aired.isNotEmpty;
      for (final MapEntry(key: season, value: count) in aired.entries) {
        final date = _allSeenAt([
          for (var e = 1; e <= count; e++) seen[(season, e)],
        ]);
        if (date == null) {
          complete = false;
          continue;
        }
        if (count == info.episodeCounts[season]) seasons.add(date);
        if (showDate == null || date.isAfter(showDate)) showDate = date;
      }
      if (!complete || showDate == null) continue;
      caughtUp.add(id);
      (info.isFinished ? ended : running).add(showDate);
    }

    final today = DateTime.now();
    final sagas = <String, DateTime>{};
    for (final parts in sagaParts.values) {
      final released = [
        for (final p in parts)
          if (DateTime.tryParse(p.releaseDate)?.isAfter(today) == false) p.id,
      ]..sort();
      if (released.length < 2) continue; // a single film is not a saga
      final date = _allSeenAt([for (final id in released) movies[id]]);
      if (date != null) sagas[released.join(',')] = date;
    }

    final watchlistDone = watchlist.where((w) {
      if (w.type == 'movie') return movies.containsKey(w.id);
      return caughtUp.contains(w.id);
    }).length;

    return _Completions(
      seasons: seasons,
      endedSeries: ended,
      runningSeries: running,
      sagas: sagas.values.toList(),
      seenTitles: seenTitles.length,
      watchlistSize: watchlist.length,
      watchlistDone: watchlistDone,
    );
  }

  /// Seen titles with their cached metadata and, when [withAirDates], the
  /// release / air date of each movie and episode seen.
  Future<_TitleData> _buildTitleData(
    List<SeenItemModel> items, {
    required bool withAirDates,
  }) async {
    final source = mediaSource;
    if (source == null) return const _TitleData([], []);

    // First view of each title and episode (items are chronological).
    final firstSeen = <(int, String), DateTime>{};
    final episodes = <(int, int, int), DateTime>{};
    for (final i in items) {
      firstSeen.putIfAbsent((i.tmdbId, i.type), () => i.seenDate);
      if (i.type == 'tv' && i.seasonNumber != null && i.episodeNumber != null) {
        episodes.putIfAbsent((
          i.tmdbId,
          i.seasonNumber!,
          i.episodeNumber!,
        ), () => i.seenDate);
      }
    }

    final infos = await source.titles(firstSeen.keys.toSet());
    final titles = [
      for (final MapEntry(key: key, value: date) in firstSeen.entries)
        if (infos[key] case final info?) _SeenTitle(date, info),
    ];
    if (!withAirDates) return _TitleData(titles, const []);

    final releases = <(String, DateTime)>[
      for (final MapEntry(key: (id, type), value: date) in firstSeen.entries)
        if (type == 'movie' && infos[(id, type)] != null)
          (infos[(id, type)]!.releaseDate, date),
    ];
    final airDates = <(int, int), Map<int, String>?>{};
    for (final MapEntry(key: (show, season, episode), value: date)
        in episodes.entries) {
      final key = (show, season);
      final dates = airDates.containsKey(key)
          ? airDates[key]
          : airDates[key] = await source.episodeAirDates(show, season);
      final airDate = dates?[episode];
      if (airDate != null) releases.add((airDate, date));
    }
    return _TitleData(titles, releases);
  }

  /// [seen] falls on the calendar day of [releaseDate] (`yyyy-mm-dd`) or at
  /// most [maxDays] days later. Calendar days are compared in UTC so a DST
  /// change does not shift the difference.
  static bool _isWithinDays(String releaseDate, DateTime seen, int maxDays) {
    final release = DateTime.tryParse(releaseDate);
    if (release == null) return false;
    final delay = DateTime.utc(
      seen.year,
      seen.month,
      seen.day,
    ).difference(DateTime.utc(release.year, release.month, release.day)).inDays;
    return delay >= 0 && delay <= maxDays;
  }

  /// [target] distinct values, reached when the [target]-th new value appears.
  /// [entries] are (date, values) pairs in chronological order.
  static _ProgressData _distinctMilestone(
    List<(DateTime, Iterable<Object>)> entries,
    int target,
  ) {
    final seen = <Object>{};
    DateTime? reachedAt;
    for (final (date, values) in entries) {
      seen.addAll(values);
      if (reachedAt == null && seen.length >= target) reachedAt = date;
    }
    return _ProgressData(
      (seen.length / target).clamp(0.0, 1.0),
      '${seen.length}/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  /// Latest of [dates], or null if one is missing.
  static DateTime? _allSeenAt(List<DateTime?> dates) {
    DateTime? latest;
    for (final d in dates) {
      if (d == null) return null;
      if (latest == null || d.isAfter(latest)) latest = d;
    }
    return latest;
  }

  /// [target] completions, reached at the [target]-th completion date.
  _ProgressData _datesMilestone(List<DateTime> dates, int target) {
    final sorted = [...dates]..sort();
    final count = sorted.length;
    return _ProgressData(
      (count / target).clamp(0.0, 1.0),
      '$count/$target',
      milestoneReachedAt: count >= target ? sorted[target - 1] : null,
    );
  }

  /// Every watchlist title seen (series: caught up), with at least [target]
  /// titles in the history so an unused watchlist does not count. The state
  /// has no history: it is dated when observed.
  _ProgressData _watchlistMilestone(_Completions c, int target) {
    final seen = c.seenTitles < target ? c.seenTitles : target;
    final done = seen >= target && c.watchlistDone == c.watchlistSize;
    return _ProgressData(
      (seen + c.watchlistDone) / (target + c.watchlistSize),
      c.watchlistSize == 0
          ? '$seen/$target'
          : '${c.watchlistDone}/${c.watchlistSize}',
      milestoneReachedAt: done ? DateTime.now() : null,
    );
  }
}

class _Completions {
  final List<DateTime> seasons;
  final List<DateTime> endedSeries;
  final List<DateTime> runningSeries;
  final List<DateTime> sagas;
  final int seenTitles;
  final int watchlistSize;
  final int watchlistDone;

  const _Completions({
    required this.seasons,
    required this.endedSeries,
    required this.runningSeries,
    required this.sagas,
    required this.seenTitles,
    required this.watchlistSize,
    required this.watchlistDone,
  });
}

class _SeenTitle {
  final DateTime firstSeen;
  final TitleInfo info;
  const _SeenTitle(this.firstSeen, this.info);
}

class _TitleData {
  /// Seen titles with cached metadata, by first view.
  final List<_SeenTitle> titles;

  /// (release or air date, first view) of each movie and episode seen.
  final List<(String, DateTime)> releases;

  const _TitleData(this.titles, this.releases);
}

class _ProgressData {
  final double progress;
  final String label;
  final DateTime? milestoneReachedAt;
  const _ProgressData(this.progress, this.label, {this.milestoneReachedAt});
}
