import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late MockAchievementProvider mockAchievementProvider;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  late StreamController<Achievement> achievementStreamController;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();
    mockAchievementProvider = MockAchievementProvider();
    achievementStreamController = StreamController<Achievement>.broadcast();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.setStringList(any(), any())).thenAnswer((_) async => true);

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.discoverMedia(
      page: any(named: 'page'),
      type: any(named: 'type'),
      genreIds: any(named: 'genreIds'),
      releaseYear: any(named: 'releaseYear'),
      minRating: any(named: 'minRating'),
    )).thenAnswer((_) async => []);

    // Provide a dummy achievement to avoid infinite CircularProgressIndicator animation
    final dummyAchievement = Achievement(
      id: 'test_id',
      title: 'Epic Achievement',
      description: 'You did something great!',
      iconPath: 'icons/test.png',
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    when(() => mockAchievementProvider.achievements).thenReturn([dummyAchievement]);
    when(() => mockAchievementProvider.onAchievementUnlocked).thenAnswer((_) => achievementStreamController.stream);

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    // Register mocks in GetIt for widgets that use locator directly
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockRepository);
  });

  tearDown(() {
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    achievementStreamController.close();
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

  group('Achievement Requirements', () {
    testWidgets('shows notification pop-up when achievement is unlocked', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger initial builds

      final achievement = Achievement(
        id: 'test_id',
        title: 'Epic Achievement',
        description: 'You did something great!',
        iconPath: 'icons/test.png',
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      achievementStreamController.add(achievement);
      // Manual pumps are needed to avoid timeout from auto-dismissal timer.
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 500)); 

      expect(find.text('Achievement Unlocked!'), findsOneWidget);
      expect(find.text('Epic Achievement'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Verify it disappears after 5 seconds
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('Achievement Unlocked!'), findsNothing);
    });

    testWidgets('tapping notification leads to achievement details', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final achievement = Achievement(
        id: 'test_id',
        title: 'Epic Achievement',
        description: 'You did something great!',
        iconPath: 'icons/test.png',
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      achievementStreamController.add(achievement);
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 500)); 

      // Tap on the banner
      await tester.tap(find.text('Epic Achievement'));
      
      // Handle the sequence of dismissal and navigation
      await tester.pump(); // Trigger dismissal animation
      await tester.pump(const Duration(milliseconds: 600)); // Animation finish
      await tester.pump(); // Push route
      await tester.pump(const Duration(milliseconds: 500)); // Animation start
      await tester.pumpAndSettle(); // Finish everything

      expect(find.text('Achievements'), findsWidgets);
      expect(find.text('Overall Progress'), findsOneWidget);

      // Clean up any remaining overlay timers
      await tester.pump(const Duration(seconds: 5));
    });

    group('Date Seen Selection Requirements', () {
      testWidgets('tapping check_circle_outline opens date picker dialog with calendar by default', (WidgetTester tester) async {
        // Prepare discovery movie
        final movie = MediaItem(id: 1, title: 'Inception', overview: '', releaseDate: '2010', mediaType: MediaType.movie);
        
        // Mock getSeenStatus to return empty list (not seen)
        when(() => mockRepository.getSeenStatus(1, MediaType.movie)).thenAnswer((_) async => []);
        
        // Mock discovery results
        when(() => mockRepository.discoverMedia(
          page: any(named: 'page'), 
          type: MediaType.movie,
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
        )).thenAnswer((_) async => [movie]);

        // Mock MediaDetails for the DetailPage
        when(() => mockRepository.getMediaDetails(1, type: any(named: 'type'))).thenAnswer((_) async => MediaDetails(
          item: movie,
          cast: [],
        ));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle(); // Initial discover call

        // Ensure the movie is rendered
        expect(find.textContaining('Inception'), findsAtLeast(1));

        // Tapping the movie to go to details (where check_circle_outline button exists)
        await tester.tap(find.textContaining('Inception').first);
        await tester.pumpAndSettle();

        // Requirement: Date selection dialog opens
        // Tapping the seen icon (Icons.check_circle_outline) in MediaDetailPage action bar
        final seenIcon = find.byIcon(Icons.check_circle_outline);
        expect(seenIcon, findsOneWidget);
        await tester.tap(seenIcon);
        
        // Pump through dialog animation
        await tester.pump(); 
        await tester.pump(const Duration(milliseconds: 500));

        // Requirement: Date shown as a calendar defaulted to current
        expect(find.byType(CalendarDatePicker), findsOneWidget);
        expect(find.text('LOG VIEWING'), findsOneWidget);
      });
    });
  });
}
