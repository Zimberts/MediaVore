// Journey #467: swipe mode, from the settings switch to the decisions it
// leaves in the library.
//
// Regressions covered: #393 (the settings switch shows and hides the swipe
// mode), #379 (no message covers the swipe buttons), #390 (liked titles
// reach the library and Home without a restart), and the deck skipping the
// rest of a discover page once it held enough cards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/features/discovery/presentation/pages/swiper_page.dart';
import 'package:mediavore/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:mediavore/features/discovery/presentation/widgets/swipe_card.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/providers/swiper_provider.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_tmdb.dart';
import '../harness.dart';

/// Discover titles, in deck order: page 1 of the discover fixture (101, 102,
/// 103), then page 2 (ids shifted by 1000: 1101, 1102, 1103).
const int _liked = 101;
const int _passed = 102;
const int _sagaVolume = 103;
const int _next = 1101;

/// Saga of [_sagaVolume]; its parts are 9000, 9001 and 9002 (FakeTmdb).
const int _sagaId = 900;
const List<int> _sagaParts = [9000, 9001, 9002];

const _discard = Key('swiper_discard_button');
const _undo = Key('swiper_undo_button');
const _seen = Key('swiper_seen_button');
const _add = Key('swiper_add_button');

FakeTmdb _tmdb() =>
    FakeTmdb(collectionOf: (id) => id == _sagaVolume ? _sagaId : null);

SearchProvider _search(WidgetTester tester) => tester
    .element(find.byType(MainPage, skipOffstage: false))
    .read<SearchProvider>();

/// Swiper of the Discover tab (owned by [SwiperPage]).
SwiperProvider _swiper(WidgetTester tester) => tester
    .element(find.byType(SwipeCard, skipOffstage: false))
    .read<SwiperProvider>();

/// Entries (`<id>:<type>`) of the watchlist.
List<String> _watchlist(WidgetTester tester) =>
    _search(tester).listEntries['watchlist'] ?? const [];

/// Explore / Swipe switch of Discover.
final Finder _modeSwitch = find.byType(AppSegmented<DiscoverMode>);

/// Opens the settings from the Me tab and flips the swipe mode switch.
Future<void> _toggleSwipeMode(WidgetTester tester) async {
  await goToTab(tester, AppTab.me);
  await tester.scrollUntilVisible(
    find.byKey(const Key('profile_settings')),
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.tap(find.byKey(const Key('profile_settings')));
  await pumpUntilSettled(tester);
  final toggle = find.byKey(const Key('settings_swipe_mode_switch'));
  await tester.scrollUntilVisible(
    toggle,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.tap(toggle);
  await pumpUntilSettled(tester);
  await tester.pageBack();
  await pumpUntilSettled(tester);
}

/// The card on top of the deck: its title id, or the saga id for a saga.
int? _topCard(WidgetTester tester) {
  final candidate = _swiper(tester).currentCandidate;
  if (candidate == null) return null;
  return candidate.isSaga ? candidate.collectionId : candidate.item.id;
}

/// Pumps until [done] holds. A decision chains several Isar writes, some
/// without a frame in between, which [pumpUntilSettled] can mistake for idle.
Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done(), isTrue, reason: 'swipe decision not applied in time');
  await pumpUntilSettled(tester);
}

/// Number of decisions of the swipe session.
int _decisions(WidgetTester tester) {
  final swiper = _swiper(tester);
  return swiper.sessionAddedCount +
      swiper.sessionSeenCount +
      swiper.sessionDiscardedCount;
}

/// Taps a swipe button, after checking nothing covers it (#379), and waits
/// until the decision is recorded (or undone) and [top] is on top of the
/// deck: the counters change last when deciding, the card comes back last
/// when undoing.
Future<void> _press(WidgetTester tester, Key button, {required int top}) async {
  final expected = _decisions(tester) + (button == _undo ? -1 : 1);
  expect(find.byKey(button).hitTestable(), findsOneWidget);
  await tester.tap(find.byKey(button));
  await _until(
    tester,
    () => _decisions(tester) == expected && _topCard(tester) == top,
  );
}

