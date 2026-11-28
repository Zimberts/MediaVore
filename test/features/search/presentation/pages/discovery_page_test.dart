import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/liked_item_info.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/offline_banner.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/discovery/presentation/pages/swiper_page.dart';
import 'package:mediavore/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:mediavore/features/discovery/presentation/widgets/because_you_row.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/search_filter_sheet.dart';
import 'package:mediavore/features/search/presentation/widgets/search_people_row.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

MediaItem _item(int id, String title, {MediaType type = MediaType.movie}) =>
    MediaItem(
      id: id,
      title: title,
      overview: '',
      releaseDate: '2021-05-01',
      mediaType: type,
      voteAverage: 8.5,
    );

void main() {
  late MockMediaRepository repository;
  late MockSharedPreferences prefs;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  late DiscoveryProvider discoveryProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(const SearchFilters());
  });

  void stubTrending(List<MediaItem> Function(int page) pageOf) {
    when(
      () => repository.getTrendingMedia(page: any(named: 'page')),
    ).thenAnswer(
      (invocation) async => pageOf(invocation.namedArguments[#page] as int),
    );
  }

  void stubTrendingThrows(Object error) {
    when(
      () => repository.getTrendingMedia(page: any(named: 'page')),
    ).thenThrow(error);
  }

  void stubSearch(List<MediaItem> Function(String query, MediaType type) of) {
    when(
      () => repository.searchMedia(
        any(),
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        originalLanguage: any(named: 'originalLanguage'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((invocation) async {
      if (invocation.namedArguments[#page] != 1) return [];
      return of(
        invocation.positionalArguments.first as String,
        invocation.namedArguments[#type] as MediaType,
      );
    });
  }

  void stubDiscover(List<MediaItem> Function(MediaType type) of) {
    when(
      () => repository.discoverMedia(
        page: any(named: 'page'),
        filters: any(named: 'filters'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        originalLanguage: any(named: 'originalLanguage'),
        type: any(named: 'type'),
        sortBy: any(named: 'sortBy'),
      ),
    ).thenAnswer((invocation) async {
      if (invocation.namedArguments[#page] != 1) return [];
      return of(invocation.namedArguments[#type] as MediaType);
    });
  }

  setUp(() {
    repository = MockMediaRepository();
    prefs = MockSharedPreferences();
    when(() => prefs.getInt(any())).thenReturn(null);
    when(() => prefs.getDouble(any())).thenReturn(null);
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.getString(any())).thenReturn(null);
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async => true);

    when(
      () => repository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(() => repository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => repository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => repository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => repository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repository.getNotifiedItems()).thenAnswer((_) async => []);
    stubTrending((_) => []);

    searchProvider = SearchProvider(repository);
    settingsProvider = SettingsProvider(prefs, FakeTmdbCredentialStore());
    discoveryProvider = DiscoveryProvider();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    AppPalette palette = AppPalette.paper,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
          ChangeNotifierProvider<DiscoveryProvider>.value(
            value: discoveryProvider,
          ),
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
            child: child!,
          ),
          home: const Scaffold(body: DiscoveryPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    // Debounce.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
  }

  String resultsTitle(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const Key('discovery_results_title')),
          matching: find.byType(Text),
        ),
      )
      .data!;

  group('DiscoveryPage Explore', () {
    testWidgets('should show the trends of the week without query nor filter', (
      tester,
    ) async {
      stubTrending(
        (page) => page == 1
            ? [_item(1, 'Movie 1'), _item(2, 'TV 1', type: MediaType.tv)]
            : [],
      );

      await pumpPage(tester);

      expect(find.text('Discover'), findsOneWidget);
      expect(resultsTitle(tester), 'Trending this week');
      expect(find.text('Movie 1'), findsOneWidget);
      expect(find.text('TV 1'), findsOneWidget);
      expect(find.byType(MediaPosterCard), findsNWidgets(2));
      verifyNever(
        () => repository.discoverMedia(
          page: any(named: 'page'),
          type: any(named: 'type'),
        ),
      );
    });

    testWidgets('should lay the posters out on 3 columns', (tester) async {
      stubTrending(
        (page) => page == 1
            ? [for (var i = 1; i <= 7; i++) _item(i, 'Movie $i')]
            : [],
      );

      await pumpPage(tester);

      final tops = [
        for (var i = 1; i <= 4; i++) tester.getTopLeft(find.text('Movie $i')),
      ];
      final first = tester.getRect(find.byType(MediaPosterCard).at(0));
      final fourth = tester.getRect(find.byType(MediaPosterCard).at(3));
      expect(tester.getRect(find.byType(MediaPosterCard).at(2)).top, first.top);
      expect(fourth.top, greaterThan(first.top));
      expect(fourth.left, first.left);
      expect(tops, hasLength(4));
      // No list / grid / size picker on this screen any more.
      expect(find.byIcon(Icons.grid_on), findsNothing);
      expect(find.byIcon(Icons.list), findsNothing);
    });

    testWidgets(
      'should search from the permanent field after the debounce and show "Results"',
      (tester) async {
        stubTrending((page) => page == 1 ? [_item(1, 'Trend')] : []);
        stubSearch(
          (query, type) => type == MediaType.movie
              ? [_item(10, 'Dune')]
              : [_item(11, 'Dune: Prophecy', type: MediaType.tv)],
        );
        await pumpPage(tester);

        // The field is there from the start: no icon to tap, no other page.
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Films, series'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'dune');
        await tester.pump(const Duration(milliseconds: 300));
        verifyNever(
          () => repository.searchMedia(
            any(),
            page: any(named: 'page'),
            type: any(named: 'type'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Dune'), findsWidgets);
        expect(find.text('Dune: Prophecy'), findsOneWidget);
        expect(find.text('Trend'), findsNothing);
        expect(resultsTitle(tester), 'Results');
        expect(find.byType(DiscoveryPage), findsOneWidget);
        // Relevance: the exact title comes first.
        expect(searchProvider.items.first.title, 'Dune');

        // Once the last page is loaded the count is known.
        await searchProvider.fetchNextPage();
        await tester.pump();
        expect(resultsTitle(tester), 'Results · 2');
      },
    );

    testWidgets('should go back to the trends when the query is cleared', (
      tester,
    ) async {
      stubTrending((page) => page == 1 ? [_item(1, 'Trend')] : []);
      stubSearch((query, type) => [_item(10, 'Dune')]);
      await pumpPage(tester);
      expect(find.byKey(const Key('discovery_search_clear')), findsNothing);

      await type(tester, 'dune');
      expect(find.text('Trend'), findsNothing);

      await tester.tap(find.byKey(const Key('discovery_search_clear')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(find.text('Trend'), findsOneWidget);
      expect(resultsTitle(tester), 'Trending this week');
    });

    testWidgets('should keep the query when the page is rebuilt', (
      tester,
    ) async {
      stubSearch((query, type) => [_item(10, 'Dune')]);
      await pumpPage(tester);
      await type(tester, 'dune');

      // Leaving and coming back to the tab rebuilds the page in the worst
      // case: the query comes back from the provider.
      await tester.pumpWidget(const SizedBox());
      await pumpPage(tester);

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'dune',
      );
    });

    testWidgets('should filter by type from the chips, without a Books chip', (
      tester,
    ) async {
      stubTrending((page) => page == 1 ? [_item(1, 'Trend')] : []);
      stubDiscover(
        (type) => type == MediaType.tv
            ? [_item(20, 'Popular series', type: MediaType.tv)]
            : [_item(21, 'Popular film')],
      );
      await pumpPage(tester);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Films'), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.text('Books'), findsNothing);

      await tester.tap(find.text('Series'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(searchProvider.filterType, MediaType.tv);
      expect(find.text('Popular series'), findsOneWidget);
      expect(find.text('Trend'), findsNothing);
      expect(resultsTitle(tester), 'Results');
      verify(
        () => repository.discoverMedia(
          type: MediaType.tv,
          filters: any(named: 'filters'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          sortBy: any(named: 'sortBy'),
        ),
      ).called(1);

      await tester.tap(find.text('All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(searchProvider.filterType, isNull);
      expect(find.text('Trend'), findsOneWidget);
    });

    testWidgets('should keep the other filters when the type changes', (
      tester,
    ) async {
      stubDiscover((type) => []);
      searchProvider.setFilters(minRating: 7, genreIds: [18]);
      await pumpPage(tester);

      await tester.tap(find.text('Films'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(searchProvider.filterType, MediaType.movie);
      expect(searchProvider.minRating, 7);
      expect(searchProvider.genreIds, [18]);
    });

    testWidgets('should still open the filters', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('discovery_filters')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchFilterSheet), findsOneWidget);
    });

    testWidgets('should load the next page when scrolling to the end', (
      tester,
    ) async {
      stubTrending(
        (page) => page <= 2
            ? [
                for (var i = 1; i <= 18; i++)
                  _item(page * 100 + i, 'Movie $page-$i'),
              ]
            : [],
      );
      await pumpPage(tester);
      verifyNever(() => repository.getTrendingMedia(page: 2));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => repository.getTrendingMedia(page: 2)).called(1);
      expect(searchProvider.items, hasLength(36));
    });

    testWidgets('should say when nothing matches and offer to clear filters', (
      tester,
    ) async {
      stubSearch((query, type) => []);
      searchProvider.setFilters(minRating: 9);
      await pumpPage(tester);
      await type(tester, 'zzzz');

      expect(find.text('No results for "zzzz".'), findsOneWidget);
      expect(resultsTitle(tester), 'Results · 0');

      await tester.tap(find.byKey(const Key('discovery_clear_filters')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(searchProvider.hasActiveFilters, isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'zzzz',
      );
    });

    testWidgets('should be written in French', (tester) async {
      stubTrending((page) => page == 1 ? [_item(1, 'Trend')] : []);
      await pumpPage(tester, locale: const Locale('fr'));

      expect(find.text('Découvrir'), findsOneWidget);
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Swiper'), findsOneWidget);
      expect(find.text('Films, séries'), findsOneWidget);
      expect(find.text('Tout'), findsOneWidget);
      expect(find.text('Séries'), findsOneWidget);
      expect(find.text('Tendances de la semaine'), findsOneWidget);
    });
  });

  group('DiscoveryPage states', () {
    testWidgets('should show a spinner while the first page loads', (
      tester,
    ) async {
      when(
        () => repository.getTrendingMedia(page: any(named: 'page')),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return [_item(1, 'Trend')];
      });

      await pumpPage(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The search stays usable meanwhile.
      expect(find.byType(TextField), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Trend'), findsOneWidget);
    });

    testWidgets(
      'should lead straight to the TMDB credential page when the key is missing',
      (tester) async {
        stubTrendingThrows(const ConfigurationException('missing key'));
        await pumpPage(tester);

        expect(
          find.text(searchErrorMessage(SearchErrorType.missingApiKey)),
          findsOneWidget,
        );
        expect(find.byType(OfflineBanner), findsNothing);

        await tester.tap(find.byKey(const Key('discovery_connect_tmdb')));
        await tester.pumpAndSettle();

        expect(find.byType(TmdbCredentialPage), findsOneWidget);
      },
    );

    // Regression test for #245: saving a key (first-launch screen or
    // Settings) must reload Discover instead of leaving the error.
    testWidgets('should reload when a TMDB key is saved', (tester) async {
      stubTrendingThrows(const ConfigurationException('missing key'));
      await pumpPage(tester);
      expect(
        find.text(searchErrorMessage(SearchErrorType.missingApiKey)),
        findsOneWidget,
      );

      stubTrending((page) => page == 1 ? [_item(1, 'Loaded')] : []);
      await settingsProvider.setTmdbApiKey('new_key');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(searchErrorMessage(SearchErrorType.missingApiKey)),
        findsNothing,
      );
      expect(find.text('Loaded'), findsOneWidget);
    });

    // Regression test for #463: removing the key must drop the results it
    // loaded and invite to connect TMDB again.
    testWidgets('should invite to connect TMDB when the key is removed', (
      tester,
    ) async {
      await settingsProvider.setTmdbApiKey('old_key');
      stubTrending((page) => page == 1 ? [_item(1, 'Loaded')] : []);
      await pumpPage(tester);
      expect(find.text('Loaded'), findsOneWidget);

      stubTrendingThrows(const ConfigurationException('missing key'));
      await settingsProvider.setTmdbApiKey('');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Loaded'), findsNothing);
      expect(find.byKey(const Key('discovery_connect_tmdb')), findsOneWidget);
    });

    testWidgets('should show the offline banner and a retry button', (
      tester,
    ) async {
      stubTrendingThrows(const NetworkException('offline'));
      await pumpPage(tester);

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(
        find.text(searchErrorMessage(SearchErrorType.offline)),
        findsOneWidget,
      );

      // Back online: retry loads the results and clears the error.
      stubTrending((page) => page == 1 ? [_item(1, 'Trend')] : []);
      await tester.tap(find.byKey(const Key('discovery_retry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('discovery_retry')), findsNothing);
      expect(find.byType(OfflineBanner), findsNothing);
      expect(find.text('Trend'), findsOneWidget);
    });

    testWidgets('should offer to retry when TMDB is down', (tester) async {
      stubTrendingThrows(const ServerException('down', 503));
      await pumpPage(tester);

      expect(
        find.text(searchErrorMessage(SearchErrorType.server)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('discovery_retry')), findsOneWidget);
      expect(find.byKey(const Key('discovery_connect_tmdb')), findsNothing);
    });
  });

  group('DiscoveryPage Swipe', () {
    testWidgets('should show swipe screen and come back to Explore', (
      tester,
    ) async {
      stubTrending((page) => page == 1 ? [_item(1, 'Trend')] : []);
      await pumpPage(tester);
      expect(find.byType(AppSegmented<DiscoverMode>), findsOneWidget);

      await tester.tap(find.text('Swipe'));
      await tester.pumpAndSettle();

      expect(discoveryProvider.mode, DiscoverMode.swipe);
      expect(find.byType(SwiperPage), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Trend'), findsOneWidget);
    });

    testWidgets(
      'should hide swipe mode segment when swipeModeEnabled is false',
      (tester) async {
        await settingsProvider.setSwipeModeEnabled(false);
        stubTrending((page) => page == 1 ? [_item(1, 'Trend')] : []);
        await pumpPage(tester);

        expect(find.byType(AppSegmented<DiscoverMode>), findsNothing);
        expect(find.text('Swipe'), findsNothing);
      },
    );
  });

  group('DiscoveryPage rendering', () {
    const longTitle =
        'The Incredibly Long and Winding Chronicle of a Family Nobody Asked '
        'About, Extended Edition';

    for (final palette in testPalettes) {
      testWidgets('should render with long titles on ${palette.id.name}', (
        tester,
      ) async {
        stubTrending(
          (page) => page == 1
              ? [for (var i = 1; i <= 9; i++) _item(i, '$longTitle $i')]
              : [],
        );
        await pumpPage(tester, palette: palette);

        expect(tester.takeException(), isNull);
        expect(
          Theme.of(tester.element(find.byType(DiscoveryPage))).brightness,
          palette.brightness,
        );
        expect(find.byType(MediaPosterCard), findsWidgets);
      });

      testWidgets(
        'should not overflow on a small phone with large text on ${palette.id.name}',
        (tester) async {
          stubTrending(
            (page) => page == 1
                ? [for (var i = 1; i <= 9; i++) _item(i, '$longTitle $i')]
                : [],
          );
          await pumpPage(
            tester,
            palette: palette,
            size: const Size(320, 568),
            textScale: 2,
            locale: const Locale('fr'),
          );

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('should keep the results visible above the keyboard', (
      tester,
    ) async {
      stubTrending(
        (page) => page == 1
            ? [for (var i = 1; i <= 9; i++) _item(i, 'Movie $i')]
            : [],
      );
      await pumpPage(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      await tester.tap(find.byType(TextField));
      await tester.pump();

      // The page ends above the keyboard and still shows posters there.
      final page = tester.getRect(find.byType(DiscoveryPage));
      expect(page.bottom, lessThanOrEqualTo(844 - 300));
      expect(find.byType(MediaPosterCard).hitTestable(), findsWidgets);
      expect(
        tester.getRect(find.byType(MediaPosterCard).first).top,
        lessThan(page.bottom),
      );
    });

    testWidgets('should keep every tap target at 48 dp and labeled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      stubTrending(
        (page) => page == 1
            ? [for (var i = 1; i <= 9; i++) _item(i, 'Movie $i')]
            : [],
      );
      await pumpPage(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('shows people row above results when people results exist', (
      tester,
    ) async {
      stubSearch((query, type) => [_item(1, 'Dune')]);
      when(() => repository.searchPeople('Villeneuve')).thenAnswer(
        (_) async => const [
          PersonSummary(
            id: 100,
            name: 'Denis Villeneuve',
            knownForDepartment: 'Directing',
          ),
        ],
      );

      await pumpPage(tester);

      await tester.enterText(
        find.byKey(const Key('discovery_search_field')),
        'Villeneuve',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byType(SearchPeopleRow), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Denis Villeneuve'), findsOneWidget);
      expect(find.text('Dune'), findsWidgets);
    });

    testWidgets('shows "Because you..." row in trending mode when available', (
      tester,
    ) async {
      when(() => repository.getLikedItems()).thenAnswer(
        (_) async => const [
          LikedItemInfo(tmdbId: 438631, type: MediaType.movie, title: 'Dune'),
        ],
      );
      when(
        () => repository.getRecommendedMedia(438631, MediaType.movie),
      ).thenAnswer(
        (_) async => [
          _item(10, 'Rec 1'),
          _item(20, 'Rec 2'),
          _item(30, 'Rec 3'),
        ],
      );

      stubTrending((page) => [_item(1, 'Trending 1')]);

      await pumpPage(tester);
      await searchProvider.loadBecauseYouRecommendations();
      await tester.pumpAndSettle();

      expect(find.byType(BecauseYouRow), findsOneWidget);
      expect(find.text('Because you liked Dune'), findsOneWidget);
      expect(find.text('Rec 1'), findsOneWidget);
      expect(find.text('Trending this week'), findsOneWidget);
    });
  });

  testWidgets('DiscoveryPage displays active filter badge and removable chips', (
    WidgetTester tester,
  ) async {
    when(
      () => repository.discoverMedia(
        page: any(named: 'page'),
        filters: any(named: 'filters'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        originalLanguage: any(named: 'originalLanguage'),
        type: any(named: 'type'),
        sortBy: any(named: 'sortBy'),
      ),
    ).thenAnswer((_) async => []);

    searchProvider.setFilters(
      filters: const SearchFilters(type: MediaType.movie, minRating: 7.0),
    );

    await pumpPage(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Filter badge should show count '2'
    expect(find.text('2'), findsOneWidget);

    // Active filter chips should be visible (Movies, Rating 7+, and Clear all)
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Rating 7+'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);

    // Remove the Movies filter by deleting its chip
    final moviesChip = tester.widget<InputChip>(
      find.widgetWithText(InputChip, 'Movies'),
    );
    moviesChip.onDeleted?.call();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Type filter should now be null, badge should show '1'
    expect(searchProvider.filters.type, isNull);
    expect(find.text('1'), findsOneWidget);
  });

  group('DiscoveryPage scroll to top', () {
    List<MediaItem> manyItems(int page) =>
        page == 1 ? [for (var i = 1; i <= 45; i++) _item(i, 'Movie $i')] : [];

    ScrollController scrollControllerOf(WidgetTester tester) => tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;

    double scrollToTopOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(const Key('discovery_scroll_to_top')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('should hide the scroll-to-top button initially and when '
        'scrolling down', (tester) async {
      stubTrending(manyItems);
      await pumpPage(tester);

      expect(scrollToTopOpacity(tester), 0);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1800));
      await tester.pumpAndSettle();

      expect(scrollControllerOf(tester).position.pixels, greaterThan(1700));
      expect(scrollToTopOpacity(tester), 0);
    });

    testWidgets('should show the scroll-to-top button when scrolling up after '
        'two viewports and scroll to top on tap', (tester) async {
      stubTrending(manyItems);
      await pumpPage(tester);

      // Scroll down past 2 * 844 = 1688 px.
      scrollControllerOf(tester).position.jumpTo(2200);
      await tester.pump();
      expect(scrollToTopOpacity(tester), 0);

      // Scroll up: button appears.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(scrollToTopOpacity(tester), 1);
      expect(find.byTooltip('Scroll to top'), findsOneWidget);

      // Tap button: animates to top and disappears.
      await tester.tap(find.byKey(const Key('discovery_scroll_to_top')));
      await tester.pumpAndSettle();

      expect(scrollControllerOf(tester).position.pixels, 0);
      expect(scrollToTopOpacity(tester), 0);
    });

    testWidgets(
      'should hide the scroll-to-top button when scrolling back down',
      (tester) async {
        stubTrending(manyItems);
        await pumpPage(tester);

        scrollControllerOf(tester).position.jumpTo(2200);
        await tester.pump();

        // Scroll up -> visible.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
        await tester.pumpAndSettle();
        expect(scrollToTopOpacity(tester), 1);

        // Scroll down -> hidden.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(scrollToTopOpacity(tester), 0);
      },
    );

    testWidgets('should scroll to top when the Discover tab is reselected '
        'while scrolled down', (tester) async {
      stubTrending(manyItems);
      searchProvider.setSelectedTab(AppTab.discover);
      await pumpPage(tester);

      scrollControllerOf(tester).position.jumpTo(1500);
      await tester.pump();
      expect(scrollControllerOf(tester).position.pixels, 1500);

      searchProvider.reselectTab(AppTab.discover);
      await tester.pumpAndSettle();

      expect(scrollControllerOf(tester).position.pixels, 0);
    });

    testWidgets('should focus the search field when the Discover tab is '
        'reselected at the top', (tester) async {
      stubTrending(manyItems);
      searchProvider.setSelectedTab(AppTab.discover);
      await pumpPage(tester);

      final field = tester.widget<TextField>(
        find.byKey(const Key('discovery_search_field')),
      );
      expect(field.focusNode?.hasFocus, isFalse);

      searchProvider.reselectTab(AppTab.discover);
      await tester.pump();

      expect(field.focusNode?.hasFocus, isTrue);
    });

    testWidgets('should scroll to top when tapping the status bar on iOS', (
      tester,
    ) async {
      stubTrending(manyItems);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
            ChangeNotifierProvider<DiscoveryProvider>.value(
              value: discoveryProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppPalette.paper.toThemeData(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: 44)),
              child: child!,
            ),
            home: const DiscoveryPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      scrollControllerOf(tester).position.jumpTo(1500);
      await tester.pump();
      expect(scrollControllerOf(tester).position.pixels, 1500);

      // Trigger iOS status bar tap.
      tester.simulateStatusBarTap();
      await tester.pumpAndSettle();

      expect(scrollControllerOf(tester).position.pixels, 0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('should not show the scroll-to-top button in Swipe mode', (
      tester,
    ) async {
      stubTrending(manyItems);
      await pumpPage(tester);

      discoveryProvider.setMode(DiscoverMode.swipe);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discovery_scroll_to_top')), findsNothing);
    });
  });
}
