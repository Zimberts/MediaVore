import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_seasons.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSearchProvider extends Mock implements SearchProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  late MockSearchProvider mockSearchProvider;
  late MockSettingsProvider mockSettingsProvider;

  const tTvItem = MediaItem(
    id: 1,
    title: 'Breaking Bad',
    overview: 'High school teacher turns cook',
    releaseDate: '2008-01-20',
    mediaType: MediaType.tv,
    numberOfEpisodes: 10,
    seasons: [
      TVSeason(id: 10, seasonNumber: 1, episodeCount: 10, name: 'Saison 1'),
    ],
  );

  // 10 episodes of 50 min = 500 min -> 8,3 h in French, 8.3 h in English
  final tEpisodes10 = [
    for (int i = 1; i <= 10; i++)
      {
        'episode_number': i,
        'name': 'Episode $i',
        'air_date': '2008-01-${10 + i}',
        'runtime': 50,
        'overview': 'Overview for episode $i',
      },
  ];

  setUpAll(() {
    registerFallbackValue(MediaType.tv);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
    registerFallbackValue(
      SeenItem(
        tmdbId: 1,
        type: MediaType.tv,
        title: 'Breaking Bad',
        seenDate: DateTime.now(),
        seasonNumber: 1,
        episodeNumber: 1,
      ),
    );
  });

  setUp(() {
    mockSearchProvider = MockSearchProvider();
    mockSettingsProvider = MockSettingsProvider();

    when(() => mockSettingsProvider.advancedTracking).thenReturn(false);
    when(() => mockSettingsProvider.hideNonReleased).thenReturn(false);
    when(
      () => mockSettingsProvider.previousEpisodes,
    ).thenReturn(PreviousEpisodesBehavior.ask);

    when(() => mockSearchProvider.seenItems).thenReturn([]);
    when(() => mockSearchProvider.listNames).thenReturn(['watchlist']);
    when(() => mockSearchProvider.isItemInList(any(), any())).thenReturn(false);
    when(
      () => mockSearchProvider.markItemSeen(any()),
    ).thenAnswer((_) async => () async {});
    when(
      () => mockSearchProvider.getPreviousUnseenEpisodes(
        tvId: any(named: 'tvId'),
        targetSeason: any(named: 'targetSeason'),
        targetEpisode: any(named: 'targetEpisode'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget buildWidget({
    required MediaItem item,
    required List<SeenItem> seenStatus,
    int? expandedSeason,
    Map<int, List<dynamic>>? episodesBySeason,
    ValueChanged<int>? onToggleSeason,
    Locale locale = const Locale('fr'),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: mockSearchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        theme: AppPalette.paper.toThemeData(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaDetailSeasons(
              item: item,
              seenStatus: seenStatus,
              expandedSeason: expandedSeason,
              episodesBySeason: episodesBySeason ?? {1: tEpisodes10},
              loadingSeasons: const {},
              onToggleSeason: onToggleSeason ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'displays season card with 8,3 h total duration and progress for 10 episodes of 50 min',
    (tester) async {
      // 4 episodes seen out of 10
      final seen = [
        for (int i = 1; i <= 4; i++)
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2023, 1, i),
            seasonNumber: 1,
            episodeNumber: i,
          ),
      ];

      await tester.pumpWidget(buildWidget(item: tTvItem, seenStatus: seen));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Saison 1'), findsOneWidget);
      // Subtitle: « 10 épisodes · 8,3 h · 4/10 vus »
      expect(find.text('10 épisodes · 8,3 h · 4/10 vus'), findsOneWidget);

      // Progress bar should have value 4/10 = 0.4
      final indicators = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      // The second indicator is inside the season card
      expect(indicators.last.value, closeTo(0.4, 0.001));
    },
  );

  testWidgets(
    'displays approximate duration with ~ when some durations are missing',
    (tester) async {
      final episodesPartial = [
        for (int i = 1; i <= 10; i++)
          {
            'episode_number': i,
            'name': 'Episode $i',
            'air_date': '2008-01-10',
            // 8 episodes have 50 min, 2 episodes have null runtime
            'runtime': i <= 8 ? 50 : null,
          },
      ];

      await tester.pumpWidget(
        buildWidget(
          item: tTvItem,
          seenStatus: const [],
          episodesBySeason: {1: episodesPartial},
        ),
      );
      await tester.pumpAndSettle();

      // 8 * 50 = 400 min / 60 = 6,666 -> ~6,7 h
      expect(find.text('10 épisodes · ~6,7 h · 0/10 vus'), findsOneWidget);
    },
  );

  testWidgets(
    'expanded season displays episodes list with checkmark styling and duration',
    (tester) async {
      final seen = [
        SeenItem(
          tmdbId: 1,
          type: MediaType.tv,
          title: 'Breaking Bad',
          seenDate: DateTime(2023, 1, 1),
          seasonNumber: 1,
          episodeNumber: 1,
        ),
      ];
      when(() => mockSearchProvider.seenItems).thenReturn(seen);

      await tester.pumpWidget(
        buildWidget(item: tTvItem, seenStatus: seen, expandedSeason: 1),
      );
      await tester.pumpAndSettle();

      // Check episode row items
      expect(find.text('E1: Episode 1'), findsOneWidget);
      expect(find.text('E2: Episode 2'), findsOneWidget);
      expect(find.text('Overview for episode 1'), findsOneWidget);

      // Episode 1 runtime & air date & seen date:
      // "50 min · 11 janv. 2008 · Vu 1 fois · le 1 janv. 2023"
      expect(find.textContaining('50 min'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Vu 1 fois'), findsOneWidget);

      // Episode 1 is seen: check icon visible
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    },
  );

  testWidgets('tapping unseen episode checkmark calls markItemSeen', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(item: tTvItem, seenStatus: const [], expandedSeason: 1),
    );
    await tester.pumpAndSettle();

    // Episode 1 is not seen, find its checkmark container and tap it
    final ep1CheckFinder = find.byKey(const ValueKey('seen_ep_1_1_1'));
    expect(ep1CheckFinder, findsOneWidget);

    await tester.tap(ep1CheckFinder);
    await tester.pumpAndSettle();

    verify(() => mockSearchProvider.markItemSeen(any())).called(1);
  });

  testWidgets(
    'unreleased episode is grayed out and hidden when hideNonReleased is enabled',
    (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final episodesWithUnreleased = [
        {
          'episode_number': 1,
          'name': 'Aired Episode',
          'air_date': '2020-01-01',
          'runtime': 45,
        },
        {
          'episode_number': 2,
          'name': 'Future Episode',
          'air_date':
              '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}',
          'runtime': 45,
        },
      ];

      // Case 1: hideNonReleased = false -> Future episode is displayed
      when(() => mockSettingsProvider.hideNonReleased).thenReturn(false);

      await tester.pumpWidget(
        buildWidget(
          item: tTvItem,
          seenStatus: const [],
          expandedSeason: 1,
          episodesBySeason: {1: episodesWithUnreleased},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('E1: Aired Episode'), findsOneWidget);
      expect(find.text('E2: Future Episode'), findsOneWidget);

      // Case 2: hideNonReleased = true -> Future episode is hidden
      when(() => mockSettingsProvider.hideNonReleased).thenReturn(true);

      await tester.pumpWidget(
        buildWidget(
          item: tTvItem,
          seenStatus: const [],
          expandedSeason: 1,
          episodesBySeason: {1: episodesWithUnreleased},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('E1: Aired Episode'), findsOneWidget);
      expect(find.text('E2: Future Episode'), findsNothing);
    },
  );

  testWidgets('English localization formats season subtitle correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        item: tTvItem,
        seenStatus: const [],
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    // In English: "10 episodes · 8.3 h · 0/10 seen"
    expect(find.text('10 episodes · 8.3 h · 0/10 seen'), findsOneWidget);
  });
}
