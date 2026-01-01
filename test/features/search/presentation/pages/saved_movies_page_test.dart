import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/core/domain/entities/movie_details.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';
import 'package:mediavore/features/search/presentation/pages/saved_movies_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

class FakeMovie extends Fake implements Movie {}
class FakeMovieDetails extends Fake implements MovieDetails {}

void main() {
  late MockMovieRepository mockMovieRepository;

  final movie = Movie(
    id: 1,
    title: 'Test Movie',
    overview: 'Test Overview',
    posterPath: '/test.jpg',
    releaseDate: '2022-01-01',
  );

  final movieDetails = MovieDetails(
    movie: movie,
    cast: [],
    director: null,
  );

  setUpAll(() {
    registerFallbackValue(FakeMovie());
    registerFallbackValue(FakeMovieDetails());
  });

  setUp(() {
    mockMovieRepository = MockMovieRepository();
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
    locator.registerLazySingleton<MovieRepository>(() => mockMovieRepository);
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: SavedMoviesPage(),
    );
  }

  testWidgets('displays empty message when no movies are saved', (WidgetTester tester) async {
    when(() => mockMovieRepository.getWatchlistMovieIds()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('No movies saved yet.'), findsOneWidget);
  });

  testWidgets('displays list of saved movies', (WidgetTester tester) async {
    when(() => mockMovieRepository.getWatchlistMovieIds()).thenAnswer((_) async => [1]);
    when(() => mockMovieRepository.getMovieDetails(1)).thenAnswer((_) async => movieDetails);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Test Movie'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('calls removeMovieFromWatchlist when delete button is tapped', (WidgetTester tester) async {
    when(() => mockMovieRepository.getWatchlistMovieIds()).thenAnswer((_) async => [1]);
    when(() => mockMovieRepository.getMovieDetails(1)).thenAnswer((_) async => movieDetails);
    when(() => mockMovieRepository.removeMovieFromWatchlist(1)).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete));

    verify(() => mockMovieRepository.removeMovieFromWatchlist(1)).called(1);
  });
}
