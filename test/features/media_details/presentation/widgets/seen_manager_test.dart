import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;
  late MockSharedPreferences mockPrefs;
  late SettingsProvider settingsProvider;

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
    mockPrefs = MockSharedPreferences();

    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

    settingsProvider = SettingsProvider(
      mockPrefs,
      FakeTmdbCredentialStore(),
    );

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
    when(
      () => mockRepository.updateSeenEntry(any()),
    ).thenAnswer((_) async => Future.value());
    when(
      () => mockRepository.deleteSeenEntry(any()),
    ).thenAnswer((_) async => Future.value());
    when(
      () => mockRepository.getCacheUpdateDate(any(), any()),
    ).thenAnswer((_) async => DateTime.now());
    when(
      () => mockRepository.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer(
      (_) async => MediaDetails(
        item: const MediaItem(
          id: 1,
          title: 'T',
          overview: '',
          releaseDate: '',
        ),
        cast: [],
      ),
    );

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
    bool primary = false,
    int? seasonNumber,
    int? episodeNumber,
    String? status,
    int? lastSeasonNumber,
    int? lastEpisodeNumber,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: AppPalette.paper.toThemeData(),
        home: AppMessageHost(
          child: Scaffold(
            body: SeenManager(
              compact: compact,
              primary: primary,
              seasonNumber: seasonNumber,
              episodeNumber: episodeNumber,
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
      ),
    );
  }

  group('SeenManager - Simple mode (default)', () {
    testWidgets('displays check_circle_outline icon when not seen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

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
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping check_circle_outline marks immediately with DateTime.now() and shows Undo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      // No date picker dialog shown
      expect(find.byType(Dialog), findsNothing);
      verify(() => mockRepository.markAsSeen(any())).called(1);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('tapping check_circle icon (when seen) adds viewing immediately without dialog', (
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

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      verify(() => mockRepository.markAsSeen(any())).called(1);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when long-pressing to clear history', (
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

      await tester.longPress(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.text('Clear History'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.removeFromSeen(1, MediaType.movie)).called(1);
    });

    testWidgets('primary button has no dots and toggles from Mark as seen to Rewatch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(primary: true));
      await tester.pump();

      expect(find.text('Mark as seen'), findsOneWidget);
      expect(find.text('Mark as seen…'), findsNothing);

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

      await tester.pumpWidget(createWidgetUnderTest(primary: true));
      await tester.pump();

      expect(find.text('Rewatch'), findsOneWidget);
      expect(find.text('Rewatch…'), findsNothing);
    });
  });

  group('SeenManager - Advanced mode', () {
    setUp(() async {
      await settingsProvider.setAdvancedTracking(true);
    });

    testWidgets('primary button has dots (Mark as seen… / Rewatch…)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(primary: true));
      await tester.pump();

      expect(find.text('Mark as seen…'), findsOneWidget);

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

      await tester.pumpWidget(createWidgetUnderTest(primary: true));
      await tester.pump();

      expect(find.text('Rewatch…'), findsOneWidget);
    });

    testWidgets('tapping check_circle_outline opens date picker dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(type: MediaType.tv));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Mark as seen'), findsOneWidget);
      expect(find.text('LOG VIEWING'), findsOneWidget);

      await tester.tap(find.text('LOG VIEWING'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.markAsSeen(any())).called(1);
    });

    testWidgets('episode seen icon opens Visionnages bottom sheet', (
      WidgetTester tester,
    ) async {
      final viewings = [
        SeenItem(
          id: 1,
          tmdbId: 10,
          type: MediaType.tv,
          title: 'Show',
          seasonNumber: 1,
          episodeNumber: 1,
          seenDate: DateTime(2023, 5, 10, 20, 30),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(
        createWidgetUnderTest(
          tmdbId: 10,
          type: MediaType.tv,
          seasonNumber: 1,
          episodeNumber: 1,
          compact: true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Viewings'), findsOneWidget);
      expect(find.text('Add New Viewing'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('deleting a viewing from episode sheet requires confirmation', (
      WidgetTester tester,
    ) async {
      final viewings = [
        SeenItem(
          id: 42,
          tmdbId: 10,
          type: MediaType.tv,
          title: 'Show',
          seasonNumber: 1,
          episodeNumber: 1,
          seenDate: DateTime(2023, 5, 10, 20, 30),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(
        createWidgetUnderTest(
          tmdbId: 10,
          type: MediaType.tv,
          seasonNumber: 1,
          episodeNumber: 1,
          compact: true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Remove log?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.deleteSeenEntry(42)).called(1);
    });
  });

  group('Watchlist removal behaviour (Simple mode)', () {
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

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

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

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.removeFromList(1, MediaType.movie, 'watchlist'),
      ).called(1);
    });

    testWidgets('series middle episode in watchlist is not removed', (
      WidgetTester tester,
    ) async {
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => ['2:tv']);
      await searchProvider.loadWatchlist();

      when(
        () => mockRepository.removeFromList(2, MediaType.tv, 'watchlist'),
      ).thenAnswer((_) async => {});

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
          item: const MediaItem(
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

      await tester.pumpWidget(
        createWidgetUnderTest(
          tmdbId: 2,
          type: MediaType.tv,
          status: 'Ended',
          lastSeasonNumber: 5,
          lastEpisodeNumber: 10,
          seasonNumber: 3,
          episodeNumber: 4,
          compact: true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

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

      when(
        () => mockRepository.getMediaDetails(3, type: MediaType.tv),
      ).thenAnswer(
        (_) async => MediaDetails(
          item: const MediaItem(
            id: 3,
            title: 'Finale',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.tv,
            status: 'Ended',
            lastSeasonNumber: 2,
            lastEpisodeNumber: 8,
          ),
          cast: [],
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          tmdbId: 3,
          type: MediaType.tv,
          title: 'Finale',
          status: 'Ended',
          lastSeasonNumber: 2,
          lastEpisodeNumber: 8,
          seasonNumber: 2,
          episodeNumber: 8,
          compact: true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

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
        createWidgetUnderTest(
          tmdbId: 4,
          type: MediaType.tv,
          title: 'NotSaved',
          status: 'Ended',
          lastSeasonNumber: 1,
          lastEpisodeNumber: 1,
          seasonNumber: 1,
          episodeNumber: 1,
          compact: true,
        ),
      );
      await tester.pump();

      when(
        () => mockRepository.removeFromList(any(), any(), any()),
      ).thenAnswer((_) async => {});

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.removeFromList(any(), any(), any()));
    });

    testWidgets('series last episode but status not Ended does not remove', (
      WidgetTester tester,
    ) async {
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => ['5:tv']);
      await searchProvider.loadWatchlist();

      when(
        () => mockRepository.getMediaDetails(5, type: MediaType.tv),
      ).thenAnswer(
        (_) async => MediaDetails(
          item: const MediaItem(
            id: 5,
            title: 'Ongoing',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.tv,
            status: 'Returning Series',
            lastSeasonNumber: 1,
            lastEpisodeNumber: 10,
          ),
          cast: [],
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          tmdbId: 5,
          type: MediaType.tv,
          title: 'Ongoing',
          status: 'Returning Series',
          lastSeasonNumber: 1,
          lastEpisodeNumber: 10,
          seasonNumber: 1,
          episodeNumber: 10,
          compact: true,
        ),
      );
      await tester.pump();

      when(
        () => mockRepository.removeFromList(any(), any(), any()),
      ).thenAnswer((_) async => {});

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.removeFromList(any(), any(), any()));
    });
  });
}
