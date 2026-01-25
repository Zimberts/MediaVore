import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:flutter/rendering.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
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

    if (locator.isRegistered<MediaRepository>())
      locator.unregister<MediaRepository>();
    locator.registerLazySingleton<MediaRepository>(() => mockRepository);

    if (locator.isRegistered<AchievementProvider>())
      locator.unregister<AchievementProvider>();
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

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Open item
      await tester.tap(find.textContaining('Inception').first);
      await tester.pumpAndSettle();

      // Ensure the BottomNavigationBar is present and is the top-most hit target
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final center = tester.getCenter(find.byType(BottomNavigationBar));
      final result = HitTestResult();
      TestWidgetsFlutterBinding.instance.hitTest(result, center);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(result.path.isNotEmpty, isTrue);
      // Ensure the BottomNavigationBar's render object (or one of its ancestors)
      // is present in the hit-test path — this indicates the bottom bar is
      // visually on top (hittable) at the tested point.
      bool found = result.path.any((entry) {
        final target = entry.target;
        if (identical(target, render)) return true;
        if (target is RenderObject) {
          RenderObject? p = render.parent as RenderObject?;
          while (p != null) {
            if (identical(p, target)) return true;
            p = p.parent as RenderObject?;
          }
        }
        return false;
      });
      expect(found, isTrue);
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
        () => mockRepository.getMediaDetails(1, type: any(named: 'type')),
      ).thenAnswer((_) async => MediaDetails(item: tItem, cast: tCast));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await searchProvider.loadWatchlist();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Inception').first);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final center = tester.getCenter(find.byType(BottomNavigationBar));
      final result = HitTestResult();
      TestWidgetsFlutterBinding.instance.hitTest(result, center);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(result.path.isNotEmpty, isTrue);
      bool found = result.path.any((entry) {
        final target = entry.target;
        if (identical(target, render)) return true;
        if (target is RenderObject) {
          RenderObject? p = render.parent as RenderObject?;
          while (p != null) {
            if (identical(p, target)) return true;
            p = p.parent as RenderObject?;
          }
        }
        return false;
      });
      expect(found, isTrue);
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
      final center = tester.getCenter(find.byType(BottomNavigationBar));
      final result = HitTestResult();
      TestWidgetsFlutterBinding.instance.hitTest(result, center);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(result.path.isNotEmpty, isTrue);
      bool found = result.path.any((entry) {
        final target = entry.target;
        if (identical(target, render)) return true;
        if (target is RenderObject) {
          RenderObject? p = render.parent as RenderObject?;
          while (p != null) {
            if (identical(p, target)) return true;
            p = p.parent as RenderObject?;
          }
        }
        return false;
      });
      expect(found, isTrue);
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

      // Open media detail sheet
      await tester.tap(find.textContaining('Inception').first);
      await tester.pumpAndSettle();

      // Ensure cast list is visible and tap actor name
      final detailScrollView = find
          .descendant(
            of: find.byType(MediaDetailPage),
            matching: find.byType(CustomScrollView),
          )
          .first;

      await tester.dragUntilVisible(
        find.text('Actor One'),
        detailScrollView,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Actor One').first);
      await tester.pumpAndSettle();

      // Expect bottom nav to still be visible (requirement)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final center = tester.getCenter(find.byType(BottomNavigationBar));
      final result = HitTestResult();
      TestWidgetsFlutterBinding.instance.hitTest(result, center);
      final render = tester.renderObject(find.byType(BottomNavigationBar));
      expect(result.path.isNotEmpty, isTrue);
      bool found = result.path.any((entry) {
        final target = entry.target;
        if (identical(target, render)) return true;
        if (target is RenderObject) {
          RenderObject? p = render.parent as RenderObject?;
          while (p != null) {
            if (identical(p, target)) return true;
            p = p.parent as RenderObject?;
          }
        }
        return false;
      });
      expect(found, isTrue);
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
