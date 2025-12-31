import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/data/models/movie.dart';
import 'package:mediavore/features/search/presentation/pages/saved_movies_page.dart';
import 'package:mediavore/features/search/presentation/providers/saved_movies_provider.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

class MockSavedMoviesProvider extends Mock implements SavedMoviesProvider {}
class FakeMovie extends Fake implements Movie {}


void main() {
  late MockSavedMoviesProvider mockSavedMoviesProvider;

  final movie = Movie(
    id: 1,
    title: 'Test Movie',
    overview: 'Test Overview',
    posterPath: '/test.jpg',
    releaseDate: '2022-01-01',
  );

  setUpAll(() {
    registerFallbackValue(FakeMovie());
  });

  setUp(() {
    mockSavedMoviesProvider = MockSavedMoviesProvider();
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SavedMoviesProvider>.value(
      value: mockSavedMoviesProvider,
      child: const MaterialApp(
        home: SavedMoviesPage(),
      ),
    );
  }

  testWidgets('displays empty message when no movies are saved', (WidgetTester tester) async {
    when(() => mockSavedMoviesProvider.savedMovies).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('No movies saved yet.'), findsOneWidget);
  });

  testWidgets('displays list of saved movies', (WidgetTester tester) async {
    when(() => mockSavedMoviesProvider.savedMovies).thenReturn([movie]);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Test Movie'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('calls toggleMovieSaved when delete button is tapped', (WidgetTester tester) async {
    when(() => mockSavedMoviesProvider.savedMovies).thenReturn([movie]);
    when(() => mockSavedMoviesProvider.toggleMovieSaved(movie)).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.delete));

    verify(() => mockSavedMoviesProvider.toggleMovieSaved(movie)).called(1);
  });
}
