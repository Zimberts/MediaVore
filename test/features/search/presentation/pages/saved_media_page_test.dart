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
  late MockMediaRepository mockMediaRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    // Default mocks for SharedPreferences (used by SettingsProvider)
    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    // Default mocks for SearchProvider init
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
      () => mockMediaRepository.getLikedEntries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.getNotifiedItems(),
    ).thenAnswer((_) async => []);
    when(
      () => mockMediaRepository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockMediaRepository.getListPreviews(
        any(),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockMediaRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    if (!locator.isRegistered<SearchProvider>()) {
      locator.registerSingleton<SearchProvider>(searchProvider);
    }
    if (!locator.isRegistered<MediaRepository>()) {
      locator.registerSingleton<MediaRepository>(mockMediaRepository);
    }
  });

  tearDown(() {
    locator.reset();
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

  testWidgets('displays saved items and liked status', (
    WidgetTester tester,
  ) async {
    final item = const MediaItem(
      id: 1,
      title: 'Inception',
      overview: 'Overview',
      releaseDate: '2010',
      mediaType: MediaType.movie,
    );

    when(
      () => mockMediaRepository.getListEntries('watchlist'),
    ).thenAnswer((_) async => ['1:movie']);
    when(
      () => mockMediaRepository.getMediaDetails(1, type: MediaType.movie),
    ).thenAnswer((_) async => MediaDetails(item: item, cast: []));
    when(
      () => mockMediaRepository.getLikedEntries(),
    ).thenAnswer((_) async => ['1:movie']);

    // Ensure provider has the updated liked status before building
    await searchProvider.loadLikedStatus();

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
    // Use matching by icon data since Icons.favorite is used in the widget
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('displays very long list name without overflow exceptions', (
    WidgetTester tester,
  ) async {
    const longName =
        'This is a very very very very very very very very very very very very long list name';
    when(
      () => mockMediaRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', longName]);
    when(
      () => mockMediaRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    // Force provider to load names
    await searchProvider.loadListNames();
    await tester.pumpAndSettle();

    // Open list picker
    await tester.tap(find.text('Watchlist').first);
    await tester.pumpAndSettle();

    // Select the long name list
    await tester.tap(find.text(longName).first);
    await tester.pumpAndSettle();

    // Should render the long list name without exception
    expect(tester.takeException(), isNull);
    expect(find.text(longName), findsWidgets);
  });

  testWidgets('removing an item updates the list in real-time', (
    WidgetTester tester,
  ) async {
    const item = MediaItem(
      id: 1,
      title: 'Inception',
      overview: 'Overview',
      releaseDate: '2010',
      mediaType: MediaType.movie,
    );

    // Initial state with item
    when(
      () => mockMediaRepository.getListEntries('watchlist'),
    ).thenAnswer((_) async => ['1:movie']);
    when(
      () => mockMediaRepository.getMediaDetails(1, type: MediaType.movie),
    ).thenAnswer((_) async => MediaDetails(item: item, cast: []));
    when(
      () => mockMediaRepository.removeFromList(1, MediaType.movie, 'watchlist'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);

    // Long press to enter edit mode and select item
    await tester.longPress(find.text('Inception'));
    await tester.pumpAndSettle();

    // Update mock to return empty list on reload
    when(
      () => mockMediaRepository.getListEntries('watchlist'),
    ).thenAnswer((_) async => []);

    // Tap delete icon to remove
    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    // Item should no longer be visible
    expect(find.text('Inception'), findsNothing);
  });
}
