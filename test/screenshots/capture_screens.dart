// Takes a PNG screenshot of every MediaVore screen, offline and without a
// TMDB key. Run it with `tool/screenshots.sh` (see DOCS/screenshots.md).
//
// The real app runs unchanged (DI, repository, Isar, providers, pages); only
// the edges are replaced: TMDB answers come from DemoTmdb, images from
// DemoHttpOverrides, and plugins from in-memory fakes.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/di/injection.config.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/network_images.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/main.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_catalog.dart';
import 'demo_images.dart';
import 'demo_tmdb.dart';

final _env = Platform.environment;
final _lang = _env['SCREENSHOTS_LOCALE'] ?? 'fr';
final _dark = (_env['SCREENSHOTS_THEME'] ?? 'light') == 'dark';
final _outDir = Directory(_env['SCREENSHOTS_DIR'] ?? 'build/screenshots');

/// Logical size and pixel ratio of a 6.1" phone (390 x 844 pt @3x).
const _logicalSize = Size(390, 844);
const _pixelRatio = 3.0;

final _shotKey = GlobalKey();
final _manifest = <Map<String, String>>[];

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  String _dir(String name) {
    final dir = Directory('$root/$name')..createSync(recursive: true);
    return dir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir('documents');

  @override
  Future<String?> getApplicationSupportPath() async => _dir('support');

  @override
  Future<String?> getApplicationCachePath() async => _dir('cache');

  @override
  Future<String?> getTemporaryPath() async => _dir('tmp');
}

/// Loads Roboto and the Material icons from the Flutter SDK, so text renders
/// as text instead of the test font's boxes.
Future<void> _loadFonts() async {
  final root =
      _env['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  final roboto = FontLoader('Roboto');
  for (final file in fonts.listSync().whereType<File>()) {
    if (RegExp(r'Roboto-\w+\.ttf$').hasMatch(file.path)) {
      roboto.addFont(_bytes(file));
    }
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(_bytes(File('${fonts.path}/MaterialIcons-Regular.otf')))).load();
}

Future<ByteData> _bytes(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

/// Lets real asynchronous work (Isar, image decoding) progress between frames.
Future<void> _settle(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  String title, {
  int rounds = 12,
}) async {
  await _settle(tester, rounds: rounds);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shotKey),
  );
  final file = File('${_outDir.path}/$name.png');
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
  _manifest.add({'file': '$name.png', 'title': title});
  debugPrint('[screenshots] $name.png');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _nav(IconData icon) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.byIcon(icon),
);

Future<void> _back(WidgetTester tester) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
  navigator.pop();
  await tester.pump(const Duration(milliseconds: 400));
}

MediaItem _item(DemoTmdb tmdb, DemoMedia m) =>
    MediaItem.fromJson(tmdb.details(m));

