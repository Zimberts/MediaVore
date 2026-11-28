import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/navigation/app_tab_bar.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/discovery/presentation/providers/swipe_session_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

/// Accessibility guideline checks (#208) on every tab, with one item
/// per tab so that posters, cards and their icon buttons are rendered.
void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late MockAchievementProvider mockAchievementProvider;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  const movie = MediaItem(
    id: 1,
    title: 'Inception',
    overview: 'Overview',
    releaseDate: '2010-07-16',
  );

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();
    mockAchievementProvider = MockAchievementProvider();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => ['1:movie']);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => ['1:movie']);
    when(
      () => mockRepository.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => MediaDetails(item: movie, cast: []));
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer(
      (_) async => [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2024),
        ),
      ],
    );
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer(
      (_) async => [
        NotifiedItem(
          tmdbId: 2,
          type: MediaType.movie,
          title: 'Dune',
          releaseDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );
    when(
      () => mockRepository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockRepository.getQuickAddItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => [movie]);

    when(() => mockAchievementProvider.achievements).thenReturn([]);
    when(
      () => mockAchievementProvider.onAchievementUnlocked,
    ).thenAnswer((_) => const Stream<List<Achievement>>.empty());

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(
      mockSharedPreferences,
      FakeTmdbCredentialStore('fake_api_key'),
    );

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

  tearDown(locator.reset);

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AchievementProvider>.value(
          value: mockAchievementProvider,
        ),
        ChangeNotifierProvider(create: (_) => SwipeSessionProvider()),
        ChangeNotifierProvider(create: (_) => TogetherSessionProvider()),
      ],
      child: MaterialApp(
        theme: const DefaultLightPalette().toThemeData(),
        home: const MainPage(),
      ),
    );
  }

  Future<void> goTo(WidgetTester tester, AppTab tab) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppTabBar),
        matching: find.byKey(ValueKey(tab)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens [tab]; the Library tab is visited once per section.
  Future<void> forEachScreen(
    WidgetTester tester,
    Future<void> Function(String screen) check,
  ) async {
    for (final tab in AppTab.values) {
      await goTo(tester, tab);
      await check(tab.name);
      if (tab == AppTab.library) {
        await tester.tap(find.text('History').first);
        await tester.pumpAndSettle();
        await check('library, history');
      }
    }
  }

  group('MainPage accessibility', () {
    testWidgets('should label every tap target on every tab', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await forEachScreen(tester, (screen) async {
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: screen,
        );
      });
      handle.dispose();
    });

    testWidgets('should give every IconButton a tooltip on every tab', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await forEachScreen(tester, (screen) async {
        final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
        for (final button in buttons) {
          expect(
            button.tooltip,
            isNotNull,
            reason: '$screen: IconButton(${button.icon}) has no tooltip',
          );
        }
      });
    });
  });
}
