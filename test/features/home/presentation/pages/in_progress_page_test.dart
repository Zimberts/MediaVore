import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/features/home/presentation/in_progress_sort.dart';
import 'package:mediavore/features/home/presentation/pages/in_progress_page.dart';
import 'package:mediavore/features/home/presentation/providers/home_session_provider.dart';
import 'package:mediavore/features/home/presentation/widgets/debug_omissions_section.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_row.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

final _now = DateTime(2026, 11, 14, 21);

class _Series {
  _Series(
    this.id,
    this.title, {
    this.seen = 3,
    this.episodes = 10,
    this.knowsEpisodeCount = true,
    this.daysAgo = 1,
  });

  final int id;
  final String title;
  int seen;
  final int episodes;
  final bool knowsEpisodeCount;
  final int daysAgo;
}

/// In-memory repository behaving like the real one for "In progress":
/// opting out removes the queued episode, restoring computes it again.
class _FakeRepository extends MockMediaRepository {
  final Map<int, _Series> series = {};
  final Map<int, QuickAddItem> queue = {};
  final List<QuickAddOptOut> optOuts = [];
  final List<SeenItem> viewings = [];
  List<QuickAddOmission> omissions = [];
  final List<bool> omissionCalls = [];
  int refreshCalls = 0;
  int _nextId = 1;

  QuickAddItem _next(_Series s, DateTime insertedAt) => QuickAddItem(
    isarId: _nextId++,
    tmdbId: s.id,
    type: MediaType.tv,
    seasonNumber: 1,
    episodeNumber: s.seen + 1,
    insertedAt: insertedAt,
    title: s.title,
    runtime: 50,
  );

  void addSeries(_Series s) {
    series[s.id] = s;
    queue[s.id] = _next(s, _now.subtract(Duration(days: s.daysAgo)));
  }

  @override
  Future<List<QuickAddItem>> getQuickAddItems() async => queue.values.toList();

  @override
  Future<List<InProgressItem>> getInProgressItems() async {
    final items = [
      for (final next in queue.values)
        InProgressItem(
          next: next,
          seenEpisodes: series[next.tmdbId]!.seen,
          totalEpisodes: series[next.tmdbId]!.knowsEpisodeCount
              ? series[next.tmdbId]!.episodes
              : null,
          progress: series[next.tmdbId]!.knowsEpisodeCount
              ? series[next.tmdbId]!.seen / series[next.tmdbId]!.episodes
              : null,
          lastActivity: _now.subtract(
            Duration(days: series[next.tmdbId]!.daysAgo),
          ),
          paused: series[next.tmdbId]!.daysAgo > 30,
        ),
    ];
    items.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return items;
  }

  @override
  Future<List<QuickAddOptOut>> getQuickAddOptOuts() async => List.of(optOuts);