/// Builds a plausible library: lists, likes, a year of viewing history and
/// alerts on series still airing.
Future<void> _seed(DemoTmdb tmdb) async {
  final repo = locator<MediaRepository>();
  final now = tmdb.now;
  DemoMedia byId(int id) => demoCatalog.firstWhere((m) => m.id == id);

  for (final id in [693134, 329865, 545611, 95396, 70523]) {
    await repo.addToWatchlist(_item(tmdb, byId(id)));
  }
  final lists = {
    _lang == 'fr' ? 'Ciné-club du dimanche' : 'Sunday film club': [
      496243,
      194,
      77338,
      915935,
    ],
    _lang == 'fr' ? 'Science-fiction' : 'Science fiction': [
      157336,
      329865,
      693134,
      545611,
    ],
  };
  for (final MapEntry(key: name, value: ids) in lists.entries) {
    await repo.createList(name);
    for (final id in ids) {
      await repo.addToList(_item(tmdb, byId(id)), name);
    }
  }
  for (final id in [157336, 129, 496243, 94605, 1396]) {
    await repo.toggleLike(_item(tmdb, byId(id)));
  }

  // Movies seen over the last year, one every ~3 weeks.
  final movies = [
    157336, 129, 496243, 313369, 915935, 77338, 194, 872585, //
  ];
  for (final (i, id) in movies.indexed) {
    final m = byId(id);
    await repo.markAsSeen(
      SeenItem(
        tmdbId: m.id,
        type: MediaType.movie,
        title: m.title(_lang),
        posterPath: m.posterPath,
        seenDate: now.subtract(Duration(days: 8 + 23 * i, hours: i * 3)),
        runtime: m.runtime,
        genres: [for (final g in m.genres) demoGenres[g]!.$1],
      ),
    );
  }

  // Series: (id, seasons fully seen, episodes seen in the next season,
  // days ago of the last episode).
  const series = [
    (1396, 5, 0, 200),
    (94605, 2, 0, 120),
    (95396, 1, 3, 2),
    (136315, 2, 4, 30),
    (70523, 1, 0, 60),
  ];
  for (final (id, fullSeasons, extra, lastDaysAgo) in series) {
    final m = byId(id);
    final episodes = <(int, int)>[
      for (var s = 1; s <= fullSeasons; s++)
        for (var e = 1; e <= m.seasons[s - 1].abs(); e++) (s, e),
      for (var e = 1; e <= extra; e++) (fullSeasons + 1, e),
    ];
    for (final (i, (s, e)) in episodes.indexed) {
      final daysAgo = lastDaysAgo + (episodes.length - 1 - i) ~/ 2;
      await repo.markAsSeen(
        SeenItem(
          tmdbId: m.id,
          type: MediaType.tv,
          title: m.title(_lang),
          posterPath: m.posterPath,
          seenDate: now.subtract(Duration(days: daysAgo, hours: 21 - i % 3)),
          seasonNumber: s,
          episodeNumber: e,
          runtime: m.runtime,
          genres: [for (final g in m.genres) demoGenres[g]!.$1],
        ),
      );
    }
  }

  for (final id in [95396, 136315]) {
    await repo.toggleNotification(_item(tmdb, byId(id)));
  }
  await repo.refreshNotifiedItems(force: true);
  await repo.populateQuickAddFromSeenHistory();
  await locator<AchievementProvider>().refresh();
  // Let the unlocks reach Isar so no banner shows up in the screenshots.
  await Future<void>.delayed(const Duration(milliseconds: 500));
}

