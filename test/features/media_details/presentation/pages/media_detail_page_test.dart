import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    // Default mocks for SharedPreferences (used by SettingsProvider)
    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    // Default mocks for SearchProvider init
    when(
      () => mockMediaRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockMediaRepository.getListEntries(any()),
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
    settingsProvider = SettingsProvider(mockSharedPreferences);
    
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockMediaRepository);

    // Default mocks for UI components
    when(
      () => mockMediaRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getListPreviews(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getListPreviews(
        any(),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);
  });

  tearDown(() {
    locator.reset();
  });

  const tItem = MediaItem(
    id: 1,
    title: 'Inception',
    posterPath: '/poster.jpg',
    releaseDate: '2010-07-16',
    overview: 'A mind-bending thriller',
    mediaType: MediaType.movie,
  );

  final tCast = [
    const CastMember(
      id: 1,
      name: 'Leonardo DiCaprio',
      character: 'Cobb',
      profilePath: '/leo.jpg',
    ),
  ];

  const tDirector = CrewMember(name: 'Christopher Nolan', job: 'Director');

  final tMediaDetails = MediaDetails(
    item: tItem,
    cast: tCast,
    director: tDirector,
  );

  Widget createWidgetUnderTest({MediaItem? item}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: MediaDetailPage(item: item ?? tItem),
      ),
    );
  }

  group('MediaDetailPage', () {
    testWidgets('displays media details when loading is successful', (
      WidgetTester tester,
    ) async {
      when(
        () => mockMediaRepository.getMediaDetails(
          tItem.id,
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => tMediaDetails);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Run post-frame callbacks
      await tester.pumpAndSettle(); // Finish loading

      expect(find.text('Inception'), findsAtLeast(1));
      expect(find.text('2010-07-16'), findsOneWidget);
      expect(find.text('Director: Christopher Nolan'), findsOneWidget);
      expect(find.text('A mind-bending thriller'), findsOneWidget);

      // The page uses a CustomScrollView with slivers which build lazily.
      // Scroll the view so the sliver children (including the Cast header)
      // are built, then settle before asserting.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Cast'), findsOneWidget);
    });

    testWidgets(
      'counts unique episodes seen even if an episode is logged multiple times',
      (WidgetTester tester) async {
        final tTvItem = MediaItem(
          id: 2,
          title: 'Breaking Bad',
          mediaType: MediaType.tv,
          overview: '...',
          releaseDate: '2008-01-20',
          numberOfEpisodes: 8,
        );

        final tTvDetails = MediaDetails(
          item: tTvItem,
          cast: [],
          director: const CrewMember(name: 'Vince Gilligan', job: 'Director'),
        );

        final seenStatus = [
          SeenItem(
            id: 1,
            tmdbId: 2,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2023, 1, 1),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
          SeenItem(
            id: 2,
            tmdbId: 2,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seenDate: DateTime(2023, 1, 2),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
        ];

        when(
          () =>
              mockMediaRepository.getMediaDetails(2, type: any(named: 'type')),
        ).thenAnswer((_) async => tTvDetails);
        when(
          () => mockMediaRepository.getSeenStatus(2, any()),
        ).thenAnswer((_) async => seenStatus);

        await tester.pumpWidget(createWidgetUnderTest(item: tTvItem));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Progress: 1 / 8 episodes seen'), findsOneWidget);

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, 1 / 8);
      },
    );

    testWidgets('counts unique episodes for per-season progress', (
      WidgetTester tester,
    ) async {
      final tTvItem = MediaItem(
        id: 2,
        title: 'Breaking Bad',
        mediaType: MediaType.tv,
        overview: '...',
        releaseDate: '2008-01-20',
        numberOfEpisodes: 8,
        seasons: const [
          TVSeason(id: 1, seasonNumber: 1, episodeCount: 7, name: 'Season 1'),
        ],
      );

      final tTvDetails = MediaDetails(
        item: tTvItem,
        cast: [],
        director: const CrewMember(name: 'Vince Gilligan', job: 'Director'),
      );

      // S1 E1 seen twice
      final seenStatus = [
        SeenItem(
          id: 1,
          tmdbId: 2,
          type: MediaType.tv,
          title: 'Breaking Bad',
          seenDate: DateTime(2023, 1, 1),
          seasonNumber: 1,
          episodeNumber: 1,
        ),
        SeenItem(
          id: 2,
          tmdbId: 2,
          type: MediaType.tv,
          title: 'Breaking Bad',
          seenDate: DateTime(2023, 1, 2),
          seasonNumber: 1,
          episodeNumber: 1,
        ),
      ];

      when(
        () => mockMediaRepository.getMediaDetails(2, type: any(named: 'type')),
      ).thenAnswer((_) async => tTvDetails);
      when(
        () => mockMediaRepository.getSeenStatus(2, any()),
      ).thenAnswer((_) async => seenStatus);

      await tester.pumpWidget(createWidgetUnderTest(item: tTvItem));
      await tester.pump();
      await tester.pumpAndSettle();

      // Scroll to ensure sliver children (Seasons list) are built, then assert.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Check the season list tile subtitle
      expect(find.text('1 / 7 episodes seen'), findsOneWidget);
    });
  });
}
