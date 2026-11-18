import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/media_progress_bar.dart';
import 'package:mediavore/core/widgets/offline_banner.dart';
import 'package:mediavore/features/home/presentation/pages/home_page.dart';
import 'package:mediavore/features/home/presentation/pages/in_progress_page.dart';
import 'package:mediavore/features/home/presentation/providers/home_session_provider.dart';
import 'package:mediavore/features/home/presentation/widgets/connect_tmdb_card.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_card.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_row.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_thumbnail.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

final _now = DateTime(2026, 11, 14, 21);

/// A series of the fake library.
class _Series {
  _Series(
    this.id,
    this.title, {
    this.episodes = 10,
    this.knowsEpisodeCount = true,
    this.seen = 3,
    this.lastActivityDaysAgo = 1,
  });

  final int id;
  final String title;

  /// Episodes of its single season.
  final int episodes;
  final bool knowsEpisodeCount;

  /// Episodes seen so far: the next one is `seen + 1`.
  int seen;
  int lastActivityDaysAgo;
}

/// In-memory repository behaving like the real one for the Home screen:
/// marking an episode queues the next one, or nothing when it was the last.
class _FakeHomeRepository extends MockMediaRepository {
  final Map<int, _Series> series = {};
  final List<MediaItem> firstList = [];
  final List<SeenItem> viewings = [];
  final Map<int, QuickAddItem> queue = {};
  int _nextId = 1;
  int refreshCalls = 0;

  void addSeries(_Series s) {
    series[s.id] = s;
    if (s.seen < s.episodes) {
      queue[s.id] = QuickAddItem(
        isarId: _nextId++,
        tmdbId: s.id,
        type: MediaType.tv,
        seasonNumber: 1,
        episodeNumber: s.seen + 1,
        insertedAt: _now.subtract(Duration(days: s.lastActivityDaysAgo)),
        title: s.title,
        runtime: 50,
      );
    }
  }

  @override
  Future<List<QuickAddItem>> getQuickAddItems() async => queue.values.toList();

  @override
  Future<List<InProgressItem>> getInProgressItems() async {
    final items = [
      for (final next in queue.values)
        InProgressItem(
          next: next,
          seenEpisodes: series[next.tmdbId]!.seen,
          totalEpisodes: series[next.tmdbId]!.knowsEpisodeCount
              ? series[next.tmdbId]!.episodes
              : null,
          progress: series[next.tmdbId]!.knowsEpisodeCount
              ? series[next.tmdbId]!.seen / series[next.tmdbId]!.episodes
              : null,
          lastActivity: _now.subtract(
            Duration(days: series[next.tmdbId]!.lastActivityDaysAgo),
          ),
          paused: series[next.tmdbId]!.lastActivityDaysAgo > 30,
        ),
    ];
    items.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return items;
  }

  @override
  Future<List<MediaItem>> getListMediaItems(String listName) async =>
      List.of(firstList);

  @override
  Future<void> markAsSeen(SeenItem item) async {
    final s = series[item.tmdbId]!;
    viewings.add(
      SeenItem(
        id: _nextId++,
        tmdbId: item.tmdbId,
        type: item.type,
        title: item.title,
        seenDate: item.seenDate,
        seasonNumber: item.seasonNumber,
        episodeNumber: item.episodeNumber,
      ),
    );
    s.seen = item.episodeNumber!;
    queue.remove(item.tmdbId);
    if (s.seen < s.episodes) {
      queue[s.id] = QuickAddItem(
        isarId: _nextId++,
        tmdbId: s.id,
        type: MediaType.tv,
        seasonNumber: 1,
        episodeNumber: s.seen + 1,
        insertedAt: item.seenDate,
        title: s.title,
      );
    }
  }

  @override
  Future<List<SeenItem>> getSeenItems() async => List.of(viewings);

  @override
  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type) async => [
    for (final viewing in viewings)
      if (viewing.tmdbId == tmdbId) viewing,
  ];

  @override
  Future<void> deleteSeenEntry(int id) async {
    final viewing = viewings.firstWhere((v) => v.id == id);
    viewings.remove(viewing);
    series[viewing.tmdbId]!.seen = viewing.episodeNumber! - 1;
  }

  @override
  Future<void> removeQuickAddItemById(int isarId) async =>
      queue.removeWhere((_, item) => item.isarId == isarId);

  @override
  Future<void> addQuickAddItem(QuickAddItem item) async =>
      queue.putIfAbsent(item.tmdbId, () => item);

  @override
  Future<void> refreshNotifiedItems({bool force = false}) async =>
      refreshCalls++;

  @override
  Future<void> refreshQuickAddItems() async {}
}

