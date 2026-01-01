import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/core/domain/entities/movie_details.dart';
import 'package:mediavore/features/movie_details/presentation/pages/movie_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';
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
    when(() => mockMovieRepository.isMovieInWatchlist(any())).thenAnswer((_) async => false);
  });

  tearDown(() {
    locator.reset();
  });

  const tMovie = Movie(
    id: 1,
    title: 'Inception',
    posterPath: '/poster.jpg',
    releaseDate: '2010-07-16',
    overview: 'A mind-bending thriller',
  );

  final tCast = [
    const CastMember(name: 'Leonardo DiCaprio', character: 'Cobb', profilePath: '/leo.jpg'),
  ];

  const tDirector = CrewMember(name: 'Christopher Nolan', job: 'Director');

  final tMovieDetails = MovieDetails(
    movie: tMovie,
    cast: tCast,
    director: tDirector,
  );

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MovieDetailPage(movie: tMovie),
    );
  }

  group('MovieDetailPage', () {
    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      // arrange
      when(() => mockMovieRepository.getMovieDetails(tMovie.id))
          .thenAnswer((_) async => tMovieDetails);

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget); // AppBar title
    });

    testWidgets('displays movie details when loading is successful', (WidgetTester tester) async {
      // arrange
      when(() => mockMovieRepository.getMovieDetails(tMovie.id))
          .thenAnswer((_) async => tMovieDetails);

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the future

      // assert
      expect(find.text('Inception'), findsNWidgets(2)); // Title in appbar and body
      expect(find.text('Release Date: 2010-07-16'), findsOneWidget);
      expect(find.text('Director: Christopher Nolan'), findsOneWidget);
      expect(find.text('A mind-bending thriller'), findsOneWidget);
      expect(find.text('Cast'), findsOneWidget);
      expect(find.text('Leonardo DiCaprio'), findsOneWidget);
    });

    testWidgets('displays error message when loading fails', (WidgetTester tester) async {
      // arrange
      when(() => mockMovieRepository.getMovieDetails(tMovie.id))
          .thenThrow(Exception('Network error'));

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the future

      // assert
      expect(find.text('Inception'), findsNWidgets(2)); // Title in appbar and body
      expect(find.text('A mind-bending thriller'), findsOneWidget);
      expect(find.text('Failed to load additional details.'), findsOneWidget);
    });

    testWidgets('displays fallback movie data when details fail to load', (WidgetTester tester) async {
      // arrange
      when(() => mockMovieRepository.getMovieDetails(tMovie.id))
          .thenThrow(Exception('Network error'));

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the future

      // assert
      expect(find.text('Inception'), findsNWidgets(2)); // AppBar and body
      expect(find.text('A mind-bending thriller'), findsOneWidget);
      expect(find.text('Failed to load additional details.'), findsOneWidget);
    });
  });
}