import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
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

/// Accessibility guideline checks (#208) on the four main tabs, with one item
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
    mediaType: MediaType.movie,
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
          seenDate: DateTime(2024, 1, 1),
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
    ).thenAnswer((_) => const Stream<Achievement>.empty());

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

  group('MainPage accessibility', () {
    // Bottom navigation labels, in tab order.
    for (final tab in ['Search', 'My Lists', 'Seen', 'Alerts']) {
      testWidgets('should label every tap target on the $tab tab', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('should give every IconButton a tooltip on the four tabs', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      for (final tab in ['Search', 'My Lists', 'Seen', 'Alerts']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();

        final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
        expect(buttons, isNotEmpty, reason: tab);
        for (final button in buttons) {
          expect(
            button.tooltip,
            isNotNull,
            reason: '$tab: IconButton(${button.icon}) has no tooltip',
          );
        }
      }
    });
  });
}
