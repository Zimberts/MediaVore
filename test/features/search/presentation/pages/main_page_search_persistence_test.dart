import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
// Removed unused imports: media_details, seen_item, achievement, media_detail_page, search_overlay
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

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
    ).thenAnswer((_) => const Stream.empty());

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

  Widget createWidgetUnderTest() {
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

  testWidgets('discovery search stays active when using FAB across tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final discoverySearchFinder = find.byWidgetPredicate((w) {
      if (w is TextField) {
        return w.decoration?.hintText == 'Search within Discovery...';
      }
      return false;
    });

    // Initially no discovery search field
    expect(discoverySearchFinder, findsNothing);

    // 1. Trigger FAB - opens discovery search
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(discoverySearchFinder, findsOneWidget);

    // 2. Switch to Seen tab
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // 3. Trigger FAB again while on Seen - should keep discovery search active
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Now ensure discovery search is still active (this will fail with current behavior)
    expect(discoverySearchFinder, findsOneWidget);
  });
}
