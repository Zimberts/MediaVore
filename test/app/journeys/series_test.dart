// Journey #466: a series, episode by episode then season by season, through
// "In progress" and "Upcoming" on Home.
//
// Regressions covered: #395 (bulk marking reuses the loaded seasons), #431
// (markManyAsSeen awaits the refresh before reporting), a bulk mark leaving
// stale Quick Add entries (a fully seen series stayed "In progress"), and
// the achievement banner removed twice when MainPage is disposed.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/home/presentation/pages/in_progress_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_tmdb.dart';
import '../harness.dart';

/// Ended series, 3 seasons of 3 episodes, all aired.
const int endedId = 7001;

/// Running series, 2 seasons of 3 episodes; S2E3 airs in 3 days.
const int runningId = 7002;

/// Series already started (S1E1 seen yesterday), 1 season of 3 episodes.
const int startedId = 7003;

/// Air date of S2E3 of [runningId], `yyyy-MM-dd`.
final String _upcomingDate = DateTime.now()
    .add(const Duration(days: 3))
    .toIso8601String()
    .substring(0, 10);

FakeTmdb _tmdb() => FakeTmdb(
  shows: {
    endedId: const FakeShow(seasons: 3, episodesPerSeason: 3),
    runningId: FakeShow(
      seasons: 2,
      episodesPerSeason: 3,
      airDate: (season, episode) =>
          season == 2 && episode == 3 ? _upcomingDate : FakeTmdb.defaultAirDate,
    ),
    startedId: const FakeShow(seasons: 1, episodesPerSeason: 3),
  },
);

final AppSeed _seed = AppSeed(
  seen: [
    SeenItem(
      tmdbId: startedId,
      type: MediaType.tv,
      title: 'Show $startedId',
      seasonNumber: 1,
      episodeNumber: 1,
      seenDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ],
);

SearchProvider _search(WidgetTester tester) => tester
    .element(find.byType(MainPage, skipOffstage: false))
    .read<SearchProvider>();

/// The series [tmdbId] in "In progress", or null.
InProgressItem? _inProgress(WidgetTester tester, int tmdbId) => _search(
  tester,
).inProgressItems.where((item) => item.tmdbId == tmdbId).firstOrNull;

/// Number of distinct episodes of [tmdbId] seen.
int _seenEpisodes(WidgetTester tester, int tmdbId) => _search(tester).seenItems
    .where((s) => s.tmdbId == tmdbId && s.episodeNumber != null)
    .map((s) => (s.seasonNumber, s.episodeNumber))
    .toSet()
    .length;

/// Scrolls the detail page until [finder] is built, then centres it (the
/// pinned header covers the top of the page).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(MediaDetailPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
}

/// Expands season [season] of the open detail page.
Future<void> _expandSeason(WidgetTester tester, int season) async {
  final header = find.byKey(ValueKey('detail_season_$season'));
  await _reveal(tester, header);
  await tester.tap(header);
  await pumpUntilSettled(tester);
}

/// Taps the "seen" button of an episode in the open detail page.
Future<void> _tapEpisode(
  WidgetTester tester,
  int tmdbId,
  int season,
  int episode,
) async {
  final button = find.byKey(ValueKey('seen_ep_${tmdbId}_${season}_$episode'));
  await _reveal(tester, button);
  await tester.tap(button);
  await pumpUntilSettled(tester);
}

/// Answers "Mark all" to the "previous unseen episodes" dialog.
Future<void> _markPreviousToo(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(ElevatedButton),
    ),
  );
  await pumpUntilSettled(tester);
}

/// Runs [action], then pumps until the app reports the result with a
/// message, as the user sees it. Returns [snapshot] taken at that moment:
/// what the rest of the app shows when the action says it is done (#431).
Future<T> _untilReported<T>(
  WidgetTester tester,
  Future<void> Function() action,
  T Function() snapshot,
) async {
  final before = appMessageController.current;
  late T seen;
  var reported = false;
  void onMessage() {
    final current = appMessageController.current;
    if (reported || current == null || identical(current, before)) return;
    reported = true;
    seen = snapshot();
  }

  appMessageController.addListener(onMessage);
  try {
    await action();
    // Isar answers outside fake time: give it real time until the report.
    for (var i = 0; i < 400 && !reported; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  } finally {
    appMessageController.removeListener(onMessage);
  }
  if (!reported) fail('the action never reported its result');
  await pumpUntilSettled(tester);
  return seen;
}

Future<void> _closeDetail(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(MediaDetailPage))).pop();
  await pumpUntilSettled(tester);
}

