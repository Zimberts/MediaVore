// Journey #471: offline and TMDB errors.
//
// Every TMDB failure goes through the real interceptors (rate limit, retry
// with backoff, #292) and the real error mapping; the app must keep what it
// has locally, say what went wrong and offer a way out, without unhandled
// exceptions or request loops.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/offline_banner.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_tmdb.dart';
import '../harness.dart';

/// Movie in the seeded "To watch" list.
const int listedId = 550;

/// Movie in the seeded history.
const int seenId = 551;

/// Movie never opened: not in the details cache.
const int uncachedId = 777;

/// Series whose new episodes are followed (Home "Upcoming").
const int followedShowId = 4242;

MediaItem _movie(int id) => MediaItem(
  id: id,
  title: 'Movie $id',
  overview: '',
  releaseDate: '2021-01-01',
  posterPath: '/p$id.jpg',
);

final AppSeed _library = AppSeed(
  lists: {
    'watchlist': [_movie(listedId)],
  },
  seen: [
    SeenItem(
      tmdbId: seenId,
      type: MediaType.movie,
      title: 'Movie $seenId',
      seenDate: DateTime(2026, 11, 2),
      runtime: 100,
    ),
  ],
);

FakeTmdb _offlineTmdb() => FakeTmdb()..fail(FakeTmdbFailure.offline);

SearchProvider _search(WidgetTester tester) =>
    tester.element(find.byType(MainPage, skipOffstage: false)).read();

/// Runs [pumpUntilSettled] until TMDB traffic stops, retries included: the
/// retry backoff (#292) sleeps without frames nor request in flight, which
/// [pumpUntilSettled] alone takes for idle.
Future<void> _settleRetries(WidgetTester tester, TestApp app) async {
  var before = -1;
  for (var round = 0; before != app.tmdb.requestCount; round++) {
    if (round == 20) fail('TMDB requests never stop: ${app.tmdb.requests}');
    before = app.tmdb.requestCount;
    await pumpUntilSettled(tester);
    // Longer than the retry cap (RetryInterceptor.maxDelay).
    await tester.pump(const Duration(seconds: 11));
    await pumpUntilSettled(tester);
  }
}

final Finder _discoverScrollable = find
    .descendant(
      of: find.byType(DiscoveryPage),
      matching: find.byType(Scrollable),
    )
    .first;

/// Pops the detail page.
Future<void> _closeDetail(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(MediaDetailPage))).pop();
  await pumpUntilSettled(tester);
}

