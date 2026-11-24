// Smoke test of every screen (#472): each screen of the real app is rendered
// with a realistic seed in both brightnesses, both languages, on a narrow
// phone and with large text. A screen fails on any Flutter error (exception,
// `RenderFlex overflowed`) or on a raw ARB key shown instead of its text.
//
// No pixel goldens while the v1.4.0 design moves.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/discovery/presentation/pages/swiper_page.dart';
import 'package:mediavore/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:mediavore/features/home/presentation/pages/in_progress_page.dart';
import 'package:mediavore/features/home/presentation/pages/upcoming_page.dart';
import 'package:mediavore/features/library/presentation/pages/list_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/person_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/pages/list_intersection_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/together/presentation/models/together_vote_engine.dart';
import 'package:mediavore/features/together/presentation/pages/together_results_page.dart';
import 'package:mediavore/features/together/presentation/pages/together_vote_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:provider/provider.dart';

import '../harness.dart';

/// Rendering conditions of one run over every screen.
class _Variant {
  const _Variant(
    this.language,
    this.themeMode, {
    this.size = const Size(390, 844),
    this.textScale = 1.0,
  });

  final String language;
  final ThemeMode themeMode;

  /// Logical size of the screen, in dp.
  final Size size;
  final double textScale;

  String get name =>
      '$language ${themeMode.name} ${size.width.toInt()}dp x$textScale';
}

const List<_Variant> _variants = [
  _Variant('fr', ThemeMode.light),
  _Variant('fr', ThemeMode.dark),
  _Variant('en', ThemeMode.light),
  _Variant('en', ThemeMode.dark),
  // Narrow phone (320 dp) with large text, in both languages and themes.
  _Variant('fr', ThemeMode.light, size: Size(320, 640), textScale: 1.3),
  _Variant('en', ThemeMode.dark, size: Size(320, 640), textScale: 1.3),
];

/// A screen: how to show it from the shell, and how to leave it.
class _Screen {
  const _Screen(this.name, this.open, {this.close});

  final String name;
  final Future<void> Function(WidgetTester tester) open;

  /// Back to the shell; pops every pushed route when null.
  final Future<void> Function(WidgetTester tester)? close;
}

const int _movieId = 550;
const int _showId = 1399;
const int _personId = 287;

MediaItem _movie(int id) => MediaItem(
  id: id,
  title: 'Movie $id',
  overview: 'Overview of movie $id.',
  releaseDate: '2020-01-01',
  posterPath: '/movie_$id.jpg',
);

MediaItem _show(int id) => MediaItem(
  id: id,
  title: 'Show $id',
  overview: 'Overview of show $id.',
  releaseDate: '2019-01-01',
  posterPath: '/show_$id.jpg',
  mediaType: MediaType.tv,
);

/// Lists, a started series and a few seen movies: every screen has content.
AppSeed _seed(_Variant variant) {
  final now = DateTime.now();
  return AppSeed(
    prefs: {
      'themeMode': variant.themeMode.index,
      LocaleService.overrideKey: variant.language,
    },
    lists: {
      'watchlist': [_movie(551), _movie(552), _show(1400)],
      'Weekend': [_movie(553), _movie(_movieId), _show(_showId)],
    },
    seen: [
      for (final (i, id) in [_movieId, 554, 555].indexed)
        SeenItem(
          tmdbId: id,
          type: MediaType.movie,
          title: 'Movie $id',
          posterPath: '/movie_$id.jpg',
          seenDate: now.subtract(Duration(days: 3 + 20 * i)),
          runtime: 120,
          genres: const ['Drama'],
        ),
      // Season 1 seen, season 2 started: the series is in progress.
      for (final (season, episodes) in [(1, 10), (2, 3)])
        for (var episode = 1; episode <= episodes; episode++)
          SeenItem(
            tmdbId: _showId,
            type: MediaType.tv,
            title: 'Show $_showId',
            posterPath: '/show_$_showId.jpg',
            seenDate: now.subtract(Duration(days: 30 - season * 10 - episode)),
            seasonNumber: season,
            episodeNumber: episode,
            runtime: 50,
            genres: const ['Drama'],
          ),
    ],
  );
}

BuildContext _shell(WidgetTester tester) =>
    tester.element(find.byType(MainPage, skipOffstage: false));

Future<void> _push(WidgetTester tester, Widget page) async {
  unawaited(
    Navigator.of(
      _shell(tester),
    ).push(MaterialPageRoute<void>(builder: (_) => page)),
  );
  await pumpUntilSettled(tester);
}

Future<void> _open(
  WidgetTester tester,
  Future<void> Function(BuildContext) open,
) async {
  unawaited(open(_shell(tester)));
  await pumpUntilSettled(tester);
}

Future<void> _popAll(WidgetTester tester) async {
  Navigator.of(_shell(tester)).popUntil((route) => route.isFirst);
  await pumpUntilSettled(tester);
}

const List<SharedMediaEntry> _friendEntries = [
  SharedMediaEntry(_movieId, MediaType.movie),
  SharedMediaEntry(556, MediaType.movie),
  SharedMediaEntry(_showId, MediaType.tv),
];

