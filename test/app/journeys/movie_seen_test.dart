// Journey #465: mark a movie seen and follow it everywhere (detail button,
// watchlist, history, saga counter, Me figures, achievements), log a second
// dated viewing then delete it, and undo "Seen".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_saga.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_tmdb.dart';
import '../harness.dart';

/// Saga 55: FakeTmdb lists movies 550, 551 and 552 as its parts.
const int _sagaId = 55;

/// Movie of the journey, in the watchlist, part of saga [_sagaId].
const int _movieId = 551;

/// Other part of the saga, already seen.
const int _seenPartId = 550;

/// `runtime` of the movie fixture, in minutes.
const int _runtime = 110;

const Key _seenButton = ValueKey('seen_movie_$_movieId');
const Key _summary = Key('movie_seen_summary');
const Key _viewings = Key('movie_visionnages_section');

MediaItem _movie(int id) => MediaItem(
  id: id,
  title: 'Movie $id',
  overview: '',
  releaseDate: '2020-01-01',
  posterPath: '/p$id.jpg',
);

/// Movie [_movieId] in the watchlist, [_seenPartId] seen (runtime resolved
/// from TMDB when the seed is written).
AppSeed _seed({Map<String, Object> prefs = const {}, bool sagaSeen = true}) =>
    AppSeed(
      prefs: prefs,
      lists: {
        'watchlist': [_movie(_movieId)],
      },
      seen: [
        if (sagaSeen)
          SeenItem(
            tmdbId: _seenPartId,
            type: MediaType.movie,
            title: 'Movie $_seenPartId',
            seenDate: DateTime(2024, 5, 1, 20),
          ),
      ],
    );

FakeTmdb Function() _tmdb({Duration latency = Duration.zero}) =>
    () => FakeTmdb(
      latency: latency,
      collectionOf: (id) => id ~/ 10 == _sagaId ? _sagaId : null,
    );

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(MainPage, skipOffstage: false));

SearchProvider _search(WidgetTester tester) =>
    _context(tester).read<SearchProvider>();

AppLocalizations _l10n(WidgetTester tester) => _context(tester).l10n;

/// Viewings of [_movieId] persisted in the database, oldest first.
Future<List<SeenItem>> _persisted(WidgetTester tester, TestApp app) async {
  final viewings = await tester.runAsync(
    () => app.repository.getSeenStatus(_movieId, MediaType.movie),
  );
  return viewings!..sort((a, b) => a.seenDate.compareTo(b.seenDate));
}

/// Whether the main action of the detail page shows the "seen" check.
bool _buttonShowsSeen() => find
    .descendant(of: find.byKey(_seenButton), matching: find.byIcon(Icons.check))
    .evaluate()
    .isNotEmpty;

/// Text of the saga counter « n films vus sur m », scrolled into view.
Future<String> _sagaCounter(WidgetTester tester) async {
  final counter = find.byKey(MediaDetailSaga.sagaSeenCountKey);
  await tester.scrollUntilVisible(
    counter,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  return tester.widget<Text>(counter).data!;
}

Future<void> _scrollDetailToTop(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(_seenButton),
    -200,
    scrollable: find.byType(Scrollable).first,
  );
}

/// Texts of the Me figures: movie count, then series screen time subtitle.
void _expectMeFigures(WidgetTester tester, {required int movies}) {
  final l10n = _l10n(tester);
  expect(
    find.descendant(
      of: find.byKey(const Key('profile_metric_movies')),
      matching: find.text('$movies'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key('profile_metric_series')),
      matching: find.text(l10n.profileScreenTime(movies * _runtime ~/ 60)),
    ),
    findsOneWidget,
  );
}

/// Whether the watchlist page of the Library lists [_movieId].
Future<bool> _watchlistShowsMovie(WidgetTester tester) async {
  await goToTab(tester, AppTab.library);
  _search(tester).setLibrarySection(LibrarySection.lists);
  await pumpUntilSettled(tester);
  await tester.tap(find.byKey(const ValueKey('library_list_watchlist')));
  await pumpUntilSettled(tester);
  final shown = find
      .byKey(const ValueKey('${_movieId}_movie'))
      .evaluate()
      .isNotEmpty;
  await _back(tester);
  return shown;
}

/// Opens the History section of the Library.
Future<void> _openHistory(WidgetTester tester) async {
  await goToTab(tester, AppTab.library);
  await tester.tap(find.text(_l10n(tester).navHistory));
  await pumpUntilSettled(tester);
}

