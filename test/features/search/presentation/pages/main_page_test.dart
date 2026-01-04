import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    searchProvider = SearchProvider(mockMediaRepository);
    
    // Register the mock in GetIt locator because SavedMediaPage uses it directly
    locator.registerSingleton<MediaRepository>(mockMediaRepository);
    
    // Default mocks
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.isInWatchlist(any(), any())).thenAnswer((_) async => false);
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: const MaterialApp(
        home: MainPage(),
      ),
    );
  }

  group('MainPage Navigation', () {
    testWidgets('starts on SearchPage', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(SearchPage), findsOneWidget);
      
      // SavedMediaPage is in the IndexedStack but offstage, so we need skipOffstage: false
      expect(find.byType(SavedMediaPage, skipOffstage: false), findsOneWidget);
      
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);
    });

    testWidgets('switches to Watchlist tab', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Disambiguate by looking for the icon inside the BottomNavigationBar
      final bookmarkTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.bookmark),
      );
      
      await tester.tap(bookmarkTab);
      await tester.pumpAndSettle();
      
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);
      expect(find.byType(SavedMediaPage), findsOneWidget);
    });

    testWidgets('double-tapping Search tab requests reset and selects text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter some text
      await tester.enterText(find.byType(TextField), 'Dune');
      await tester.pump();
      
      // Tap Search tab icon in the BottomNavigationBar (disambiguate from TextField icon)
      final searchTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.search),
      );
      
      await tester.tap(searchTab);
      await tester.pumpAndSettle();

      // Check if text is selected
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.selection.baseOffset, 0);
      expect(textField.controller?.selection.extentOffset, 4);
    });

    testWidgets('double-tapping Search tab from detail page pops to root', (WidgetTester tester) async {
      final movie = const MediaItem(
        id: 1,
        title: 'Dune',
        posterPath: null,
        releaseDate: '2021',
        overview: 'Sand',
        mediaType: MediaType.movie,
      );
      
      when(() => mockMediaRepository.searchMedia('Dune', page: 1))
          .thenAnswer((_) async => [movie]);
      when(() => mockMediaRepository.getMediaDetails(1, type: any(named: 'type')))
          .thenAnswer((_) async => MediaDetails(item: movie, cast: []));
      when(() => mockMediaRepository.isInWatchlist(1, any())).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Search for a movie
      await tester.enterText(find.byType(TextField), 'Dune');
      await tester.pump(const Duration(milliseconds: 600)); // Debounce
      await tester.pump(); // Start search
      await tester.pump(); // Complete search

      // 2. Navigate to details
      await tester.tap(find.widgetWithText(ListTile, 'Dune'));
      await tester.pumpAndSettle();
      
      expect(find.text('Sand'), findsOneWidget); // On detail page

      // 3. Double tap search icon in BottomNavigationBar
      final searchTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.search),
      );
      await tester.tap(searchTab);
      
      // Use repeated pump instead of pumpAndSettle to avoid timeout from potential infinite animations
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 4. Should be back on search page results
      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.text('Sand'), findsNothing);
      
      // And text should be selected
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.selection.baseOffset, 0);
    });

    testWidgets('double-tapping Watchlist tab from detail page pops to root', (WidgetTester tester) async {
      final movie = const MediaItem(
        id: 1,
        title: 'Dune',
        posterPath: null,
        releaseDate: '2021',
        overview: 'Sand',
        mediaType: MediaType.movie,
      );

      // Setup for SavedMediaPage
      when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => ['1:movie']);
      when(() => mockMediaRepository.getMediaDetails(1, type: any(named: 'type')))
          .thenAnswer((_) async => MediaDetails(item: movie, cast: []));

      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Switch to Watchlist tab
      final bookmarkTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.bookmark),
      );
      await tester.tap(bookmarkTab);
      await tester.pumpAndSettle();
      
      expect(find.byType(SavedMediaPage), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);

      // 2. Navigate to details
      await tester.tap(find.widgetWithText(ListTile, 'Dune'));
      await tester.pumpAndSettle();
      
      expect(find.text('Sand'), findsOneWidget); // On detail page

      // 3. Double tap watchlist icon in BottomNavigationBar
      await tester.tap(bookmarkTab);
      
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 4. Should be back on SavedMediaPage root
      expect(find.byType(SavedMediaPage), findsOneWidget);
      expect(find.text('Sand'), findsNothing);
      
      // Verify loadSavedMedia was called
      verify(() => mockMediaRepository.getWatchlistEntries()).called(greaterThan(1));
    });
  });
}
