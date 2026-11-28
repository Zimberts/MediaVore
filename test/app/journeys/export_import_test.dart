// Journey #469: export a rich library to a .mdv file from Me > Storage,
// reinstall the app, import the file, and find the same library, history,
// series in progress, figures and achievements; import a .mdv written by the
// previous release.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/profile/presentation/pages/profile_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_file_picker.dart';
import '../../helpers/fixture_reader.dart';
import '../harness.dart';

/// Movie seen twice (rewatch), then liked.
const int _rewatched = 550;

/// Movie seen once.
const int _seenOnce = 551;

/// Movie in the watchlist and in the custom list.
const int _planned = 552;

/// Movie only in the custom list.
const int _listed = 553;

/// Series in progress: S1E1-E3 seen.
const int _inProgress = 100;

/// Series excluded from Quick Add after S1E1, alerts on.
const int _excluded = 200;

const String _customList = 'Weekend';

MediaItem _movie(int id) => MediaItem(
  id: id,
  title: 'Movie $id',
  overview: '',
  releaseDate: '2020-01-01',
  posterPath: '/p$id.jpg',
);

MediaItem _show(int id) => MediaItem(
  id: id,
  title: 'Show $id',
  overview: '',
  releaseDate: '2020-01-01',
  posterPath: '/p$id.jpg',
  mediaType: MediaType.tv,
);

SeenItem _movieSeen(int id, DateTime date) => SeenItem(
  tmdbId: id,
  type: MediaType.movie,
  title: 'Movie $id',
  posterPath: '/p$id.jpg',
  seenDate: date,
);

SeenItem _episodeSeen(int id, int episode, DateTime date) => SeenItem(
  tmdbId: id,
  type: MediaType.tv,
  title: 'Show $id',
  posterPath: '/p$id.jpg',
  seenDate: date,
  seasonNumber: 1,
  episodeNumber: episode,
);

/// Lists in a set order, a rewatch, two series (one excluded from Quick
/// Add); likes and alerts are added through the app's repository by
/// [_seedExtras].
final AppSeed _richSeed = AppSeed(
  lists: {
    'watchlist': [_movie(_planned)],
    _customList: [_movie(_listed), _show(_inProgress), _movie(_planned)],
  },
  seen: [
    _movieSeen(_rewatched, DateTime(2024, 1, 10, 21)),
    _movieSeen(_rewatched, DateTime(2024, 6, 1, 20, 30)),
    _movieSeen(_seenOnce, DateTime(2024, 3, 2, 22)),
    for (var e = 1; e <= 3; e++)
      _episodeSeen(_inProgress, e, DateTime(2024, 7, e, 19)),
    _episodeSeen(_excluded, 1, DateTime(2024, 5, 5, 18)),
  ],
);

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(MainPage, skipOffstage: false));

SearchProvider _search(WidgetTester tester) =>
    _context(tester).read<SearchProvider>();

Future<void> _seedExtras(WidgetTester tester, TestApp app) async {
  final repository = app.repository;
  await _settle(tester, repository.toggleLike(_movie(_rewatched)));
  await _settle(tester, repository.toggleNotification(_show(_excluded)));
  await _settle(tester, repository.populateQuickAddFromSeenHistory());
  await _settle(
    tester,
    repository.optOutSeries(_excluded, seasonNumber: 1, episodeNumber: 2),
  );
  // What a user action would have reloaded (it may fetch TMDB: fake time).
  await _settle(tester, _search(tester).reloadSavedTitles());
  await pumpUntilSettled(tester);
}

/// Everything the user owns, read from the database, in a comparable form:
/// local ids and insertion times are left out, orders that the user sees
/// are kept, dates are in UTC.

