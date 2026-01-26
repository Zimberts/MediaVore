import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/theme/app_palette.dart';

import '../../helpers/mocks.dart';
import 'package:mediavore/core/di/injection.dart';

void main() {
  late MockAchievementRepository mockAchievementRepo;
  late StreamController<List<Achievement>> ctrl;
  late MockMediaRepository mockMediaRepo;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeSeenItem());
  });

  setUp(() {
    mockAchievementRepo = MockAchievementRepository();
    ctrl = StreamController<List<Achievement>>();
    when(
      () => mockAchievementRepo.watchAchievements(),
    ).thenAnswer((_) => ctrl.stream);
    when(
      () => mockAchievementRepo.getAchievements(),
    ).thenAnswer((_) async => <Achievement>[]);
    when(
      () => mockAchievementRepo.unlockAchievement(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAchievementRepo.clearAchievements(),
    ).thenAnswer((_) async {});

    mockMediaRepo = MockMediaRepository();
    when(
      () => mockMediaRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockMediaRepo.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockMediaRepo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockMediaRepo.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockMediaRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockMediaRepo.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockMediaRepo.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockMediaRepo.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
  });

  tearDown(() {
    ctrl.close();
  });

  testWidgets('Achievement pop-up appears and navigates to AchievementsPage', (
    tester,
  ) async {
    final mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    final settings = SettingsProvider(mockPrefs);
    final achievementProvider = AchievementProvider(mockAchievementRepo);
    final searchProvider = SearchProvider(mockMediaRepo);

    // Register repository in the global locator - SavedMediaPage accesses it in initState
    locator.registerSingleton<MediaRepository>(mockMediaRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<AchievementProvider>.value(
            value: achievementProvider,
          ),
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const MainPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Emit an unlocked achievement
    final a = Achievement(
      id: 'a1',
      title: 'Test Badge',
      description: 'Desc',
      iconPath: '',
      isUnlocked: true,
      isPersisted: false,
      unlockedAt: DateTime.now(),
    );

    ctrl.add([a]);
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // The top banner should be present
    expect(find.text('Achievement Unlocked!'), findsOneWidget);
    expect(find.text('Test Badge'), findsOneWidget);

    // Tap the banner (tap the title)
    await tester.tap(find.text('Achievement Unlocked!'));
    await tester.pumpAndSettle();

    // Expect navigation to AchievementsPage
    expect(find.byType(AchievementsPage), findsOneWidget);

    // Allow the auto-dismiss timer to run so the test harness has no pending timers
    await tester.pump(const Duration(seconds: 5));

    // Cleanup locator registration
    await locator.reset();
  });
}
