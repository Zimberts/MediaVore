import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/features/home/presentation/pages/home_page.dart';
import 'package:mediavore/features/home/presentation/pages/upcoming_page.dart';
import 'package:mediavore/features/home/presentation/providers/home_session_provider.dart';
import 'package:mediavore/features/home/presentation/widgets/debug_omissions_section.dart';
import 'package:mediavore/features/home/presentation/widgets/upcoming_row.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

/// Tall enough to build every row of the lazy list.
const tall = Size(390, 3000);

// Saturday evening.
final _now = DateTime(2026, 11, 14, 21);

DateTime _day(int offset) => DateTime(2026, 11, 14 + offset);

NotifiedItem _film(int id, String title, DateTime? date, {int? runtime}) =>
    NotifiedItem(
      tmdbId: id,
      type: MediaType.movie,
      title: title,
      releaseDate: date,
      runtime: runtime,
    );

NotifiedItem _episode(
  int id,
  String title,
  DateTime? date, {
  int? season = 2,
  int? episode = 4,
}) => NotifiedItem(
  tmdbId: id,
  type: MediaType.tv,
  title: title,
  releaseDate: date,
  seasonNumber: season,
  episodeNumber: episode,
  autoNotify: true,
);

/// In-memory repository behaving like the real one for the releases.
class _FakeRepository extends MockMediaRepository {
  final List<NotifiedItem> notified = [];
  final List<SeenItem> viewings = [];
  final List<bool> restoredAuto = [];
  int refreshCalls = 0;
  int _nextId = 1;

  @override
  Future<List<NotifiedItem>> getNotifiedItems() async => List.of(notified);

  @override
  Future<bool> isNotified(int tmdbId, MediaType type) async =>
      notified.any((n) => n.tmdbId == tmdbId && n.type == type);

  @override
  Future<void> toggleNotification(
    MediaItem item, {
    bool autoNotify = false,
  }) async {
    final before = notified.length;
    notified.removeWhere(
      (n) => n.tmdbId == item.id && n.type == item.mediaType,
    );
    if (notified.length == before) {
      restoredAuto.add(autoNotify);
      notified.add(
        NotifiedItem(
          tmdbId: item.id,
          type: item.mediaType,
          title: item.title,
          releaseDate: DateTime.tryParse(item.releaseDate),
          autoNotify: autoNotify,
        ),
      );
    }
  }

  @override
  Future<void> markAsSeen(SeenItem item) async => viewings.add(
    SeenItem(
      id: _nextId++,
      tmdbId: item.tmdbId,
      type: item.type,
      title: item.title,
      seenDate: item.seenDate,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
    ),
  );

  @override
  Future<List<SeenItem>> getSeenItems() async => List.of(viewings);

  @override
  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type) async => [
    for (final viewing in viewings)
      if (viewing.tmdbId == tmdbId && viewing.type == type) viewing,
  ];

  @override
  Future<void> deleteSeenEntry(int id) async =>
      viewings.removeWhere((viewing) => viewing.id == id);

  @override
  Future<void> populateQuickAddFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  }) async {}

  @override
  Future<void> refreshNotifiedItems({bool force = false}) async =>
      refreshCalls++;

  @override
  Future<void> refreshQuickAddItems() async {}
}