Future<Map<String, Object>> _snapshot(WidgetTester tester, TestApp app) async {
  final snapshot = await tester.runAsync(() async {
    final repository = app.repository;
    final names = await repository.getAllListNames()
      ..sort();
    final seen = await repository.getSeenItems();
    final likes = await repository.getLikedItems();
    final alerts = await repository.getNotifiedItems();
    final quickAdd = await repository.getQuickAddItems();
    final inProgress = await repository.getInProgressItems();
    final optOuts = await repository.getQuickAddOptOuts();
    return <String, Object>{
      'lists': {
        for (final name in names) name: await repository.getListEntries(name),
      },
      'seen': [
        for (final s in seen)
          '${s.type.name}:${s.tmdbId} S${s.seasonNumber}E${s.episodeNumber} '
              '${s.seenDate.toUtc().toIso8601String()} ${s.title} ${s.posterPath} '
              '${s.runtime} ${s.genres}',
      ]..sort(),
      'likes': [for (final l in likes) '${l.type.name}:${l.tmdbId} ${l.title}']
        ..sort(),
      'alerts': [
        for (final n in alerts)
          '${n.type.name}:${n.tmdbId} S${n.seasonNumber}E${n.episodeNumber} '
              '${n.title} ${n.releaseDate?.toUtc()} ${n.autoNotify}',
      ]..sort(),
      'quickAdd': [
        for (final q in quickAdd)
          '${q.type.name}:${q.tmdbId} S${q.seasonNumber}E${q.episodeNumber} '
              '${q.title} ${q.airDate?.toUtc()}',
      ]..sort(),
      'inProgress': [
        for (final i in inProgress)
          '${i.next.tmdbId} S${i.next.seasonNumber}E${i.next.episodeNumber} '
              'seen:${i.seenEpisodes}/${i.totalEpisodes} ${i.lastActivity.toUtc()} '
              'paused:${i.paused}',
      ],
      'optOuts': [
        for (final o in optOuts)
          '${o.tmdbId} S${o.seasonNumber}E${o.episodeNumber}',
      ]..sort(),
    };
  });
  return snapshot!;
}

/// What the screens read from the providers: Library (lists, watchlist,
/// likes), Home (Tonight, in progress, Quick Add) and alerts.
Map<String, Object> _screens(WidgetTester tester) {
  final search = _search(tester);
  String key(int id, MediaType type) => '${type.name}:$id';
  return {
    'listNames': [...search.listNames]..sort(),
    'listEntries': {
      for (final name in [...search.listEntries.keys]..sort())
        name: search.listEntries[name],
    },
    'watchlist': search.watchlistIds,
    'likes': [...search.likedIds]..sort(),
    'tonight': [
      for (final m in search.tonightCandidates()) key(m.id, m.mediaType),
    ],
    'inProgress': [
      for (final i in search.inProgressItems)
        '${i.next.tmdbId} S${i.next.seasonNumber}E${i.next.episodeNumber}',
    ],
    'quickAdd': [
      for (final q in search.quickAddItems)
        '${key(q.tmdbId, q.type)} S${q.seasonNumber}E${q.episodeNumber}',
    ]..sort(),
    'alerts': [for (final n in search.notifiedItems) key(n.tmdbId, n.type)]
      ..sort(),
  };
}

/// Unlocked achievements as the app shows them: id and date.
List<String> _achievements(WidgetTester tester) => [
  for (final a in _context(tester).read<AchievementProvider>().achievements)
    if (a.isUnlocked) '${a.id} ${a.unlockedAt?.toUtc()}',
]..sort();

/// Pumps until [future] completes; rethrows its error.
Future<void> _settle(WidgetTester tester, Future<void> future) async {
  var done = false;
  Object? error;
  unawaited(future.then((_) => done = true, onError: (Object e) => error = e));
  await _pumpUntil(tester, () => done || error != null);
  if (error != null) throw error!;
  expect(done, isTrue, reason: 'still running');
}

