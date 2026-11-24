// Journey #464: Discover, detail page, "To watch" visible everywhere.
//
// Regressions covered: #396 (optimistic list icon), #390 (list changes reach
// the Library and Home through LibraryProvider), #456 (Discover pages append
// past page 1), #445 (unreleased titles stay out of "To watch tonight").
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/library/presentation/pages/list_page.dart';
import 'package:mediavore/features/library/presentation/widgets/list_media_grid_item.dart';
import 'package:mediavore/features/library/presentation/widgets/list_media_tile.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_actions.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_icon_button.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/active_filter_chips.dart';
import 'package:mediavore/features/search/presentation/widgets/search_filter_sheet.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_tmdb.dart';
import '../../helpers/fixture_reader.dart';
import '../harness.dart';

/// Movie of `test/fixtures/tmdb/media_page.json` (page 1), released in 2021.
const int releasedId = 101;

/// Movie answered by [_unreleasedTmdb], out in 30 days.
const int unreleasedId = 901;

/// Grid cell of the title [id] of [type] in Discover.
Finder _discoverCell(int id, {MediaType type = MediaType.movie}) =>
    find.byWidgetPredicate(
      (w) =>
          w is WatchlistIconButton &&
          w.item.id == id &&
          w.item.mediaType == type,
    );

