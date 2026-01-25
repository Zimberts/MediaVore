import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late MockAchievementProvider mockAchievementProvider;
  late SettingsProvider settingsProvider;
  late SearchProvider searchProvider;

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();
    mockAchievementProvider = MockAchievementProvider();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setStringList(any(), any())).thenAnswer((_) async => true);

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

    // Provide a dummy achievement to avoid infinite CircularProgressIndicator animation
    when(() => mockAchievementProvider.achievements).thenReturn([
      const Achievement(
        id: '1',
        title: 'Test',
        description: 'Test desc',
        iconPath: '',
        isUnlocked: false,
      ),
    ]);

    settingsProvider = SettingsProvider(mockSharedPreferences);
    searchProvider = SearchProvider(mockRepository);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<AchievementProvider>.value(value: mockAchievementProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const SettingsPage(),
      ),
    );
  }

  group('Settings Page Requirements', () {
    testWidgets('displays all required sections', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Gaming & Milestones'), findsOneWidget);
      expect(find.text('Lists Display'), findsOneWidget);
      expect(find.text('Storage & History'), findsOneWidget);
      
      await tester.scrollUntilVisible(find.byType(AboutListTile), 100);
      expect(find.byType(AboutListTile), findsOneWidget);
    });

    testWidgets('can toggle theme mode', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<ThemeMode>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final darkItem = find.text('Dark').last;
      await tester.tap(darkItem);
      await tester.pumpAndSettle();

      expect(settingsProvider.themeMode, ThemeMode.dark);
    });

    testWidgets('navigates to Achievements', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Achievements'));
      // Use pump() and then a smaller pumpAndSettle or just multiple pumps if animations persist
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Overall Progress'), findsOneWidget); 
    });
  });
}
