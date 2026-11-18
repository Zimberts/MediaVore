import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_actions.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_header.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_synopsis.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockMediaRepository repository;
  late MockSharedPreferences preferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  late Map<String, List<String>> lists;
  late List<SeenItem> seen;
  late List<String> shared;

  const longOverview =
      'A thief who steals corporate secrets through the use of dream-sharing '
      'technology is given the inverse task of planting an idea into the mind '
      'of a C.E.O., but his tragic past may doom the project and his team to '
      'disaster. Every level of the dream goes deeper, slower and stranger, '
      'and nobody is quite sure any more which layer is the real one, or '
      'whether the top will ever stop spinning on the table at the very end.';

  const film = MediaItem(
    id: 1,
    title: 'Inception',
    originalTitle: 'Inception (original)',
    posterPath: '/poster.jpg',
    releaseDate: '2010-07-16',
    overview: '$longOverview $longOverview',
    mediaType: MediaType.movie,
    runtime: 148,
    voteAverage: 8.4,
    status: 'Released',
    genres: ['Action'],
    originCountries: ['US', 'GB'],
    originalLanguage: 'en',
  );

  const other = MediaItem(
    id: 5,
    title: 'Tenet',
    releaseDate: '2020-08-26',
    overview: 'Time runs backwards.',
    mediaType: MediaType.movie,
  );

  const serie = MediaItem(
    id: 2,
    title: 'Dark',
    releaseDate: '2017-12-01',
    overview: 'A missing child.',
    mediaType: MediaType.tv,
    numberOfSeasons: 2,
    numberOfEpisodes: 6,
    runtime: 52,
    status: 'Ended',
    genres: ['Drama'],
    seasons: [
      TVSeason(id: 1, seasonNumber: 1, episodeCount: 3, name: 'Season 1'),
      TVSeason(id: 2, seasonNumber: 2, episodeCount: 3, name: 'Season 2'),
    ],
  );

  SeenItem episodeSeen(int season, int episode) => SeenItem(
    id: season * 10 + episode,
    tmdbId: 2,
    type: MediaType.tv,
    title: 'Dark',
    seenDate: DateTime(2024, 1, episode),
    seasonNumber: season,
    episodeNumber: episode,
  );

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    repository = MockMediaRepository();
    preferences = MockSharedPreferences();
    lists = {'watchlist': [], 'Weekend': [], 'Classics': []};
    seen = [];
    shared = [];

    when(() => preferences.getInt(any())).thenReturn(null);
    when(() => preferences.getDouble(any())).thenReturn(null);
    when(() => preferences.getBool(any())).thenReturn(null);

    when(
      () => repository.getAllListNames(),
    ).thenAnswer((_) async => lists.keys.toList());
    when(
      () => repository.getWatchlistEntries(),
    ).thenAnswer((_) async => lists['watchlist']!);
    when(() => repository.getListEntries(any())).thenAnswer(
      (invocation) async =>
          lists[invocation.positionalArguments.first as String] ?? [],
    );
    when(
      () => repository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repository.getListMediaItems(any())).thenAnswer((_) async => []);
    when(() => repository.addToList(any(), any())).thenAnswer((
      invocation,
    ) async {
      final item = invocation.positionalArguments[0] as MediaItem;
      final name = invocation.positionalArguments[1] as String;
      lists[name] = [...?lists[name], '${item.id}:${item.mediaType.name}'];
    });
    when(() => repository.removeFromList(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      final id = invocation.positionalArguments[0] as int;
      final type = invocation.positionalArguments[1] as MediaType;
      final name = invocation.positionalArguments[2] as String;
      lists[name] = [...?lists[name]]..remove('$id:${type.name}');
    });
    when(() => repository.getSeenItems()).thenAnswer((_) async => [...seen]);
    when(() => repository.getSeenStatus(any(), any())).thenAnswer(
      (invocation) async => seen
          .where((s) => s.tmdbId == invocation.positionalArguments.first)
          .toList(),
    );
    when(
      () => repository.removeFromSeen(
        any(),
        any(),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer((invocation) async {
      seen.removeWhere((s) => s.tmdbId == invocation.positionalArguments.first);
    });
    when(() => repository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repository.toggleLike(any())).thenAnswer((_) async {});
    when(() => repository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => repository.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => repository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => repository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => repository.getMediaDetails(1, type: any(named: 'type')),
    ).thenAnswer(
      (_) async => MediaDetails(
        item: film,
        cast: const [
          CastMember(id: 9, name: 'Leonardo DiCaprio', character: 'Cobb'),
        ],
        director: const CrewMember(name: 'Christopher Nolan', job: 'Director'),
        similar: const [other],
      ),
    );
    when(
      () => repository.getMediaDetails(5, type: any(named: 'type')),
    ).thenAnswer((_) async => MediaDetails(item: other, cast: const []));
    when(
      () => repository.getMediaDetails(2, type: any(named: 'type')),
    ).thenAnswer((_) async => MediaDetails(item: serie, cast: const []));
    when(() => repository.getSeasonDetails(2, any())).thenAnswer(
      (invocation) async => {
        'episodes': [
          for (var e = 1; e <= 3; e++)
            {
              'episode_number': e,
              'name': 'S${invocation.positionalArguments[1]} episode $e',
              'air_date': '2018-01-0$e',
            },
        ],
      },
    );
    when(() => repository.getActorDetails(9)).thenAnswer(
      (_) async =>
          const ActorDetails(id: 9, name: 'Leonardo DiCaprio', items: [other]),
    );

    settingsProvider = SettingsProvider(preferences, FakeTmdbCredentialStore());
    locator.registerSingleton<MediaRepository>(repository);
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    MediaItem item, {
    AppPalette palette = AppPalette.paper,
    Locale locale = const Locale('en'),
  }) async {
    // Built inside the test zone so that the start-up load completes.
    searchProvider = SearchProvider(repository);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: MaterialApp(
          theme: palette.toThemeData(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AppMessageHost(child: child!),
          home: MediaDetailPage(
            item: item,
            onShare: (text) async => shared.add(text),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Lets a message of [showAppMessage] expire.
  Future<void> dismissMessage(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('header', () {
    for (final palette in testPalettes) {
      testWidgets('should show the header of a film (${palette.id.name})', (
        tester,
      ) async {
        await pumpPage(tester, film, palette: palette);

        expect(find.byKey(MediaDetailHeader.titleKey), findsOneWidget);
        expect(find.text('2010 · 2h 28m'), findsOneWidget);
        expect(
          find.textContaining('8.4 out of 10 on TMDB', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Released'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('should keep the poster size and cap an 80-character title', (
      tester,
    ) async {
      Future<(Size, double)> measure(String title) async {
        final item = film.copyWith(id: 5, title: title);
        when(
          () => repository.getMediaDetails(5, type: any(named: 'type')),
        ).thenAnswer((_) async => MediaDetails(item: item, cast: const []));
        await pumpPage(tester, item);
        final poster = tester.getSize(find.byKey(MediaDetailHeader.posterKey));
        final header = tester.getSize(find.byType(MediaDetailHeader)).height;
        await tester.pumpWidget(const SizedBox());
        return (poster, header);
      }

      final title80 = List.filled(8, 'Very long').join(' ').padRight(80, '!');
      expect(title80.length, 80);
      final (posterShort, _) = await measure('Up');
      final (poster80, header80) = await measure(title80);
      final (poster300, header300) = await measure(title80 * 4);

      const size = Size(
        MediaDetailHeader.posterWidth,
        MediaDetailHeader.posterHeight,
      );
      expect(posterShort, size);
      expect(poster80, size);
      expect(poster300, size);
      // Three lines at most: a longer title does not make the header taller.
      expect(header80, header300);

      final item = film.copyWith(id: 5, title: title80);
      await pumpPage(tester, item);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byKey(MediaDetailHeader.titleKey),
      );
      expect(paragraph.maxLines, MediaDetailHeader.titleMaxLines);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should give the year and the length only once', (
      tester,
    ) async {
      await pumpPage(tester, film);
      final texts = <String>[];
      void collect() {
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          final value = text.data ?? text.textSpan?.toPlainText() ?? '';
          if (!texts.contains(value)) texts.add(value);
        }
      }

      collect();
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        collect();
      }

      expect(texts.where((t) => t.contains('2010')), hasLength(1));
      expect(texts.where((t) => t.contains('2h 28m')), hasLength(1));
      expect(texts.where((t) => t.contains('148')), isEmpty);
    });

    testWidgets('should describe a series and translate its status', (
      tester,
    ) async {
      await pumpPage(tester, serie, locale: const Locale('fr'));

      expect(
        find.text('2017 · 2 saisons · 6 épisodes · ~52 min'),
        findsOneWidget,
      );
      expect(find.text('Terminée'), findsOneWidget);
      expect(find.text('Ended'), findsNothing);
    });

    testWidgets('should give round buttons 44 dp visible in a 48 dp target', (
      tester,
    ) async {
      await pumpPage(tester, film);

      final more = find.byKey(MediaDetailHeader.moreKey);
      expect(tester.getSize(more).shortestSide, kMinTapTarget);
      final disc = find.descendant(of: more, matching: find.byType(Container));
      expect(tester.getSize(disc.first), const Size.square(44));
      expect(find.byTooltip('Like'), findsOneWidget);
      expect(find.byTooltip('More actions'), findsOneWidget);
    });

    testWidgets('should fit at text scale 2 on a 320 dp screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpPage(
        tester,
        film.copyWith(title: 'A very long title that goes on and on' * 3),
        locale: const Locale('fr'),
      );
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('actions kept from the former app bar', () {
    testWidgets('should like from the header', (tester) async {
      await pumpPage(tester, film);

      await tester.tap(find.byTooltip('Like'));
      await tester.pumpAndSettle();

      verify(() => repository.toggleLike(any())).called(1);
    });

    testWidgets('should offer mark as seen as the main action of a film', (
      tester,
    ) async {
      await pumpPage(tester, film);

      expect(find.widgetWithText(FilledButton, 'Mark as seen'), findsOneWidget);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(kMinTapTarget),
      );
    });

    testWidgets('should keep the export of the history in the menu', (
      tester,
    ) async {
      await pumpPage(tester, film);

      await tester.tap(find.byKey(MediaDetailHeader.moreKey));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      await tester.tap(find.text('Export history for this item'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Nothing was seen: the export reports it.
      expect(find.text('No history to export for this item.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('more menu', () {
    testWidgets('should share the TMDB link of the title', (tester) async {
      await pumpPage(tester, film);

      await tester.tap(find.byKey(MediaDetailHeader.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(shared, ['https://www.themoviedb.org/movie/1']);
      expect(
        MediaDetailPage.tmdbLink(serie),
        'https://www.themoviedb.org/tv/2',
      );
    });

    testWidgets('should not offer to clear an empty history', (tester) async {
      await pumpPage(tester, film);

      await tester.tap(find.byKey(MediaDetailHeader.moreKey));
      await tester.pumpAndSettle();

      expect(find.text('Clear History'), findsNothing);
    });

    testWidgets('should clear the history only after a confirmation', (
      tester,
    ) async {
      seen = [
        SeenItem(
          id: 1,
          tmdbId: 1,
          type: MediaType.movie,
          title: 'Inception',
          seenDate: DateTime(2024),
        ),
      ];
      await pumpPage(tester, film);
      expect(find.textContaining('Seen'), findsWidgets);

      // Cancelling keeps the history.
      await tester.tap(find.byKey(MediaDetailHeader.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear History'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('clear all viewing history for "Inception"'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(
        () => repository.removeFromSeen(
          any(),
          any(),
          seasonNumber: any(named: 'seasonNumber'),
          episodeNumber: any(named: 'episodeNumber'),
        ),
      );

      await tester.tap(find.byKey(MediaDetailHeader.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      verify(() => repository.removeFromSeen(1, MediaType.movie)).called(1);
      expect(find.widgetWithText(FilledButton, 'Mark as seen'), findsOneWidget);
    });
  });

  group('synopsis', () {
    testWidgets('should fold to four lines and unfold with Read more', (
      tester,
    ) async {
      await pumpPage(tester, film);
      await reveal(tester, find.text('Read more'));

      RenderParagraph paragraph() => tester.renderObject<RenderParagraph>(
        find.byKey(MediaDetailSynopsis.textKey),
      );
      expect(paragraph().maxLines, MediaDetailSynopsis.collapsedLines);
      final folded = paragraph().size.height;

      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();
      expect(paragraph().maxLines, isNull);
      expect(paragraph().size.height, greaterThan(folded));

      await reveal(tester, find.text('Show less'));
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      // Folding shortens the page: bring the synopsis back into view.
      await tester.scrollUntilVisible(
        find.text('Read more'),
        -100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(paragraph().maxLines, MediaDetailSynopsis.collapsedLines);
    });

    testWidgets('should have no link when the text is short', (tester) async {
      await pumpPage(tester, other);

      expect(find.text('Time runs backwards.'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);
    });

    testWidgets('should be hidden when empty', (tester) async {
      const empty = MediaItem(
        id: 5,
        title: 'Tenet',
        releaseDate: '2020-08-26',
        overview: '  ',
      );
      when(
        () => repository.getMediaDetails(5, type: any(named: 'type')),
      ).thenAnswer((_) async => MediaDetails(item: empty, cast: const []));
      await pumpPage(tester, empty);

      expect(find.byKey(MediaDetailSynopsis.textKey), findsNothing);
      expect(find.text('Overview'), findsNothing);
    });
  });

  group('info', () {
    testWidgets('should show localized country and language names', (
      tester,
    ) async {
      await pumpPage(tester, film, locale: const Locale('fr'));
      await reveal(tester, find.text('Langue'));

      expect(find.text('Réalisation'), findsOneWidget);
      expect(find.text('Christopher Nolan'), findsOneWidget);
      expect(find.text('Titre original'), findsOneWidget);
      expect(find.text('Inception (original)'), findsOneWidget);
      expect(find.text('États-Unis, Royaume-Uni'), findsOneWidget);
      expect(find.text('Anglais'), findsOneWidget);
    });
  });

  group('lists', () {
    testWidgets('should add to the first list in one tap, with Undo', (
      tester,
    ) async {
      await pumpPage(tester, film);

      await tester.tap(find.byKey(ListSplitButton.mainKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(lists['watchlist'], ['1:movie']);
      expect(find.text('Added to “Watchlist”'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(lists['watchlist'], isEmpty);

      // A second tap on the main part removes the title, also confirmed.
      await tester.tap(find.byKey(ListSplitButton.mainKey));
      await tester.pump();
      await dismissMessage(tester);
      await tester.tap(find.byKey(ListSplitButton.mainKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(lists['watchlist'], isEmpty);
      expect(find.text('Removed from “Watchlist”'), findsOneWidget);
      await dismissMessage(tester);
    });

    testWidgets('should add to another list in two taps', (tester) async {
      await pumpPage(tester, film);
      expect(find.byKey(ListSplitButton.badgeKey), findsNothing);

      await tester.tap(find.byKey(ListSplitButton.menuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekend'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(lists['Weekend'], ['1:movie']);
      expect(lists['watchlist'], isEmpty);
      expect(find.text('Added to “Weekend”'), findsOneWidget);
      // The badge counts the other lists holding the title.
      expect(
        find.descendant(
          of: find.byKey(ListSplitButton.badgeKey),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      await dismissMessage(tester);

      await reveal(tester, find.text('In your lists: Weekend'));
      expect(find.text('In your lists: Weekend'), findsOneWidget);
    });

    testWidgets('should remove from a list through the menu', (tester) async {
      lists['Classics'] = ['1:movie'];
      await pumpPage(tester, film);

      await tester.tap(find.byKey(ListSplitButton.menuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classics'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(lists['Classics'], isEmpty);
      expect(find.text('Removed from “Classics”'), findsOneWidget);
      await dismissMessage(tester);
    });
  });

  group('section order', () {
    testWidgets('should put the seasons of a series right under the actions', (
      tester,
    ) async {
      await pumpPage(tester, serie);

      final seasons = tester.getTopLeft(find.text('Seasons')).dy;
      expect(
        seasons,
        greaterThan(tester.getBottomLeft(find.byType(ListSplitButton)).dy),
      );
      await reveal(tester, find.text('Drama'));
      // Genres come after the last season.
      expect(
        tester.getTopLeft(find.text('Drama')).dy,
        greaterThan(tester.getTopLeft(find.text('Season 2')).dy),
      );
    });

    testWidgets('should keep genres and synopsis first for a film', (
      tester,
    ) async {
      await pumpPage(tester, film);

      expect(find.text('Seasons'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Action')).dy,
        lessThan(tester.getTopLeft(find.text('Overview')).dy),
      );
    });

    testWidgets(
      'should open the season of the next episode of a started series, '
      'visible on a 844 dp screen',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        seen = [episodeSeen(1, 1), episodeSeen(1, 2), episodeSeen(1, 3)];

        await pumpPage(tester, serie);

        // Next episode: S2 E1, offered by the main action and listed in its
        // unfolded season, without scrolling.
        expect(find.text('Watch Next: S2 E1').hitTestable(), findsOneWidget);
        expect(find.text('E1: S2 episode 1').hitTestable(), findsOneWidget);
        expect(find.text('E1: S1 episode 1'), findsNothing);
      },
    );

    testWidgets('should leave the seasons folded for a series not started', (
      tester,
    ) async {
      await pumpPage(tester, serie);

      expect(find.textContaining('episode 1'), findsNothing);
    });
  });

  group('offline', () {
    testWidgets('should show the offline banner and a retry', (tester) async {
      when(
        () => repository.getMediaDetails(1, type: any(named: 'type')),
      ).thenThrow(Exception('SocketException'));

      await pumpPage(tester, film);

      expect(find.textContaining('Offline Mode'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(ListSplitButton), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('should stack pages: title, person, other title, and back', (
      tester,
    ) async {
      await pumpPage(tester, film);

      await reveal(tester, find.text('Leonardo DiCaprio'));
      await tester.tap(find.text('Leonardo DiCaprio'));
      await tester.pumpAndSettle();
      expect(find.byType(ActorDetailPage), findsOneWidget);

      await tester.ensureVisible(find.text('Tenet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenet'));
      await tester.pumpAndSettle();
      expect(find.byType(MediaDetailPage), findsOneWidget);
      expect(find.text('Time runs backwards.'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ActorDetailPage), findsOneWidget);
      expect(find.text('Time runs backwards.'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ActorDetailPage), findsNothing);
      expect(find.byType(MediaDetailPage), findsOneWidget);
      expect(find.text('Leonardo DiCaprio'), findsOneWidget);
      expect(find.text('Directed by'), findsOneWidget);
    });

    testWidgets('should push a related title and come back', (tester) async {
      await pumpPage(tester, film);

      await reveal(tester, find.text('Tenet'));
      await tester.tap(find.text('Tenet'));
      await tester.pumpAndSettle();
      expect(find.text('Time runs backwards.'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Time runs backwards.'), findsNothing);
      expect(find.text('Similar'), findsOneWidget);
    });
  });
}
