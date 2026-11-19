import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_header.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_seasons.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watch_next_button.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(MediaType.tv);
    registerFallbackValue(
      QuickAddItem(
        tmdbId: 1,
        type: MediaType.tv,
        insertedAt: DateTime.now(),
      ),
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

  const tSeries = MediaItem(
    id: 1,
    title: 'Breaking Bad',
    overview: 'High school teacher',
    releaseDate: '2008-01-20',
    mediaType: MediaType.tv,
    numberOfEpisodes: 3,
    numberOfSeasons: 1,
    seasons: [
      TVSeason(id: 10, seasonNumber: 1, episodeCount: 3, name: 'Season 1'),
    ],
  );

  final tEpisodes = [
    for (int i = 1; i <= 3; i++)
      {
        'episode_number': i,
        'name': 'Episode $i',
        'air_date': '2008-01-${10 + i}',
        'runtime': 50,
      },
  ];

  void stubDefaults(MockMediaRepository repo) {
    when(() => repo.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => repo.getListEntries(any())).thenAnswer((_) async => []);
    when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenItems()).thenAnswer((_) async => []);
    when(() => repo.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => repo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repo.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => repo.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => repo.getInProgressItems()).thenAnswer((_) async => []);
    when(() => repo.getQuickAddOptOuts()).thenAnswer((_) async => []);
    when(() => repo.watchNotifiedItems()).thenAnswer((_) => const Stream.empty());
    when(() => repo.getListPreviews(any())).thenAnswer((_) async => []);
    when(() => repo.getRecommendedMedia(any(), any())).thenAnswer((_) async => []);
    when(() => repo.getLikedItems()).thenAnswer((_) async => []);
  }

  group('SearchProvider cycle calculation', () {
    test('calculateCompletedCycles returns 0 when incomplete', () {
      final seen = [
        SeenItem(
          tmdbId: 1,
          type: MediaType.tv,
          title: 'Breaking Bad',
          seenDate: DateTime(2024, 1, 1),
          seasonNumber: 1,
          episodeNumber: 1,
        ),
        SeenItem(
          tmdbId: 1,
          type: MediaType.tv,
          title: 'Breaking Bad',
          seenDate: DateTime(2024, 1, 2),
          seasonNumber: 1,
          episodeNumber: 2,
        ),
      ];

      expect(SearchProvider.calculateCompletedCycles(tSeries, seen), 0);
    });

    test('calculateCompletedCycles returns 1 when all episodes seen once', () {
      final seen = [
        for (int i = 1; i <= 3; i++)
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2024, 1, i),
            seasonNumber: 1,
            episodeNumber: i,
          ),
      ];

      expect(SearchProvider.calculateCompletedCycles(tSeries, seen), 1);
    });

    test('calculateCompletedCycles returns 2 when all episodes seen twice', () {
      final seen = [
        for (int i = 1; i <= 3; i++) ...[
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2024, 1, i),
            seasonNumber: 1,
            episodeNumber: i,
          ),
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2025, 1, i),
            seasonNumber: 1,
            episodeNumber: i,
          ),
        ],
      ];

      expect(SearchProvider.calculateCompletedCycles(tSeries, seen), 2);
    });
  });

  group('startSeriesRewatch and cancelSeriesRewatch', () {
    late MockMediaRepository mockRepo;
    late SearchProvider provider;

    setUp(() {
      mockRepo = MockMediaRepository();
      stubDefaults(mockRepo);
      provider = SearchProvider(mockRepo);

      when(() => mockRepo.getSeenStatus(1, MediaType.tv)).thenAnswer(
        (_) async => [
          for (int i = 1; i <= 3; i++)
            SeenItem(
              tmdbId: 1,
              type: MediaType.tv,
              title: 'Breaking Bad',
              seenDate: DateTime(2024, 1, i),
              seasonNumber: 1,
              episodeNumber: i,
            ),
        ],
      );
      when(() => mockRepo.clearOptOutSeries(1, seasonNumber: 1, episodeNumber: 1))
          .thenAnswer((_) async {});
      when(() => mockRepo.getSeasonDetails(1, 1)).thenAnswer(
        (_) async => {'episodes': tEpisodes},
      );
      when(() => mockRepo.addQuickAddItem(any())).thenAnswer((_) async {});
      when(() => mockRepo.getQuickAddItems()).thenAnswer((_) async => []);
      when(() => mockRepo.getInProgressItems()).thenAnswer((_) async => []);
      when(() => mockRepo.getQuickAddOptOuts()).thenAnswer((_) async => []);
      when(() => mockRepo.setSeriesRewatchStart(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockRepo.clearSeriesRewatchStart(any()))
          .thenAnswer((_) async {});
    });

    test('startSeriesRewatch starts cycle 2 and adds S1 E1 to quick add', () async {
      when(() => mockRepo.getSeriesRewatchStart(1)).thenReturn(null);

      final cycle = await provider.startSeriesRewatch(tSeries);
      expect(cycle, 2);

      verify(() => mockRepo.setSeriesRewatchStart(1, any())).called(1);
      verify(() => mockRepo.addQuickAddItem(any(that: predicate<QuickAddItem>((item) =>
          item.tmdbId == 1 &&
          item.seasonNumber == 1 &&
          item.episodeNumber == 1)))).called(1);
    });

    test('cancelSeriesRewatch clears rewatch start and removes S1 E1', () async {
      final qItem = QuickAddItem(
        isarId: 42,
        tmdbId: 1,
        type: MediaType.tv,
        seasonNumber: 1,
        episodeNumber: 1,
        insertedAt: DateTime.now(),
      );
      when(() => mockRepo.getQuickAddItems()).thenAnswer((_) async => [qItem]);
      when(() => mockRepo.removeQuickAddItemById(42)).thenAnswer((_) async {});

      await provider.cancelSeriesRewatch(1);

      verify(() => mockRepo.clearSeriesRewatchStart(1)).called(1);
      verify(() => mockRepo.removeQuickAddItemById(42)).called(1);
    });
  });

  group('WatchNextButton widget test', () {
    late MockMediaRepository mockRepo;

    setUp(() {
      mockRepo = MockMediaRepository();
      stubDefaults(mockRepo);
      when(() => mockRepo.clearOptOutSeries(1, seasonNumber: 1, episodeNumber: 1))
          .thenAnswer((_) async {});
      when(() => mockRepo.getSeasonDetails(1, 1)).thenAnswer(
        (_) async => {'episodes': tEpisodes},
      );
      when(() => mockRepo.addQuickAddItem(any())).thenAnswer((_) async {});
      when(() => mockRepo.getQuickAddItems()).thenAnswer((_) async => []);
      when(() => mockRepo.getInProgressItems()).thenAnswer((_) async => []);
      when(() => mockRepo.getQuickAddOptOuts()).thenAnswer((_) async => []);
      when(() => mockRepo.setSeriesRewatchStart(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockRepo.clearSeriesRewatchStart(any()))
          .thenAnswer((_) async {});
    });

    testWidgets('shows Rewatch series when series is completed', (tester) async {
      when(() => mockRepo.getSeriesRewatchStart(1)).thenReturn(null);
      when(() => mockRepo.getSeenStatus(1, MediaType.tv)).thenAnswer(
        (_) async => [
          for (int i = 1; i <= 3; i++)
            SeenItem(
              tmdbId: 1,
              type: MediaType.tv,
              title: 'Breaking Bad',
              seenDate: DateTime(2024, 1, i),
              seasonNumber: 1,
              episodeNumber: i,
            ),
        ],
      );

      final provider = SearchProvider(mockRepo);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('en'),
          home: ChangeNotifierProvider<SearchProvider>.value(
            value: provider,
            child: const Scaffold(
              body: WatchNextButton(item: tSeries),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rewatch series'), findsOneWidget);
    });

    testWidgets('tapping Rewatch series starts rewatch and shows Undo toast', (tester) async {
      when(() => mockRepo.getSeriesRewatchStart(1)).thenReturn(null);
      when(() => mockRepo.getSeenStatus(1, MediaType.tv)).thenAnswer(
        (_) async => [
          for (int i = 1; i <= 3; i++)
            SeenItem(
              tmdbId: 1,
              type: MediaType.tv,
              title: 'Breaking Bad',
              seenDate: DateTime(2024, 1, i),
              seasonNumber: 1,
              episodeNumber: i,
            ),
        ],
      );

      final provider = SearchProvider(mockRepo);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('en'),
          builder: (context, child) => AppMessageHost(child: child!),
          home: ChangeNotifierProvider<SearchProvider>.value(
            value: provider,
            child: const Scaffold(
              body: WatchNextButton(item: tSeries),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = find.text('Rewatch series');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.textContaining('2nd watch started'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.clearSeriesRewatchStart(1)).called(1);
    });
  });

  group('MediaDetailHeader personal status', () {
    late MockMediaRepository mockRepo;

    setUp(() {
      mockRepo = MockMediaRepository();
      stubDefaults(mockRepo);
    });

    testWidgets('displays Watched 2 times when completed 2 times', (tester) async {
      when(() => mockRepo.getSeriesRewatchStart(1)).thenReturn(null);
      final provider = SearchProvider(mockRepo);

      final seen = [
        for (int i = 1; i <= 3; i++) ...[
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2024, 1, i),
            seasonNumber: 1,
            episodeNumber: i,
          ),
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2025, 1, i),
            seasonNumber: 1,
            episodeNumber: i,
          ),
        ],
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('en'),
          home: ChangeNotifierProvider<SearchProvider>.value(
            value: provider,
            child: Scaffold(
              body: MediaDetailHeader(
                item: tSeries,
                seenStatus: seen,
                onMore: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Watched 2 times'), findsOneWidget);
    });

    testWidgets('displays 2nd watch · Next: S1 E1 during active rewatch', (tester) async {
      when(() => mockRepo.getSeriesRewatchStart(1)).thenReturn(DateTime(2026, 1, 1));
      final provider = SearchProvider(mockRepo);

      final seen = [
        for (int i = 1; i <= 3; i++)
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2024, 1, i),
            seasonNumber: 1,
            episodeNumber: i,
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('en'),
          home: ChangeNotifierProvider<SearchProvider>.value(
            value: provider,
            child: Scaffold(
              body: MediaDetailHeader(
                item: tSeries,
                seenStatus: seen,
                onMore: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('2nd watch · Next: S1 E1'), findsOneWidget);
    });
  });

  group('MediaDetailSeasons rewatch display', () {
    late MockMediaRepository mockRepo;

    setUp(() {
      mockRepo = MockMediaRepository();
      stubDefaults(mockRepo);
    });

    testWidgets('displays Already seen on ... and 0/3 progress during rewatch', (tester) async {
      when(() => mockRepo.getSeriesRewatchStart(1)).thenReturn(DateTime(2026, 1, 1));
      final provider = SearchProvider(mockRepo);

      final seen = [
        for (int i = 1; i <= 3; i++)
          SeenItem(
            tmdbId: 1,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2024, 1, 15),
            seasonNumber: 1,
            episodeNumber: i,
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('en'),
          home: ChangeNotifierProvider<SearchProvider>.value(
            value: provider,
            child: Scaffold(
              body: MediaDetailSeasons(
                item: tSeries,
                seenStatus: seen,
                episodesBySeason: {1: tEpisodes},
                expandedSeason: 1,
                loadingSeasons: const {},
                onToggleSeason: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress should be 0 / 3
      expect(find.textContaining('0 / 3'), findsOneWidget);

      // Episode subtitle should say "Already seen on Jan 15, 2024"
      expect(find.textContaining('Already seen on'), findsWidgets);
    });
  });
}