  @override
  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    optOuts.add(
      QuickAddOptOut(
        tmdbId: tmdbId,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        optedOutAt: _now,
        title: series[tmdbId]?.title,
      ),
    );
    queue.remove(tmdbId);
  }

  @override
  Future<void> clearOptOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    optOuts.removeWhere(
      (o) =>
          o.tmdbId == tmdbId &&
          o.seasonNumber == seasonNumber &&
          o.episodeNumber == episodeNumber,
    );
  }

  @override
  Future<void> populateQuickAddFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  }) async {
    final s = series[tmdbId];
    if (s == null || optOuts.any((o) => o.tmdbId == tmdbId)) return;
    queue.putIfAbsent(s.id, () => _next(s, _now));
  }

  @override
  Future<void> addQuickAddItem(QuickAddItem item) async =>
      queue.putIfAbsent(item.tmdbId, () => item);

  @override
  Future<void> removeQuickAddItemById(int isarId) async =>
      queue.removeWhere((_, item) => item.isarId == isarId);

  @override
  Future<void> markAsSeen(SeenItem item) async {
    final s = series[item.tmdbId]!;
    viewings.add(
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
    s.seen = item.episodeNumber!;
    queue.remove(s.id);
    if (s.seen < s.episodes) queue[s.id] = _next(s, item.seenDate);
  }

  @override
  Future<List<SeenItem>> getSeenItems() async => List.of(viewings);

  @override
  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type) async => [
    for (final viewing in viewings)
      if (viewing.tmdbId == tmdbId) viewing,
  ];

  @override
  Future<void> deleteSeenEntry(int id) async {
    final viewing = viewings.firstWhere((v) => v.id == id);
    viewings.remove(viewing);
    series[viewing.tmdbId]!.seen = viewing.episodeNumber! - 1;
  }

  @override
  Future<List<QuickAddOmission>> getQuickAddOmissions({
    bool allowFetch = false,
  }) async {
    omissionCalls.add(allowFetch);
    return List.of(omissions);
  }

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
    when(() => repository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => repository.getMediaDetails(any(), type: any(named: 'type')),
    ).thenThrow(Exception('offline'));
  });

  tearDown(appMessageController.dismiss);

  Future<void> pumpPage(
    WidgetTester tester, {
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
          home: InProgressPage(clock: () => _now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Ids of the rows, from top to bottom.
  List<int> rowIds(WidgetTester tester) => [
    for (final row in tester.widgetList<InProgressRow>(
      find.byType(InProgressRow),
    ))
      row.item.tmdbId,
  ];

  void addFour() {
    repository.addSeries(_Series(1, 'Severance', seen: 2, daysAgo: 3));
    repository.addSeries(_Series(2, 'Andor', seen: 9, daysAgo: 40));
    repository.addSeries(_Series(3, 'The Bear', knowsEpisodeCount: false));
    repository.addSeries(_Series(4, 'Dark', seen: 5, daysAgo: 35));
  }

  group('InProgressPage list', () {
    testWidgets('should list every title with its next episode and activity', (
      tester,
    ) async {
      addFour();
      await pumpPage(tester);

      expect(find.text('In progress · 4'), findsOneWidget);
      expect(rowIds(tester), [3, 1, 4, 2]);
      expect(find.text('Next: S1 E3 · 50m · 3 d ago'), findsOneWidget);
      expect(find.text('Paused · 2'), findsOneWidget);
      // A single kind: no kind chips.
      expect(find.text('All'), findsNothing);
      expect(find.text('Series'), findsNothing);
    });

    testWidgets('should say when nothing is in progress', (tester) async {
      await pumpPage(tester);

      expect(find.text('In progress · 0'), findsOneWidget);
      expect(find.text('No next episodes to track.'), findsOneWidget);
      expect(find.byType(InProgressRow), findsNothing);
    });

    testWidgets('should be written in French', (tester) async {
      addFour();
      repository.optOuts.add(
        QuickAddOptOut(
          tmdbId: 9,
          seasonNumber: 1,
          episodeNumber: 5,
          optedOutAt: _now,
          title: 'Chernobyl',
        ),
      );
      await pumpPage(tester, locale: const Locale('fr'));

      expect(find.text('En cours · 4'), findsOneWidget);
      expect(find.text('En pause · 2'), findsOneWidget);
      expect(find.text('Récents'), findsOneWidget);
      expect(find.text('Presque finis'), findsOneWidget);
      expect(find.text('A–Z'), findsOneWidget);
      expect(find.text('Retirées de l\'ajout rapide · 1'), findsOneWidget);
      expect(find.text('Rétablir'), findsOneWidget);
    });
  });

  group('InProgressPage filters and sorts', () {
    testWidgets('should apply the three sorts', (tester) async {
      addFour();
      await pumpPage(tester);

      await tester.tap(find.text('Almost done'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [2, 4, 1, 3]);

      await tester.tap(find.text('A–Z'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [2, 4, 1, 3]);

      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [3, 1, 4, 2]);
    });

    testWidgets('should combine "Paused" with a sort', (tester) async {
      addFour();
      await pumpPage(tester);

      await tester.tap(find.text('Paused · 2'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [4, 2]);

      await tester.tap(find.text('Almost done'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [2, 4]);

      await tester.tap(find.text('Paused · 2'));
      await tester.pumpAndSettle();
      expect(rowIds(tester), [2, 4, 1, 3]);
    });

    testWidgets('should say when the filters leave nothing', (tester) async {
      repository.addSeries(_Series(1, 'Severance'));
      session.setInProgressPausedOnly(true);
      await pumpPage(tester);

      expect(find.text('Nothing matches these filters.'), findsOneWidget);
      expect(find.text('Paused · 0'), findsOneWidget);
    });

    testWidgets('should keep filters and sort when the page is reopened', (
      tester,
    ) async {
      addFour();
      await pumpPage(tester);
      await tester.tap(find.text('Paused · 2'));
      await tester.tap(find.text('A–Z'));
      await tester.pumpAndSettle();

      // Leave the page, then build a new one in the same session.
      await tester.pumpWidget(const SizedBox());
      await pumpPage(tester);

      expect(session.inProgressSort, InProgressSort.alphabetical);
      expect(session.inProgressPausedOnly, isTrue);
      expect(rowIds(tester), [2, 4]);
    });
  });

  group('InProgressPage actions', () {
    testWidgets('should mark the next episode as seen, with Undo', (
      tester,
    ) async {
      repository.addSeries(_Series(1, 'Severance'));
      await pumpPage(tester);

      await tester.tap(find.byTooltip('Mark S1 E4 of Severance as seen'));
      await tester.pumpAndSettle();

      expect(find.text('S1 E4 seen · Severance'), findsOneWidget);
      expect(find.textContaining('Next: S1 E5'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.viewings, isEmpty);
      expect(find.textContaining('Next: S1 E4'), findsOneWidget);
    });

    testWidgets('should drop the row when the last episode is marked', (
      tester,
    ) async {
      repository.addSeries(_Series(1, 'Severance', episodes: 4));
      await pumpPage(tester);

      await tester.tap(find.byTooltip('Mark S1 E4 of Severance as seen'));
      await tester.pumpAndSettle();

      expect(find.byType(InProgressRow), findsNothing);
      expect(find.text('In progress · 0'), findsOneWidget);
    });

    testWidgets('should remove a series from the menu, then restore it', (
      tester,
    ) async {
      addFour();
      await pumpPage(tester);

      await tester.tap(find.byTooltip('More actions for Severance'));
      await tester.pumpAndSettle();
      expect(find.text('Open details'), findsOneWidget);
      await tester.tap(find.text('Remove from quick add'));
      await tester.pumpAndSettle();

      expect(rowIds(tester), [3, 4, 2]);
      expect(find.text('Series removed from quick add'), findsOneWidget);
      expect(find.text('Removed from quick add · 1'), findsOneWidget);
      expect(find.text('In progress · 3'), findsOneWidget);
      appMessageController.dismiss();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(repository.optOuts, isEmpty);
      expect(rowIds(tester), contains(1));
      expect(find.text('Series restored'), findsOneWidget);
      expect(find.byKey(const Key('in_progress_opt_outs')), findsNothing);
    });

    testWidgets('should put the same episode back with Undo after a removal', (
      tester,
    ) async {
      repository.addSeries(_Series(1, 'Severance'));
      await pumpPage(tester);
      final entry = repository.queue[1];

      await tester.tap(find.byTooltip('More actions for Severance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from quick add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.optOuts, isEmpty);
      expect(repository.queue[1], same(entry));
      expect(rowIds(tester), [1]);
    });

    testWidgets('should remove a series by swiping its row', (tester) async {
      addFour();
      await pumpPage(tester);

      await tester.drag(
        find.byKey(const ValueKey('in_progress_row_3')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(rowIds(tester), [1, 4, 2]);
      expect(repository.optOuts.single.tmdbId, 3);
      expect(repository.optOuts.single.episodeNumber, 4);
      expect(find.text('Series removed from quick add'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('should list a series removed in an earlier session', (
      tester,
    ) async {
      repository.series[9] = _Series(9, 'Chernobyl', seen: 4);
      repository.optOuts.add(
        QuickAddOptOut(
          tmdbId: 9,
          seasonNumber: 1,
          episodeNumber: 5,
          optedOutAt: _now.subtract(const Duration(days: 90)),
          title: 'Chernobyl',
        ),
      );
      await pumpPage(tester);

      expect(find.text('Removed from quick add · 1'), findsOneWidget);
      expect(find.text('Chernobyl'), findsOneWidget);
      expect(find.text('S1 E5'), findsOneWidget);

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(rowIds(tester), [9]);
      expect(find.textContaining('Next: S1 E5'), findsOneWidget);
    });

    testWidgets(
      'should not list an opt-out whose series is in progress again',
      (tester) async {
        repository.addSeries(_Series(1, 'Severance', seen: 5));
        repository.optOuts.add(
          QuickAddOptOut(
            tmdbId: 1,
            seasonNumber: 1,
            episodeNumber: 4,
            optedOutAt: _now,
            title: 'Severance',
          ),
        );
        await pumpPage(tester);

        expect(find.byKey(const Key('in_progress_opt_outs')), findsNothing);
      },
    );

    testWidgets('should open the detail page from the row', (tester) async {
      repository.addSeries(_Series(1, 'Severance'));
      await pumpPage(tester);

      await tester.tap(find.text('Severance'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MediaDetailPage), findsOneWidget);
    });

    testWidgets('should refresh on pull', (tester) async {
      repository.addSeries(_Series(1, 'Severance'));
      await pumpPage(tester);

      await tester.fling(
        find.byType(InProgressRow),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.refreshCalls, 1);
    });
  });

  group('InProgressPage debug', () {
    List<QuickAddOmission> everyReason() => [
      QuickAddOmission(
        tmdbId: 1,
        title: 'Chernobyl',
        seasonNumber: 1,
        episodeNumber: 5,
        reason: QuickAddOmissionReason.optedOut,
      ),
      QuickAddOmission(
        tmdbId: 2,
        title: 'Severance',
        seasonNumber: 2,
        episodeNumber: 4,
        airDate: DateTime(2026, 12, 3),
        reason: QuickAddOmissionReason.notReleased,
      ),
      QuickAddOmission(
        tmdbId: 3,
        title: 'Andor',
        seasonNumber: 1,
        episodeNumber: 2,
        reason: QuickAddOmissionReason.noAirDate,
      ),
      QuickAddOmission(
        tmdbId: 4,
        title: 'Dark',
        tailSeason: 1,
        tailEpisode: 8,
        reason: QuickAddOmissionReason.noCacheData,
      ),
      QuickAddOmission(
        tmdbId: 5,
        title: 'The Bear',
        seasonNumber: 3,
        episodeNumber: 1,
        reason: QuickAddOmissionReason.notPopulated,
      ),
    ];

    testWidgets('should not show the section when debug is off', (
      tester,
    ) async {
      repository.omissions = everyReason();
      await pumpPage(tester);

      expect(find.byType(DebugOmissionsSection), findsNothing);
      expect(repository.omissionCalls, isEmpty);
    });

    testWidgets('should show every reason, grouped, when debug is on', (
      tester,
    ) async {
      repository.omissions = everyReason();
      await pumpPage(tester, debug: true);

      expect(repository.omissionCalls, [false]);
      expect(find.text('Debug — missing episodes'), findsOneWidget);
      for (final text in [
        'Removed from quick add · 1',
        'Chernobyl · S1 E5',
        'Removed manually',
        'Next episode not aired yet · 1',
        'Severance · S2 E4',
        'Airs on Dec 3, 2026',
        'No air date · 1',
        'The episode has no known air date',
        'Season data not cached · 1',
        'Dark · after S1 E8',
        'Tap Recompute to fetch the season',
        'Not added to quick add · 1',
        'Aired episode missing from quick add: try Recompute',
      ]) {
        expect(find.text(text, skipOffstage: false), findsOneWidget);
      }
    });

    testWidgets('should translate the reasons in French', (tester) async {
      repository.omissions = everyReason();
      await pumpPage(tester, debug: true, locale: const Locale('fr'));

      for (final text in [
        'Debug — épisodes manquants',
        'Prochains épisodes attendus mais non affichés ci-dessus.',
        'Recalculer',
        'Retirée de l\'ajout rapide · 1',
        'Retirée manuellement',
        'Prochain épisode pas encore diffusé · 1',
        'Severance · S2 É4',
        'Diffusion le 3 déc. 2026',
        'Sans date de diffusion · 1',
        'Données de saison absentes du cache · 1',
        'Dark · après S1 É8',
        'Non ajouté à l\'ajout rapide · 1',
      ]) {
        expect(find.text(text, skipOffstage: false), findsOneWidget);
      }
    });

    testWidgets('should run the diagnostic again with "Recompute"', (
      tester,
    ) async {
      await pumpPage(tester, debug: true);
      expect(find.text('Nothing omitted.'), findsOneWidget);

      repository.omissions = everyReason().sublist(0, 1);
      await tester.tap(find.text('Recompute'));
      await tester.pumpAndSettle();

      expect(repository.omissionCalls, [false, true]);
      expect(find.text('Chernobyl · S1 E5'), findsOneWidget);
      expect(find.text('Nothing omitted.'), findsNothing);
    });
  });

  group('InProgressPage rendering', () {
    void addLong() {
      repository.addSeries(
        _Series(
          1,
          'The Incredibly Long Title Of A Series That Never Seems To End, '
          'Season After Season',
        ),
      );
      repository.addSeries(_Series(2, 'Andor', daysAgo: 45));
      repository.optOuts.add(
        QuickAddOptOut(
          tmdbId: 9,
          seasonNumber: 12,
          episodeNumber: 24,
          optedOutAt: _now,
          title:
              'Another Extremely Long Title For A Series Removed From '
              'Quick Add A Long Time Ago',
        ),
      );
      repository.omissions = [
        QuickAddOmission(
          tmdbId: 5,
          title: 'A Very Long Title For A Debug Entry That Wraps On Lines',
          seasonNumber: 3,
          episodeNumber: 1,
          reason: QuickAddOmissionReason.notPopulated,
        ),
      ];
    }

    for (final palette in testPalettes) {
      testWidgets('should render every block on ${palette.id.name}', (
        tester,
      ) async {
        addLong();
        await pumpPage(tester, palette: palette, debug: true);

        expect(find.byType(InProgressRow), findsNWidgets(2));
        expect(find.byKey(const Key('in_progress_opt_outs')), findsOneWidget);
        expect(find.byType(DebugOmissionsSection), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'should not overflow at text scale 2 on 320 dp on ${palette.id.name}',
        (tester) async {
          addLong();
          await pumpPage(
            tester,
            palette: palette,
            debug: true,
            textScale: 2,
            size: const Size(320, 640),
            locale: const Locale('fr'),
          );

          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(ListView), const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('should keep every tap target at 48 dp and labeled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      addLong();
      await pumpPage(tester, debug: true);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      for (final tooltip in [
        'Mark S1 E4 of Andor as seen',
        'More actions for Andor',
      ]) {
        final size = tester.getSize(find.byTooltip(tooltip));
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      }
      expect(find.bySemanticsLabel(RegExp('^Restore Another')), findsOneWidget);
      handle.dispose();
    });
  });
}
