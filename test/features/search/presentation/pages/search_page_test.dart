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
      when(() => mockMediaRepository.searchMedia('Inception')).thenAnswer((_) async => results);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Breaking Bad'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget); 
    });

    testWidgets('shows initial message when search results are empty', (WidgetTester tester) async {
      when(() => mockMediaRepository.searchMedia(any())).thenThrow(Exception('Failed to load results'));

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pumpAndSettle();

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
      when(() => mockMediaRepository.searchMedia('Inception')).thenAnswer((_) async => items);
      when(() => mockMediaRepository.addToWatchlist(1, MediaType.movie)).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_border).first);
      
      await tester.pumpAndSettle();

      verify(() => mockMediaRepository.addToWatchlist(1, MediaType.movie)).called(1);
    });
  });
}
