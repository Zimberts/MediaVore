import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
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
    registerFallbackValue(DisplayMode.grid);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setStringList(any(), any())).thenAnswer((_) async => true);

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist', 'Favorites']);
    when(() => mockRepository.getListEntries('watchlist')).thenAnswer((_) async => ['1:movie', '2:tv']);
    when(() => mockRepository.getListEntries('Favorites')).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => ['1:movie', '2:tv']);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    
    // Mock details for the items in the list
    when(() => mockRepository.getMediaDetails(1, type: MediaType.movie)).thenAnswer((_) async => MediaDetails(
      item: const MediaItem(id: 1, title: 'Movie 1', overview: '', releaseDate: '2020-01-01', mediaType: MediaType.movie),
      cast: [],
    ));
    when(() => mockRepository.getMediaDetails(2, type: MediaType.tv)).thenAnswer((_) async => MediaDetails(
      item: const MediaItem(id: 2, title: 'Series 1', overview: '', releaseDate: '2021-01-01', mediaType: MediaType.tv),
      cast: [],
    ));

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    // Register mocks in GetIt for widgets that use locator directly
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockRepository);
  });

  tearDown(() {
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const SavedMediaPage(),
      ),
    );
  }

  group('Saved Media Page Requirements', () {
    testWidgets('can switch between lists', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Watchlist'), findsWidgets);
      expect(find.text('Movie 1'), findsOneWidget);

      // Tap to open list picker
      await tester.tap(find.text('Watchlist').first);
      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsOneWidget);
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsWidgets);
      expect(find.text('Movie 1'), findsNothing);
    });

    testWidgets('can change display mode to grid', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open display options
      await tester.tap(find.byIcon(Icons.grid_on));
      await tester.pumpAndSettle();

      // Tap Grid icon in ToggleButtons
      await tester.tap(find.byIcon(Icons.grid_view).last);
      await tester.pumpAndSettle();

      expect(settingsProvider.displayMode, DisplayMode.grid);
    });

    testWidgets('shows sort options bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      expect(find.text('Sort Options'), findsOneWidget);
      expect(find.text('Manual Order'), findsOneWidget);
      expect(find.text('Release Date'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
    });

    testWidgets('enters edit mode on long press', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Movie 1'));
      await tester.pumpAndSettle();

      // Should show '1 selected' in AppBar
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