void main() {
  group('series journey', () {
    testApp(
      'should follow a series from its first episode to its last, show the '
      'next release and keep a series taken out of In progress out',
      (tester, app) async {
        // 0. The seeded viewing already puts the started series in progress.
        expect(_inProgress(tester, startedId)?.next.episodeNumber, 2);
        expect(find.byKey(const ValueKey('home_resume_$startedId')), findsOne);

        // 1. One episode: the series enters In progress with S1E2 next.
        await openDetail(tester, endedId, type: MediaType.tv);
        await _expandSeason(tester, 1);
        var item = await _untilReported<InProgressItem?>(
          tester,
          () => _tapEpisode(tester, endedId, 1, 1),
          () => _inProgress(tester, endedId),
        );
        expect(_seenEpisodes(tester, endedId), 1);
        expect((item?.next.seasonNumber, item?.next.episodeNumber), (1, 2));
        expect(item!.seenEpisodes, 1);
        expect(item.totalEpisodes, 9);

        // 2a. The whole season 1 (S1E3, with the episode before it): S2E1.
        await _tapEpisode(tester, endedId, 1, 3);
        item = await _untilReported<InProgressItem?>(
          tester,
          () => _markPreviousToo(tester),
          () => _inProgress(tester, endedId),
        );
        expect(_seenEpisodes(tester, endedId), 3);
        expect((item?.next.seasonNumber, item?.next.episodeNumber), (2, 1));
        expect(item!.seenEpisodes, 3);

        // 2b. Seasons 2 and 3 at once (S3E3 with the 5 episodes before it),
        // with a bounded number of TMDB requests (#395). Ended and fully
        // seen, the series has left In progress when the app reports it
        // (#431).
        await _expandSeason(tester, 3);
        final before = app.tmdb.requestCount;
        await _tapEpisode(tester, endedId, 3, 3);
        final stillInProgress = await _untilReported(
          tester,
          () => _markPreviousToo(tester),
          () => _inProgress(tester, endedId) != null,
        );
        expect(
          app.tmdb.requests.skip(before),
          isEmpty,
          reason: 'the page loaded these seasons already (#395)',
        );
        expect(_seenEpisodes(tester, endedId), 9);
        expect(stillInProgress, isFalse);

        // 3. Back on Home: no trace of it in Resume.
        await _closeDetail(tester);
        expect(_inProgress(tester, endedId), isNull);
        expect(
          find.byKey(const ValueKey('home_resume_$endedId')),
          findsNothing,
        );

        // 4. The running series, followed, seen up to its last aired
        // episode: out of In progress, its next episode in Upcoming with
        // its poster.
        await openDetail(tester, runningId, type: MediaType.tv);
        await tester.tap(find.byKey(const Key('detail_notify')));
        await pumpUntilSettled(tester);
        await _expandSeason(tester, 2);
        await _tapEpisode(tester, runningId, 2, 2);
        await _untilReported(tester, () => _markPreviousToo(tester), () {});
        expect(_seenEpisodes(tester, runningId), 5);
        await _closeDetail(tester);
        expect(_inProgress(tester, runningId), isNull);
        final release = find.byKey(
          const ValueKey('upcoming_row_tv_${runningId}_2_3'),
        );
        await tester.scrollUntilVisible(release, 200);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('home_upcoming_thisWeek')),
            matching: release,
          ),
          findsOne,
        );
        expect(
          find.descendant(
            of: release,
            matching: find.byKey(const Key('upcoming_row_poster')),
          ),
          findsOne,
        );

        // 5. Taken out of In progress: listed apart, still out after a
        // relaunch.
        unawaited(InProgressPage.show(tester.element(find.byType(MainPage))));
        await pumpUntilSettled(tester);
        final row = find.byKey(const ValueKey('in_progress_row_$startedId'));
        expect(row, findsOne);
        await _untilReported(
          tester,
          () => tester.drag(row, const Offset(-600, 0)),
          () {},
        );
        expect(row, findsNothing);
        expect(find.byKey(const Key('in_progress_opt_outs')), findsOne);

        await restartTestApp(tester);
        expect(_inProgress(tester, startedId), isNull);
        expect(
          find.byKey(const ValueKey('home_resume_$startedId')),
          findsNothing,
        );
        expect(_search(tester).quickAddOptOuts.map((o) => o.tmdbId), [
          startedId,
        ]);
      },
      seed: _seed,
      tmdb: _tmdb,
    );
  });
}