Finder _historyMenu(int seenId) => find.byKey(Key('history_item_menu_$seenId'));

/// Pumps until [condition] holds, giving real time to Isar at each step:
/// what follows a write (provider reload, achievements watcher, messages)
/// lands on real time, possibly after the app looks idle. Bounded by 15 s of
/// fake time, enough for two queued 4 s achievement banners.
Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 300 && !condition(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Gives [steps] slices of real time to pending Isar work, pumping between
/// them, when nothing on screen tells that it is over.
Future<void> _drainIo(WidgetTester tester, {int steps = 20}) async {
  for (var i = 0; i < steps; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

/// Leaves the current page, as the system back button does.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await pumpUntilSettled(tester);
}

bool _unlocked(WidgetTester tester, String id) => _context(tester)
    .read<AchievementProvider>()
    .achievements
    .any((a) => a.id == id && a.isUnlocked);

void main() => registerMovieSeenJourney();

/// Registers the #465 movie seen journey.
void registerMovieSeenJourney() {
  group('movie seen journey', () {
    testApp(
      'should flip the button at once, then show the viewing in the '
      'watchlist, the history, the saga and Me',
      (tester, app) async {
        final search = _search(tester);
        expect(search.watchlistIds, contains('$_movieId'));
        await goToTab(tester, AppTab.me);
        _expectMeFigures(tester, movies: 1);

        await openDetail(tester, _movieId);
        final l10n = _l10n(tester);
        expect(await _sagaCounter(tester), l10n.sagaSeenCount(1, 3));
        await _scrollDetailToTop(tester);
        expect(_buttonShowsSeen(), isFalse);
        expect(find.byKey(_summary), findsNothing);

        // 1. The button flips on the next frame, before any I/O or TMDB
        //    answer (#355): no fake time has passed.
        final requestsBefore = app.tmdb.requestCount;
        await tester.tap(find.byKey(_seenButton));
        await tester.pump();
        expect(_buttonShowsSeen(), isTrue);
        expect(search.getSeenCount(_movie(_movieId)), 1);

        await pumpUntilSettled(tester);
        expect(_buttonShowsSeen(), isTrue);
        expect(find.byKey(_summary), findsOneWidget);
        expect(app.tmdb.requestCount, greaterThanOrEqualTo(requestsBefore));
        final persisted = await _persisted(tester, app);
        expect(persisted, hasLength(1));
        expect(persisted.single.runtime, _runtime);

        // 5. The saga counter counts the global history (#459).
        expect(await _sagaCounter(tester), l10n.sagaSeenCount(2, 3));
        await _back(tester);

        // 2. Out of the watchlist, into the history, newest first.
        expect(search.watchlistIds, isNot(contains('$_movieId')));
        expect(await _watchlistShowsMovie(tester), isFalse);

        await _openHistory(tester);
        final seenId = persisted.single.id!;
        final seenPart = (await tester.runAsync(
          () => app.repository.getSeenStatus(_seenPartId, MediaType.movie),
        ))!.single;
        expect(_historyMenu(seenId), findsOneWidget);
        expect(
          tester.getTopLeft(_historyMenu(seenId)).dy,
          lessThan(tester.getTopLeft(_historyMenu(seenPart.id!)).dy),
          reason: 'history sorted by date, newest first',
        );
        // The row menu opens the detail page again.
        await tester.tap(_historyMenu(seenId));
        await pumpUntilSettled(tester);
        await tester.tap(find.text(l10n.historyActionOpenDetail));
        await pumpUntilSettled(tester);
        expect(_buttonShowsSeen(), isTrue);
        await _back(tester);

        // 4. Me: movie count and screen time.
        await goToTab(tester, AppTab.me);
        _expectMeFigures(tester, movies: 2);
      },
      seed: _seed(),
      tmdb: _tmdb(latency: const Duration(milliseconds: 800)),
    );

    testApp(
      'should restore every screen when "Seen" is undone',
      (tester, app) async {
        final search = _search(tester);
        await openDetail(tester, _movieId);
        final l10n = _l10n(tester);
        await tester.tap(find.byKey(_seenButton));
        // The message comes once the viewing is stored (real I/O) and stays
        // up 6 s of fake time: wait on real time, not on a settled app.
        final undo = find.text(l10n.commonUndo);
        await _pumpUntil(tester, () => undo.evaluate().isNotEmpty);
        expect(_buttonShowsSeen(), isTrue);
        expect(search.watchlistIds, isNot(contains('$_movieId')));

        // 6. Undo from the confirmation message.
        await tester.tap(undo);
        await _pumpUntil(tester, () => !_buttonShowsSeen());
        await pumpUntilSettled(tester);

        expect(_buttonShowsSeen(), isFalse);
        expect(find.byKey(_summary), findsNothing);
        expect(await _persisted(tester, app), isEmpty);
        expect(await _sagaCounter(tester), l10n.sagaSeenCount(1, 3));
        await _back(tester);

        expect(search.watchlistIds, contains('$_movieId'));
        expect(await _watchlistShowsMovie(tester), isTrue);
        await goToTab(tester, AppTab.me);
        _expectMeFigures(tester, movies: 1);
      },
      seed: _seed(),
      tmdb: _tmdb(),
    );

    // 3. Advanced tracking: dated viewings typed in the language's format
    //    (#389), listed in the "Viewings" section, deletable.
    for (final (language, typed, shown) in [
      ('fr', '04/03/2025', '4 mars 2025'),
      ('en', '03/04/2025', 'Mar 4, 2025'),
    ]) {
      testApp(
        'should log a viewing typed as $typed in "$language", add a second '
        'one and delete it',
        (tester, app) async {
          expect(_unlocked(tester, 'movie_1'), isFalse);
          await openDetail(tester, _movieId);

          // First viewing, typed date.
          await tester.tap(find.byKey(_seenButton));
          await pumpUntilSettled(tester);
          await tester.tap(find.byIcon(Icons.keyboard));
          await pumpUntilSettled(tester);
          await tester.enterText(find.byType(TextField), typed);
          await tester.tap(find.byType(ElevatedButton));

          // 4. First movie: first tier of the movie achievements, announced
          //    by a banner that stays up 4 s of fake time. The unlock follows
          //    the stored history (real I/O): wait on real time, not on a
          //    settled app.
          final banner = find.byKey(
            const ValueKey('achievement_banner_movie_1'),
          );
          await _pumpUntil(tester, () => banner.evaluate().isNotEmpty);
          expect(banner, findsOneWidget);
          expect(_unlocked(tester, 'movie_1'), isTrue);
          expect(_unlocked(tester, 'rewatch_movie_2'), isFalse);
          await pumpUntilSettled(tester);

          var persisted = await _persisted(tester, app);
          expect(persisted, hasLength(1));
          final date = persisted.single.seenDate;
          expect((date.year, date.month, date.day), (2025, 3, 4));
          final section = find.byKey(_viewings);
          expect(section, findsOneWidget);
          expect(
            find.descendant(of: section, matching: find.byType(ListTile)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: section, matching: find.textContaining(shown)),
            findsOneWidget,
          );

          // Second viewing, today (calendar default).
          await tester.tap(find.byKey(_seenButton));
          await pumpUntilSettled(tester);
          await tester.tap(find.byType(ElevatedButton));
          await pumpUntilSettled(tester);

          persisted = await _persisted(tester, app);
          expect(persisted, hasLength(2));
          expect(
            find.descendant(of: section, matching: find.byType(ListTile)),
            findsNWidgets(2),
          );
          await _pumpUntil(tester, () => _unlocked(tester, 'rewatch_movie_2'));
          expect(_unlocked(tester, 'rewatch_movie_2'), isTrue);

          // Delete the second viewing (listed last), with confirmation.
          final deletes = find.descendant(
            of: section,
            matching: find.byIcon(Icons.delete_outline),
          );
          await tester.ensureVisible(deletes.last);
          await tester.tap(deletes.last);
          await pumpUntilSettled(tester);
          await tester.tap(
            find.widgetWithText(TextButton, _l10n(tester).commonDelete).last,
          );
          await pumpUntilSettled(tester);
          // The page is lazy: bring its top back to build the section.
          await _scrollDetailToTop(tester);

          final tiles = find.descendant(
            of: section,
            matching: find.byType(ListTile),
          );
          await _pumpUntil(tester, () => tiles.evaluate().length == 1);
          expect(tiles, findsOneWidget);
          final left = await _persisted(tester, app);
          expect(left.map((s) => s.id), [persisted.first.id]);
          // deleteSeenEntry goes on reloading (alerts, size, Quick Add) after
          // the section is updated: let it end before the app is torn down.
          await _drainIo(tester);
        },
        seed: _seed(
          sagaSeen: false,
          prefs: {
            SettingsProvider.advancedTrackingKey: true,
            LocaleService.overrideKey: language,
          },
        ),
        tmdb: _tmdb(),
      );
    }
  });
}
