// Journey #468: personal lists (create, add, sort, compare, share, delete).
//
// Regressions covered: the share QR code named a missing logo asset, and
// importing a shared list overwrote the cached title and poster of the
// titles already known with a placeholder.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/library/presentation/pages/list_page.dart';
import 'package:mediavore/features/library/presentation/widgets/list_media_tile.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_actions.dart';
import 'package:mediavore/features/search/presentation/pages/list_intersection_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../helpers/fake_tmdb.dart';
import '../harness.dart';

/// Name of the list the journey creates.
const String listName = 'Weekend';

/// Entries of the journey, as stored (`id:type`).
const String movieA = '101:movie';
const String movieB = '102:movie';
const String movieC = '103:movie';
const String showS = '201:tv';

/// Release dates that make the release date order differ from the order
/// of addition (A, B, S): B (1999), S (2020, fixture), A (2021).
FakeTmdb _datedTmdb() => FakeTmdb(
  releaseDateOf: (id) => switch (id) {
    101 => '2021-05-01',
    102 => '1999-03-31',
    _ => null,
  },
);

/// Movie [id] as TMDB names it (`FakeTmdb`), so that the cache holds real
/// metadata.
MediaItem _movie(int id) => MediaItem(
  id: id,
  title: 'Movie $id',
  overview: '',
  releaseDate: '2020-01-01',
  posterPath: '/p$id.jpg',
);

const MediaItem _show = MediaItem(
  id: 201,
  title: 'Show 201',
  overview: '',
  releaseDate: '2020-01-01',
  mediaType: MediaType.tv,
  posterPath: '/p201.jpg',
);

/// The front dialog (app dialog, menu or Material alert).
Finder get _dialog => find.byType(Dialog).last;

/// Types [text] in the single field of the front dialog.
Future<void> _typeInDialog(WidgetTester tester, String text) async {
  await tester.enterText(
    find.descendant(of: _dialog, matching: find.byType(TextField)),
    text,
  );
  await tester.pump();
}

/// Taps the last (confirming) action of the front dialog.
Future<void> _confirmDialog(WidgetTester tester) async {
  final actions = find.descendant(
    of: _dialog,
    matching: find.byWidgetPredicate(
      (w) => w is TextButton || w is FilledButton,
    ),
  );
  await tester.tap(actions.last);
  await pumpUntilSettled(tester);
}

/// Runs [read] (real Isar I/O) outside fake time.
Future<T> _real<T>(WidgetTester tester, Future<T> Function() read) async {
  final value = await tester.runAsync(read);
  if (value is! T) fail('real I/O did not complete');
  return value;
}

/// Stored entries of the list [name].
Future<List<String>> _entries(WidgetTester tester, TestApp app, String name) =>
    _real(tester, () => app.repository.getListEntries(name));

/// Pumps until [done] holds: imports chain Isar writes without frames, so
/// [pumpUntilSettled] can return before they end.
Future<void> _until(
  WidgetTester tester,
  Future<bool> Function() done, {
  required String reason,
}) async {
  for (var i = 0; i < 200; i++) {
    if (await tester.runAsync(done) ?? false) return;
    await pumpUntilSettled(tester, quietSteps: 2);
  }
  fail('timed out waiting until $reason');
}

/// Title and poster of each "To watch" row of the Library.
Future<List<(String, String?)>> _watchlistPreviews(
  WidgetTester tester,
  TestApp app,
) async => [
  for (final p in await _real(
    tester,
    () => app.repository.getListPreviews('watchlist'),
  ))
    (p.title, p.posterPath),
];

/// Expects the stored entries of [name] to match [matcher] once the writes
/// of the last action have landed.
Future<void> _expectStored(
  WidgetTester tester,
  TestApp app,
  String name,
  Object matcher,
) async {
  final wrapped = wrapMatcher(matcher);
  await _until(
    tester,
    () async => wrapped.matches(await app.repository.getListEntries(name), {}),
    reason: 'list $name matches $matcher',
  );
  expect(await _entries(tester, app, name), matcher);
}

/// Expects the open list page to show [expected] once it has rebuilt.
Future<void> _expectShown(WidgetTester tester, List<String> expected) async {
  await _until(
    tester,
    () async => listEquals(_shown(tester), expected),
    reason: 'the list page shows $expected',
  );
  expect(_shown(tester), expected);
}

Finder _row(String name) => find.byKey(ValueKey('library_list_$name'));

/// Pops the top page of the navigator holding [page].
Future<void> _close(WidgetTester tester, Finder page) async {
  Navigator.of(tester.element(page)).pop();
  await pumpUntilSettled(tester);
}

Future<void> _openList(WidgetTester tester, String name) async {
  await goToTab(tester, AppTab.library);
  await tester.tap(_row(name));
  await pumpUntilSettled(tester);
  expect(find.byType(ListPage), findsOneWidget);
}