void main() {
  group('swipe journey', () {
    testApp(
      'should hide and show the swipe mode from the settings, add the liked '
      'titles and sagas everywhere, undo the last decision and keep the '
      'session across tabs',
      (tester, app) async {
        // A phone in portrait: the swipe screen does not fit 800x600.
        tester.view
          ..physicalSize = const Size(1080, 2340)
          ..devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);

        // 1. The settings switch hides then shows the swipe mode (#393).
        await goToTab(tester, AppTab.discover);
        expect(_modeSwitch, findsOneWidget);

        await _toggleSwipeMode(tester);
        await goToTab(tester, AppTab.discover);
        expect(_modeSwitch, findsNothing);

        await _toggleSwipeMode(tester);
        await goToTab(tester, AppTab.discover);
        expect(_modeSwitch, findsOneWidget);

        // 2. Swipe: the deck follows the discover order.
        await tester.tap(
          find.descendant(
            of: _modeSwitch,
            matching: find.byIcon(Icons.style_outlined),
          ),
        );
        await pumpUntilSettled(tester);
        expect(find.byType(SwiperPage), findsOneWidget);
        expect(_topCard(tester), _liked);
        expect(find.byKey(_undo).hitTestable(), findsOneWidget);

        await _press(tester, _add, top: _passed);
        expect(_watchlist(tester), contains('$_liked:movie'));

        await _press(tester, _discard, top: _sagaId);
        expect(_watchlist(tester), isNot(contains('$_passed:movie')));

        // 3. A volume of a saga is proposed as the whole saga; liking it adds
        // every part.
        final saga = _swiper(tester).currentCandidate!;
        expect(saga.sagaItems.map((m) => m.id), _sagaParts);
        await _press(tester, _add, top: _next);
        for (final part in _sagaParts) {
          expect(_watchlist(tester), contains('$part:movie'));
        }

        // Undo the last decision: the saga leaves the list and comes back on
        // top of the deck. No message is left over the buttons (#379).
        await _press(tester, _undo, top: _sagaId);
        for (final part in _sagaParts) {
          expect(_watchlist(tester), isNot(contains('$part:movie')));
        }
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(MaterialBanner), findsNothing);

        await _press(tester, _add, top: _next);
        final swiper = _swiper(tester);
        expect(swiper.sessionAddedCount, 2);
        expect(swiper.sessionDiscardedCount, 1);

        // 4. Without a restart: the liked titles are in the library and in
        // Home's "Tonight", the passed one is in neither.
        await goToTab(tester, AppTab.library);
        final library = _search(tester);
        expect(library.isItemInList(_movie(_liked), 'watchlist'), isTrue);
        expect(library.isItemInList(_movie(_passed), 'watchlist'), isFalse);

        await goToTab(tester, AppTab.home);
        final tonight = _search(
          tester,
        ).tonightCandidates().map((item) => item.id).toList();
        expect(tonight, containsAll([_liked, ..._sagaParts]));
        expect(tonight, isNot(contains(_passed)));
        expect(
          find.byKey(const ValueKey('home_tonight_movie_$_liked')),
          findsOneWidget,
        );

        // 5. Back to Discover: same session, same card, same counters.
        await goToTab(tester, AppTab.discover);
        expect(identical(_swiper(tester), swiper), isTrue);
        expect(_topCard(tester), _next);
        expect(swiper.sessionAddedCount, 2);
        expect(swiper.sessionDiscardedCount, 1);
        expect(swiper.canUndo, isTrue);

        // The deck goes on with the rest of the discover page: its first
        // load stopped after the first title of page 2.
        await _press(tester, _seen, top: _next + 1);
        expect(_search(tester).seenItems.map((s) => s.tmdbId), contains(_next));
        expect(swiper.sessionSeenCount, 1);

        // Undo seen: viewing is removed and card returns on top.
        await _press(tester, _undo, top: _next);
        expect(
          _search(tester).seenItems.map((s) => s.tmdbId),
          isNot(contains(_next)),
        );
        expect(swiper.sessionSeenCount, 0);

        // Mark seen again and advance to the next card.
        await _press(tester, _seen, top: _next + 1);
        expect(_search(tester).seenItems.map((s) => s.tmdbId), contains(_next));
        expect(swiper.sessionSeenCount, 1);

        // A new session (back to Explore then Swipe) reloads the deck from
        // the decision journal: no decided title is proposed again.
        await tester.tap(
          find.descendant(of: _modeSwitch, matching: find.byIcon(Icons.search)),
        );
        await pumpUntilSettled(tester);
        await tester.tap(
          find.descendant(
            of: _modeSwitch,
            matching: find.byIcon(Icons.style_outlined),
          ),
        );
        await pumpUntilSettled(tester);
        final deck = _swiper(tester).candidates;
        expect(deck, isNotEmpty);
        expect(
          deck.map((c) => c.item.id),
          isNot(anyOf(contains(_liked), contains(_passed), contains(_next))),
        );
        expect(deck.where((c) => c.collectionId == _sagaId), isEmpty);
      },
      tmdb: _tmdb,
    );
  });
}

MediaItem _movie(int id) =>
    MediaItem(id: id, title: 'Movie $id', overview: '', releaseDate: '');