MediaItem _film(int id, String title) => MediaItem(
  id: id,
  title: title,
  overview: '',
  releaseDate: '2014-11-05',
  runtime: 169,
  voteAverage: 8.4,
);

void main() {
  late _FakeHomeRepository repository;
  late SearchProvider searchProvider;
  late MockSharedPreferences prefs;
  late HomeSessionProvider session;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    repository = _FakeHomeRepository();
    prefs = MockSharedPreferences();
    session = HomeSessionProvider();
    when(() => prefs.getInt(any())).thenReturn(null);
    when(() => prefs.getDouble(any())).thenReturn(null);
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.getString(any())).thenReturn(null);

    when(
      () => repository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(() => repository.getListEntries(any())).thenAnswer((_) async => []);
    when(
      () => repository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => repository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => repository.getMediaDetails(any(), type: any(named: 'type')),
    ).thenThrow(Exception('offline'));
  });

  tearDown(() => appMessageController.dismiss());

  Future<void> pumpHome(
    WidgetTester tester, {
    AppPalette palette = AppPalette.paper,
    Locale locale = const Locale('en'),
    String tmdbKey = 'key',
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    searchProvider = SearchProvider(repository);
    final settings = SettingsProvider(prefs, FakeTmdbCredentialStore(tmdbKey));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<HomeSessionProvider>.value(value: session),
        ],
        child: MaterialApp(
          theme: palette.toThemeData(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: AppMessageHost(child: child!),
          ),
          home: Scaffold(body: HomePage(clock: () => _now)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 20 series in progress, the three most recent first; two of them paused.
  void addTwentySeries({int paused = 0}) {
    for (var i = 1; i <= 20; i++) {
      repository.addSeries(
        _Series(
          i,
          'Show $i',
          lastActivityDaysAgo: i > 20 - paused ? 30 + i : i,
        ),
      );
    }
  }

  Finder markButton(int tmdbId) => find.descendant(
    of: find.byKey(ValueKey('home_resume_$tmdbId')),
    matching: find.byIcon(Icons.check),
  );

  group('HomePage header', () {
    testWidgets('should show the date, the title and the refresh button', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Saturday, November 14'), findsOneWidget);
      expect(find.text('Tonight'), findsOneWidget);
      expect(find.byTooltip('Refresh releases'), findsOneWidget);
    });

    testWidgets('should be written in French', (tester) async {
      repository.addSeries(_Series(1, 'Severance'));
      await pumpHome(tester, locale: const Locale('fr'));

      expect(find.text('Samedi 14 novembre'), findsOneWidget);
      expect(find.text('Ce soir'), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
      expect(find.text('Prochain : S1 É4 · 50m'), findsOneWidget);
    });

    testWidgets('should refresh the releases from the button', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byKey(const Key('home_refresh')));
      await tester.pumpAndSettle();

      expect(repository.refreshCalls, 1);
    });

    testWidgets('should tell when the app is offline', (tester) async {
      await pumpHome(tester);
      expect(find.byType(OfflineBanner), findsNothing);

      searchProvider.setOffline(true);
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(
        find.textContaining('releases will be refreshed', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('HomePage in progress', () {
    testWidgets(
      'should show 3 cards, 10 thumbnails, a +n tile and the paused row with 20 series',
      (tester) async {
        addTwentySeries(paused: 2);
        await pumpHome(tester);

        // 18 active: 3 in "Resume", 15 others of which 10 are shown.
        expect(find.byType(InProgressCard), findsNWidgets(3));
        for (final id in [1, 2, 3]) {
          expect(find.byKey(ValueKey('home_resume_$id')), findsOneWidget);
        }
        expect(find.text('Also in progress · 15'), findsOneWidget);
        expect(find.text('See all (18)'), findsOneWidget);
        expect(
          find.byType(InProgressThumbnail, skipOffstage: false),
          findsNWidgets(10),
        );
        expect(
          find.byKey(const Key('home_thumbnail_4'), skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_thumbnail_14'), skipOffstage: false),
          findsNothing,
        );
        final more = find.byType(MoreInProgressTile, skipOffstage: false);
        expect(more, findsOneWidget);
        expect(tester.widget<MoreInProgressTile>(more).count, 5);

        await tester.scrollUntilVisible(
          find.byKey(const Key('home_paused')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('2 paused'), findsOneWidget);
        expect(find.text('No activity for more than 30 days'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('should have no tile, no row and no section up to 3 series', (
      tester,
    ) async {
      for (var i = 1; i <= 3; i++) {
        repository.addSeries(_Series(i, 'Show $i'));
      }
      await pumpHome(tester);

      expect(find.byType(InProgressCard), findsNWidgets(3));
      expect(find.byKey(const Key('home_also_in_progress')), findsNothing);
      expect(find.byType(MoreInProgressTile), findsNothing);
      expect(find.byKey(const Key('home_paused')), findsNothing);
    });

    testWidgets(
      'should not offer type chips while only series are in progress',
      (tester) async {
        addTwentySeries();
        await pumpHome(tester);

        expect(find.byKey(const Key('home_also_in_progress')), findsOneWidget);
        expect(find.byType(FilterChipRow), findsNothing);
      },
    );

    testWidgets('should describe the next episode and the last activity', (
      tester,
    ) async {
      for (var i = 1; i <= 4; i++) {
        repository.addSeries(
          _Series(i, 'Show $i', seen: i, lastActivityDaysAgo: i + 1),
        );
      }
      await pumpHome(tester);

      expect(find.text('Next: S1 E2 · 50m'), findsOneWidget);
      expect(find.text('S1 E5 · 5 d ago'), findsOneWidget);
    });

    testWidgets(
      'should show no progress bar when the episode count is unknown',
      (tester) async {
        repository.addSeries(_Series(1, 'Known'));
        repository.addSeries(
          _Series(
            2,
            'Unknown',
            knowsEpisodeCount: false,
            lastActivityDaysAgo: 2,
          ),
        );
        await pumpHome(tester);

        Finder barOf(int id) => find.descendant(
          of: find.byKey(ValueKey('home_resume_$id')),
          matching: find.byType(MediaProgressBar),
        );
        expect(barOf(1), findsOneWidget);
        expect(tester.widget<MediaProgressBar>(barOf(1)).value, 0.3);
        expect(barOf(2), findsNothing);
      },
    );

    testWidgets(
      'should open the full list from "See all" and from the +n tile',
      (tester) async {
        addTwentySeries();
        await pumpHome(tester);

        await tester.tap(find.text('See all (20)'));
        await tester.pumpAndSettle();

        expect(find.byType(InProgressPage), findsOneWidget);
        expect(find.text('In progress · 20'), findsOneWidget);
        expect(session.inProgressPausedOnly, isFalse);
        expect(find.byKey(const ValueKey('in_progress_row_1')), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.byKey(const Key('home_more_in_progress')),
          find.byKey(const ValueKey('home_thumbnail_4')),
          const Offset(-300, 0),
        );
        await tester.tap(find.byKey(const Key('home_more_in_progress')));
        await tester.pumpAndSettle();

        expect(find.byType(InProgressPage), findsOneWidget);
      },
    );

    testWidgets(
      'should open the list on "Paused" from the paused row, and clear it from "See all"',
      (tester) async {
        addTwentySeries(paused: 2);
        await pumpHome(tester);

        await tester.scrollUntilVisible(
          find.byKey(const Key('home_paused')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('home_paused')));
        await tester.pumpAndSettle();

        expect(find.byType(InProgressPage), findsOneWidget);
        expect(session.inProgressPausedOnly, isTrue);
        expect(find.byType(InProgressRow), findsNWidgets(2));

        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('See all (18)'));
        await tester.pumpAndSettle();

        expect(session.inProgressPausedOnly, isFalse);
      },
    );
  });

  group('HomePage mark as seen', () {
    testWidgets('should move the card on to the next episode', (tester) async {
      repository.addSeries(_Series(1, 'Severance', seen: 3));
      await pumpHome(tester);
      expect(find.text('Next: S1 E4 · 50m'), findsOneWidget);

      await tester.tap(markButton(1));
      await tester.pumpAndSettle();

      expect(find.text('Next: S1 E5'), findsOneWidget);
      expect(find.text('Next: S1 E4 · 50m'), findsNothing);
      expect(repository.viewings.single.episodeNumber, 4);
      expect(repository.viewings.single.seasonNumber, 1);
      expect(find.text('S1 E4 seen · Severance'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('should remove the card when the series is finished', (
      tester,
    ) async {
      repository.addSeries(_Series(1, 'Severance', seen: 9, episodes: 10));
      repository.addSeries(_Series(2, 'The Bear', lastActivityDaysAgo: 2));
      await pumpHome(tester);
      expect(find.byType(InProgressCard), findsNWidgets(2));

      await tester.tap(markButton(1));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home_resume_1')), findsNothing);
      expect(find.byKey(const ValueKey('home_resume_2')), findsOneWidget);
    });

    testWidgets('should restore the episode and the card on Undo', (
      tester,
    ) async {
      repository.addSeries(_Series(1, 'Severance', seen: 9, episodes: 10));
      await pumpHome(tester);

      await tester.tap(markButton(1));
      await tester.pumpAndSettle();
      expect(find.byType(InProgressCard), findsNothing);
      expect(repository.viewings, hasLength(1));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.viewings, isEmpty);
      expect(find.byKey(const ValueKey('home_resume_1')), findsOneWidget);
      expect(find.text('Next: S1 E10 · 50m'), findsOneWidget);
      expect(find.text('S1 E10 seen · Severance'), findsNothing);
    });

    testWidgets(
      'should go back one episode on Undo in the middle of a series',
      (tester) async {
        repository.addSeries(_Series(1, 'Severance', seen: 3));
        await pumpHome(tester);

        await tester.tap(markButton(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();

        expect(find.text('Next: S1 E4 · 50m'), findsOneWidget);
        expect(repository.queue.values.single.episodeNumber, 4);
        expect(repository.viewings, isEmpty);
      },
    );

    testWidgets('should say it in French', (tester) async {
      repository.addSeries(_Series(1, 'Severance', seen: 3));
      await pumpHome(tester, locale: const Locale('fr'));

      await tester.tap(markButton(1));
      await tester.pumpAndSettle();

      expect(find.text('S1 É4 vu · Severance'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });
  });

  group('HomePage to watch tonight', () {
    testWidgets(
      'should show 3 posters for a film-only profile with 5 films to watch',
      (tester) async {
        repository.firstList.addAll([
          for (var i = 1; i <= 5; i++) _film(i, 'Film $i'),
        ]);
        await pumpHome(tester);

        expect(find.byType(InProgressCard), findsNothing);
        expect(find.text('Resume'), findsNothing);
        expect(find.text('To watch tonight'), findsOneWidget);
        expect(
          find.text('From your list "Watchlist" · 5 titles not seen yet'),
          findsOneWidget,
        );
        expect(find.byType(MediaPosterCard), findsNWidgets(3));
        for (final id in [1, 2, 3]) {
          expect(
            find.byKey(ValueKey('home_tonight_movie_$id')),
            findsOneWidget,
          );
        }
        expect(find.byKey(const Key('home_empty')), findsNothing);
      },
    );

    testWidgets('should offer the next three with "Another idea"', (
      tester,
    ) async {
      repository.firstList.addAll([
        for (var i = 1; i <= 5; i++) _film(i, 'Film $i'),
      ]);
      await pumpHome(tester);

      await tester.tap(find.text('Another idea'));
      await tester.pumpAndSettle();

      for (final id in [4, 5, 1]) {
        expect(find.byKey(ValueKey('home_tonight_movie_$id')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('home_tonight_movie_2')), findsNothing);
    });

    testWidgets('should not offer "Another idea" with 3 titles or fewer', (
      tester,
    ) async {
      repository.firstList.addAll([_film(1, 'Film 1'), _film(2, 'Film 2')]);
      await pumpHome(tester);

      expect(find.byType(MediaPosterCard), findsNWidgets(2));
      expect(find.text('Another idea'), findsNothing);
    });

    testWidgets('should leave out titles already seen or started', (
      tester,
    ) async {
      repository.firstList.addAll([
        _film(1, 'Seen film'),
        _film(2, 'New film'),
        const MediaItem(
          id: 3,
          title: 'Started show',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.tv,
        ),
      ]);
      repository.viewings.addAll([
        SeenItem(
          id: 90,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Seen film',
          seenDate: _now,
        ),
        SeenItem(
          id: 91,
          tmdbId: 3,
          type: MediaType.tv,
          title: 'Started show',
          seenDate: _now,
          seasonNumber: 1,
          episodeNumber: 1,
        ),
      ]);
      await pumpHome(tester);

      expect(find.byType(MediaPosterCard), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home_tonight_movie_2')),
        findsOneWidget,
      );
      expect(
        find.text('From your list "Watchlist" · 1 title not seen yet'),
        findsOneWidget,
      );
    });

    testWidgets('should sit below "Resume"', (tester) async {
      repository.addSeries(_Series(1, 'Severance'));
      repository.firstList.add(_film(1, 'Film 1'));
      await pumpHome(tester);

      expect(
        tester.getTopLeft(find.text('To watch tonight')).dy,
        greaterThan(tester.getBottomLeft(find.byType(InProgressCard)).dy),
      );
    });

    testWidgets('should lead to Together from "Choose together"', (
      tester,
    ) async {
      repository.firstList.add(_film(1, 'Film 1'));
      await pumpHome(tester);

      await tester.tap(find.text('Choose together'));
      await tester.pumpAndSettle();

      expect(searchProvider.selectedTab, AppTab.together);
    });
  });

  group('HomePage empty and without TMDB key', () {
    testWidgets(
      'should show the "Nothing planned tonight" card leading to Discover',
      (tester) async {
        await pumpHome(tester);

        expect(find.byKey(const Key('home_empty')), findsOneWidget);
        expect(find.text('Nothing planned tonight.'), findsOneWidget);
        expect(
          find.text(
            'Add films or series to your list "Watchlist" to find them here.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Discover titles'));
        await tester.pumpAndSettle();

        expect(searchProvider.selectedTab, AppTab.discover);
      },
    );

    testWidgets('should say it in French, without the former text', (
      tester,
    ) async {
      await pumpHome(tester, locale: const Locale('fr'));

      expect(find.text('Rien de prévu ce soir.'), findsOneWidget);
      expect(find.text('Découvrir des titres'), findsOneWidget);
      expect(find.textContaining('Rien en cours'), findsNothing);
    });

    testWidgets(
      'should show "Connect TMDB" instead of the network blocks without a key',
      (tester) async {
        await pumpHome(tester, tmdbKey: '');

        expect(find.byType(ConnectTmdbCard), findsOneWidget);
        expect(find.text('Connect TMDB'), findsOneWidget);
        expect(find.byKey(const Key('home_empty')), findsNothing);
        expect(find.byKey(const Key('home_upcoming')), findsNothing);
        expect(find.byKey(const Key('home_refresh')), findsNothing);

        await tester.tap(find.text('Connect to TMDB'));
        await tester.pumpAndSettle();

        expect(find.byType(TmdbCredentialPage), findsOneWidget);
      },
    );

    testWidgets('should keep what is stored locally without a key', (
      tester,
    ) async {
      repository.addSeries(_Series(1, 'Severance'));
      await pumpHome(tester, tmdbKey: '');

      expect(find.byType(InProgressCard), findsOneWidget);
      expect(find.byType(ConnectTmdbCard), findsOneWidget);
    });
  });

  group('HomePage rendering', () {
    const longTitle =
        'The Incredibly Long and Winding Chronicle of a Family Nobody Asked '
        'About, Extended Edition';

    void fill() {
      for (var i = 1; i <= 20; i++) {
        repository.addSeries(
          _Series(
            i,
            i.isOdd ? '$longTitle $i' : 'Show $i',
            lastActivityDaysAgo: i > 18 ? 40 : i,
            knowsEpisodeCount: i % 4 != 0,
          ),
        );
      }
      repository.firstList.addAll([
        for (var i = 1; i <= 5; i++) _film(i, i == 1 ? longTitle : 'Film $i'),
      ]);
    }

    for (final palette in testPalettes) {
      testWidgets('should render every block on ${palette.id.name}', (
        tester,
      ) async {
        fill();
        await pumpHome(tester, palette: palette);

        expect(tester.takeException(), isNull);
        expect(
          Theme.of(tester.element(find.byType(HomePage))).brightness,
          palette.brightness,
        );
        expect(find.byType(InProgressCard), findsNWidgets(3));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'should not overflow on a small phone with large text on ${palette.id.name}',
        (tester) async {
          fill();
          await pumpHome(
            tester,
            palette: palette,
            textScale: 2,
            size: const Size(320, 568),
            locale: const Locale('fr'),
          );

          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -1500),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('should keep every tap target at 48 dp and labeled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      fill();
      await pumpHome(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('should name the mark-as-seen button for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      repository.addSeries(_Series(1, 'Severance'));
      await pumpHome(tester);

      expect(
        find.bySemanticsLabel('Mark S1 E4 of Severance as seen'),
        findsOneWidget,
      );
      final size = tester.getSize(markButton(1));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });
  });
}
