import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/di/definitions_loader.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/achievements/data/datasources/achievement_media_source.dart';
import 'package:mediavore/features/achievements/data/datasources/export_log.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/data/repositories/achievement_repository_impl.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

class _Loader implements DefinitionsLoader {
  final List<Map<String, dynamic>> defs;
  _Loader(this.defs);
  @override
  Future<List<Map<String, dynamic>>> load() async => defs;
}

class _FakeMediaSource implements AchievementMediaSource {
  final Map<(int, String), TitleInfo> titleData;
  _FakeMediaSource([this.titleData = const {}]);

  @override
  Future<Map<int, ShowInfo>> shows(Set<int> tvIds) async => const {};

  @override
  Future<Map<int, List<SagaPart>>> sagas(Set<int> movieIds) async => const {};

  @override
  Future<Map<(int, String), TitleInfo>> titles(Set<(int, String)> keys) async =>
      {
        for (final k in keys)
          if (titleData[k] != null) k: titleData[k]!,
      };

  @override
  Future<Map<int, String>?> episodeAirDates(int tvId, int season) async => null;
}

class _FakeExportLog implements ExportLog {
  final List<DateTime> logged;
  _FakeExportLog([List<DateTime>? logged]) : logged = logged ?? [];

  @override
  Future<List<DateTime>> dates() async => [...logged];

  @override
  Future<void> record(DateTime at) async => logged.add(at);
}

Map<String, dynamic> _def(String type, int target, {String? id}) => {
  'id': id ?? '${type}_$target',
  'title': 'T',
  'description': 'D',
  'iconPath': 'I',
  'type': type,
  'params': {'target': target},
};

SeenItemModel _seen(int id, String type, DateTime date) => SeenItemModel(
  tmdbId: id,
  type: type,
  title: '$type$id',
  seenDate: date,
  seasonNumber: type == 'tv' ? 1 : null,
  episodeNumber: type == 'tv' ? id : null,
);

MediaListItem _listed(int id, String type, String list) =>
    MediaListItem(id: id, type: type, title: '$type$id', listName: list);