/// Entries shown by the open list page, top to bottom.
List<String> _shown(WidgetTester tester) => [
  for (final tile in tester.widgetList<ListMediaTile>(
    find.descendant(
      of: find.byType(ListPage),
      matching: find.byType(ListMediaTile),
    ),
  ))
    '${tile.item.id}:${tile.item.mediaType.name}',
];

Finder _tile(String entry) => find.descendant(
  of: find.byType(ListPage),
  matching: find.byKey(ValueKey(entry.replaceFirst(':', '_'))),
);

/// Opens the sort sheet of the list page.
Future<void> _openSortSheet(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.swap_vert),
    ),
  );
  await pumpUntilSettled(tester);
}

/// Adds the title of the open detail page to [list] through the list menu.
Future<void> _addFromDetail(WidgetTester tester, String list) async {
  final menu = find.byKey(ListSplitButton.menuKey);
  await tester.ensureVisible(menu);
  await pumpUntilSettled(tester);
  await tester.tap(menu);
  await pumpUntilSettled(tester);
  await tester.tap(find.descendant(of: _dialog, matching: find.text(list)));
  await pumpUntilSettled(tester);
}

/// Runs an action of the "more" menu of the list page, by its icon.
Future<void> _moreAction(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byKey(const Key('lists_more_actions')));
  await pumpUntilSettled(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(PopupMenuItem<String>),
      matching: find.byIcon(icon),
    ),
  );
  await pumpUntilSettled(tester);
}

SearchProvider _search(WidgetTester tester) => tester
    .element(find.byType(MainPage, skipOffstage: false))
    .read<SearchProvider>();