/// Pumps until [condition] holds, giving real time to Isar at each step:
/// achievements follow the database through a watcher, on real time.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int steps = 300,
}) async {
  for (var i = 0; i < steps && !condition(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Texts of the page of type [T], top to bottom.
List<String> _texts<T extends Widget>(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(
    find.descendant(of: find.byType(T), matching: find.byType(Text)),
  ))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];

/// Texts of Me (figures, achievement preview) and of All statistics.
Future<List<String>> _figures(WidgetTester tester) async {
  await goToTab(tester, AppTab.me);
  tester.state<ScrollableState>(_meScrollable()).position.jumpTo(0);
  await pumpUntilSettled(tester);
  final stats = find.byKey(const Key('profile_stats'));
  final me = _texts<ProfilePage>(tester);
  await tester.tap(stats);
  await pumpUntilSettled(tester);
  final figures = _texts<MediaStatsPage>(tester);
  await _back(tester);
  return [...me, '---', ...figures];
}

Finder _meScrollable() => find
    .descendant(of: find.byType(ProfilePage), matching: find.byType(Scrollable))
    .first;

/// Lets the achievement banners queued by the main page run out (4 s each).
Future<void> _waitBanners(WidgetTester tester) async {
  final banner = find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_AchievementTopBanner',
    skipOffstage: false,
  );
  for (var quiet = 0, i = 0; quiet < 3 && i < 120; i++) {
    await tester.pump(const Duration(seconds: 1));
    quiet = banner.evaluate().isEmpty ? quiet + 1 : 0;
  }
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await pumpUntilSettled(tester);
}

/// Opens Me > Storage.
Future<void> _openStorage(WidgetTester tester) async {
  await goToTab(tester, AppTab.me);
  final storage = find.byKey(const Key('profile_storage'));
  await tester.scrollUntilVisible(storage, 200, scrollable: _meScrollable());
  await tester.tap(storage);
  await pumpUntilSettled(tester);
  expect(find.byType(DataCacheSettingsPage), findsOneWidget);
}

/// Taps the tile [key] of the Storage page, scrolled into view (the list is
/// lazy).
Future<void> _tapStorageTile(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    200,
    scrollable: find
        .descendant(
          of: find.byType(DataCacheSettingsPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(find.byKey(key));
}

/// Installs a fake file picker for the test.
FakeFilePickerPlatform _fakeFilePicker() {
  final previous = FilePickerPlatform.instance;
  final picker = FakeFilePickerPlatform();
  FilePickerPlatform.instance = picker;
  addTearDown(() => FilePickerPlatform.instance = previous);
  return picker;
}

/// Exports from Storage with "Save to device"; returns the saved bytes.
Future<(String, Uint8List)> _export(
  WidgetTester tester,
  FakeFilePickerPlatform picker,
) async {
  await _openStorage(tester);
  await _tapStorageTile(tester, DataCacheSettingsPage.exportKey);
  await pumpUntilSettled(tester);
  await tester.tap(find.byKey(DataCacheSettingsPage.saveToDeviceKey));
  await pumpUntilSettled(tester);
  expect(picker.savedBytes, isNotNull, reason: 'export saved');
  final result = (picker.savedFileName!, picker.savedBytes!);
  await _back(tester);
  return result;
}

/// Imports [file] from Storage, replacing the data (with confirmation), and
/// waits for the confirmation message.
Future<void> _import(
  WidgetTester tester,
  FakeFilePickerPlatform picker,
  File file,
) async {
  picker.files = [LocalPlatformFile(file.path)];
  await _openStorage(tester);
  await _tapStorageTile(tester, DataCacheSettingsPage.importKey);
  await pumpUntilSettled(tester);
  await tester.tap(find.byKey(DataCacheSettingsPage.importReplaceKey));
  await pumpUntilSettled(tester);
  await tester.tap(find.byKey(DataCacheSettingsPage.replaceConfirmKey));
  // The import ends on real I/O, then the screens reload: wait on real time
  // for the message shown once both are done.
  final done = find.text(_context(tester).l10n.dataImportedReplaced);
  await _pumpUntil(tester, () => done.evaluate().isNotEmpty, steps: 1200);
  expect(done, findsOneWidget);
  await pumpUntilSettled(tester);
  await _back(tester);
}

/// Writes [bytes] to a temporary file named [name], as a file manager would
/// hand it to the app.
File _file(String name, List<int> bytes) {
  final dir = Directory.systemTemp.createTempSync('mediavore_mdv_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return File('${dir.path}/$name')..writeAsBytesSync(bytes);
}

void main() => registerExportImportJourney();

/// Registers the #469 export and import journey.
void registerExportImportJourney() {
  group('export and import journey', () {
    testApp(
      'should restore the library, history, series in progress, exclusions, '
      'figures and achievements after an export, a reinstall and an import',
      (tester, app) async {
        final picker = _fakeFilePicker();
        await _seedExtras(tester, app);
        final before = await _snapshot(tester, app);
        final screens = _screens(tester);
        expect(screens['listEntries'], isNotEmpty);
        expect(screens['inProgress'], hasLength(1));
        expect(before['optOuts'], ['$_excluded S1E2']);
        expect(before['inProgress'], hasLength(1));

        // Figures and achievements before the export: exporting unlocks the
        // backup achievement, whose export log stays on the device.
        final achievements = _achievements(tester);
        expect(achievements, isNot(contains(startsWith('archivist_'))));
        final figures = await _figures(tester);

        // 1. Export from Me > Storage, saved through the system picker.
        final (fileName, bytes) = await _export(tester, picker);
        expect(
          fileName,
          matches(
            RegExp(r'^mediavore_export_\d{4}(-\d\d){2}_\d\d(-\d\d){2}\.mdv$'),
          ),
        );
        await _pumpUntil(
          tester,
          () => _achievements(tester).any((a) => a.startsWith('archivist_1 ')),
        );
        expect(_achievements(tester), contains(startsWith('archivist_1 ')));

        // 2. Reinstall: an empty app.
        await _waitBanners(tester);
        app = await reinstallTestApp(tester);
        final empty = await _snapshot(tester, app);
        expect(empty['lists'], {'watchlist': <String>[]});
        for (final key in ['seen', 'likes', 'alerts', 'quickAdd', 'optOuts']) {
          expect(empty[key], isEmpty, reason: key);
        }
        expect(_achievements(tester), isEmpty);

        // 3. Import the file: same data, same screens.
        await _import(tester, picker, _file(fileName, bytes));
        expect(await _snapshot(tester, app), before);
        expect(_screens(tester), screens);
        await _pumpUntil(
          tester,
          () => _achievements(tester).length == achievements.length,
        );
        expect(_achievements(tester), achievements);
        expect(await _figures(tester), figures);

        // 4. The restored exclusion holds: a new scan of the history does not
        //    queue the excluded series again.
        // It may fetch TMDB: run it on fake time (the app's HTTP stack keeps
        // timers there), pumping until it ends.
        await _settle(tester, app.repository.populateQuickAddFromSeenHistory());
        expect((await _snapshot(tester, app))['quickAdd'], before['quickAdd']);
        await _waitBanners(tester);
      },
      seed: _richSeed,
    );

    // 5. An archive written by the previous release (format version 1)
    //    still imports. Regenerate the fixture when the format changes:
    //    test/fixtures/README.md.
    testApp('should import a .mdv file exported by v1.4.4', (
      tester,
      app,
    ) async {
      final picker = _fakeFilePicker();
      await _import(
        tester,
        picker,
        _file(
          'mediavore_export_2026-11-22_10-00-00.mdv',
          fixtureBytes('export_v1.4.4.mdv'),
        ),
      );

      final snapshot = await _snapshot(tester, app);
      expect(snapshot['lists'], {
        'Weekend': ['553:movie', '100:tv'],
        'watchlist': ['552:movie'],
      });
      expect(snapshot['seen'], [
        'movie:550 SnullEnull 2024-01-10T20:00:00.000Z Movie 550 /p550.jpg '
            '110 [Action, Science Fiction]',
        'movie:550 SnullEnull 2024-06-01T18:30:00.000Z Movie 550 /p550.jpg '
            '110 [Action, Science Fiction]',
        'tv:100 S1E1 2024-07-01T17:00:00.000Z Show 100 /p100.jpg 45 [Drama]',
        'tv:100 S1E2 2024-07-02T17:00:00.000Z Show 100 /p100.jpg 45 [Drama]',
      ]);
      expect(snapshot['likes'], ['movie:550 Movie 550']);
      expect(snapshot['alerts'], [
        'tv:200 S1E1 Show 200 2020-01-01 00:00:00.000Z false',
      ]);
      expect(snapshot['quickAdd'], [
        'tv:100 S1E3 Show 100 2020-01-01 00:00:00.000Z',
      ]);
      expect(snapshot['inProgress'], [
        '100 S1E3 seen:2/20 2024-07-02 17:00:00.000Z paused:true',
      ]);
      expect(snapshot['optOuts'], isEmpty);

      // The screens follow: 2 viewings of one movie, 2 episodes.
      expect(_search(tester).seenItems, hasLength(4));
      await _pumpUntil(tester, () => _achievements(tester).isNotEmpty);
      expect(_achievements(tester), contains(startsWith('movie_1 ')));
      await _waitBanners(tester);
    });
  });
}
