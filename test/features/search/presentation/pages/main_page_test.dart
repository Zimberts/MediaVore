import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/search_overlay.dart';
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
    registerFallbackValue(const MediaItem(id: 0, title: '', overview: '', releaseDate: ''));
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();
    mockAchievementProvider = MockAchievementProvider();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.setStringList(any(), any())).thenAnswer((_) async => true);

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.discoverMedia(
      page: any(named: 'page'),
      type: any(named: 'type'),
      genreIds: any(named: 'genreIds'),
      releaseYear: any(named: 'releaseYear'),
      minRating: any(named: 'minRating'),
    )).thenAnswer((_) async => []);
    when(() => mockRepository.refreshNotifiedItems()).thenAnswer((_) async => {});

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
    expect(find.text('Discover'), findsWidgets); 
    
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

  testWidgets('search, add to watchlist, and verify direct update in Lists tab', (WidgetTester tester) async {
    final tItem = const MediaItem(id: 1, title: 'Inception', overview: '', releaseDate: '2010', mediaType: MediaType.movie);
    
    // Mock search results
    when(() => mockRepository.searchMedia(any(), page: any(named: 'page')))
        .thenAnswer((_) async => [tItem]);
    
    // Mock addition
    when(() => mockRepository.addToList(any(), 'watchlist')).thenAnswer((_) async => {});
    when(() => mockRepository.toggleNotification(any(), autoNotify: true)).thenAnswer((_) async => {});
    
    // Mock the repository reflecting the new state
    var currentEntries = <String>[];
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => currentEntries);
    when(() => mockRepository.getListEntries('watchlist')).thenAnswer((_) async => currentEntries);
    when(() => mockRepository.getMediaDetails(1, type: any(named: 'type')))
        .thenAnswer((_) async => MediaDetails(item: tItem, cast: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Open search overlay using FAB explicitly
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 2. Search for the media
    final searchField = find.descendant(of: find.byType(SearchOverlay), matching: find.byType(TextField));
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'Inception');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Expect the result in the list
    expect(find.descendant(of: find.byType(ListView), matching: find.text('Inception')), findsOneWidget);

    // 3. Add to watchlist
    final addButton = find.byIcon(Icons.bookmark_add_outlined);
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    currentEntries.add('1:movie'); 
    
    // Sync state
    await searchProvider.loadWatchlist();
    await tester.pumpAndSettle();

    // 4. Close search overlay.
    // Use manual pop to avoid flaky back button finders in fullscreen dialogs.
    final navigator = Navigator.of(tester.element(find.byType(SearchOverlay)));
    navigator.pop();
    await tester.pumpAndSettle();
    
    // Switch to Lists tab
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    // 5. Verify it is there directly
    expect(find.textContaining('Inception'), findsAtLeast(1));
  });

  testWidgets('removing from details accessed via List removes directly from List', (WidgetTester tester) async {
    final tItem = const MediaItem(id: 1, title: 'Inception', overview: '', releaseDate: '2010', mediaType: MediaType.movie);
    var currentEntries = <String>['1:movie'];

    // Mock initial state with item in list
    when(() => mockRepository.getListEntries('watchlist')).thenAnswer((_) async => currentEntries);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => currentEntries);
    when(() => mockRepository.getMediaDetails(1, type: any(named: 'type')))
        .thenAnswer((_) async => MediaDetails(item: tItem, cast: []));
    when(() => mockRepository.removeFromList(1, MediaType.movie, 'watchlist')).thenAnswer((_) async {
      currentEntries.remove('1:movie');
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Ensure state is loaded
    await searchProvider.loadWatchlist();
    await tester.pumpAndSettle();

    // 1. Go to Lists
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(find.textContaining('Inception'), findsAtLeast(1));

    // 2. Open Details from List
    await tester.tap(find.textContaining('Inception').first);
    await tester.pumpAndSettle();

    // 3. Remove from watchlist
    // Use a specific finder for the CustomScrollView in the detail page to avoid ambiguity.
    // DraggableScrollableSheet uses a scroll controller that might create its own scroll view.
    final detailScrollView = find.descendant(
      of: find.byType(MediaDetailPage), 
      matching: find.byType(CustomScrollView)
    ).first; 
    
    await tester.dragUntilVisible(
      find.text('On Watchlist'),
      detailScrollView,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    final onWatchlistButton = find.text('On Watchlist');
    expect(onWatchlistButton, findsOneWidget);
    await tester.tap(onWatchlistButton); 
    
    // Sync state
    await searchProvider.loadWatchlist();
    await tester.pumpAndSettle();

    // 4. Close details sheet.
    // When isSheet is true, MediaDetailPage provides a keyboard_arrow_down icon to dismiss.
    final dismissIcon = find.descendant(
      of: find.byType(MediaDetailPage), 
      matching: find.byIcon(Icons.keyboard_arrow_down)
    );
    await tester.tap(dismissIcon);
    await tester.pumpAndSettle();

    // 5. Verify it is GONE directly
    expect(find.textContaining('Inception'), findsNothing);
  });

  group('MediaDetailPage Accessibility from all tabs', () {
    final tItem = const MediaItem(id: 1, title: 'Inception', overview: '', releaseDate: '2010', mediaType: MediaType.movie);
    final tDetails = MediaDetails(item: tItem, cast: []);

    setUp(() {
      when(() => mockRepository.getMediaDetails(any(), type: any(named: 'type'))).thenAnswer((_) async => tDetails);
      when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    });

    testWidgets('access from Search tab shows navigation bar', (WidgetTester tester) async {
      when(() => mockRepository.discoverMedia(page: any(named: 'page'), type: any(named: 'type')))
          .thenAnswer((_) async => [tItem]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Inception').first);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('access from List tab shows navigation bar', (WidgetTester tester) async {
      when(() => mockRepository.getListEntries('watchlist')).thenAnswer((_) async => ['1:movie']);
      when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => ['1:movie']);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Ensure provider state is synced before interacting with tabs that depend on it
      await searchProvider.loadWatchlist();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Inception').first);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('access from Seen tab shows navigation bar', (WidgetTester tester) async {
      final seenItem = SeenItem(id: 1, tmdbId: 1, title: 'Inception', type: MediaType.movie, seenDate: DateTime.now());
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => [seenItem]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      await searchProvider.loadAllSeenStatus();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(of: find.byType(ListView), matching: find.textContaining('Inception'));
      expect(itemFinder, findsAtLeast(1));
      await tester.tap(itemFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('access from Notif tab shows navigation bar', (WidgetTester tester) async {
      final now = DateTime.now();
      final notified = NotifiedItem(tmdbId: 1, title: 'Inception', type: MediaType.movie, releaseDate: now);
      
      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => [notified]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await searchProvider.loadNotifiedItems();
      await searchProvider.loadAllSeenStatus();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(of: find.byType(ListView), matching: find.textContaining('Inception'));
      expect(itemFinder, findsAtLeast(1));
      await tester.tap(itemFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