void main() {
  group('personal lists journey', () {
    testApp(
      'should keep the order of addition, the split, the sort and a manual '
      'reorder when a list is filled from detail pages',
      (tester, app) async {
        // 1. Create the list from the Library.
        await goToTab(tester, AppTab.library);
        await tester.tap(find.byKey(const Key('library_new_list')));
        await pumpUntilSettled(tester);
        await _typeInDialog(tester, listName);
        await _confirmDialog(tester);
        expect(_row(listName), findsOneWidget);
        await _expectStored(tester, app, listName, isEmpty);

        // 2. Add two movies and a show from their detail pages.
        for (final (id, type) in [
          (101, MediaType.movie),
          (102, MediaType.movie),
          (201, MediaType.tv),
        ]) {
          await openDetail(tester, id, type: type);
          await _addFromDetail(tester, listName);
          await _close(tester, find.byType(MediaDetailPage));
        }
        await _expectStored(tester, app, listName, [movieA, movieB, showS]);
        // Only the chosen list changed.
        expect(await _entries(tester, app, 'watchlist'), isEmpty);

        // 3. The row splits movies and series 2 to 1.
        int flex(String key) => tester
            .widget<Expanded>(
              find
                  .ancestor(
                    of: find.descendant(
                      of: _row(listName),
                      matching: find.byKey(Key(key)),
                    ),
                    matching: find.byType(Expanded),
                  )
                  .first,
            )
            .flex;
        expect(flex('library_split_movie'), 2);
        expect(flex('library_split_series'), 1);

        // 4. The list opens in the order of addition.
        await _openList(tester, listName);
        await _expectShown(tester, [movieA, movieB, showS]);

        // 5. Release date order, reversed, then back to manual.
        await _openSortSheet(tester);
        await tester.tap(find.byIcon(Icons.calendar_today));
        await pumpUntilSettled(tester);
        await _expectShown(tester, [movieB, showS, movieA]);

        await _openSortSheet(tester);
        await tester.tap(find.byType(Switch));
        await pumpUntilSettled(tester);
        await _close(tester, find.byType(Switch));
        await _expectShown(tester, [movieA, showS, movieB]);

        await _openSortSheet(tester);
        await tester.tap(find.byType(Switch));
        await pumpUntilSettled(tester);
        await tester.tap(find.byIcon(Icons.drag_indicator));
        await pumpUntilSettled(tester);
        await _expectShown(tester, [movieA, movieB, showS]);
        // Sorting only changes the display.
        expect(await _entries(tester, app, listName), [movieA, movieB, showS]);

        // 6. Drag the show to the top: the new order is stored.
        final handle = find.descendant(
          of: _tile(showS),
          matching: find.byIcon(Icons.drag_handle),
        );
        final rowHeight = tester.getSize(_tile(movieA)).height;
        final drag = await tester.startGesture(tester.getCenter(handle));
        // No pause after the press: a long press selects the row instead.
        await tester.pump();
        for (var i = 0; i < 20; i++) {
          await drag.moveBy(Offset(0, -rowHeight * 0.1));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await drag.up();
        await pumpUntilSettled(tester);
        await _expectShown(tester, [showS, movieA, movieB]);
        await _expectStored(tester, app, listName, [showS, movieA, movieB]);
      },
      tmdb: _datedTmdb,
      // List display: rows with drag handles.
      seed: const AppSeed(prefs: {'displayMode': 0}),
    );

    testApp(
      'should import a shared list, compare it and delete it without '
      'touching the history or the other lists',
      (tester, app) async {
        // 1. Share the list: the sheet shows the QR code of its link.
        await _openList(tester, listName);
        await _moreAction(tester, Icons.share);
        // Its logo is a bundled asset (it named a missing file).
        final logo =
            tester.widget<QrImageView>(find.byType(QrImageView)).embeddedImage!
                as AssetImage;
        final bytes = await tester.runAsync(
          () => rootBundle.load(logo.assetName),
        );
        expect(bytes!.lengthInBytes, greaterThan(0));
        // The link the sheet encodes (`QrImageView` keeps it private).
        final link = _search(tester).getShareLinkForList(listName);
        await _close(tester, find.byType(QrImageView));
        final payload = ListShareCodec.decodeUri(Uri.parse(link))!;
        expect(payload.name, listName);
        expect(payload.entries.map((e) => '$e'), unorderedEquals(_weekend));
        await _close(tester, find.byType(ListPage));

        // 2. Import the link under another name: same entries.
        final watchlistBefore = await _watchlistPreviews(tester, app);
        await tester.tap(find.byKey(const Key('library_import_list')));
        await pumpUntilSettled(tester);
        await tester.tap(
          find.descendant(of: _dialog, matching: find.byIcon(Icons.link)),
        );
        await pumpUntilSettled(tester);
        await _typeInDialog(tester, link);
        await _confirmDialog(tester);
        await _typeInDialog(tester, '$listName copy');
        await _confirmDialog(tester);
        // The import ends with its confirmation message.
        await _until(
          tester,
          () async => appMessageController.current != null,
          reason: 'the import is confirmed',
        );
        expect(_row('$listName copy'), findsOneWidget);
        expect(
          await _entries(tester, app, '$listName copy'),
          unorderedEquals(_weekend),
        );
        // Importing never degrades what is already known about a title
        // (it overwrote their cached title and poster with a placeholder).
        expect(await _watchlistPreviews(tester, app), watchlistBefore);
        expect(watchlistBefore.map((p) => p.$2), everyElement(isNotNull));

        // Let the message go: it would cover the sheet of the next step.
        await tester.pump(AppMessageHost.durationWithoutAction);
        await pumpUntilSettled(tester);
        expect(appMessageController.current, isNull);

        // 3. Receive the link: compare it with "To watch" (A, B, C).
        await app.openLink(tester, Uri.parse(link));
        await tester.tap(find.byKey(const Key('incoming_list_compare_button')));
        await pumpUntilSettled(tester);
        final compared = find.descendant(
          of: find.byType(ListIntersectionPage),
          matching: find.byType(ListTile),
        );
        // A and B are common; A is seen.
        expect(compared, findsNWidgets(2));
        await tester.tap(find.byKey(const Key('hide_seen_toggle_chip')));
        await pumpUntilSettled(tester);
        expect(compared, findsOneWidget);
        await tester.tap(
          find.byKey(const Key('save_intersection_as_list_button')),
        );
        await pumpUntilSettled(tester);
        await _typeInDialog(tester, 'Common');
        await _confirmDialog(tester);
        await _expectStored(tester, app, 'Common', [movieB]);
        await _close(tester, find.byType(ListIntersectionPage));

        // 4. Delete the list: titles stay in the history and other lists.
        await _openList(tester, listName);
        await _moreAction(tester, Icons.delete);
        await _confirmDialog(tester);
        expect(find.byType(ListPage), findsNothing);
        expect(_row(listName), findsNothing);
        expect(_search(tester).listNames, isNot(contains(listName)));
        expect(
          await _real(tester, app.repository.getAllListNames),
          isNot(contains(listName)),
        );
        await _expectStored(tester, app, listName, isEmpty);
        expect(await _entries(tester, app, 'watchlist'), [
          movieA,
          movieB,
          movieC,
        ]);
        expect(
          await _entries(tester, app, '$listName copy'),
          unorderedEquals(_weekend),
        );
        final seen = await _real(tester, app.repository.getSeenItems);
        expect([for (final s in seen) s.tmdbId], [101]);
      },
      seed: AppSeed(
        lists: {
          listName: [_movie(101), _movie(102), _show],
          'watchlist': [_movie(101), _movie(102), _movie(103)],
        },
        seen: [
          SeenItem(
            tmdbId: 101,
            type: MediaType.movie,
            title: 'Movie 101',
            posterPath: '/p101.jpg',
            seenDate: DateTime(2026, 1, 2),
          ),
        ],
      ),
    );
  });
}

const List<String> _weekend = [movieA, movieB, showS];
