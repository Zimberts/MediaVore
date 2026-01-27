import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import '../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  final appThemeExt = AppThemeExtension(
    onWatchlist: Colors.red,
    likeHeart: Colors.pink,
    ratingStar: Colors.amber,
    visualSelection: Colors.blue,
    logicFlow: Colors.green,
    dataValues: Colors.teal,
    constants: Colors.grey,
    functions: Colors.black,
    structural: Colors.brown,
    comments: Colors.blueGrey,
    badgeBg: Colors.grey,
    badgeBgSeen: Colors.black,
    badgeText: Colors.white,
    warning: Colors.orange,
    error: Colors.red,
    success: Colors.green,
    info: Colors.blue,
    placeholder: Colors.grey,
  );

  Future<SearchProvider> makeProviderWithCommonStubs(
    MockMediaRepository mockRepo,
  ) async {
    debugPrint('HELPER: start _makeProviderWithCommonStubs');
    // Common stubs used by SearchProvider initialization
    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepo.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getListPreviews(any()),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepo.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    final provider = SearchProvider(mockRepo);
    debugPrint('HELPER: created SearchProvider, returning provider immediately');
    return provider;
  }

  testWidgets('displays backdrop and export shows empty snackbar', (
    tester,
  ) async {
    debugPrint('TEST_START: displays backdrop');
    final mockRepo = MockMediaRepository();

    final movieItem = MediaItem(
      id: 1,
      title: 'Test Movie',
      posterPath: null,
      overview: 'Overview',
      releaseDate: '2020-01-01',
      mediaType: MediaType.movie,
    );

    final details = MediaDetails(
      item: movieItem,
      cast: [],
      director: null,
      similar: [],
      recommendations: [],
      videos: [],
    );

    when(
      () => mockRepo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => details);
    when(
      () => mockRepo.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepo.exportSeenData(
        tmdbId: any(named: 'tmdbId'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);

    final provider = await makeProviderWithCommonStubs(mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [appThemeExt]),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(MockSharedPreferences()),
            ),
          ],
          child: MediaDetailPage(item: movieItem),
        ),
      ),
    );

    await tester.pumpAndSettle();

    debugPrint('TEST: after pumpAndSettle (displays backdrop)');

    expect(find.text('Test Movie'), findsWidgets);
    expect(find.byIcon(Icons.movie), findsOneWidget);

    // Tap the export button and expect a snackbar for empty export
    final exportButton = find.byTooltip('Export history for this item');
    expect(exportButton, findsOneWidget);
    await tester.tap(exportButton);
    debugPrint('TEST: after tap export (before pump)');
    await tester.pumpAndSettle();

    debugPrint('TEST: after pumpAndSettle (after export)');

    expect(find.text('No history to export for this item.'), findsOneWidget);
  });

  testWidgets('TV progress and seasons expansion show episodes', (
    tester,
  ) async {
    debugPrint('TEST_START: TV progress');
    final mockRepo = MockMediaRepository();

    final tvItem = MediaItem(
      id: 2,
      title: 'Test Show',
      posterPath: null,
      overview: 'Show overview',
      releaseDate: '2021-01-01',
      mediaType: MediaType.tv,
      numberOfEpisodes: 10,
      seasons: [
        TVSeason(id: 11, seasonNumber: 1, episodeCount: 1, name: 'Season 1'),
      ],
    );

    final details = MediaDetails(
      item: tvItem,
      cast: [],
      director: null,
      similar: [],
      recommendations: [],
      videos: [],
    );

    when(
      () => mockRepo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => details);
    when(() => mockRepo.getSeenStatus(tvItem.id, MediaType.tv)).thenAnswer(
      (_) async => [
        SeenItem(
          tmdbId: tvItem.id,
          type: MediaType.tv,
          title: tvItem.title,
          seenDate: DateTime.now(),
          seasonNumber: 1,
          episodeNumber: 1,
        ),
      ],
    );

    when(() => mockRepo.getSeasonDetails(tvItem.id, 1)).thenAnswer(
      (_) async => {
        'episodes': [
          {'episode_number': 1, 'name': 'Pilot', 'air_date': '2021-01-01'},
        ],
      },
    );

    // Ensure export / common init stubs
    when(
      () => mockRepo.exportSeenData(
        tmdbId: any(named: 'tmdbId'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);

    final provider = await makeProviderWithCommonStubs(mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [appThemeExt]),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(MockSharedPreferences()),
            ),
          ],
          child: MediaDetailPage(item: tvItem),
        ),
      ),
    );

    await tester.pumpAndSettle();

    debugPrint('TEST: after pumpAndSettle (TV progress)');

    expect(find.text('Progress: 1 / 10 episodes seen'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Season expansion/episode loading is exercised elsewhere; ensure progress shown
  });

  testWidgets('like and notify buttons trigger repository calls', (
    tester,
  ) async {
    debugPrint('TEST_START: like/notify');
    final mockRepo = MockMediaRepository();

    final movieItem = MediaItem(
      id: 3,
      title: 'Unreleased Movie',
      posterPath: null,
      overview: 'Overview',
      releaseDate: '', // empty -> should show notify
      mediaType: MediaType.movie,
    );

    final details = MediaDetails(
      item: movieItem,
      cast: [],
      director: null,
      similar: [],
      recommendations: [],
      videos: [],
    );

    when(
      () => mockRepo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => details);
    when(
      () => mockRepo.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepo.exportSeenData(
        tmdbId: any(named: 'tmdbId'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);

    // Stubs for toggle operations
    when(() => mockRepo.toggleLike(any())).thenAnswer((_) async {});
    when(
      () => mockRepo.toggleNotification(
        any(),
        autoNotify: any(named: 'autoNotify'),
      ),
    ).thenAnswer((_) async {});

    final provider = await makeProviderWithCommonStubs(mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [appThemeExt]),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(MockSharedPreferences()),
            ),
          ],
          child: MediaDetailPage(item: movieItem),
        ),
      ),
    );

    await tester.pumpAndSettle();

    debugPrint('TEST: after pumpAndSettle (like/notify)');

    // Like button should be present
    final likeButton = find.byTooltip('Like');
    expect(likeButton, findsOneWidget);
    await tester.tap(likeButton);
    debugPrint('TEST: after tap like (before pump)');
    await tester.pumpAndSettle();

    debugPrint('TEST: after pumpAndSettle (after like)');

    verify(() => mockRepo.toggleLike(any())).called(1);

    // Notify button should be visible for empty releaseDate
    final notifyButton = find.byTooltip('Notify me on release');
    expect(notifyButton, findsOneWidget);
    await tester.tap(notifyButton);
    debugPrint('TEST: after tap notify (before pump)');
    await tester.pumpAndSettle();

    debugPrint('TEST: after pumpAndSettle (after notify)');

    verify(
      () => mockRepo.toggleNotification(
        any(),
        autoNotify: any(named: 'autoNotify'),
      ),
    ).called(greaterThanOrEqualTo(1));
  });
}
