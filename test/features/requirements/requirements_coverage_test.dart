import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
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

  testWidgets('Requirements: core pages and providers exist', (tester) async {
    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    // Core widgets
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Providers available via context
    final context = tester.element(find.byType(MainPage));
    expect(context.read<SearchProvider>(), isA<SearchProvider>());
    expect(context.read<SettingsProvider>(), isA<SettingsProvider>());
    expect(context.read<AchievementProvider>(), isA<AchievementProvider>());

    // Access app colors (theming)
    final palette = DefaultLightPalette();
    final theme = palette.toThemeData();
    expect(theme, isNotNull);
  });

  testWidgets('Requirements: open MediaStats and Achievements pages', (
    tester,
  ) async {
    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    // Push MediaStatsPage
    final navigator = Navigator.of(tester.element(find.byType(MainPage)));
    navigator.push(MaterialPageRoute(builder: (_) => const MediaStatsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MediaStatsPage), findsOneWidget);

    // Push AchievementsPage
    navigator.push(MaterialPageRoute(builder: (_) => const AchievementsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(AchievementsPage), findsOneWidget);
  });

  testWidgets('Requirements: actor & media detail sheets available', (
    tester,
  ) async {
    final tItem = const MediaItem(
      id: 42,
      title: 'Test',
      overview: '',
      releaseDate: '2020',
      mediaType: MediaType.movie,
    );

    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => [tItem]);
    when(
      () => mockRepository.getMediaDetails(42, type: any(named: 'type')),
    ).thenAnswer((_) async => MediaDetails(item: tItem, cast: []));

    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    // Open media detail by tapping the discovery result
    await tester.tap(find.textContaining('Test').first);
    await tester.pumpAndSettle();
    expect(find.byType(MediaDetailPage), findsOneWidget);

    // Actor detail can be shown via ActorDetailPage.show (call directly)
    ActorDetailPage.show(
      tester.element(find.byType(MainPage)),
      actorId: 1,
      actorName: 'A',
    );
    await tester.pumpAndSettle();
    expect(find.byType(ActorDetailPage), findsOneWidget);
  });
}
