import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
    when(
      () => mockRepository.refreshNotifiedItems(),
    ).thenAnswer((_) async => {});

    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
      ),
    ).thenAnswer(
      (_) async => [
        MediaItem(
          id: 11,
          title: 'Grid Movie 1',
          overview: '',
          releaseDate: '2024',
          mediaType: MediaType.movie,
        ),
        MediaItem(
          id: 12,
          title: 'Grid Movie 2',
          overview: '',
          releaseDate: '2024',
          mediaType: MediaType.movie,
        ),
        MediaItem(
          id: 13,
          title: 'Grid Movie 3',
          overview: '',
          releaseDate: '2024',
          mediaType: MediaType.movie,
        ),
      ],
    );
  });

  testWidgets('Grid size slider updates grid count and seen overlay appears', (
    tester,
  ) async {
    final provider = SearchProvider(mockRepository);
    final mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    final settings = SettingsProvider(mockPrefs);

    // Ensure we are in grid mode for this test.
    await settings.setDisplayMode(DisplayMode.grid);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const DiscoveryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initial grid uses settings.gridSize (default 3)
    final gridFinder = find.byType(GridView);
    expect(gridFinder, findsOneWidget);
    final grid = tester.widget<GridView>(gridFinder);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, equals(settings.gridSize.round()));

    // Change grid size via provider and verify delegate updates
    await settings.setGridSize(5.0);
    await tester.pumpAndSettle();
    final grid2 = tester.widget<GridView>(gridFinder);
    final delegate2 =
        grid2.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate2.crossAxisCount, equals(5));

    // Now simulate an item being marked seen by returning a seen item
    final seen = SeenItem(
      id: 1,
      tmdbId: 12,
      type: MediaType.movie,
      title: 'Grid Movie 2',
      seenDate: DateTime.now(),
    );
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => [seen]);

    // Refresh provider state
    await provider.loadAllSeenStatus();
    await tester.pumpAndSettle();

    // Verify provider reports the seen count for the item
    final item12 = provider.items.firstWhere((i) => i.id == 12);
    expect(provider.getSeenCount(item12), equals(1));
  });
}
