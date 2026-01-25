import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/search_overlay.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(const MediaItem(id: 0, title: '', overview: '', releaseDate: ''));
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockRepository);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const SearchOverlay(),
      ),
    );
  }

  group('SearchOverlay Requirements', () {
    testWidgets('search result has bookmark icon button', (WidgetTester tester) async {
      final tItem = const MediaItem(id: 1, title: 'Test Movie', overview: '', releaseDate: '2023', mediaType: MediaType.movie);
      
      when(() => mockRepository.searchMedia(any(), page: any(named: 'page')))
          .thenAnswer((_) async => [tItem]);

      await tester.pumpWidget(createWidgetUnderTest());
      
      // Type something to trigger search
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 400)); // Debounce
      await tester.pumpAndSettle();

      expect(find.text('Test Movie'), findsOneWidget);
      
      // Requirement: `Add to Watchlist` button for search
      // It should be an IconButton with bookmark_add_outlined (since it's not in watchlist)
      final addButton = find.byIcon(Icons.bookmark_add_outlined);
      expect(addButton, findsOneWidget);

      // Verify it triggers toggle
      when(() => mockRepository.addToList(any(), 'watchlist')).thenAnswer((_) async => {});
      when(() => mockRepository.toggleNotification(any(), autoNotify: true)).thenAnswer((_) async => {});
      
      await tester.tap(addButton);
      await tester.pump();

      verify(() => mockRepository.addToList(any(), 'watchlist')).called(1);
    });

    testWidgets('clear button resets search results', (WidgetTester tester) async {
      when(() => mockRepository.searchMedia(any(), page: any(named: 'page')))
          .thenAnswer((_) async => [const MediaItem(id: 1, title: 'Result', overview: '', releaseDate: '')]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Result'), findsOneWidget);

      // Requirement: `Clear search` button clears content
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Result'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, '');
    });
  });
}
