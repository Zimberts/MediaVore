import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

class FakeMovie extends Fake implements Movie {}

void main() {
  late MockMovieRepository mockMovieRepository;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMovie());
  });

  setUp(() {
    mockMovieRepository = MockMovieRepository();
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
    // Register mock repository
    locator.registerLazySingleton<MovieRepository>(() => mockMovieRepository);
    when(() => mockMovieRepository.getWatchlistMovieIds()).thenAnswer((_) async => []);
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: const SearchPage(),
    );
  }

  group('SearchPage', () {
    testWidgets('displays results from TMDB when search is successful', (WidgetTester tester) async {
      final movies = [
        Movie(
          id: 1,
          title: 'Inception',
          posterPath: '/poster.jpg',
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
        ),
      ];
      when(() => mockMovieRepository.searchMovies('Inception')).thenAnswer((_) async => movies);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump(); 
      await tester.pump(); 

      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
    });

    testWidgets('shows error snackbar when server is unavailable', (WidgetTester tester) async {
      when(() => mockMovieRepository.searchMovies('Inception')).thenThrow(Exception('Server unreachable'));

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump();
      await tester.pump();

      expect(find.text('Failed to load movies: Exception: Server unreachable'), findsOneWidget);
    });

    testWidgets('calls toggleMovieSaved when save button is tapped', (WidgetTester tester) async {
      final movies = [
        Movie(
          id: 1,
          title: 'Inception',
          posterPath: '/poster.jpg',
          releaseDate: '2010-07-16',
          overview: 'A mind-bending thriller',
        ),
      ];
      when(() => mockMovieRepository.searchMovies('Inception')).thenAnswer((_) async => movies);
      when(() => mockMovieRepository.addMovieToWatchlist(1)).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.bookmark_border).first);

      verify(() => mockMovieRepository.addMovieToWatchlist(1)).called(1);
    });
  });
}
