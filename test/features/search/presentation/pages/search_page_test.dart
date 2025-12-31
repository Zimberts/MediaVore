import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import '../../../../helpers/mocks.dart';
import '../../../../helpers/fixture_reader.dart';

void main() {
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerTestFallbacks();
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
  });

  group('SearchPage', () {
    testWidgets('displays results from TMDB when search is successful', (WidgetTester tester) async {
      final jsonResponse = fixture('movie_search_results.json');

      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      await tester.pumpWidget(MaterialApp(
        home: SearchPage(httpClient: mockHttpClient),
      ));

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump(); 
      await tester.pump(); 

      expect(find.widgetWithText(ListTile, 'Inception'), findsOneWidget);
    });

    testWidgets('shows error snackbar when server is unavailable', (WidgetTester tester) async {
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenThrow(Exception('Server unreachable'));

      await tester.pumpWidget(MaterialApp(
        home: SearchPage(httpClient: mockHttpClient),
      ));

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.tap(find.byIcon(Icons.search));
      
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Error: Exception: Server unreachable'), findsOneWidget);
    });
  });
}