void main() {
  late Directory tmp;
  late DemoTmdb tmdb;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('mediavore_screens_');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    await Isar.initializeIsarCore(download: true);
    await _loadFonts();
    _outDir.createSync(recursive: true);
  });

  tearDownAll(() {
    if (locator.isRegistered<Isar>()) locator<Isar>().close();
    tmp.deleteSync(recursive: true);
  });

  testWidgets('capture every screen', (tester) async {
    tester.view.physicalSize = _logicalSize * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    tester.platformDispatcher.localesTestValue = [Locale(_lang)];
    tester.platformDispatcher.platformBrightnessTestValue = _dark
        ? Brightness.dark
        : Brightness.light;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    // Real shadows; restored before the end of the test, which checks it.
    debugDisableShadows = false;
    debugForceNetworkImages = true;

    // No deep link at startup.
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (call) async => null,
    );
    messenger.setMockStreamHandler(
      const EventChannel('com.llfbandit.app_links/events'),
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );

    // An app already set up: key saved, theme following the system.
    const fakeKey = '0123456789abcdef0123456789abcdef';
    SharedPreferences.setMockInitialValues({'themeMode': 0, 'gridSize': 3.0});
    FlutterSecureStorage.setMockInitialValues({'tmdbApiKey': fakeKey});

    tmdb = DemoTmdb(now: DateTime.now(), language: _lang);
    await tester.runAsync(() async {
      final images = await renderDemoImages(_lang);
      final posters = Directory('${_outDir.path}/posters')
        ..createSync(recursive: true);
      for (final m in demoCatalog) {
        await File(
          '${posters.path}/${m.mediaType}-${m.id}.png',
        ).writeAsBytes(images[m.posterPath]!);
      }
      HttpOverrides.global = DemoHttpOverrides(images);
      await locator.reset();
      await init(locator);
      locator<Dio>().interceptors.add(DemoTmdbInterceptor(tmdb));
      await _seed(tmdb);
    });

    await tester.pumpWidget(
      RepaintBoundary(key: _shotKey, child: const MediaVoreApp()),
    );
    await _settle(tester, rounds: 25);

    // 1. Discover
    await _shot(tester, '01_discover', 'Découvrir', rounds: 25);

    // 2. Search results
    await _tap(tester, find.byIcon(Icons.search));
    await tester.enterText(find.byType(TextField).first, 'in');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _shot(tester, '02_search', 'Recherche', rounds: 20);
    FocusManager.instance.primaryFocus?.unfocus();

    // 3-5. Movie details, cast member, series details
    final interstellar = demoCatalog.firstWhere((m) => m.id == 157336);
    await _tap(tester, find.text(interstellar.title(_lang)));
    await _shot(tester, '03_movie_details', 'Fiche film', rounds: 25);
    final actor = find.text('Matthew McConaughey');
    await tester.scrollUntilVisible(
      actor,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await _shot(
      tester,
      '04_movie_cast',
      'Fiche film : distribution',
      rounds: 25,
    );
    if (actor.evaluate().isNotEmpty) {
      await _tap(tester, actor);
      await _shot(tester, '05_actor', 'Fiche acteur', rounds: 20);
      await _back(tester);
    }
    await _back(tester);
    await _settle(tester);

    // 4. My lists
    await _tap(tester, _nav(Icons.bookmark));
    await _shot(tester, '06_lists', 'Mes listes', rounds: 20);

    // 5. History
    await _tap(tester, _nav(Icons.history));
    await _shot(tester, '07_history', 'Historique', rounds: 20);

    // Series details from the history
    final severance = demoCatalog.firstWhere((m) => m.id == 95396);
    final severanceTile = find.text(severance.title(_lang));
    if (severanceTile.evaluate().isNotEmpty) {
      await _tap(tester, severanceTile);
      await _shot(tester, '08_series_details', 'Fiche série', rounds: 25);
      await _back(tester);
      await _settle(tester);
    }

    // 6. Alerts
    await _tap(tester, _nav(Icons.notifications));
    await _shot(tester, '09_alerts', 'Alertes : sorties', rounds: 20);
    await _tap(tester, find.byType(Tab).last);
    await _shot(tester, '10_quick_add', 'Alertes : ajout rapide', rounds: 15);

    // 7. Profile and its pages
    await _tap(tester, _nav(Icons.person_outline));
    await _shot(tester, '11_profile', 'Profil');
    await _tap(tester, find.byKey(const Key('profile_stats')));
    await _shot(tester, '12_stats', 'Statistiques', rounds: 20);
    await _back(tester);
    await _tap(tester, find.byKey(const Key('profile_achievements')));
    await _shot(tester, '13_achievements', 'Succès', rounds: 20);
    await _back(tester);
    await _tap(tester, find.byKey(const Key('profile_settings')));
    await _shot(tester, '14_settings', 'Réglages');

    final manifest = const JsonEncoder.withIndent('  ').convert({
      'locale': _lang,
      'theme': _dark ? 'dark' : 'light',
      'size': [_logicalSize.width, _logicalSize.height],
      'pixelRatio': _pixelRatio,
      'screens': _manifest,
      'catalog': [
        for (final m in demoCatalog)
          {
            'title': m.title(_lang),
            'originalTitle': m.originalTitle,
            'type': m.mediaType,
            'year': m.year,
            'genres': [
              for (final g in m.genres)
                _lang == 'fr' ? demoGenres[g]!.$1 : demoGenres[g]!.$2,
            ],
            'rating': m.rating,
            'runtime': m.runtime,
            'overview': m.overview(_lang),
            'poster': 'posters/${m.mediaType}-${m.id}.png',
          },
      ],
    });
    await tester.runAsync(
      () => File('${_outDir.path}/manifest.json').writeAsString(manifest),
    );

    // Dispose the app while Isar is still open.
    await tester.pumpWidget(const SizedBox());
    await _settle(tester, rounds: 3);
    debugDisableShadows = true;
    debugForceNetworkImages = false;
  });
}