/// Scrolls Discover until the cell of [id] is built and visible.
Future<void> _revealCell(
  WidgetTester tester,
  int id, {
  MediaType type = MediaType.movie,
}) async {
  await tester.scrollUntilVisible(
    _discoverCell(id, type: type),
    200,
    scrollable: find
        .descendant(
          of: find.byType(DiscoveryPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await pumpUntilSettled(tester);
}

/// Poster of the Discover cell of [id] (opens the detail page).
Finder _discoverPoster(int id) => find.ancestor(
  of: _discoverCell(id),
  matching: find.byType(MediaPosterCard),
);

/// Watchlist icon of the Discover cell of [id].
Finder _discoverBookmark(int id, IconData icon) =>
    find.descendant(of: _discoverCell(id), matching: find.byIcon(icon));

/// Icon of the main part of the detail page's list button.
Finder _listButtonIcon(IconData icon) => find.descendant(
  of: find.byKey(ListSplitButton.mainKey),
  matching: find.byIcon(icon),
);

Finder _tonight(int id) => find.byKey(ValueKey('home_tonight_movie_$id'));

Finder _upcoming(int id) =>
    find.byKey(ValueKey('upcoming_row_movie_${id}_null_null'));

/// Row (or grid cell) of the movie [id] in the open list.
Finder _listEntry(int id) => find.descendant(
  of: find.byType(ListPage),
  matching: find.byWidgetPredicate(
    (w) =>
        (w is ListMediaTile || w is ListMediaGridItem) &&
        w.key == ValueKey('${id}_movie'),
  ),
);

SearchProvider _search(WidgetTester tester) =>
    tester.element(find.byType(DiscoveryPage)).read<SearchProvider>();

/// Results of Discover, as `id:type`.
List<String> _ids(WidgetTester tester) => [
  for (final item in _search(tester).items) '${item.id}:${item.mediaType.name}',
];

Future<void> _searchFor(WidgetTester tester, String query) async {
  await goToTab(tester, AppTab.discover);
  await tester.enterText(
    find.byKey(const Key('discovery_search_field')),
    query,
  );
  // pumpUntilSettled runs out the 500 ms debounce.
  await pumpUntilSettled(tester);
}

/// Pops the top page (detail or list) of the navigator holding [page].
Future<void> _close(WidgetTester tester, Finder page) async {
  Navigator.of(tester.element(page)).pop();
  await pumpUntilSettled(tester);
}

/// Opens the "To watch" list from the Library tab.
Future<void> _openWatchlist(WidgetTester tester) async {
  await goToTab(tester, AppTab.library);
  await tester.tap(find.byKey(const ValueKey('library_list_watchlist')));
  await pumpUntilSettled(tester);
  expect(find.byType(ListPage), findsOneWidget);
}

Future<List<String>> _persistedWatchlist(
  WidgetTester tester,
  TestApp app,
) async =>
    await tester.runAsync(() => app.repository.getListEntries('watchlist')) ??
    fail('reading the persisted watchlist did not complete');

/// Drags the Discover grid up, past the infinite-scroll threshold.
Future<void> _scrollDiscover(WidgetTester tester) async {
  await tester.drag(
    find.descendant(
      of: find.byType(DiscoveryPage),
      matching: find.byType(CustomScrollView),
    ),
    const Offset(0, -400),
  );
  await pumpUntilSettled(tester);
}

/// TMDB where [unreleasedId] comes out in 30 days.
FakeTmdb _unreleasedTmdb() {
  final release = DateTime.now()
      .add(const Duration(days: 30))
      .toIso8601String()
      .split('T')
      .first;
  final movie = jsonDecode(fixture('tmdb/movie.json')) as Map<String, dynamic>;
  return FakeTmdb()..respond('movie/$unreleasedId', {
    ...movie,
    'id': unreleasedId,
    'title': 'Upcoming Movie',
    'original_title': 'Upcoming Movie',
    'release_date': release,
    'status': 'Post Production',
  });
}

void main() {
  group('Discover and add journey', () {
    testApp('should show a released title in Discover, the Library and '
        '"To watch tonight", then drop it, when added then removed from its '
        'detail page', (tester, app) async {
      await _searchFor(tester, 'dune');
      expect(
        app.tmdb.requests.where(
          (uri) =>
              uri.path.endsWith('/search/movie') &&
              uri.queryParameters['query'] == 'dune',
        ),
        isNotEmpty,
      );
      await _revealCell(tester, releasedId);
      expect(_discoverBookmark(releasedId, Icons.bookmark_border), findsOne);

      // Detail page from the poster.
      await tester.tap(_discoverPoster(releasedId));
      await pumpUntilSettled(tester);
      expect(find.byType(MediaDetailPage), findsOneWidget);
      expect(_listButtonIcon(Icons.add), findsOneWidget);

      // #396: one frame, no real I/O: the icon already shows the title in
      // the list, before the database write completes.
      await tester.tap(find.byKey(ListSplitButton.mainKey));
      await tester.pump();
      expect(_listButtonIcon(Icons.check), findsOneWidget);
      await pumpUntilSettled(tester);
      expect(
        await _persistedWatchlist(tester, app),
        contains('$releasedId:movie'),
      );

      // Visible everywhere without a restart: Discover, Library, Home.
      await _close(tester, find.byType(MediaDetailPage));
      expect(_discoverBookmark(releasedId, Icons.bookmark), findsOne);

      await _openWatchlist(tester);
      expect(_listEntry(releasedId), findsOneWidget);
      await _close(tester, find.byType(ListPage));

      await goToTab(tester, AppTab.home);
      expect(_tonight(releasedId), findsOneWidget);
      // Released: no release to wait for (#445).
      expect(_upcoming(releasedId), findsNothing);

      // Removed from its detail page: gone from Home, Library and the
      // Discover bookmark.
      await openDetail(tester, releasedId);
      expect(_listButtonIcon(Icons.check), findsOneWidget);
      await tester.tap(find.byKey(ListSplitButton.mainKey));
      await pumpUntilSettled(tester);
      expect(_listButtonIcon(Icons.add), findsOneWidget);
      await _close(tester, find.byType(MediaDetailPage));

      expect(_tonight(releasedId), findsNothing);
      await _openWatchlist(tester);
      expect(_listEntry(releasedId), findsNothing);
      await _close(tester, find.byType(ListPage));
      await goToTab(tester, AppTab.discover);
      await _revealCell(tester, releasedId);
      expect(_discoverBookmark(releasedId, Icons.bookmark_border), findsOne);
      expect(
        await _persistedWatchlist(tester, app),
        isNot(contains('$releasedId:movie')),
      );
    });

    testApp('should list an unreleased title under "Upcoming", never under '
        '"To watch tonight", when added from its detail page', (
      tester,
      app,
    ) async {
      // Opened directly (as a poster tap does), not through a search:
      // the Discover search path is the previous test's.
      await openDetail(tester, unreleasedId);
      expect(_listButtonIcon(Icons.add), findsOneWidget);

      // #396: one frame, no real I/O: the icon flips before the database
      // write and the release follow-up complete.
      await tester.tap(find.byKey(ListSplitButton.mainKey));
      await tester.pump();
      expect(_listButtonIcon(Icons.check), findsOneWidget);
      await pumpUntilSettled(tester);
      await _close(tester, find.byType(MediaDetailPage));

      await _openWatchlist(tester);
      expect(_listEntry(unreleasedId), findsOneWidget);
      await _close(tester, find.byType(ListPage));

      await goToTab(tester, AppTab.home);
      expect(_upcoming(unreleasedId), findsOneWidget);
      expect(_tonight(unreleasedId), findsNothing);
    }, tmdb: _unreleasedTmdb);

    testApp(
      'should append page 2 when scrolling Discover, with and without '
      'filters, and hide seen titles when asked',
      (tester, app) async {
        await goToTab(tester, AppTab.discover);
        final firstPage = _search(tester).items.map((i) => i.id).toList();
        expect(firstPage, isNotEmpty);
        expect(app.tmdb.countFor('trending'), 1);

        // #456: trending, page 2 appended after page 1.
        await _scrollDiscover(tester);
        expect(app.tmdb.countFor('trending'), 2);
        final trending = _search(tester).items.map((i) => i.id).toList();
        expect(trending.take(firstPage.length), firstPage);
        expect(trending.length, greaterThan(firstPage.length));

        // Filters: hide seen titles.
        await tester.tap(find.byKey(const Key('discovery_filters')));
        await pumpUntilSettled(tester);
        final hideSeen = find.descendant(
          of: find.byType(SearchFilterSheet),
          matching: find.byType(SwitchListTile),
        );
        await tester.scrollUntilVisible(
          hideSeen,
          200,
          scrollable: find
              .descendant(
                of: find.byType(SearchFilterSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(hideSeen);
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.byType(SearchFilterSheet),
            matching: find.byType(FilledButton),
          ),
        );
        await pumpUntilSettled(tester);

        expect(find.byType(ActiveFilterChips), findsOneWidget);
        expect(app.tmdb.countFor('discover/movie'), 1);
        expect(app.tmdb.countFor('discover/tv'), 1);
        // Movie 101 is seen; show 101 and movie 102 are not.
        expect(_ids(tester), isNot(contains('$releasedId:movie')));
        expect(_ids(tester), containsAll(['102:movie', '$releasedId:tv']));

        // #456: discover (filtered), page 2 appended, still without seen.
        final filtered = _search(tester).items.length;
        await _scrollDiscover(tester);
        expect(app.tmdb.countFor('discover/movie'), 2);
        expect(_ids(tester).length, greaterThan(filtered));
        expect(_ids(tester), isNot(contains('$releasedId:movie')));
      },
      seed: AppSeed(
        seen: [
          SeenItem(
            tmdbId: releasedId,
            type: MediaType.movie,
            title: 'Discover Movie 1',
            seenDate: DateTime(2024, 1, 2),
          ),
        ],
      ),
    );
  });
}
