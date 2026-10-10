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
    when(() => mockSharedPreferences.setInt(any(), any())).thenAnswer(
      (_) async => true,
    );
    when(() => mockSharedPreferences.setBool(any(), any())).thenAnswer(
      (_) async => true,
    );
    when(() => mockSharedPreferences.setDouble(any(), any())).thenAnswer(
      (_) async => true,
    );
    when(() => mockSharedPreferences.setString(any(), any())).thenAnswer(
      (_) async => true,
    );

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
    settingsProvider = SettingsProvider(mockSharedPreferences, FakeTmdbCredentialStore());

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

  Widget createWidgetUnderTest([GlobalKey<SavedMediaPageState>? key]) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: SavedMediaPage(key: key),
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

  /// Serves [count] movies for the watchlist backed by a mutable entry list so
  /// that removals are reflected on the next fetch.
  List<String> stubWatchlist({int count = 30}) {
    final entries = List.generate(count, (i) => '${i + 1}:movie');
    when(
      () => mockMediaRepository.getListEntries('watchlist'),
    ).thenAnswer((_) async => List<String>.from(entries));
    when(
      () => mockMediaRepository.getMediaDetails(
        any(),
        type: any(named: 'type'),
      ),
    ).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as int;
      return MediaDetails(
        item: MediaItem(
          id: id,
          title: 'Item $id',
          overview: '',
          releaseDate: '2010',
          mediaType: MediaType.movie,
        ),
        cast: [],
      );
    });
    return entries;
  }

  ScrollPosition listPosition(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('preserves scroll position when the list refreshes', (
    WidgetTester tester,
  ) async {
    stubWatchlist();

    final pageKey = GlobalKey<SavedMediaPageState>();
    await tester.pumpWidget(createWidgetUnderTest(pageKey));
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    final position = listPosition(tester);
    final offsetBefore = position.pixels;
    expect(offsetBefore, greaterThan(0));

    // Same refresh path used after opening a detail sheet or removing an item.
    await pageKey.currentState!.loadSavedMedia();
    await tester.pumpAndSettle();

    final positionAfter = listPosition(tester);
    expect(identical(position, positionAfter), isTrue);
    expect(positionAfter.pixels, offsetBefore);
  });

  testWidgets('preserves scroll position when toggling edit mode', (
    WidgetTester tester,
  ) async {
    stubWatchlist();

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();

    final position = listPosition(tester);
    final offsetBefore = position.pixels;
    expect(offsetBefore, greaterThan(0));

    await tester.longPress(find.text('Item 1'));
    await tester.pumpAndSettle();

    final positionAfter = listPosition(tester);
    expect(identical(position, positionAfter), isTrue);
    expect(positionAfter.pixels, offsetBefore);
  });

  testWidgets('preserves scroll position when removing an item', (
    WidgetTester tester,
  ) async {
    final entries = stubWatchlist();
    when(
      () => mockMediaRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => List<String>.from(entries));
    when(
      () => mockMediaRepository.removeFromList(any(), any(), any()),
    ).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as int;
      final type = invocation.positionalArguments[1] as MediaType;
      entries.remove('$id:${type.name}');
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Populate the provider's cached entries so removeFromList persists.
    await searchProvider.loadWatchlist();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();

    final position = listPosition(tester);
    final offsetBefore = position.pixels;

    await tester.longPress(find.text('Item 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    expect(entries.contains('1:movie'), isFalse);
    expect(find.text('Item 1'), findsNothing);
    final positionAfter = listPosition(tester);
    expect(identical(position, positionAfter), isTrue);
    expect(positionAfter.pixels, offsetBefore);
  });

  testWidgets('starts at the top when switching lists', (
    WidgetTester tester,
  ) async {
    stubWatchlist();
    when(
      () => mockMediaRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', 'mylist']);
    when(
      () => mockMediaRepository.getListEntries('mylist'),
    ).thenAnswer((_) async => List.generate(30, (i) => '${i + 101}:movie'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Make the extra list available in the picker (provider initialised in
    // setUp before this test's stubs were registered).
    await searchProvider.loadListNames();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(listPosition(tester).pixels, greaterThan(0));

    // Open the list picker and switch to another list.
    await tester.tap(find.text('Watchlist').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('mylist').first);
    await tester.pumpAndSettle();

    expect(listPosition(tester).pixels, 0);
  });

  testWidgets('reorders items in manual list mode via the drag handle', (
    WidgetTester tester,
  ) async {
    stubWatchlist(count: 5);
    await settingsProvider.setDisplayMode(DisplayMode.list);

    List<String>? reordered;
    when(
      () => mockMediaRepository.updateListOrder(any(), any()),
    ).thenAnswer((invocation) async {
      reordered = (invocation.positionalArguments[1] as List).cast<String>();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final handle = find.byIcon(Icons.drag_handle).first;
    expect(handle, findsOneWidget);

    await tester.drag(handle, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(reordered, isNotNull);
    expect(reordered!.first, isNot('1:movie'));
  });

  testWidgets('reorders items in manual grid mode by dragging', (
    WidgetTester tester,
  ) async {
    stubWatchlist(count: 6);

    List<String>? reordered;
    when(
      () => mockMediaRepository.updateListOrder(any(), any()),
    ).thenAnswer((invocation) async {
      reordered = (invocation.positionalArguments[1] as List).cast<String>();
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Hold past the long-press timeout, then move, so the grid starts dragging.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Item 1')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reordered, isNotNull);
    expect(reordered!.first, isNot('1:movie'));
  });

  testWidgets('enters edit mode with a plain long-press in grid mode', (
    WidgetTester tester,
  ) async {
    stubWatchlist(count: 6);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Item 1'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
  });
}
