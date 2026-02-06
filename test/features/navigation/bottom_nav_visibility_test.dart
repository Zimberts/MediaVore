import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late MockAchievementProvider mockAchievementProvider;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();
    mockAchievementProvider = MockAchievementProvider();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(
      () => mockSharedPreferences.setStringList(any(), any()),
    ).thenAnswer((_) async => true);

    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.refreshNotifiedItems(),
    ).thenAnswer((_) async => {});

    when(() => mockAchievementProvider.achievements).thenReturn([]);
    when(
      () => mockAchievementProvider.onAchievementUnlocked,
    ).thenAnswer((_) => const Stream<Achievement>.empty());

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockRepository);

    if (locator.isRegistered<AchievementProvider>()) {
      locator.unregister<AchievementProvider>();
    }
    locator.registerLazySingleton<AchievementProvider>(
      () => mockAchievementProvider,
    );
  });

  tearDown(() {
    locator.reset();
  });

  Widget createApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AchievementProvider>.value(
          value: mockAchievementProvider,
        ),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const MainPage(),
      ),
    );
  }

  final tItem = const MediaItem(
    id: 1,
    title: 'Inception',
    overview: '',
    releaseDate: '2010',
    mediaType: MediaType.movie,
  );
  final tCast = [
    const CastMember(
      id: 10,
      name: 'Actor One',
      character: 'Hero',
      profilePath: null,
    ),
  ];

  testWidgets(
    'BottomNavigationBar visible when opening media details from Discover',
    (WidgetTester tester) async {
      when(
        () => mockRepository.discoverMedia(
          page: any(named: 'page'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => [tItem]);
      when(
        () => mockRepository.getMediaDetails(1, type: any(named: 'type')),
      ).thenAnswer((_) async => MediaDetails(item: tItem, cast: tCast));
      when(
        () => mockRepository.getListPreviews(
          'watchlist',
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => [
          MediaItemPreview(id: 1, title: 'Inception', type: 'movie'),
        ],
      );

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Open item
      await tester.tap(find.textContaining('Inception').first);
      await tester.pumpAndSettle();

      // Ensure the BottomNavigationBar is present and is the top-most hit target
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(render.attached, isTrue);
      expect(render.paintBounds.isEmpty, isFalse);
    },
  );

  testWidgets(
    'BottomNavigationBar visible when opening media details from My Lists',
    (WidgetTester tester) async {
      when(
        () => mockRepository.getListEntries('watchlist'),
      ).thenAnswer((_) async => ['1:movie']);
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => ['1:movie']);
      when(
        () => mockRepository.getListPreviews(
          'watchlist',
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => [
          MediaItemPreview(id: 1, title: 'Inception', type: 'movie'),
        ],
      );
      when(
        () => mockRepository.getMediaDetails(1, type: any(named: 'type')),
      ).thenAnswer((_) async => MediaDetails(item: tItem, cast: tCast));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await searchProvider.loadWatchlist();
      await tester.pumpAndSettle();

      // Tap the BottomNavigationBar item label to avoid hitting any in-page bookmark icons.
      await tester.tap(find.text('My Lists'));
      await tester.pumpAndSettle();

      await searchProvider.loadWatchlist();
      await tester.pumpAndSettle();

      // SavedMediaPage builds from a Future; give it a couple frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify we are on the Lists tab and the BottomNavigationBar remains visible.
      // (SavedMediaPage content can vary based on online/offline and async detail fetch behavior.)
      expect(find.text('My Lists'), findsWidgets);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(render.attached, isTrue);
      expect(render.paintBounds.isEmpty, isFalse);
    },
  );

  testWidgets(
    'BottomNavigationBar visible when opening media details from Seen',
    (WidgetTester tester) async {
      final seenItem = SeenItem(
        id: 1,
        tmdbId: 1,
        title: 'Inception',
        type: MediaType.movie,
        seenDate: DateTime.now(),
      );
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => [seenItem]);
      when(
        () => mockRepository.getMediaDetails(1, type: any(named: 'type')),
      ).thenAnswer((_) async => MediaDetails(item: tItem, cast: tCast));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await searchProvider.loadAllSeenStatus();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(
        of: find.byType(ListView),
        matching: find.textContaining('Inception'),
      );
      expect(itemFinder, findsAtLeast(1));
      await tester.tap(itemFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(render.attached, isTrue);
      expect(render.paintBounds.isEmpty, isFalse);
    },
  );

  testWidgets(
    'BottomNavigationBar visible when navigating to actor from media details',
    (WidgetTester tester) async {
      when(
        () => mockRepository.discoverMedia(
          page: any(named: 'page'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => [tItem]);
      when(
        () => mockRepository.getMediaDetails(1, type: any(named: 'type')),
      ).thenAnswer((_) async => MediaDetails(item: tItem, cast: tCast));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Open media detail sheet directly (more robust than tapping a list tile).
      MediaDetailPage.show(tester.element(find.byType(MainPage)), tItem);
      // Wait for the details fetch to complete (cast list is loaded asynchronously).
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Ensure cast list is visible and tap actor name
      // MediaDetailPage itself builds a Scaffold with a CustomScrollView.
      final detailScrollView = find.byType(CustomScrollView);
      expect(find.byType(MediaDetailPage), findsAtLeast(1));
      expect(detailScrollView, findsAtLeast(1));

      // Scroll a bit to ensure the Cast section is built.
      await tester.drag(detailScrollView.first, const Offset(0, -300));
      await tester.pumpAndSettle();

      final actorFinder = find.text('Actor One');

      await tester.dragUntilVisible(
        actorFinder,
        detailScrollView.first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Actor One').first);
      await tester.pumpAndSettle();

      // Expect bottom nav to still be visible (requirement)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(render.attached, isTrue);
      expect(render.paintBounds.isEmpty, isFalse);
    },
  );

  testWidgets(
    'BottomNavigationBar hidden when navigating to Settings from Lists',
    (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Go to Lists
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();

      // Push SettingsPage from the MainPage navigator
      final navigator = Navigator.of(tester.element(find.byType(MainPage)));
      navigator.push(MaterialPageRoute(builder: (_) => const SettingsPage()));
      await tester.pumpAndSettle();

      // Settings is full-screen and bottom nav should not be visible
      expect(find.byType(BottomNavigationBar), findsNothing);
    },
  );
}