void main() {
  late _FakeRepository repository;
  late SearchProvider searchProvider;
  late HomeSessionProvider session;
  late MockSharedPreferences prefs;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    repository = _FakeRepository();
    session = HomeSessionProvider();
    prefs = MockSharedPreferences();
    when(() => prefs.getInt(any())).thenReturn(null);
    when(() => prefs.getDouble(any())).thenReturn(null);
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.getString(any())).thenReturn(null);

    when(
      () => repository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(() => repository.getListEntries(any())).thenAnswer((_) async => []);
    when(
      () => repository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => repository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repository.getLikedEntries()).thenAnswer((_) async => []);
    when(
      () => repository.getMediaDetails(any(), type: any(named: 'type')),
    ).thenThrow(Exception('offline'));
  });

  tearDown(() => appMessageController.dismiss());

  Future<void> pump(
    WidgetTester tester, {
    bool home = false,
    AppPalette palette = AppPalette.paper,
    Locale locale = const Locale('en'),
    bool debug = false,
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => prefs.getBool('notificationCenterDebug')).thenReturn(debug);
    searchProvider = SearchProvider(repository);
    final settings = SettingsProvider(prefs, FakeTmdbCredentialStore('key'));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<HomeSessionProvider>.value(value: session),
        ],
        child: MaterialApp(
          theme: palette.toThemeData(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: AppMessageHost(child: child!),
          ),
          home: home
              ? Scaffold(body: HomePage(clock: () => _now))
              : UpcomingPage(clock: () => _now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Ids of the rows, from top to bottom.
  List<int> rowIds(WidgetTester tester) => [
    for (final row in tester.widgetList<UpcomingRow>(
      find.byType(UpcomingRow, skipOffstage: false),
    ))
      row.item.tmdbId,
  ];

  /// 8 dated releases (1 already out, 2 this week, 2 this month, 3 later)
  /// and 3 without a date.
  void addMany() {
    repository.notified.addAll([
      _film(1, 'Dune', _day(-20), runtime: 135),
      _episode(2, 'Severance', _day(0)),
      _film(3, 'Alien', _day(5)),
      _film(4, 'Heat', _day(10)),
      _episode(5, 'Andor', _day(25), season: 1, episode: 1),
      _film(6, 'Tenet', DateTime(2027, 2, 3)),
      _film(7, 'Zodiac', DateTime(2027, 2, 20)),
      _episode(8, 'Dark', DateTime(2027, 5, 1)),
      _episode(9, 'The Bear', null, season: null, episode: null),
      _film(10, 'Avatar 4', null),
      _episode(11, 'Arcane', null, season: 3, episode: 1),
    ]);
  }

  group('UpcomingPage list', () {
    testWidgets('should list what is out, then month by month, then no date', (
      tester,
    ) async {
      addMany();
      await pump(tester, size: tall);

      expect(find.text('Upcoming · 8'), findsOneWidget);
      expect(rowIds(tester), [1, 2, 3, 4, 5, 6, 7, 8, 11, 9, 10]);
      for (final title in [
        'Already released · 1',
        'November 2026 · 3',
        'December 2026 · 1',
        'February 2027 · 2',
        'May 2027 · 1',
        'No date · 3',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('should keep a release of today, with its mark button', (
      tester,
    ) async {
      repository.notified.add(_episode(2, 'Severance', _day(0)));
      await pump(tester);

      expect(find.text('November 2026 · 1'), findsOneWidget);
      expect(find.text('S2 E4 · Released: Nov 14, 2026'), findsOneWidget);
      expect(find.byTooltip('Mark Severance as seen'), findsOneWidget);
    });

    testWidgets('should follow the current rules for past releases', (
      tester,
    ) async {
      repository.notified.addAll([
        // A film stays until it is seen, an episode for 30 days.
        _film(1, 'Old film', _day(-200)),
        _episode(2, 'Recent episode', _day(-29)),
        _episode(3, 'Old episode', _day(-31)),
        _film(4, 'Seen film', _day(-3)),
      ]);
      repository.viewings.add(
        SeenItem(
          id: 99,
          tmdbId: 4,
          type: MediaType.movie,
          title: 'Seen film',
          seenDate: _day(-1),
        ),
      );
      await pump(tester);

      expect(rowIds(tester), [1, 2]);
      expect(find.text('Already released · 2'), findsOneWidget);
      expect(find.byType(DebugOmissionsSection), findsNothing);
    });

    testWidgets('should show the runtime only when it is known', (
      tester,
    ) async {
      repository.notified.addAll([
        _film(1, 'Dune', _day(3), runtime: 135),
        _film(2, 'Alien', _day(4)),
      ]);
      await pump(tester);

      expect(find.text('Releases: Nov 17, 2026 · 2h 15m'), findsOneWidget);
      expect(find.text('Releases: Nov 18, 2026'), findsOneWidget);
      // Not out yet: nothing to mark.
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('should say when nothing is planned', (tester) async {
      await pump(tester);

      expect(find.text('Upcoming · 0'), findsOneWidget);
      expect(find.text('Nothing planned.'), findsOneWidget);
      expect(find.byKey(const Key('upcoming_filters')), findsNothing);
    });

    testWidgets('should be written in French', (tester) async {
      addMany();
      await pump(tester, locale: const Locale('fr'), size: tall);

      expect(find.text('À venir · 8'), findsOneWidget);
      expect(find.text('Déjà sorties · 1'), findsOneWidget);
      expect(find.text('Novembre 2026 · 3'), findsOneWidget);
      expect(find.text('S2 É4 · Sorti le 14 nov. 2026'), findsOneWidget);
      expect(find.text('Sans date · 3'), findsOneWidget);
    });
  });

  group('UpcomingPage type filter', () {
    testWidgets('should filter by type and keep the total in the title', (
      tester,
    ) async {
      addMany();
      await pump(tester, size: tall);
      expect(find.text('Books'), findsNothing);

      await tester.tap(find.text('Films'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [1, 3, 4, 6, 7, 10]);
      expect(find.text('Upcoming · 8'), findsOneWidget);
      expect(find.text('November 2026 · 2'), findsOneWidget);

      await tester.tap(find.text('Series'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [2, 5, 8, 11, 9]);
      expect(find.text('Already released · 1'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), hasLength(11));
    });

    testWidgets('should keep the filter when the page is reopened', (
      tester,
    ) async {
      addMany();
      await pump(tester, size: tall);
      await tester.tap(find.text('Series'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await pump(tester, size: tall);

      expect(session.upcomingKind, MediaKind.series);
      expect(rowIds(tester), [2, 5, 8, 11, 9]);
    });

    testWidgets('should not offer a filter with a single type', (tester) async {
      repository.notified.add(_film(1, 'Dune', _day(3)));
      session.setUpcomingKind(MediaKind.series);
      await pump(tester);

      expect(find.byKey(const Key('upcoming_filters')), findsNothing);
      expect(rowIds(tester), [1]);
    });
  });

  group('UpcomingPage actions', () {
    testWidgets('should mark a released film as seen, with Undo', (
      tester,
    ) async {
      repository.notified.add(_film(1, 'Dune', _day(-2)));
      await pump(tester);

      await tester.tap(find.byTooltip('Mark Dune as seen'));
      await tester.pumpAndSettle();

      expect(repository.viewings.single.tmdbId, 1);
      expect(find.byType(UpcomingRow), findsNothing);
      expect(find.text('Seen · Dune'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.viewings, isEmpty);
      expect(rowIds(tester), [1]);
    });

    testWidgets('should mark the notified episode, not the whole series', (
      tester,
    ) async {
      repository.notified.add(_episode(2, 'Severance', _day(-1)));
      await pump(tester);

      await tester.tap(find.byTooltip('Mark Severance as seen'));
      await tester.pumpAndSettle();

      final viewing = repository.viewings.single;
      expect(viewing.seasonNumber, 2);
      expect(viewing.episodeNumber, 4);
    });

    testWidgets('should disable the alert from the menu, with Undo', (
      tester,
    ) async {
      repository.notified.addAll([
        _episode(2, 'Severance', _day(3)),
        _film(3, 'Alien', _day(5)),
      ]);
      await pump(tester);

      await tester.tap(find.byTooltip('More actions for Severance'));
      await tester.pumpAndSettle();
      expect(find.text('Open details'), findsOneWidget);
      await tester.tap(find.text('Disable the alert'));
      await tester.pumpAndSettle();

      expect(rowIds(tester), [3]);
      expect(find.text('Alert disabled · Severance'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(rowIds(tester), [2, 3]);
      // Followed again as it was: automatically.
      expect(repository.restoredAuto, [true]);
    });

    testWidgets('should open the detail page from a row', (tester) async {
      repository.notified.add(_film(1, 'Dune', _day(3)));
      await pump(tester);

      await tester.tap(find.text('Dune'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MediaDetailPage), findsOneWidget);
    });

    testWidgets('should refresh on pull', (tester) async {
      repository.notified.add(_film(1, 'Dune', _day(3)));
      await pump(tester);

      await tester.fling(find.byType(UpcomingRow), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repository.refreshCalls, 1);
    });
  });

  group('UpcomingPage debug', () {
    void addHidden() {
      repository.notified.addAll([
        _film(1, 'Dune', _day(3)),
        _film(4, 'Seen film', _day(-3)),
        _episode(3, 'Old show', _day(-31)),
      ]);
      repository.viewings.add(
        SeenItem(
          id: 99,
          tmdbId: 4,
          type: MediaType.movie,
          title: 'Seen film',
          seenDate: _day(-1),
        ),
      );
    }

    testWidgets('should not show the section when debug is off', (
      tester,
    ) async {
      addHidden();
      await pump(tester);

      expect(find.byType(DebugOmissionsSection), findsNothing);
      expect(find.text('Seen film'), findsNothing);
    });

    testWidgets('should list hidden releases by reason, at the bottom', (
      tester,
    ) async {
      addHidden();
      await pump(tester, debug: true);

      for (final text in [
        'Debug — hidden releases',
        'These items exist in the database but are omitted above.',
        'Already seen · 1',
        'Seen film',
        'Already in the history',
        'Aired more than 30 days ago · 1',
        'Old show · S2 E4',
        'Stored air date: Oct 14, 2026',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.byType(DebugOmissionsSection)).dy,
        greaterThan(tester.getTopLeft(find.byType(UpcomingRow)).dy),
      );
    });

    testWidgets('should translate the reasons in French', (tester) async {
      addHidden();
      await pump(tester, debug: true, locale: const Locale('fr'));

      for (final text in [
        'Debug — sorties masquées',
        'Ces éléments existent dans la base mais sont omis ci-dessus.',
        'Déjà vu · 1',
        'Déjà dans l\'historique',
        'Diffusé il y a plus de 30 jours · 1',
        'Old show · S2 É4',
        'Date de diffusion enregistrée : 14 oct. 2026',
        'Recalculer',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('should refresh the releases with "Recompute"', (tester) async {
      await pump(tester, debug: true);
      expect(find.text('Nothing omitted.'), findsOneWidget);

      addHidden();
      await tester.tap(find.text('Recompute'));
      await tester.pumpAndSettle();

      expect(repository.refreshCalls, 1);
      expect(find.text('Already seen · 1'), findsOneWidget);
    });
  });

  group('HomePage upcoming', () {
    Future<void> showUpcoming(WidgetTester tester, Key key) async {
      await tester.scrollUntilVisible(
        find.byKey(key),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }

    testWidgets(
      'should show 5 releases at most, with the count of each group',
      (tester) async {
        addMany();
        await pump(tester, home: true);

        expect(find.text('Upcoming · 8', skipOffstage: false), findsOneWidget);
        expect(rowIds(tester), [1, 2, 3, 4, 5]);
        for (final label in [
          'Already released · 1',
          'This week · 2',
          'This month · 2',
        ]) {
          expect(find.text(label, skipOffstage: false), findsOneWidget);
        }
        expect(find.textContaining('Later', skipOffstage: false), findsNothing);
        expect(
          find.text('3 without a date', skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets('should count a group in full even when it is cut', (
      tester,
    ) async {
      repository.notified.addAll([
        for (var i = 1; i <= 7; i++) _film(i, 'Film $i', _day(i - 1)),
      ]);
      await pump(tester, home: true);

      expect(rowIds(tester), [1, 2, 3, 4, 5]);
      expect(find.text('This week · 7', skipOffstage: false), findsOneWidget);
      expect(find.text('Upcoming · 7', skipOffstage: false), findsOneWidget);
    });

    testWidgets('should put a release of today in "This week"', (tester) async {
      repository.notified.add(_episode(2, 'Severance', _day(0)));
      await pump(tester, home: true);

      expect(find.text('This week · 1', skipOffstage: false), findsOneWidget);
      expect(find.text('Upcoming · 1', skipOffstage: false), findsOneWidget);
      // 5 releases or fewer: everything is here, no "See all".
      expect(find.text('See all', skipOffstage: false), findsNothing);
    });

    testWidgets('should agree with the full page, opened from "See all"', (
      tester,
    ) async {
      addMany();
      await pump(tester, home: true);

      await showUpcoming(tester, const Key('home_upcoming'));
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('home_upcoming')),
          matching: find.text('See all'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UpcomingPage), findsOneWidget);
      expect(find.text('Upcoming · 8'), findsOneWidget);
    });

    testWidgets('should open the full page from "without a date"', (
      tester,
    ) async {
      repository.notified.add(_film(10, 'Avatar 4', null));
      await pump(tester, home: true);

      expect(find.text('Upcoming · 0', skipOffstage: false), findsOneWidget);
      await showUpcoming(tester, const Key('home_upcoming_undated'));
      await tester.tap(find.byKey(const Key('home_upcoming_undated')));
      await tester.pumpAndSettle();

      expect(find.byType(UpcomingPage), findsOneWidget);
      expect(find.text('No date · 1'), findsOneWidget);
    });

    testWidgets('should explain an empty section, in French too', (
      tester,
    ) async {
      await pump(tester, home: true, locale: const Locale('fr'));

      expect(find.text('À venir · 0', skipOffstage: false), findsOneWidget);
      expect(
        find.textContaining('Aucune sortie à venir', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home_upcoming_debug')), findsNothing);
    });

    testWidgets('should mark a released film as seen from Home', (
      tester,
    ) async {
      repository.notified.add(_film(1, 'Dune', _day(-2)));
      await pump(tester, home: true);

      await tester.tap(find.byTooltip('Mark Dune as seen'));
      await tester.pumpAndSettle();

      expect(repository.viewings.single.tmdbId, 1);
      expect(find.text('Upcoming · 0', skipOffstage: false), findsOneWidget);
    });

    testWidgets('should lead to the hidden releases only when debug is on', (
      tester,
    ) async {
      repository.notified.addAll([
        _film(1, 'Dune', _day(3)),
        _episode(3, 'Old show', _day(-31)),
      ]);
      await pump(tester, home: true, debug: true);

      expect(
        find.text('Debug · 1 hidden release', skipOffstage: false),
        findsOneWidget,
      );
      await showUpcoming(tester, const Key('home_upcoming_debug'));
      await tester.tap(find.byKey(const Key('home_upcoming_debug')));
      await tester.pumpAndSettle();

      expect(find.byType(UpcomingPage), findsOneWidget);
      expect(find.text('Aired more than 30 days ago · 1'), findsOneWidget);
    });
  });

  group('Upcoming rendering', () {
    void addLong() {
      repository.notified.addAll([
        _film(
          1,
          'The Incredibly Long Title Of A Film That Was Released A While Ago '
          'And Never Watched',
          _day(-12),
          runtime: 185,
        ),
        _episode(
          2,
          'Another Extremely Long Title For A Series With Many Seasons',
          _day(2),
          season: 12,
          episode: 24,
        ),
        _episode(3, 'Old show', _day(-31)),
        _episode(9, 'The Bear', null, season: null, episode: null),
      ]);
    }

    for (final palette in testPalettes) {
      for (final home in [false, true]) {
        final where = home ? 'Home' : 'the page';
        testWidgets('should render $where on ${palette.id.name}', (
          tester,
        ) async {
          addLong();
          await pump(tester, home: home, palette: palette, debug: true);

          expect(find.byType(UpcomingRow, skipOffstage: false), findsWidgets);
          expect(tester.takeException(), isNull);
        });

        testWidgets('should not overflow $where at text scale 2 on 320 dp on '
            '${palette.id.name}', (tester) async {
          addLong();
          await pump(
            tester,
            home: home,
            palette: palette,
            debug: true,
            textScale: 2,
            size: const Size(320, 640),
            locale: const Locale('fr'),
          );

          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('should keep every tap target at 48 dp and labeled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      addLong();
      await pump(tester, debug: true);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      for (final tooltip in [
        'Mark The Incredibly Long Title Of A Film That Was Released A While '
            'Ago And Never Watched as seen',
        'More actions for The Bear',
      ]) {
        final size = tester.getSize(find.byTooltip(tooltip));
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      }
      handle.dispose();
    });
  });
}
