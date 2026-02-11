import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watch_next_button.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider provider;

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

    // Basic provider init stubs
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

    provider = SearchProvider(mockRepository);
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
  });

  testWidgets(
    'NotificationCenter movie: marking as seen removes from watchlist',
    (WidgetTester tester) async {
      final now = DateTime.now().subtract(const Duration(days: 1));
      when(() => mockRepository.getNotifiedItems()).thenAnswer(
        (_) async => [
          NotifiedItem(
            tmdbId: 10,
            type: MediaType.movie,
            title: 'Movie10',
            releaseDate: now,
          ),
        ],
      );
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => ['10:movie']);
      when(
        () => mockRepository.getMediaDetails(10, type: MediaType.movie),
      ).thenAnswer(
        (_) async => MediaDetails(
          item: MediaItem(
            id: 10,
            title: 'Movie10',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.movie,
          ),
          cast: [],
        ),
      );
      when(
        () => mockRepository.removeFromList(10, MediaType.movie, 'watchlist'),
      ).thenAnswer((_) async => {});

      // Refresh provider state from mocked repository
      await provider.loadNotifiedItems();
      await provider.loadWatchlist();

      await tester.pumpWidget(
        ChangeNotifierProvider<SearchProvider>.value(
          value: provider,
          child: const MaterialApp(home: NotificationCenterPage()),
        ),
      );

      await tester.pumpAndSettle();

      // The released item should have a 'Mark as seen' icon (visibility_outlined)
      final markButtons = find.byTooltip('Mark as seen');
      expect(markButtons, findsOneWidget);

      await tester.tap(markButtons.first);
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.removeFromList(10, MediaType.movie, 'watchlist'),
      ).called(1);
    },
  );

  testWidgets(
    'WatchNextButton marks next ep and removes series from watchlist when appropriate',
    (WidgetTester tester) async {
      // Prepare watchlist to include the series
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => ['20:tv']);

      // Stub seen status so provider.getNextEpisode will return a next ep
      when(() => mockRepository.getSeenStatus(20, MediaType.tv)).thenAnswer(
        (_) async => [
          SeenItem(
            id: 1,
            tmdbId: 20,
            type: MediaType.tv,
            title: 'Series20',
            seenDate: DateTime.now(),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
        ],
      );

      when(
        () => mockRepository.getMediaDetails(20, type: MediaType.tv),
      ).thenAnswer(
        (_) async => MediaDetails(
          item: MediaItem(
            id: 20,
            title: 'Series20',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.tv,
            seasons: [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
            status: 'Ended',
            lastSeasonNumber: 1,
            lastEpisodeNumber: 2,
          ),
          cast: [],
        ),
      );

      when(() => mockRepository.getSeasonDetails(20, 1)).thenAnswer(
        (_) async => {
          'episodes': [
            {
              'episode_number': 2,
              'air_date': DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
            },
          ],
        },
      );

      when(
        () => mockRepository.removeFromList(20, MediaType.tv, 'watchlist'),
      ).thenAnswer((_) async => {});

      await provider.loadWatchlist();

      await tester.pumpWidget(
        ChangeNotifierProvider<SearchProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: WatchNextButton(
                item: MediaItem(
                  id: 20,
                  title: 'Series20',
                  overview: '',
                  releaseDate: '',
                  mediaType: MediaType.tv,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Button should be present
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.removeFromList(20, MediaType.tv, 'watchlist'),
      ).called(1);
    },
  );

  testWidgets(
    'QuickAddTab: pressing check marks next ep and removes from watchlist',
    (WidgetTester tester) async {
      // Provide a seen item so QuickAddTab will consider it
      when(() => mockRepository.getSeenItems()).thenAnswer(
        (_) async => [
          SeenItem(
            id: 101,
            tmdbId: 30,
            type: MediaType.tv,
            title: 'Series30',
            seenDate: DateTime.now(),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
        ],
      );

      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => ['30:tv']);

      when(() => mockRepository.getSeenStatus(30, MediaType.tv)).thenAnswer(
        (_) async => [
          SeenItem(
            id: 101,
            tmdbId: 30,
            type: MediaType.tv,
            title: 'Series30',
            seenDate: DateTime.now(),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
        ],
      );

      when(
        () => mockRepository.getMediaDetails(30, type: MediaType.tv),
      ).thenAnswer(
        (_) async => MediaDetails(
          item: MediaItem(
            id: 30,
            title: 'Series30',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.tv,
            seasons: [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
            status: 'Ended',
            lastSeasonNumber: 1,
            lastEpisodeNumber: 2,
          ),
          cast: [],
        ),
      );

      when(() => mockRepository.getSeasonDetails(30, 1)).thenAnswer(
        (_) async => {
          'episodes': [
            {
              'episode_number': 2,
              'air_date': DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
            },
          ],
        },
      );

      when(
        () => mockRepository.removeFromList(30, MediaType.tv, 'watchlist'),
      ).thenAnswer((_) async => {});

      // We need to build the QuickAddTab which is private; reuse the _QuickAddTab via NotificationCenterPage's _QuickAddTab
      // Refresh provider state so QuickAddTab sees the seen items
      // Ensure repository returns a QuickAdd entry so the QuickAdd tab renders
      when(() => mockRepository.getQuickAddItems()).thenAnswer((_) async => [
            QuickAddItem(
              isarId: null,
              tmdbId: 30,
              type: MediaType.tv,
              seasonNumber: 1,
              episodeNumber: 2,
              insertedAt: DateTime.now(),
              airDate: DateTime.now().subtract(const Duration(days: 1)),
              title: 'Series30',
              posterPath: null,
            )
          ]);

      await provider.loadAllSeenStatus();
      // Ensure quick-add items are loaded from repository stub
      await provider.loadQuickAddItems();
      await provider.loadWatchlist();
      await provider.loadNotifiedItems();

      await tester.pumpWidget(
        ChangeNotifierProvider<SearchProvider>.value(
          value: provider,
          child: const MaterialApp(home: NotificationCenterPage()),
        ),
      );

      await tester.pumpAndSettle();

      // The quick add tab is the second tab; open it
      await tester.tap(find.text('Quick Add'));
      await tester.pumpAndSettle();

      // There should be a check icon for marking next as seen
      final checkButtons = find.byIcon(Icons.check_circle_outline);
      expect(checkButtons, findsWidgets);

      await tester.tap(checkButtons.first);
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.removeFromList(30, MediaType.tv, 'watchlist'),
      ).called(1);
    },
  );
}
