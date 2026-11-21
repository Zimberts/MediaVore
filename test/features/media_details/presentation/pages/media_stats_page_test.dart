import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_activity_chart.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_decade_section.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_lists_section.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_media_split_bar.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_series_progression_section.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_top_genres_list.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  group('MediaStatsPage Widget Tests', () {
    late MockMediaRepository mockRepository;
    late SearchProvider searchProvider;

    setUp(() {
      mockRepository = MockMediaRepository();

      when(
        () => mockRepository.getAllListNames(),
      ).thenAnswer((_) async => ['watchlist', 'Favorites']);
      when(
        () => mockRepository.getListEntries(any()),
      ).thenAnswer((_) async => ['101:movie', '102:movie']);
      when(
        () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => ['101:movie', '201:tv']);
      when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
      when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
      when(
        () => mockRepository.watchNotifiedItems(),
      ).thenAnswer((_) => const Stream.empty());

      when(() => mockRepository.getCachedMediaItems(any())).thenAnswer((
        inv,
      ) async {
        final keys = inv.positionalArguments[0] as List<(int, MediaType)>;
        return keys.map<MediaItem?>((key) {
          if (key.$1 == 101) {
            return const MediaItem(
              id: 101,
              title: 'Inception',
              overview: 'Dreams within dreams',
              releaseDate: '2010-07-16',
              voteAverage: 8.8,
            );
          } else if (key.$1 == 102) {
            return const MediaItem(
              id: 102,
              title: 'The Matrix',
              overview: 'Red pill or blue pill',
              releaseDate: '1999-03-31',
              voteAverage: 8.7,
            );
          } else if (key.$1 == 201) {
            return const MediaItem(
              id: 201,
              title: 'Breaking Bad',
              overview: 'A chemistry teacher cooks',
              mediaType: MediaType.tv,
              releaseDate: '2008-01-20',
              voteAverage: 9.5,
              numberOfEpisodes: 62,
            );
          }
          return null;
        }).toList();
      });
    });

    Widget createWidgetUnderTest({Locale locale = const Locale('fr')}) {
      return ChangeNotifierProvider<SearchProvider>.value(
        value: searchProvider,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: const DefaultLightPalette().toThemeData(),
          home: const MediaStatsPage(),
        ),
      );
    }

    testWidgets('displays empty message when seen items is empty', (
      tester,
    ) async {
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
      searchProvider = SearchProvider(mockRepository);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Statistiques'), findsOneWidget);
      expect(
        find.text('Pas encore de données. À vos écrans !'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders all sections on single scrolling page when data exists',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final seenList = [
          SeenItem(
            tmdbId: 101,
            type: MediaType.movie,
            title: 'Inception',
            runtime: 148,
            genres: const ['Action', 'Science Fiction'],
            seenDate: DateTime(2026, 5, 10),
          ),
          SeenItem(
            tmdbId: 102,
            type: MediaType.movie,
            title: 'The Matrix',
            runtime: 136,
            genres: const ['Action', 'Science Fiction'],
            seenDate: DateTime(2026, 5, 12),
          ),
          SeenItem(
            tmdbId: 201,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seasonNumber: 1,
            episodeNumber: 1,
            runtime: 58,
            genres: const ['Drama', 'Crime'],
            seenDate: DateTime(2026, 6),
          ),
        ];

        when(
          () => mockRepository.getSeenItems(),
        ).thenAnswer((_) async => seenList);
        searchProvider = SearchProvider(mockRepository);
        await searchProvider.loadAllSeenStatus();

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Title
        expect(find.text('Statistiques'), findsOneWidget);

        // Metric toggle button
        expect(find.byKey(const Key('stats_toggle_metric')), findsOneWidget);

        // Period scope buttons
        expect(find.text('Tout'), findsOneWidget);
        expect(find.text('Année'), findsOneWidget);
        expect(find.text('Mois'), findsOneWidget);

        // Total Watch Time
        expect(find.text('Temps de visionnage total'), findsOneWidget);

        // Activity Chart
        expect(find.byType(ActivityChart), findsOneWidget);

        // Media split bar
        expect(find.byType(MediaSplitBar), findsOneWidget);

        // Top genres
        expect(find.byType(TopGenresList), findsOneWidget);

        // Decades section
        expect(find.byType(DecadeSection), findsOneWidget);

        // Series progression
        expect(find.byType(SeriesProgressionSection), findsOneWidget);

        // Lists & discovery section
        expect(find.byType(ListsAndDiscoverySection), findsOneWidget);

        // Footer disclaimer
        expect(find.text("Calculé sur l'historique daté."), findsOneWidget);
      },
    );

    testWidgets('toggles metric from entries to runtime', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final seenList = [
        SeenItem(
          tmdbId: 101,
          type: MediaType.movie,
          title: 'Inception',
          runtime: 148,
          seenDate: DateTime(2026, 5, 10),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => seenList);
      searchProvider = SearchProvider(mockRepository);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initially in entries (logs)
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.text('Palmarès (entrées)'), findsOneWidget);

      // Toggle to runtime
      await tester.tap(find.byKey(const Key('stats_toggle_metric')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.text('Palmarès (durée)'), findsOneWidget);
    });

    testWidgets('displays dedicated no-data message when period has no items', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final seenList = [
        SeenItem(
          tmdbId: 101,
          type: MediaType.movie,
          title: 'Inception',
          runtime: 148,
          seenDate: DateTime(2025, 5, 10),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => seenList);
      searchProvider = SearchProvider(mockRepository);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to year
      await tester.tap(find.text('Année'));
      await tester.pumpAndSettle();

      // In 2025 (or current year):
      // If current year is 2026 and item is 2025, switch/navigate to 2025 first or verify 2026 has no data
      final hasDataNow = find
          .byKey(const Key('stats_no_data'))
          .evaluate()
          .isEmpty;
      if (hasDataNow) {
        // Navigate to next period (which has no data)
        final nextBtn = find.byTooltip('Période suivante');
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // In period with no data: dedicated card is shown, charts are hidden
      expect(find.byKey(const Key('stats_no_data')), findsOneWidget);
      expect(
        find.text('Aucune donnée de visionnage pour cette période'),
        findsOneWidget,
      );
      expect(find.byType(ActivityChart), findsNothing);
      expect(find.byType(MediaSplitBar), findsNothing);

      // But all-time sections are still present!
      expect(find.byType(DecadeSection), findsOneWidget);
      expect(find.byType(ListsAndDiscoverySection), findsOneWidget);
      expect(find.text("Calculé sur l'historique daté."), findsOneWidget);
    });

    testWidgets('non-regression on period totals for identical dataset', (
      tester,
    ) async {
      final seenList = [
        SeenItem(
          tmdbId: 101,
          type: MediaType.movie,
          title: 'Movie One',
          runtime: 120, // 2h
          seenDate: DateTime(2026),
        ),
        SeenItem(
          tmdbId: 102,
          type: MediaType.movie,
          title: 'Movie Two',
          runtime: 60, // 1h
          seenDate: DateTime(2026, 1, 2),
        ),
        SeenItem(
          tmdbId: 201,
          type: MediaType.tv,
          title: 'Series One',
          runtime: 30,
          seasonNumber: 1,
          episodeNumber: 1,
          seenDate: DateTime(2026, 1, 3),
        ),
      ];
      // Total: 210 min = 3h 30m, 2 movies, 1 episode
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => seenList);
      searchProvider = SearchProvider(mockRepository);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Duration: 0 j 3 h 30 min
      expect(find.text('0 j 3 h 30 min'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 movies count
      expect(find.text('1'), findsWidgets); // 1 episode count
    });
  });
}