void main() {
  group('offline and TMDB errors journey', () {
    testApp(
      'should show the local library when TMDB is unreachable at launch',
      (tester, app) async {
        await _settleRetries(tester, app);
        expect(tester.takeException(), isNull);

        // Home: the offline banner, the local data still there.
        expect(find.byType(OfflineBanner), findsOneWidget);
        expect(
          find.byKey(const ValueKey('home_tonight_movie_$listedId')),
          findsOneWidget,
        );

        // Library: the seeded list.
        await goToTab(tester, AppTab.library);
        await _settleRetries(tester, app);
        expect(
          find.byKey(const ValueKey('library_list_watchlist')),
          findsOneWidget,
        );

        // A listed title opens in offline mode, with a way to retry.
        await openDetail(tester, listedId);
        await _settleRetries(tester, app);
        expect(find.byType(OfflineBanner), findsWidgets);
        expect(find.byKey(const Key('detail_retry')), findsOneWidget);
        await _closeDetail(tester);
        expect(tester.takeException(), isNull);
      },
      seed: _library,
      tmdb: _offlineTmdb,
    );

    testApp('should open a cached detail page in full when offline', (
      tester,
      app,
    ) async {
      await openDetail(tester, listedId);
      await _closeDetail(tester);

      // Offline: the cached details come back without a request.
      app.tmdb.fail(FakeTmdbFailure.offline);
      final fetched = app.tmdb.countFor('movie/$listedId');
      await openDetail(tester, listedId);
      await _settleRetries(tester, app);
      expect(app.tmdb.countFor('movie/$listedId'), fetched);
      expect(find.byType(OfflineBanner), findsNothing);
      expect(find.byKey(const Key('detail_retry')), findsNothing);
      expect(find.text('Movie $listedId'), findsWidgets);
      await _closeDetail(tester);
      expect(tester.takeException(), isNull);
    }, seed: _library);

    testApp(
      'should retry Discover then its next page once the network is back',
      (tester, app) async {
        await goToTab(tester, AppTab.discover);
        await _settleRetries(tester, app);
        expect(_search(tester).errorType, SearchErrorType.offline);
        expect(find.byKey(const Key('discovery_retry')), findsOneWidget);

        // Back online: one tap reloads the first page.
        app.tmdb.recover();
        await tester.tap(find.byKey(const Key('discovery_retry')));
        await _settleRetries(tester, app);
        expect(_search(tester).errorType, isNull);
        final firstPage = _search(tester).items.length;
        expect(firstPage, greaterThan(0));

        // The next page fails: a retry cell, no automatic reload loop.
        app.tmdb.fail(FakeTmdbFailure.offline);
        await tester.fling(_discoverScrollable, const Offset(0, -5000), 3000);
        await _settleRetries(tester, app);
        expect(_search(tester).errorType, SearchErrorType.offline);
        final failed = app.tmdb.requestCount;
        await _settleRetries(tester, app);
        expect(app.tmdb.requestCount, failed);

        app.tmdb.recover();
        final footer = find.byKey(const Key('discovery_retry_next_page'));
        await tester.scrollUntilVisible(
          footer,
          400,
          scrollable: _discoverScrollable,
        );
        await tester.tap(footer);
        await _settleRetries(tester, app);
        expect(_search(tester).errorType, isNull);
        expect(_search(tester).items.length, greaterThan(firstPage));
        expect(tester.takeException(), isNull);
      },
      tmdb: _offlineTmdb,
    );

    testApp('should get through a few 429 and stop after the retry budget', (
      tester,
      app,
    ) async {
      // Two 429 then success: the detail loads.
      app.tmdb.fail(
        FakeTmdbFailure.rateLimited,
        pathPrefix: 'movie/$uncachedId',
        times: 2,
      );
      await openDetail(tester, uncachedId);
      await _settleRetries(tester, app);
      expect(app.tmdb.countFor('movie/$uncachedId'), 3);
      expect(find.byKey(const Key('detail_retry')), findsNothing);
      await _closeDetail(tester);

      // 429 for good: 1 request + 3 retries, then an error, no loop.
      app.tmdb.fail(FakeTmdbFailure.rateLimited, pathPrefix: 'movie/888');
      await openDetail(tester, 888);
      await _settleRetries(tester, app);
      expect(app.tmdb.countFor('movie/888'), 4);
      expect(find.byKey(const Key('detail_retry')), findsOneWidget);
      await _closeDetail(tester);
      expect(tester.takeException(), isNull);
    });

    testApp('should say the key is rejected when TMDB revokes it', (
      tester,
      app,
    ) async {
      await goToTab(tester, AppTab.discover);
      app.tmdb.fail(FakeTmdbFailure.unauthorized);
      final before = app.tmdb.requestCount;
      await tester.enterText(
        find.byKey(const Key('discovery_search_field')),
        'alien',
      );
      await _settleRetries(tester, app);
      expect(_search(tester).errorType, SearchErrorType.invalidApiKey);
      expect(find.byKey(const Key('discovery_connect_tmdb')), findsOneWidget);
      // 401 is not retried: one request per search call, then silence.
      final after = app.tmdb.requestCount;
      expect(after - before, lessThanOrEqualTo(4));
      await _settleRetries(tester, app);
      expect(app.tmdb.requestCount, after);

      // A detail page says so too.
      await openDetail(tester, uncachedId);
      await _settleRetries(tester, app);
      expect(app.tmdb.countFor('movie/$uncachedId'), 1);
      expect(find.byKey(const Key('detail_retry')), findsOneWidget);
      await _closeDetail(tester);
      expect(tester.takeException(), isNull);
    });

    testApp('should offer a retry on a detail page that timed out', (
      tester,
      app,
    ) async {
      app.tmdb.fail(FakeTmdbFailure.timeout, pathPrefix: 'movie/$uncachedId');
      await openDetail(tester, uncachedId);
      await _settleRetries(tester, app);
      expect(app.tmdb.countFor('movie/$uncachedId'), 4);
      expect(find.byKey(const Key('detail_retry')), findsOneWidget);

      app.tmdb.recover();
      await tester.tap(find.byKey(const Key('detail_retry')));
      await _settleRetries(tester, app);
      expect(find.byKey(const Key('detail_retry')), findsNothing);
      expect(find.byType(OfflineBanner), findsNothing);
      await _closeDetail(tester);
      expect(tester.takeException(), isNull);
    });

    testApp('should keep Home as it was when a refresh fails offline', (
      tester,
      app,
    ) async {
      final tonight = find.byKey(
        const ValueKey('home_tonight_movie_$listedId'),
      );
      expect(tonight, findsOneWidget);
      // A followed release: the refresh asks TMDB about it.
      // As the bell of its detail page does.
      unawaited(
        _search(tester).toggleNotification(
          const MediaItem(
            id: followedShowId,
            title: 'Show $followedShowId',
            overview: '',
            releaseDate: '2020-01-01',
            mediaType: MediaType.tv,
          ),
        ),
      );
      await _settleRetries(tester, app);
      expect(await tester.runAsync(() => app.repository.getNotifiedItems()), [
        isA<Object>(),
      ]);

      app.tmdb.fail(FakeTmdbFailure.offline);
      final before = app.tmdb.countFor('tv/$followedShowId');
      AppMessage? reported;
      void listener() => reported ??= appMessageController.current;
      appMessageController.addListener(listener);
      addTearDown(() => appMessageController.removeListener(listener));
      await tester.tap(find.byKey(const Key('home_refresh')));
      await _settleRetries(tester, app);

      expect(app.tmdb.countFor('tv/$followedShowId'), greaterThan(before));
      expect(
        reported?.text,
        'You\'re offline. Check your connection and try again.',
      );
      expect(tonight, findsOneWidget);
      expect(tester.takeException(), isNull);
    }, seed: _library);
  });
}
