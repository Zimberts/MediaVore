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
  late MockMediaRepository mockMediaRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(
        id: 0,
        title: '',
        overview: '',
        posterPath: null,
        releaseDate: '',
        mediaType: MediaType.movie,
      ),
    );
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(
      () => mockSharedPreferences.setDouble(any(), any()),
    ).thenAnswer((_) async => true);

    when(
      () => mockMediaRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockMediaRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getListPreviews(
        any(),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getLikedEntries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getNotifiedItems(),
    ).thenAnswer((_) async => []);

    // Default discovery mocks
    when(
      () => mockMediaRepository.discoverMedia(
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
        sortBy: any(named: 'sortBy'),
      ),
    ).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockMediaRepository);
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

  testWidgets('DiscoveryPage displays items from repository', (
    WidgetTester tester,
  ) async {
    final movieItems = [
      const MediaItem(
        id: 1,
        title: 'Movie 1',
        overview: 'O1',
        releaseDate: '2021',
        mediaType: MediaType.movie,
        voteAverage: 8.5,
      ),
    ];
    final tvItems = [
      const MediaItem(
        id: 2,
        title: 'TV 1',
        overview: 'O2',
        releaseDate: '2022',
        mediaType: MediaType.tv,
        voteAverage: 7.0,
      ),
    ];

    when(
      () => mockMediaRepository.discoverMedia(
        type: MediaType.movie,
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        sortBy: any(named: 'sortBy'),
      ),
    ).thenAnswer((_) async => movieItems);

    when(
      () => mockMediaRepository.discoverMedia(
        type: MediaType.tv,
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        sortBy: any(named: 'sortBy'),
      ),
    ).thenAnswer((_) async => tvItems);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.text('TV 1'), findsOneWidget);
  });

  testWidgets('DiscoveryPage adjusts grid size via bottom sheet', (
    WidgetTester tester,
  ) async {
    final items = [
      const MediaItem(
        id: 1,
        title: 'Item 1',
        overview: 'O1',
        releaseDate: '2021',
        mediaType: MediaType.movie,
      ),
    ];
    when(
      () => mockMediaRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        sortBy: any(named: 'sortBy'),
      ),
    ).thenAnswer((_) async => items);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify GridView is present
    expect(find.byType(GridView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_on));
    await tester.pumpAndSettle();

    // The UI shows 'Grid Size' inside the display options sheet
    expect(find.text('Grid Size'), findsOneWidget);

    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(settingsProvider.gridSize > 3, true);

    await tester.tapAt(const Offset(10, 10)); // Tap outside to close
    await tester.pumpAndSettle();

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, settingsProvider.gridSize.round());
  });
}
