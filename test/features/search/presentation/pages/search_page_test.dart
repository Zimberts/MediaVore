import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

class FakeMediaItem extends Fake implements MediaItem {}

void main() {
  late MockMediaRepository mockMediaRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    searchProvider = SearchProvider(mockMediaRepository);
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
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
      await tester.tap(find.byIcon(Icons.search));
      
      // Use pump instead of pumpAndSettle because of the infinite CircularProgressIndicator
      await tester.pump(); // Trigger search
      await tester.pump(const Duration(milliseconds: 100)); // Wait for mock and rebuild

      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Breaking Bad'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget); 
    });

    testWidgets('shows initial message when search results are empty', (WidgetTester tester) async {
      when(() => mockMediaRepository.searchMedia(any(), page: any(named: 'page')))
          .thenThrow(Exception('Failed to load results'));

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ListTile), findsNothing);
      expect(find.text('Search for movies or series!'), findsOneWidget);
    });


    testWidgets('calls addToWatchlist when save button is tapped', (WidgetTester tester) async {
      final items = [
        const MediaItem(
          id: 1,
          title: 'Inception',
          posterPath: null,
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
          mediaType: MediaType.movie,
        ),
      ];
      when(() => mockMediaRepository.searchMedia('Inception', page: any(named: 'page')))
          .thenAnswer((_) async => items);
      when(() => mockMediaRepository.addToWatchlist(1, MediaType.movie)).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.bookmark_border).first);
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockMediaRepository.addToWatchlist(1, MediaType.movie)).called(1);
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
        MediaItem(
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
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Movie 0'), findsOneWidget);
      expect(find.text('Fetched Movie'), findsNothing);

      // Scroll to the bottom
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump(); // Trigger scroll listener
      await tester.pump(const Duration(milliseconds: 100)); // Wait for fetch

      expect(find.text('Fetched Movie'), findsOneWidget);
      verify(() => mockMediaRepository.searchMedia('test', page: 2)).called(1);
    });
  });
}
