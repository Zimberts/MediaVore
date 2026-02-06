import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(const MediaItem(
      id: 0,
      title: '',
      overview: '',
      posterPath: null,
      releaseDate: '',
      mediaType: MediaType.movie,
    ));
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    // Default mocks for SharedPreferences (used by SettingsProvider)
    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    // Default mocks for initialization
    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockMediaRepository.addToList(any(), any())).thenAnswer((_) async => Future.value());
    when(() => mockMediaRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.toggleNotification(any(), autoNotify: any(named: 'autoNotify')))
        .thenAnswer((_) async => Future.value());

    // Default discovery mocks
    when(() => mockMediaRepository.discoverMedia(
      page: any(named: 'page'),
      genreIds: any(named: 'genreIds'),
      releaseYear: any(named: 'releaseYear'),
      minRating: any(named: 'minRating'),
      language: any(named: 'language'),
      type: any(named: 'type'),
      sortBy: any(named: 'sortBy'),
    )).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockMediaRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const SearchPage(),
      ),
    );
  }

  group('SearchPage (DiscoveryPage)', () {
    testWidgets('shows discovery results initially', (WidgetTester tester) async {
      final movieItems = [
        const MediaItem(id: 1, title: 'Trending Movie', overview: 'O', releaseDate: '2023', mediaType: MediaType.movie),
      ];
      final tvItems = [
        const MediaItem(id: 2, title: 'Trending TV', overview: 'O', releaseDate: '2023', mediaType: MediaType.tv),
      ];

      when(() => mockMediaRepository.discoverMedia(
        type: MediaType.movie,
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        sortBy: any(named: 'sortBy'),
      )).thenAnswer((_) async => movieItems);

      when(() => mockMediaRepository.discoverMedia(
        type: MediaType.tv,
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        sortBy: any(named: 'sortBy'),
      )).thenAnswer((_) async => tvItems);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('Trending Movie'), findsOneWidget);
      expect(find.text('Trending TV'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('toggles search bar and triggers auto-search', (WidgetTester tester) async {
      final searchItems = [
        const MediaItem(id: 2, title: 'Search Result', overview: 'O', releaseDate: '2023', mediaType: MediaType.movie),
      ];
      when(() => mockMediaRepository.searchMedia(
        'test',
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => searchItems);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap search icon in Discovery AppBar
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // Verify TextField is present
      expect(find.byType(TextField), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Search Result'), findsOneWidget);
    });

    testWidgets('opens filter dialog and applies changes', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Clear initial discovery calls
      clearInteractions(mockMediaRepository);

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('Discovery Filters'), findsOneWidget);

      // Select TV Show type from dropdown
      await tester.tap(find.text('Both'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TV Shows').last);
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Apply'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockMediaRepository.discoverMedia(
        page: 1,
        type: MediaType.tv,
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        sortBy: any(named: 'sortBy'),
      )).called(1);
    });
  });
}