final List<_Screen> _screens = [
  _Screen('home', (t) => goToTab(t, AppTab.home)),
  _Screen('in progress', (t) => _open(t, InProgressPage.show)),
  _Screen('upcoming', (t) => _open(t, UpcomingPage.show)),
  _Screen('discover', (t) => goToTab(t, AppTab.discover)),
  _Screen(
    'swipe',
    (t) async {
      t
          .element(find.byType(DiscoveryPage))
          .read<DiscoveryProvider>()
          .setMode(DiscoverMode.swipe);
      await pumpUntilSettled(t);
      expect(find.byType(SwiperPage), findsOneWidget);
    },
    close: (t) async {
      t
          .element(find.byType(DiscoveryPage))
          .read<DiscoveryProvider>()
          .setMode(DiscoverMode.explore);
      await pumpUntilSettled(t);
    },
  ),
  _Screen('library', (t) => goToTab(t, AppTab.library)),
  _Screen('list', (t) => _push(t, const ListPage(initialList: 'Weekend'))),
  _Screen('history', (t) => _push(t, const SeenHistoryPage())),
  _Screen(
    'list intersection',
    (t) => _push(
      t,
      const ListIntersectionPage(
        sharedPayload: ListSharePayload(name: 'Sam', entries: _friendEntries),
      ),
    ),
  ),
  _Screen('together', (t) => goToTab(t, AppTab.together)),
  _Screen('together results', (t) async {
    _shell(t).read<TogetherSessionProvider>().addParticipant(
      const TogetherParticipant(name: 'Sam', entries: _friendEntries),
    );
    await _push(t, const TogetherResultsPage());
  }, close: _resetTogether),
  _Screen(
    'together vote',
    (t) => _push(
      t,
      TogetherVotePage(
        candidates: [
          TogetherVoteCandidate(item: _movie(_movieId)),
          TogetherVoteCandidate(item: _show(_showId)),
        ],
        participants: const ['Alex', 'Sam'],
      ),
    ),
    close: _resetTogether,
  ),
  _Screen('me', (t) => goToTab(t, AppTab.me)),
  _Screen('stats', (t) => _push(t, const MediaStatsPage())),
  _Screen('achievements', (t) => _push(t, const AchievementsPage())),
  _Screen('settings', (t) => _push(t, const SettingsPage())),
  _Screen('data', (t) => _push(t, const DataCacheSettingsPage())),
  _Screen('tmdb key', (t) => _push(t, const TmdbCredentialPage())),
  _Screen('movie detail', (t) => openDetail(t, _movieId)),
  _Screen(
    'series detail and season',
    (t) => openDetail(t, _showId, type: MediaType.tv),
  ),
  _Screen(
    'person',
    (t) => _open(
      t,
      (context) => PersonPage.show(
        context,
        personId: _personId,
        personName: 'Person $_personId',
      ),
    ),
  ),
];

Future<void> _resetTogether(WidgetTester tester) async {
  await _popAll(tester);
  _shell(tester).read<TogetherSessionProvider>().reset();
  await pumpUntilSettled(tester);
}

/// ARB keys (template), to spot a key shown instead of its text.
final Set<String> _arbKeys = {
  for (final key
      in (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>)
          .keys)
    if (!key.startsWith('@')) key,
};

/// camelCase identifiers: a raw key always has one (`navHome`), real text
/// rarely does.
final RegExp _identifier = RegExp(r'\b[a-z]+[A-Z][A-Za-z0-9]*\b');

/// ARB keys displayed as text on the current screen.
Set<String> _rawKeys(WidgetTester tester) {
  final texts = [
    for (final widget in tester.widgetList<RichText>(find.byType(RichText)))
      widget.text.toPlainText(),
    for (final widget in tester.widgetList<EditableText>(
      find.byType(EditableText),
    ))
      widget.controller.text,
  ];
  return {
    for (final text in texts)
      for (final match in _identifier.allMatches(text))
        if (_arbKeys.contains(match[0])) match[0]!,
  };
}

void main() {
  group('screens smoke test', () {
    for (final variant in _variants) {
      testApp(
        'should render every screen without error when ${variant.name}',
        (tester, app) async {
          tester.view
            ..devicePixelRatio = 3
            ..physicalSize = variant.size * 3;
          tester.platformDispatcher
            ..localesTestValue = [Locale(variant.language)]
            ..textScaleFactorTestValue = variant.textScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          await pumpUntilSettled(tester);

          final problems = <String>[];
          var screen = 'boot';
          final reportError = FlutterError.onError;
          // Every error is collected (with its screen) instead of stopping at
          // the first one; the full report still goes to the console.
          FlutterError.onError = (details) {
            FlutterError.dumpErrorToConsole(details, forceReport: true);
            problems.add(
              '[$screen] ${details.exceptionAsString().split('\n').first}',
            );
          };
          try {
            for (final s in _screens) {
              screen = s.name;
              await s.open(tester);
              for (final key in _rawKeys(tester)) {
                problems.add('[$screen] raw ARB key shown: $key');
              }
              await (s.close ?? _popAll)(tester);
            }
          } finally {
            FlutterError.onError = reportError;
          }
          expect(problems, isEmpty, reason: problems.join('\n'));
        },
        seed: _seed(variant),
        timeout: const Timeout(Duration(minutes: 5)),
      );
    }
  });
}
