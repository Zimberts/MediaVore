import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/data/models/movie.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mediavore/features/search/presentation/providers/saved_movies_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/fixture_reader.dart';

class MockSavedMoviesProvider extends Mock implements SavedMoviesProvider {}

class FakeMovie extends Fake implements Movie {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockSavedMoviesProvider mockSavedMoviesProvider;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMovie());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockSavedMoviesProvider = MockSavedMoviesProvider();
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SavedMoviesProvider>.value(
      value: mockSavedMoviesProvider,
      child: MaterialApp(
        home: SearchPage(httpClient: mockHttpClient),
      ),
    );
  }

  group('SearchPage', () {
    testWidgets('displays results from TMDB when search is successful', (WidgetTester tester) async {
      final jsonResponse = fixture('movie_search_results.json');
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async => http.Response(jsonResponse, 200));
      when(() => mockSavedMoviesProvider.isMovieSaved(any())).thenReturn(false);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump(); 
      await tester.pump(); 

      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
    });

    testWidgets('shows error snackbar when server is unavailable', (WidgetTester tester) async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers'))).thenThrow(Exception('Server unreachable'));
      when(() => mockSavedMoviesProvider.isMovieSaved(any())).thenReturn(false);


      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Error: Exception: Server unreachable'), findsOneWidget);
    });

    testWidgets('calls toggleMovieSaved when save button is tapped', (WidgetTester tester) async {
      final jsonResponse = fixture('movie_search_results.json');
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async => http.Response(jsonResponse, 200));
      when(() => mockSavedMoviesProvider.isMovieSaved(any())).thenReturn(false);
      when(() => mockSavedMoviesProvider.toggleMovieSaved(any())).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.bookmark_border).first);

      verify(() => mockSavedMoviesProvider.toggleMovieSaved(any())).called(1);
    });
  });
}
