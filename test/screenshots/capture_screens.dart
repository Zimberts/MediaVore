// Generates PNG screenshots of MediaVore's key screens offline using the real
// app harness, FakeTmdb, and drawn poster placeholders.
//
// Run via `tool/screenshots.sh` (not named `*_test.dart` so `flutter test`
// skips it during regular test runs).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';

import '../app/harness.dart';
import '../helpers/fake_image_cache.dart';
import '../helpers/fake_tmdb.dart';

final _env = Platform.environment;
final _lang = _env['SCREENSHOTS_LOCALE'] ?? 'en';
final _themeMode = (_env['SCREENSHOTS_THEME'] ?? 'light') == 'dark'
    ? ThemeMode.dark
    : ThemeMode.light;
final _outDir = Directory(_env['SCREENSHOTS_DIR'] ?? 'DOCS/screenshots');

const _logicalSize = Size(390, 844);
const _pixelRatio = 2.0;

final _shotKey = GlobalKey();

/// Draws deterministic, stylized poster/backdrop PNGs offline via `dart:ui`
/// so every card in the screenshots has a vivid visual instead of blank boxes.
class _PosterImageService extends FakeImageService {
  final Map<String, List<int>> _cache = {};

  static const _palettes = [
    (Color(0xFF1A237E), Color(0xFF5C6BC0)),
    (Color(0xFF880E4F), Color(0xFFEC407A)),
    (Color(0xFF004D40), Color(0xFF26A69A)),
    (Color(0xFF311B92), Color(0xFF7E57C2)),
    (Color(0xFFBF360C), Color(0xFFFF7043)),
    (Color(0xFF0D47A1), Color(0xFF29B6F6)),
    (Color(0xFF1B5E20), Color(0xFF66BB6A)),
    (Color(0xFF3E2723), Color(0xFF8D6E63)),
  ];

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    requests.add(Uri.parse(url));
    final bytes = _cache[url] ??= await _drawPoster(url);
    return _BytesResponse(bytes);
  }

  Future<List<int>> _drawPoster(String url) async {
    const w = 240.0;
    const h = 360.0;
    final hash = url.codeUnits.fold<int>(
      0,
      (acc, c) => (acc * 31 + c) & 0x7FFF,
    );
    final (dark, light) = _palettes[hash % _palettes.length];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(w, h), [
          dark,
          light,
        ]),
    );

    // Subtle geometric accents to give each poster visual depth.
    final accent = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(w * (0.25 + (hash % 5) * 0.12), h * 0.34),
      56,
      accent,
    );
    canvas.drawCircle(
      Offset(w * (0.75 - (hash % 4) * 0.1), h * 0.62),
      84,
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List();
  }
}

class _BytesResponse implements FileServiceResponse {
  _BytesResponse(this._bytes);

  final List<int> _bytes;

  @override
  Stream<List<int>> get content => Stream.value(_bytes);

  @override
  int get contentLength => _bytes.length;

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 7));

  @override
  String? get eTag => null;

  @override
  String get fileExtension => '.png';
}

Future<ByteData> _readFontBytes(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

Future<void> _loadFontDir(String family, Directory dir) async {
  if (!dir.existsSync()) return;
  final loader = FontLoader(family);
  for (final file in dir.listSync().whereType<File>()) {
    if (file.path.endsWith('.ttf') || file.path.endsWith('.otf')) {
      loader.addFont(_readFontBytes(file));
    }
  }
  await loader.load();
}

/// Loads the app's bundled fonts (Bricolage Grotesque, Inter) plus Roboto and
/// MaterialIcons from the Flutter SDK so text and icons render as real glyphs
/// rather than the test runner's Ahem boxes.
Future<void> _loadFonts() async {
  await _loadFontDir(
    'Bricolage Grotesque',
    Directory('assets/fonts/bricolage_grotesque'),
  );
  await _loadFontDir('Inter', Directory('assets/fonts/inter'));

  final root =
      _env['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!fonts.existsSync()) {
    throw StateError('Flutter material_fonts not found at ${fonts.path}');
  }
  final roboto = FontLoader('Roboto');
  for (final file in fonts.listSync().whereType<File>()) {
    if (RegExp(r'Roboto-\w+\.ttf$').hasMatch(file.path)) {
      roboto.addFont(_readFontBytes(file));
    }
  }
  await roboto.load();
  final icons = File('${fonts.path}/MaterialIcons-Regular.otf');
  await (FontLoader('MaterialIcons')..addFont(_readFontBytes(icons))).load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await pumpUntilSettled(tester);
  // Dismiss any achievement unlock toast triggered by the seed data.
  while (find.byIcon(Icons.close).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.close).first);
    await pumpUntilSettled(tester);
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shotKey),
  );
  _outDir.createSync(recursive: true);
  final file = File('${_outDir.path}/$name.png');
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

