import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(const MediaItem(
      id: 0,
      title: '',
      overview: '',
      posterPath: null,
      releaseDate: '',
      mediaType: MediaType.movie,
    ));
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    
    // Default mocks for initialization
    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockMediaRepository.addToList(any(), any())).thenAnswer((_) async => Future.value());

    searchProvider = SearchProvider(mockMediaRepository);
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: const MaterialApp(
        home: SearchPage(),
      ),
    );
  }

  group('SearchPage', () {
    testWidgets('clears text when clear button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.pump(); // Rebuild to show clear button

      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.text('Inception'), findsNothing);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('triggers search automatically after typing with debounce', (WidgetTester tester) async {
      final movies = [
        const MediaItem(
          id: 1,
          title: 'Inception',
          posterPath: null,
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
          mediaType: MediaType.movie
        ),
      ];
      when(() => mockMediaRepository.searchMedia('Inception', page: any(named: 'page')))
          .thenAnswer((_) async => movies);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      
      // Should not have triggered search immediately due to debounce
      verifyNever(() => mockMediaRepository.searchMedia('Inception', page: any(named: 'page')));

      // Wait for debounce (500ms)
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockMediaRepository.searchMedia('Inception', page: 1)).called(1);
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
    });

    testWidgets('displays results from TMDB when search is successful', (WidgetTester tester) async {
      final results = [
        const MediaItem(
          id: 1,
          title: 'Inception',
          posterPath: null,
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
          mediaType: MediaType.movie,
        ),
        const MediaItem(
          id: 2,
          title: 'Breaking Bad',
          posterPath: null,
          releaseDate: '2008-01-20',
          overview: 'A high school chemistry teacher...',
          mediaType: MediaType.tv,
        ),
      ];
      when(() => mockMediaRepository.searchMedia('Inception', page: any(named: 'page')))
          .thenAnswer((_) async => results);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Breaking Bad'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget); 
    });

    testWidgets('shows initial message when search results are empty', (WidgetTester tester) async {
      // Return empty list instead of throwing to test "Search for movies or series!"
      when(() => mockMediaRepository.searchMedia(any(), page: any(named: 'page')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ListTile), findsNothing);
      expect(find.text('Search for movies or series!'), findsOneWidget);
    });


    testWidgets('calls addToWatchlist when save button is tapped', (WidgetTester tester) async {
      final item = const MediaItem(
          id: 1,
          title: 'Inception',
          posterPath: null,
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
          mediaType: MediaType.movie,
        );
      final items = [item];
      
      when(() => mockMediaRepository.searchMedia('Inception', page: any(named: 'page')))
          .thenAnswer((_) async => items);
      when(() => mockMediaRepository.addToList(any(), any())).thenAnswer((_) async => Future.value());
      when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.bookmark_border).first);
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockMediaRepository.addToList(any(), 'watchlist')).called(1);
    });

    testWidgets('loads more movies when scrolled to bottom', (WidgetTester tester) async {
      final page1 = List.generate(20, (i) => MediaItem(
        id: i,
        title: 'Movie $i',
        posterPath: null,
        releaseDate: '2020-01-01',
        overview: 'Overview $i',
        mediaType: MediaType.movie,
      ));
      final page2 = [
        const MediaItem(
          id: 100,
          title: 'Fetched Movie',
          posterPath: null,
          releaseDate: '2021-01-01',
          overview: 'New movie',
          mediaType: MediaType.movie,
        ),
      ];

      when(() => mockMediaRepository.searchMedia('test', page: 1)).thenAnswer((_) async => page1);
      when(() => mockMediaRepository.searchMedia('test', page: 2)).thenAnswer((_) async => page2);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'test');
      // Wait for debounce instead of tapping non-existent button
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Movie 0'), findsOneWidget);
      expect(find.text('Fetched Movie'), findsNothing);

      // Scroll to the bottom
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pump(); // Trigger scroll listener
      await tester.pump(const Duration(milliseconds: 100)); // Wait for fetch
      await tester.pump(); // Rebuild with new items

      expect(find.text('Fetched Movie'), findsOneWidget);
      verify(() => mockMediaRepository.searchMedia('test', page: 2)).called(1);
    });
  });
}