void main() {
  late Isar isar;
  late MockMediaListLocalDataSource local;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_app_usage_achievements';
    Directory(tempPath).createSync(recursive: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [AchievementModelSchema, SeenItemModelSchema],
      directory: tempPath,
      name: 'test_app_usage_achievements_db',
    );
    local = MockMediaListLocalDataSource();
    when(() => local.getAllSeenItems()).thenAnswer((_) async => []);
    when(() => local.getListItems(any())).thenAnswer((_) async => []);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  AchievementRepositoryImpl repo(
    List<Map<String, dynamic>> defs, {
    List<SeenItemModel> seen = const [],
    AchievementMediaSource? source,
    ExportLog? exportLog,
  }) {
    when(() => local.getAllSeenItems()).thenAnswer((_) async => seen);
    return AchievementRepositoryImpl(
      isar,
      local,
      definitionsLoader: _Loader(defs),
      mediaSource: source ?? _FakeMediaSource(),
      exportLog: exportLog,
    );
  }

  Future<Map<String, Achievement>> evaluate(
    AchievementRepositoryImpl r,
  ) async => {for (final a in await r.getAchievements()) a.id: a};

  group('backup_export', () {
    test('should count logged export days, dated by the target-th', () async {
      final days = [
        DateTime(2024, 1, 1, 10),
        DateTime(2024, 2, 1, 10),
        DateTime(2024, 3, 1, 10),
      ];
      final a = await evaluate(
        repo([
          _def('backup_export', 1),
          _def('backup_export', 3),
          _def('backup_export', 5),
        ], exportLog: _FakeExportLog(days)),
      );
      expect(a['backup_export_1']!.unlockedAt, days[0]);
      expect(a['backup_export_3']!.unlockedAt, days[2]);
      expect(a['backup_export_5']!.isUnlocked, isFalse);
      expect(a['backup_export_5']!.progressLabel, '3/5');
    });

    test('should stay at 0 without an export log', () async {
      final a = await evaluate(repo([_def('backup_export', 1)]));
      expect(a['backup_export_1']!.isUnlocked, isFalse);
      expect(a['backup_export_1']!.progressLabel, '0/1');
    });

    test('recordExport should write to the log', () async {
      final log = _FakeExportLog();
      final r = repo([_def('backup_export', 1)], exportLog: log);
      final at = DateTime(2024, 5, 4, 12);
      await r.recordExport(at);
      expect(log.logged, [at]);
      expect((await evaluate(r))['backup_export_1']!.unlockedAt, at);
    });
  });

  group('PrefsExportLog', () {
    test('should keep one date per calendar day, sorted', () async {
      SharedPreferences.setMockInitialValues({});
      final log = PrefsExportLog(await SharedPreferences.getInstance());
      await log.record(DateTime(2024, 3, 2, 9));
      await log.record(DateTime(2024, 3, 2, 23)); // same day: ignored
      await log.record(DateTime(2024, 3, 1, 8));
      expect(await log.dates(), [
        DateTime(2024, 3, 1, 8),
        DateTime(2024, 3, 2, 9),
      ]);
    });

    test('should skip unparsable entries', () async {
      SharedPreferences.setMockInitialValues({
        PrefsExportLog.key: ['garbage', '2024-01-01T10:00:00.000'],
      });
      final log = PrefsExportLog(await SharedPreferences.getInstance());
      expect(await log.dates(), [DateTime(2024, 1, 1, 10)]);
    });
  });

  group('list_items', () {
    setUp(() {
      when(
        () => local.getAllListNames(),
      ).thenAnswer((_) async => ['watchlist', 'favorites']);
    });

    test('should count distinct titles over every list', () async {
      when(() => local.getListItems('watchlist')).thenAnswer(
        (_) async => [_listed(1, 'movie', 'watchlist'), _listed(1, 'tv', 'w')],
      );
      when(() => local.getListItems('favorites')).thenAnswer(
        (_) async => [
          _listed(1, 'movie', 'favorites'), // already in the watchlist
          _listed(2, 'movie', 'favorites'),
        ],
      );
      final before = DateTime.now();
      final a = await evaluate(
        repo([_def('list_items', 3), _def('list_items', 4)]),
      );
      expect(a['list_items_3']!.isUnlocked, isTrue);
      expect(a['list_items_3']!.unlockedAt!.isBefore(before), isFalse);
      expect(a['list_items_4']!.isUnlocked, isFalse);
      expect(a['list_items_4']!.progressLabel, '3/4');
    });

    test(
      'should stay unlocked once persisted after the lists shrink',
      () async {
        final r = repo([_def('list_items', 1)]);
        await r.unlockAchievement('list_items_1', DateTime(2024));
        final a = await evaluate(r);
        expect(a['list_items_1']!.isUnlocked, isTrue);
        expect(a['list_items_1']!.unlockedAt, DateTime(2024));
      },
    );

    test('should stay at 0 when the lists cannot be read', () async {
      when(() => local.getAllListNames()).thenThrow(Exception('db'));
      final a = await evaluate(repo([_def('list_items', 1)]));
      expect(a['list_items_1']!.isUnlocked, isFalse);
    });
  });

  group('distinct_languages', () {
    TitleInfo info(String? language) => TitleInfo(originalLanguage: language);

    test('should count original languages, xx and unknown excluded', () async {
      final d1 = DateTime(2024, 1, 1, 20);
      final d2 = DateTime(2024, 1, 2, 20);
      final d3 = DateTime(2024, 1, 3, 20);
      final d4 = DateTime(2024, 1, 4, 20);
      final a = await evaluate(
        repo(
          [_def('distinct_languages', 3), _def('distinct_languages', 4)],
          seen: [
            _seen(1, 'movie', d1),
            _seen(2, 'movie', d2), // en again
            _seen(3, 'tv', d2),
            _seen(4, 'movie', d3), // no linguistic content
            _seen(5, 'movie', d3), // unknown
            _seen(6, 'tv', d4),
            _seen(3, 'tv', d4), // later episode: same title
          ],
          source: _FakeMediaSource({
            (1, 'movie'): info('en'),
            (2, 'movie'): info('en'),
            (3, 'tv'): info('ja'),
            (4, 'movie'): info('xx'),
            (5, 'movie'): info(null),
            (6, 'tv'): info('ko'),
          }),
        ),
      );
      expect(a['distinct_languages_3']!.unlockedAt, d4);
      expect(a['distinct_languages_4']!.progressLabel, '3/4');
    });
  });

  group('MediaItem.originalLanguage', () {
    test('should be parsed, serialized and kept by copyWith', () {
      final item = MediaItem.fromJson({
        'id': 1,
        'title': 'T',
        'overview': '',
        'release_date': '2000-01-01',
        'media_type': 'movie',
        'original_language': 'fr',
      });
      expect(item.originalLanguage, 'fr');
      expect(MediaItem.fromJson(item.toJson()).originalLanguage, 'fr');
      expect(item.copyWith(title: 'U').originalLanguage, 'fr');
      expect(TitleInfo.fromItem(item).originalLanguage, 'fr');
    });
  });
}
