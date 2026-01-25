import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    
    // Default discovery results - Mock specifically for Movie and TV to avoid duplicates
    when(() => mockRepository.discoverMedia(
      page: any(named: 'page'),
      type: MediaType.movie,
      genreIds: any(named: 'genreIds'),
      releaseYear: any(named: 'releaseYear'), 
      minRating: any(named: 'minRating'),
    )).thenAnswer((_) async => [
      const MediaItem(id: 1, title: 'Discovery Movie', overview: '', releaseDate: '2023-01-01', mediaType: MediaType.movie),
    ]);

    when(() => mockRepository.discoverMedia(
      page: any(named: 'page'),
      type: MediaType.tv,
      genreIds: any(named: 'genreIds'),
      releaseYear: any(named: 'releaseYear'), 
      minRating: any(named: 'minRating'),
    )).thenAnswer((_) async => [
      const MediaItem(id: 2, title: 'Discovery TV', overview: '', releaseDate: '2023-01-01', mediaType: MediaType.tv),
    ]);

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const DiscoveryPage(),
      ),
    );
  }

  group('Discovery Screen Requirements', () {
    testWidgets('clearing search restores discovery content', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Discovery Movie'), findsOneWidget);
      expect(find.text('Discovery TV'), findsOneWidget);

      // Open search in Discovery
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Mock search results
      when(() => mockRepository.searchMedia(any(), page: any(named: 'page')))
          .thenAnswer((_) async => [
            const MediaItem(id: 3, title: 'Search Result', overview: '', releaseDate: ''),
          ]);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 600)); // Debounce
      await tester.pumpAndSettle();

      expect(find.text('Search Result'), findsOneWidget);
      expect(find.text('Discovery Movie'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should be back to discovery
      expect(find.text('Discovery Movie'), findsOneWidget);
      expect(find.text('Discovery TV'), findsOneWidget);
      expect(find.text('Search Result'), findsNothing);
    });

    testWidgets('filter dialog allows type and year selection', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('Discovery Filters'), findsOneWidget);
      expect(find.text('Media Type'), findsOneWidget);
      expect(find.text('Release Year'), findsOneWidget);
    });
  });
}
