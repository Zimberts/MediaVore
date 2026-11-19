import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() async {
    registerFallbackValue(MediaType.movie);
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('fr', null);
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    when(
      () => mockMediaRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockMediaRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getListPreviews(
        any(),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getLikedEntries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getNotifiedItems(),
    ).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockMediaRepository);
    settingsProvider = SettingsProvider(
      mockSharedPreferences,
      FakeTmdbCredentialStore(),
    );

    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerSingleton<MediaRepository>(mockMediaRepository);

    when(
      () => mockMediaRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest({Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: AppPalette.paper.toThemeData(),
        home: const SeenHistoryPage(),
      ),
    );
  }

  testWidgets('displays empty message when no items seen', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No items seen yet.'), findsOneWidget);
  });

  testWidgets('empty state offers a search action that opens Discover', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    searchProvider.setSelectedTab(AppTab.library);

    expect(
      find.text('Mark a movie or an episode as seen to start your history.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Search a movie or series'));
    expect(searchProvider.selectedTab, AppTab.discover);
  });

  testWidgets(
    'displays grouped list of seen items, duration and liked status',
    (tester) async {
      final seenDate = DateTime(2023, 10, 1);
      final seenItems = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Movie A',
          seenDate: seenDate,
          runtime: 130, // 2 h 10
        ),
        SeenItem(
          id: 2,
          tmdbId: 2,
          type: MediaType.tv,
          title: 'Show B',
          seenDate: seenDate,
          seasonNumber: 1,
          episodeNumber: 1,
        ),
      ];

      when(
        () => mockMediaRepository.getSeenItems(),
      ).thenAnswer((_) async => seenItems);
      when(
        () => mockMediaRepository.getLikedEntries(),
      ).thenAnswer((_) async => ['1:movie']);

      await searchProvider.loadAllSeenStatus();
      await searchProvider.loadLikedStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Movie A'), findsOneWidget);
      expect(find.text('Show B'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Check group header
      expect(find.text('October 1, 2023 · 2 items · 2 h 10'), findsOneWidget);
    },
  );

  testWidgets(
    'day with 2 episodes of 50 min and 1 movie of 1h55 displays « 3 éléments · 3 h 35 »',
    (tester) async {
      final seenDate = DateTime(2026, 11, 16);
      final seenItems = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Film 1h55',
          seenDate: seenDate,
          runtime: 115,
        ),
        SeenItem(
          id: 2,
          tmdbId: 2,
          type: MediaType.tv,
          title: 'Série Épisode 1',
          seenDate: seenDate,
          seasonNumber: 1,
          episodeNumber: 1,
          runtime: 50,
        ),
        SeenItem(
          id: 3,
          tmdbId: 2,
          type: MediaType.tv,
          title: 'Série Épisode 2',
          seenDate: seenDate,
          seasonNumber: 1,
          episodeNumber: 2,
          runtime: 50,
        ),
      ];

      when(
        () => mockMediaRepository.getSeenItems(),
      ).thenAnswer((_) async => seenItems);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();

      // In French, header displays: "Aujourd'hui · 3 éléments · 3 h 35"
      expect(find.textContaining('3 éléments · 3 h 35'), findsOneWidget);
    },
  );

  testWidgets(
    'design v1.5: swiping does NOT delete; two voluntary gestures required (menu then dialog)',
    (tester) async {
      final seenDate = DateTime(2023, 10, 1);
      final seenItems = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Movie A',
          seenDate: seenDate,
        ),
      ];

      when(
        () => mockMediaRepository.getSeenItems(),
      ).thenAnswer((_) async => seenItems);
      when(
        () => mockMediaRepository.deleteSeenEntry(any()),
      ).thenAnswer((_) async {});

      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Movie A'), findsOneWidget);

      // Swiping does nothing (no Dismissible)
      await tester.drag(find.text('Movie A'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Remove log?'), findsNothing);
      verifyNever(() => mockMediaRepository.deleteSeenEntry(any()));

      // Voluntary gesture 1: Open item menu
      await tester.tap(find.byKey(const Key('history_item_menu_1')));
      await tester.pumpAndSettle();

      expect(find.text('Delete this viewing'), findsOneWidget);
      await tester.tap(find.text('Delete this viewing'));
      await tester.pumpAndSettle();

      // Voluntary gesture 2: Confirm in dialog
      expect(find.text('Remove log?'), findsOneWidget);
      when(
        () => mockMediaRepository.getSeenItems(),
      ).thenAnswer((_) async => []);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      verify(() => mockMediaRepository.deleteSeenEntry(1)).called(1);
    },
  );

  testWidgets(
    'switching to Library view aggregates by title and displays episode/entry counts',
    (tester) async {
      final seenItems = [
        SeenItem(
          id: 1,
          tmdbId: 10,
          type: MediaType.tv,
          title: 'Stranger Things',
          seenDate: DateTime(2026, 11, 15),
          seasonNumber: 1,
          episodeNumber: 1,
        ),
        SeenItem(
          id: 2,
          tmdbId: 10,
          type: MediaType.tv,
          title: 'Stranger Things',
          seenDate: DateTime(2026, 11, 16),
          seasonNumber: 1,
          episodeNumber: 2,
        ),
        SeenItem(
          id: 3,
          tmdbId: 20,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2026, 11, 10),
        ),
        SeenItem(
          id: 4,
          tmdbId: 20,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2026, 11, 12),
        ),
      ];

      when(
        () => mockMediaRepository.getSeenItems(),
      ).thenAnswer((_) async => seenItems);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();

      // Tap on segment "Bibliothèque"
      await tester.tap(find.text('Bibliothèque'));
      await tester.pumpAndSettle();

      // Mode reminder is updated
      expect(find.text('Une entrée par titre'), findsOneWidget);

      // Stranger Things has 2 episodes and 2 entries
      expect(find.text('2 épisodes vus · 2 entrées'), findsOneWidget);
      // Inception has 2 entries -> "Vu 2 fois"
      expect(find.text('Vu 2 fois'), findsOneWidget);
    },
  );

  testWidgets(
    'search filters items in real time and shows distinct empty state when no matches',
    (tester) async {
      final seenItems = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Avatar',
          seenDate: DateTime(2026, 11, 16),
        ),
      ];

      when(
        () => mockMediaRepository.getSeenItems(),
      ).thenAnswer((_) async => seenItems);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Avatar'), findsOneWidget);

      // Enter non-matching query
      await tester.enterText(find.byType(TextField), 'Matrix');
      await tester.pumpAndSettle();

      expect(find.text('Avatar'), findsNothing);
      expect(find.text('No matches found.'), findsOneWidget);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Avatar'), findsOneWidget);
    },
  );

  testWidgets('should reload seen items on pull-to-refresh when empty', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    clearInteractions(mockMediaRepository);

    await tester.fling(
      find.text('No items seen yet.'),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    verify(() => mockMediaRepository.getSeenItems()).called(1);
  });
}
