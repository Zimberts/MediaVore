import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'T',
        seenDate: DateTime.now(),
      ),
    );
    registerFallbackValue(
      const MediaItem(id: 1, title: 'T', overview: '', releaseDate: ''),
    );
  });

  setUp(() {
    mockRepository = MockMediaRepository();

    // Default mocks for SearchProvider init
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.markAsSeen(any()),
    ).thenAnswer((_) async => Future.value());

    searchProvider = SearchProvider(mockRepository);

    // Default mocks for UI components
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest({
    int tmdbId = 1,
    MediaType type = MediaType.movie,
    String title = 'Inception',
    bool compact = false,
    String? status,
    int? lastSeasonNumber,
    int? lastEpisodeNumber,
  }) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: Scaffold(
          body: SeenManager(
            compact: compact,
            item: MediaItem(
              id: tmdbId,
              mediaType: type,
              title: title,
              overview: '',
              releaseDate: '',
              status: status,
              lastSeasonNumber: lastSeasonNumber,
              lastEpisodeNumber: lastEpisodeNumber,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markAsSeenViaUi(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    // Press the LOG VIEWING button in the dialog
    await tester.tap(find.text('LOG VIEWING'));
    await tester.pumpAndSettle();
  }

  group('SeenManager', () {
    testWidgets('displays check_circle_outline icon when not seen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Initial load

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays check_circle icon when seen', (
      WidgetTester tester,
    ) async {
      final viewings = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2023),
        ),
      ];
      // Mock both the direct repository call and the provider's seenItems list
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping check_circle icon opens bottom sheet', (
      WidgetTester tester,
    ) async {
      final viewings = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2023),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Viewing History'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when clearing history', (
      WidgetTester tester,
    ) async {
      final viewings = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2023),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      when(
        () => mockRepository.removeFromSeen(
          any(),
          any(),
          seasonNumber: any(named: 'seasonNumber'),
          episodeNumber: any(named: 'episodeNumber'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Long press on the ListTile (SeenManager uses ListTile when not compact)
      await tester.longPress(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Clear History'), findsOneWidget);

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.removeFromSeen(1, MediaType.movie)).called(1);
    });

    group('Tv Support', () {
      testWidgets('tapping check_circle_outline opens date picker dialog', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest(type: MediaType.tv));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.check_circle_outline));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Mark as seen'), findsOneWidget);
      });
    });

    group('Watchlist removal behaviour', () {
      testWidgets('movie not in watchlist does not remove', (
        WidgetTester tester,
      ) async {
        when(
          () => mockRepository.getWatchlistEntries(),
        ).thenAnswer((_) async => []);
        await searchProvider.loadWatchlist();

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        when(
          () => mockRepository.removeFromList(any(), any(), any()),
        ).thenAnswer((_) async => {});

        await _markAsSeenViaUi(tester);

        verifyNever(() => mockRepository.removeFromList(any(), any(), any()));
      });

      testWidgets('movie in watchlist is removed when marked seen', (
        WidgetTester tester,
      ) async {
        when(
          () => mockRepository.getWatchlistEntries(),
        ).thenAnswer((_) async => ['1:movie']);
        await searchProvider.loadWatchlist();

        when(
          () => mockRepository.removeFromList(1, MediaType.movie, 'watchlist'),
        ).thenAnswer((_) async => {});

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        await _markAsSeenViaUi(tester);

        verify(
          () => mockRepository.removeFromList(1, MediaType.movie, 'watchlist'),
        ).called(1);
      });

      testWidgets('series middle episode in watchlist is not removed', (
        WidgetTester tester,
      ) async {
        // TV show in watchlist
        when(
          () => mockRepository.getWatchlistEntries(),
        ).thenAnswer((_) async => ['2:tv']);
        await searchProvider.loadWatchlist();

        // Item has last episode 5:10, we mark 3:4 (middle)
        await tester.pumpWidget(
          createWidgetUnderTest(
            tmdbId: 2,
            type: MediaType.tv,
            status: 'Ended',
            lastSeasonNumber: 5,
            lastEpisodeNumber: 10,
          ),
        );
        await tester.pump();

        when(
          () => mockRepository.removeFromList(2, MediaType.tv, 'watchlist'),
        ).thenAnswer((_) async => {});

        // Ensure provider.getNextEpisode can resolve a following episode so
        // it doesn't mistakenly say there are no remaining episodes.
        when(() => mockRepository.getSeenStatus(2, MediaType.tv)).thenAnswer(
          (_) async => [
            SeenItem(
              id: 11,
              tmdbId: 2,
              type: MediaType.tv,
              title: 'Show',
              seenDate: DateTime.now(),
              seasonNumber: 3,
              episodeNumber: 4,
            ),
          ],
        );
        when(
          () => mockRepository.getMediaDetails(2, type: MediaType.tv),
        ).thenAnswer(
          (_) async => MediaDetails(
            item: MediaItem(
              id: 2,
              title: 'Show',
              overview: '',
              releaseDate: '',
              mediaType: MediaType.tv,
              seasons: [TVSeason(id: 1, seasonNumber: 3, episodeCount: 10)],
            ),
            cast: [],
          ),
        );
        when(() => mockRepository.getSeasonDetails(2, 3)).thenAnswer(
          (_) async => {
            'episodes': [
              {
                'episode_number': 5,
                'air_date': DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
              },
            ],
          },
        );

        // Simulate marking season 3 episode 4
        // The SeenManager uses widget.seasonNumber/episodeNumber to check, so we create a SeenManager for those via compact mode
        // Rebuild with episode context
        await tester.pumpWidget(
          ChangeNotifierProvider<SearchProvider>.value(
            value: searchProvider,
            child: MaterialApp(
              theme: DefaultLightPalette().toThemeData(),
              home: Scaffold(
                body: SeenManager(
                  compact: false,
                  item: MediaItem(
                    id: 2,
                    mediaType: MediaType.tv,
                    title: 'Show',
                    overview: '',
                    releaseDate: '',
                    status: 'Ended',
                    lastSeasonNumber: 5,
                    lastEpisodeNumber: 10,
                  ),
                  seasonNumber: 3,
                  episodeNumber: 4,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        await _markAsSeenViaUi(tester);

        verifyNever(
          () => mockRepository.removeFromList(2, MediaType.tv, 'watchlist'),
        );
      });

      testWidgets('series end episode in watchlist is removed', (
        WidgetTester tester,
      ) async {
        when(
          () => mockRepository.getWatchlistEntries(),
        ).thenAnswer((_) async => ['3:tv']);
        await searchProvider.loadWatchlist();

        when(
          () => mockRepository.removeFromList(3, MediaType.tv, 'watchlist'),
        ).thenAnswer((_) async => {});

        await tester.pumpWidget(
          ChangeNotifierProvider<SearchProvider>.value(
            value: searchProvider,
            child: MaterialApp(
              theme: DefaultLightPalette().toThemeData(),
              home: Scaffold(
                body: SeenManager(
                  compact: false,
                  item: MediaItem(
                    id: 3,
                    mediaType: MediaType.tv,
                    title: 'Finale',
                    overview: '',
                    releaseDate: '',
                    status: 'Ended',
                    lastSeasonNumber: 2,
                    lastEpisodeNumber: 8,
                  ),
                  seasonNumber: 2,
                  episodeNumber: 8,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        await _markAsSeenViaUi(tester);

        verify(
          () => mockRepository.removeFromList(3, MediaType.tv, 'watchlist'),
        ).called(1);
      });

      testWidgets('series end episode not in watchlist does nothing', (
        WidgetTester tester,
      ) async {
        when(
          () => mockRepository.getWatchlistEntries(),
        ).thenAnswer((_) async => []);
        await searchProvider.loadWatchlist();

        await tester.pumpWidget(
          ChangeNotifierProvider<SearchProvider>.value(
            value: searchProvider,
            child: MaterialApp(
              theme: DefaultLightPalette().toThemeData(),
              home: Scaffold(
                body: SeenManager(
                  compact: false,
                  item: MediaItem(
                    id: 4,
                    mediaType: MediaType.tv,
                    title: 'NotSaved',
                    overview: '',
                    releaseDate: '',
                    status: 'Ended',
                    lastSeasonNumber: 1,
                    lastEpisodeNumber: 1,
                  ),
                  seasonNumber: 1,
                  episodeNumber: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        when(
          () => mockRepository.removeFromList(any(), any(), any()),
        ).thenAnswer((_) async => {});

        await _markAsSeenViaUi(tester);

        verifyNever(() => mockRepository.removeFromList(any(), any(), any()));
      });

      testWidgets('series last episode but status not Ended does not remove', (
        WidgetTester tester,
      ) async {
        when(
          () => mockRepository.getWatchlistEntries(),
        ).thenAnswer((_) async => ['5:tv']);
        await searchProvider.loadWatchlist();

        await tester.pumpWidget(
          ChangeNotifierProvider<SearchProvider>.value(
            value: searchProvider,
            child: MaterialApp(
              theme: DefaultLightPalette().toThemeData(),
              home: Scaffold(
                body: SeenManager(
                  compact: false,
                  item: MediaItem(
                    id: 5,
                    mediaType: MediaType.tv,
                    title: 'Ongoing',
                    overview: '',
                    releaseDate: '',
                    status: 'Returning Series',
                    lastSeasonNumber: 1,
                    lastEpisodeNumber: 10,
                  ),
                  seasonNumber: 1,
                  episodeNumber: 10,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        when(
          () => mockRepository.removeFromList(any(), any(), any()),
        ).thenAnswer((_) async => {});

        await _markAsSeenViaUi(tester);

        verifyNever(() => mockRepository.removeFromList(any(), any(), any()));
      });
    });
  });
}
