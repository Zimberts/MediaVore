import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_movie_viewings.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;
  late MockSharedPreferences mockPrefs;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'Inception',
        seenDate: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockPrefs = MockSharedPreferences();

    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

    settingsProvider = SettingsProvider(mockPrefs, FakeTmdbCredentialStore());

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.updateSeenEntry(any()),
    ).thenAnswer((_) async => Future.value());
    when(
      () => mockRepository.deleteSeenEntry(any()),
    ).thenAnswer((_) async => Future.value());

    searchProvider = SearchProvider(mockRepository);
  });

  Widget buildWidget({MediaItem? item}) {
    final mediaItem =
        item ??
        const MediaItem(
          id: 1,
          title: 'Inception',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.movie,
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: AppPalette.paper.toThemeData(),
        home: Scaffold(body: MediaDetailMovieViewings(item: mediaItem)),
      ),
    );
  }

  group('MediaDetailMovieViewings - Simple mode (default)', () {
    testWidgets('renders nothing when movie has not been seen', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byKey(const Key('movie_seen_summary')), findsNothing);
      expect(find.byKey(const Key('movie_visionnages_section')), findsNothing);
    });

    testWidgets('renders nothing for TV shows even if seen', (tester) async {
      final viewings = [
        SeenItem(
          id: 1,
          tmdbId: 2,
          type: MediaType.tv,
          title: 'TV Show',
          seenDate: DateTime(2023, 10, 5),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      const tvItem = MediaItem(
        id: 2,
        title: 'TV Show',
        overview: '',
        releaseDate: '',
        mediaType: MediaType.tv,
      );

      await tester.pumpWidget(buildWidget(item: tvItem));
      await tester.pump();

      expect(find.byKey(const Key('movie_seen_summary')), findsNothing);
    });

    testWidgets('displays single viewing summary when seen once', (
      tester,
    ) async {
      final viewings = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2023, 11, 3),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byKey(const Key('movie_seen_summary')), findsOneWidget);
      expect(find.textContaining('Seen once'), findsOneWidget);
      expect(find.byKey(const Key('movie_visionnages_section')), findsNothing);
    });

    testWidgets(
      'displays multiple viewings summary with last date when seen multiple times',
      (tester) async {
        final viewings = [
          SeenItem(
            id: 1,
            tmdbId: 1,
            type: MediaType.movie,
            title: 'Inception',
            seenDate: DateTime(2023, 5, 1),
          ),
          SeenItem(
            id: 2,
            tmdbId: 1,
            type: MediaType.movie,
            title: 'Inception',
            seenDate: DateTime(2023, 11, 3),
          ),
        ];
        when(
          () => mockRepository.getSeenItems(),
        ).thenAnswer((_) async => viewings);
        await searchProvider.loadAllSeenStatus();

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.byKey(const Key('movie_seen_summary')), findsOneWidget);
        expect(find.textContaining('Seen 2 times'), findsOneWidget);
        expect(
          find.byKey(const Key('movie_visionnages_section')),
          findsNothing,
        );
      },
    );
  });

  group('MediaDetailMovieViewings - Advanced mode', () {
    setUp(() async {
      await settingsProvider.setAdvancedTracking(true);
    });

    testWidgets('displays Visionnages section with list of viewings', (
      tester,
    ) async {
      final viewings = [
        SeenItem(
          id: 10,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2023, 1, 15, 20, 0),
        ),
        SeenItem(
          id: 20,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2023, 6, 20, 21, 30),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byKey(const Key('movie_seen_summary')), findsNothing);
      expect(
        find.byKey(const Key('movie_visionnages_section')),
        findsOneWidget,
      );
      expect(find.text('Viewings'), findsOneWidget);
      expect(find.textContaining('1st viewing'), findsOneWidget);
      expect(find.textContaining('2nd viewing'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('editing a viewing date calls updateSeenEntry', (tester) async {
      final viewings = [
        SeenItem(
          id: 10,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2023, 1, 15, 20, 0),
        ),
      ];
      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Edit date'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateSeenEntry(any())).called(1);
    });

    testWidgets(
      'deleting a viewing asks confirmation and calls deleteSeenEntry',
      (tester) async {
        final viewings = [
          SeenItem(
            id: 10,
            tmdbId: 1,
            type: MediaType.movie,
            title: 'Inception',
            seenDate: DateTime(2023, 1, 15, 20, 0),
          ),
        ];
        when(
          () => mockRepository.getSeenItems(),
        ).thenAnswer((_) async => viewings);
        await searchProvider.loadAllSeenStatus();

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Remove log?'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        verify(() => mockRepository.deleteSeenEntry(10)).called(1);
      },
    );
  });
}
