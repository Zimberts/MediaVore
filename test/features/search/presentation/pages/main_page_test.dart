import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
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
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();
    mockAchievementProvider = MockAchievementProvider();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.discoverMedia(
      page: any(named: 'page'),
      type: any(named: 'type'),
    )).thenAnswer((_) async => []);

    // Achievement Provider mocks
    when(() => mockAchievementProvider.achievements).thenReturn([]);
    when(() => mockAchievementProvider.onAchievementUnlocked).thenAnswer((_) => const Stream<Achievement>.empty());

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockRepository);
    
    if (locator.isRegistered<AchievementProvider>()) {
      locator.unregister<AchievementProvider>();
    }
    locator.registerLazySingleton<AchievementProvider>(() => mockAchievementProvider);
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AchievementProvider>.value(value: mockAchievementProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const MainPage(),
      ),
    );
  }

  testWidgets('navigation switches tabs correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Initially on Discover (SearchPage)
    expect(find.text('Discover'), findsWidgets); // Tab bar label and AppBar title
    
    // Tap My Lists
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    
    expect(searchProvider.selectedTab, 1);
    expect(find.text('My Lists'), findsWidgets);

    // Tap Seen
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    
    expect(searchProvider.selectedTab, 2);
    expect(find.text('Seen History'), findsOneWidget);
  });

  testWidgets('FAB opens discovery search bar and switches to Discover', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    expect(searchProvider.selectedTab, 1);
    expect(find.text('My Lists'), findsWidgets);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(searchProvider.selectedTab, 0);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search within Discovery...',
      ),
      findsOneWidget,
    );
  });
}