MediaItem _movie(
  int id,
  String title, {
  String releaseDate = '2024-03-01',
  double voteAverage = 8.4,
}) => MediaItem(
  id: id,
  title: title,
  overview: 'Overview for $title.',
  releaseDate: releaseDate,
  posterPath: '/poster_movie_$id.jpg',
  voteAverage: voteAverage,
  genres: const ['Sci-Fi', 'Drama'],
);

MediaItem _show(int id, String title, {double voteAverage = 8.8}) => MediaItem(
  id: id,
  title: title,
  overview: 'Overview for $title.',
  releaseDate: '2022-02-18',
  posterPath: '/poster_tv_$id.jpg',
  voteAverage: voteAverage,
  mediaType: MediaType.tv,
  genres: const ['Drama', 'Thriller'],
);

AppSeed _buildSeed() {
  final now = DateTime.now();
  return AppSeed(
    prefs: {'themeMode': _themeMode.index, LocaleService.overrideKey: _lang},
    lists: {
      'watchlist': [
        _movie(157336, 'Interstellar', releaseDate: '2014-11-05'),
        _movie(693134, 'Dune: Part Two', releaseDate: '2024-02-27'),
        _show(95396, 'Severance'),
      ],
      'Weekend Picks': [
        _movie(129, 'Spirited Away', releaseDate: '2001-07-20'),
        _movie(550, 'Fight Club', releaseDate: '1999-10-15'),
        _show(1396, 'Breaking Bad'),
      ],
    },
    seen: [
      for (final (i, entry) in [
        (550, 'Fight Club', 139, ['Drama', 'Thriller']),
        (157336, 'Interstellar', 169, ['Sci-Fi', 'Drama']),
        (129, 'Spirited Away', 125, ['Animation', 'Fantasy']),
        (27205, 'Inception', 148, ['Sci-Fi', 'Action']),
      ].indexed)
        SeenItem(
          tmdbId: entry.$1,
          type: MediaType.movie,
          title: entry.$2,
          posterPath: '/poster_movie_${entry.$1}.jpg',
          seenDate: now.subtract(Duration(days: 2 + 12 * i)),
          runtime: entry.$3,
          genres: entry.$4,
        ),
      for (final (season, episodes) in [(1, 10), (2, 4)])
        for (var ep = 1; ep <= episodes; ep++)
          SeenItem(
            tmdbId: 1396,
            type: MediaType.tv,
            title: 'Breaking Bad',
            posterPath: '/poster_tv_1396.jpg',
            seenDate: now.subtract(Duration(days: 28 - season * 8 - ep)),
            seasonNumber: season,
            episodeNumber: ep,
            runtime: 47,
            genres: const ['Drama', 'Crime'],
          ),
    ],
  );
}

FakeTmdb _buildTmdb() {
  final tomorrow = DateTime.now().add(const Duration(days: 3));
  final tomorrowStr =
      '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-'
      '${tomorrow.day.toString().padLeft(2, '0')}';
  return FakeTmdb(
    shows: {
      1396: FakeShow(
        seasons: 2,
        episodesPerSeason: 10,
        airDate: (s, e) => s == 2 && e == 5 ? tomorrowStr : '2020-01-01',
      ),
    },
  );
}

void main() {
  setUpAll(_loadFonts);

  testApp(
    'capture key screenshots',
    (tester, app) async {
      tester.view
        ..devicePixelRatio = _pixelRatio
        ..physicalSize = _logicalSize * _pixelRatio;
      tester.platformDispatcher.localesTestValue = [Locale(_lang)];
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpUntilSettled(tester);

      // 1. Home
      await goToTab(tester, AppTab.home);
      await _capture(tester, 'home');

      // 2. Discover
      await goToTab(tester, AppTab.discover);
      await _capture(tester, 'discover');

      // 3. Media Detail
      await openDetail(tester, 550);
      await _capture(tester, 'detail');
      final shell = tester.element(find.byType(MainPage, skipOffstage: false));
      Navigator.of(shell).popUntil((route) => route.isFirst);
      await pumpUntilSettled(tester);

      // 4. Library
      await goToTab(tester, AppTab.library);
      await _capture(tester, 'library');

      // 5. Together
      await goToTab(tester, AppTab.together);
      await _capture(tester, 'together');

      // 6. Me -> Stats
      await goToTab(tester, AppTab.me);
      Navigator.of(
        tester.element(find.byType(MainPage, skipOffstage: false)),
      ).push(MaterialPageRoute<void>(builder: (_) => const MediaStatsPage()));
      await _capture(tester, 'stats');
    },
    seed: _buildSeed(),
    tmdb: _buildTmdb,
    imageService: _PosterImageService.new,
    wrapApp: (child) => RepaintBoundary(key: _shotKey, child: child),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
