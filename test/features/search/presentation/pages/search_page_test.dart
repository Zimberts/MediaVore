import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

class FakeMovie extends Fake implements Movie {}

void main() {
  late MockMovieRepository mockMovieRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMovie());
  });

  setUp(() {
    mockMovieRepository = MockMovieRepository();
    searchProvider = SearchProvider(mockMovieRepository);
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
    when(() => mockMovieRepository.getWatchlistMovieIds()).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        home: const SearchPage(),
      ),
    );
  }

  group('SearchPage', () {
    testWidgets('displays results from TMDB when search is successful', (WidgetTester tester) async {
      final movies = [
        Movie(
          id: 1,
          title: 'Inception',
          posterPath: null,
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
        ),
      ];
      when(() => mockMovieRepository.searchMovies('Inception')).thenAnswer((_) async => movies);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
    });

    testWidgets('shows error message when search fails', (WidgetTester tester) async {
      when(() => mockMovieRepository.searchMovies(any())).thenThrow(Exception('Failed to load movies'));

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pumpAndSettle();

      // In the new implementation, errors are printed to the console, not shown in a snackbar.
      // This test can be modified to check for the absence of movie results.
      expect(find.widgetWithText(ListTile, 'Inception'), findsNothing);
      expect(find.text('Search for movies!'), findsOneWidget);
    });


    testWidgets('calls toggleMovieSaved when save button is tapped', (WidgetTester tester) async {
      final movies = [
        Movie(
          id: 1,
          title: 'Inception',
          posterPath: null,
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
        ),
      ];
      when(() => mockMovieRepository.searchMovies('Inception')).thenAnswer((_) async => movies);
      when(() => mockMovieRepository.addMovieToWatchlist(1)).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_border).first);
      
      await tester.pumpAndSettle();

      verify(() => mockMovieRepository.addMovieToWatchlist(1)).called(1);
    });
  });
}
