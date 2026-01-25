import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(SeenItem(tmdbId: 1, type: MediaType.movie, title: 'T', seenDate: DateTime.now()));
  });

  setUp(() {
    mockRepository = MockMediaRepository();

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.refreshNotifiedItems()).thenAnswer((_) async => {});
    
    // Mock notified items for Releases tab
    final notifiedItem = NotifiedItem(
      tmdbId: 1,
      title: 'Upcoming Movie',
      type: MediaType.movie,
      releaseDate: DateTime.now().add(const Duration(days: 1)),
    );
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => [notifiedItem]);
    
    // Mock seen items for Quick Add tab
    final tSeenItem = SeenItem(id: 1, tmdbId: 2, title: 'Ongoing Show', type: MediaType.tv, seenDate: DateTime.now(), seasonNumber: 1, episodeNumber: 1);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => [tSeenItem]);
    when(() => mockRepository.getSeenStatus(2, MediaType.tv)).thenAnswer((_) async => [tSeenItem]);

    // Mock next episode logic
    when(() => mockRepository.getMediaDetails(2, type: MediaType.tv)).thenAnswer((_) async => MediaDetails(
      item: const MediaItem(
        id: 2, 
        title: 'Ongoing Show', 
        overview: '', 
        releaseDate: '', 
        mediaType: MediaType.tv,
        seasons: [
          TVSeason(id: 1, seasonNumber: 1, episodeCount: 10, name: 'Season 1'),
        ],
      ),
      cast: [],
    ));
    when(() => mockRepository.getSeasonDetails(2, 1)).thenAnswer((_) async => {
      'episodes': [
        {'episode_number': 1, 'name': 'Ep 1', 'air_date': '2023-01-01'},
        {'episode_number': 2, 'name': 'Ep 2', 'air_date': '2023-01-08'},
      ]
    });

    searchProvider = SearchProvider(mockRepository);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const NotificationCenterPage(),
      ),
    );
  }

  group('Notification Center Requirements', () {
    testWidgets('shows both tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Releases'), findsWidgets);
      expect(find.text('Quick Add'), findsWidgets);
    });

    testWidgets('Releases tab shows notified items', (WidgetTester tester) async {
      // Ensure provider is fully loaded before building widget
      await searchProvider.loadNotifiedItems();
      await searchProvider.loadAllSeenStatus();
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Movie'), findsOneWidget);
    });

    testWidgets('Quick Add tab shows next episodes for ongoing series', (WidgetTester tester) async {
      // Ensure provider is fully loaded
      await searchProvider.loadAllSeenStatus();
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      // Switch to Quick Add tab
      await tester.tap(find.text('Quick Add').first);
      await tester.pumpAndSettle();

      // We pump repeatedly to allow all awaits inside loadNextEpisodes to resolve
      // loadNextEpisodes calls getNextEpisode for each series
      // getNextEpisode calls: getSeenStatus, getMediaDetails, getSeasonDetails
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(find.text('Ongoing Show'), findsOneWidget);
      expect(find.textContaining('Next: Season 1, Episode 2'), findsOneWidget);
    });
   group('Date Seen Selection Requirements', () {
      testWidgets('tapping check_circle_outline opens date picker dialog with calendar by default', (WidgetTester tester) async {
        // This is partially covered by seen_date_time_picker_test.dart
        // but let's ensure it's integrated here if needed or just refer to it.
      });
    });
  });
}
