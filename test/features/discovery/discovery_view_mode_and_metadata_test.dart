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
    ).thenAnswer((_) async => {});

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
    'shows metadata in grid and toggles to list with watchlist action',
    (WidgetTester tester) async {
      final movie = const MediaItem(
        id: 1,
        title: 'Movie A',
        overview: '',
        releaseDate: '2021-05-01',
        mediaType: MediaType.movie,
        runtime: 125,
        voteAverage: 7.5,
      );
      final tv = const MediaItem(
        id: 2,
        title: 'Show B',
        overview: '',
        releaseDate: '2020-09-10',
        mediaType: MediaType.tv,
        numberOfSeasons: 3,
        voteAverage: 8.0,
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // metadata shows (year and runtime/seasons)
      expect(find.textContaining('2021'), findsWidgets);
      expect(find.textContaining('125 min'), findsOneWidget);
      expect(find.textContaining('3 season'), findsOneWidget);

      // open grid size sheet and toggle to list mode
      await tester.tap(find.byTooltip('Grid Size'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Toggle Grid/List View'));
      await tester.pumpAndSettle();
      // close the sheet so list items are tappable
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);

      // verify watchlist action triggers repository add
      when(
        () => mockMediaRepository.addToList(any(), 'watchlist'),
      ).thenAnswer((_) async {});
      when(
        () => mockMediaRepository.getListEntries('watchlist'),
      ).thenAnswer((_) async => ['1:movie']);

      // find the movie watchlist button in list (use deterministic key)
      final watchButton = find.byKey(const ValueKey('watchlist-1-movie-list'));
      expect(watchButton, findsOneWidget);
      await tester.tap(watchButton);
      await tester.pumpAndSettle();

      verify(() => mockMediaRepository.addToList(any(), 'watchlist')).called(1);
    },
  );
}
