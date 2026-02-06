import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

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
    when(
      () => mockMediaRepository.toggleNotification(
        any(),
        autoNotify: any(named: 'autoNotify'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockMediaRepository.toggleLike(any())).thenAnswer((_) async {});

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

  testWidgets(
    'watchlist button updates immediately and like/notify behave by eligibility',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 10)).toIso8601String();
      final pastDate = now
          .subtract(const Duration(days: 100))
          .toIso8601String();

      final movie = MediaItem(
        id: 1,
        title: 'Future Movie',
        overview: '',
        releaseDate: futureDate,
        mediaType: MediaType.movie,
      );
      final tv = MediaItem(
        id: 2,
        title: 'Show Future Ep',
        overview: '',
        releaseDate: pastDate,
        mediaType: MediaType.tv,
        nextEpisodeAirDate: futureDate,
      );

      when(
        () => mockMediaRepository.discoverMedia(
          type: MediaType.movie,
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => [movie]);
      when(
        () => mockMediaRepository.discoverMedia(
          type: MediaType.tv,
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => [tv]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Switch to list mode (list has more accessible trailing buttons)
      // open grid size sheet and toggle view
      await tester.tap(find.byTooltip('Grid Size'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Toggle Grid/List View'));
      await tester.pumpAndSettle();
      // close the sheet so list items are tappable
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Prepare repository stubs for watchlist toggle
      when(
        () => mockMediaRepository.addToList(any(), 'watchlist'),
      ).thenAnswer((_) async {});
      when(
        () => mockMediaRepository.getListEntries('watchlist'),
      ).thenAnswer((_) async => ['1:movie']);

      // Tap the watchlist button via its test key and verify provider state updates
      final watchKey = ValueKey(
        'watchlist-${movie.id}-${movie.mediaType.name}-list',
      );
      expect(find.byKey(watchKey), findsWidgets);
      // Determine matched widgets for later use (removed debug prints).
      // Tap the keyed quick-action directly
      final watchFinder = find.byKey(watchKey).first;
      await tester.ensureVisible(watchFinder);
      await tester.pumpAndSettle();
      await tester.tap(watchFinder);
      await tester.pumpAndSettle();

      final entry = '${movie.id}:${movie.mediaType.name}';
      expect(
        searchProvider.getListEntries('watchlist').contains(entry),
        isTrue,
      );
      expect(searchProvider.isItemInList(movie, 'watchlist'), isTrue);

      // Like is indicator-only: stub liked items and verify a heart is shown.
      when(
        () => mockMediaRepository.getLikedEntries(),
      ).thenAnswer((_) async => ['1:movie']);
      await searchProvider.loadLikedStatus();
      await tester.pumpAndSettle();
      expect(searchProvider.isLiked(movie), isTrue);
      expect(find.byIcon(Icons.favorite), findsWidgets);

      // Switch back to grid to check notify icons (present for future items)
      // open grid size sheet and toggle back
      await tester.tap(find.byTooltip('Grid Size'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Toggle Grid/List View'));
      await tester.pumpAndSettle();
      // close sheet
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final notifyMovieKey = ValueKey(
        'notify-${movie.id}-${movie.mediaType.name}-grid',
      );
      final notifyTvKey = ValueKey('notify-${tv.id}-${tv.mediaType.name}-grid');
      expect(find.byKey(notifyMovieKey), findsWidgets);
      expect(find.byKey(notifyTvKey), findsWidgets);
    },
  );
}
