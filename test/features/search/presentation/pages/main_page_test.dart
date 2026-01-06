import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
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
    
    // Default mocks for SearchProvider init
    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockMediaRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockMediaRepository);
    
    // Register the mock in GetIt locator because SavedMediaPage uses it directly
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerSingleton<MediaRepository>(mockMediaRepository);
    
    // Default mocks to prevent Null pointer errors during component initialization
    when(() => mockMediaRepository.isInWatchlist(any(), any())).thenAnswer((_) async => false);
    when(() => mockMediaRepository.getListPreviews(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
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
      
      expect(find.byType(SavedMediaPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(SeenHistoryPage, skipOffstage: false), findsOneWidget);
      
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);
    });

    testWidgets('switches to Watchlist tab', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
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

    testWidgets('switches to Seen tab', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      final seenTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.visibility),
      );
      
      await tester.tap(seenTab);
      await tester.pumpAndSettle();
      
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 2);
      expect(find.byType(SeenHistoryPage), findsOneWidget);
    });

    testWidgets('tapping Search tab requests reset and selects text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Dune');
      await tester.pump();
      
      final searchTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.search),
      );
      
      await tester.tap(searchTab);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.selection.baseOffset, 0);
      expect(textField.controller?.selection.extentOffset, 4);
    });

    testWidgets('tapping Watchlist tab from detail page pops to root', (WidgetTester tester) async {
      final movie = const MediaItem(
        id: 1,
        title: 'Dune',
        posterPath: null,
        releaseDate: '2021',
        overview: 'Sand',
        mediaType: MediaType.movie,
      );

      when(() => mockMediaRepository.getListEntries('watchlist')).thenAnswer((_) async => ['1:movie']);
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

      // 2. Navigate to details
      await tester.tap(find.widgetWithText(ListTile, 'Dune'));
      await tester.pumpAndSettle();
      
      expect(find.text('Sand'), findsOneWidget);

      // 3. Tap watchlist icon again
      await tester.tap(bookmarkTab);
      
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 4. Should be back on SavedMediaPage root
      expect(find.byType(SavedMediaPage), findsOneWidget);
      expect(find.text('Sand'), findsNothing);
    });

    testWidgets('tapping Watchlist tab on root resets to default list', (WidgetTester tester) async {
      // 1. Setup with a custom list
      when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist', 'Custom']);
      when(() => mockMediaRepository.getListEntries('Custom')).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());

      // 2. Switch to Watchlist tab
      final bookmarkTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.bookmark),
      );
      await tester.tap(bookmarkTab);
      await tester.pumpAndSettle();

      final listPicker = find.descendant(
        of: find.byType(SavedMediaPage),
        matching: find.text('Watchlist'),
      );
      
      await tester.tap(listPicker);
      await tester.pumpAndSettle();
      
      // Select Custom list from bottom sheet
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      
      expect(find.text('Custom'), findsOneWidget);
      
      // 4. Tap bookmarkTab again to reset
      await tester.tap(bookmarkTab);
      await tester.pumpAndSettle();
      
      // Verify the list title in SavedMediaPage is 'Watchlist'
      final currentListTitle = find.descendant(
        of: find.byType(SavedMediaPage),
        matching: find.text('Watchlist'),
      );
      expect(currentListTitle, findsOneWidget);
    });
  });
}
