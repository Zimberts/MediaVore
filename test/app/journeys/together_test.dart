// Journey #470: Together session, from the QR codes to the vote results.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/constants/storage_keys.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/navigation/app_tab_bar.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/together/presentation/pages/together_page.dart';
import 'package:mediavore/features/together/presentation/pages/together_results_page.dart';
import 'package:mediavore/features/together/presentation/pages/together_vote_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_mobile_scanner.dart';
import '../harness.dart';

/// Titles on every list: the vote candidates.
const _common = [101, 102, 103];

/// Host-only extras, also on the second friend's list: more than one QR
/// code (150 titles each) for both.
final _extras = [for (var id = 2000; id < 2148; id++) id];

MediaItem _movie(int id) => MediaItem(
  id: id,
  title: 'Movie $id',
  overview: '',
  releaseDate: '2020-01-01',
);

List<SharedMediaEntry> _entries(Iterable<int> ids) => [
  for (final id in ids) SharedMediaEntry(id, MediaType.movie),
];

/// QR codes shown by a friend's app: the same call as [TogetherPage].
List<String> _friendQr(Iterable<int> ids) =>
    ListShareCodec.createTogetherUrls(entries: _entries(ids));

void main() {
  group('Together journey', () {
    late FakeMobileScanner scanner;

    setUp(() => scanner = FakeMobileScanner()..install());

    testApp(
      'should share, scan friends, vote and rank the common titles',
      (tester, app) async {
        await _phoneView(tester);
        final l10n = tester.element(find.byType(MainPage)).l10n;
        final session = tester
            .element(find.byType(MainPage))
            .read<TogetherSessionProvider>();

        // 5. Home "Choose together" opens the tab.
        await tester.ensureVisible(
          find.byKey(const Key('home_choose_together')),
        );
        await tester.tap(find.byKey(const Key('home_choose_together')));
        await pumpUntilSettled(tester);
        expect(
          tester.widget<AppTabBar>(find.byType(AppTabBar)).selected,
          AppTab.together,
        );

        // 1. The host QR holds the whole watchlist, in two parts (150
        // titles each). QrImageView hides its data: the codes are rebuilt
        // with the call the page makes and must round-trip the list.
        final hostIds = {..._common, 104, ..._extras};
        expect(find.text(l10n.togetherMultiQrPart(1, 2)), findsOneWidget);
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();
        expect(find.text(l10n.togetherMultiQrPart(2, 2)), findsOneWidget);
        final hostQr = ListShareCodec.createTogetherUrls(
          entries: ListShareCodec.parseEntries(
            await tester.runAsync(
                  () => app.repository.getListEntries('watchlist'),
                ) ??
                const [],
          ),
        ).map(ListShareCodec.parse).toList();
        expect(hostQr.map((p) => p!.part), [1, 2]);
        expect({
          for (final p in hostQr) ...p!.entries,
        }, _entries(hostIds).toSet());
        // The QR names nobody: "Me (Host)" means nothing on a friend's phone.
        expect(hostQr.first!.name, isEmpty);

        // 2. A foreign code is ignored, a broken MediaVore one rejected.
        await _openScanner(tester);
        scanner.scan('https://example.com/not-a-list');
        await pumpUntilSettled(tester);
        expect(find.byType(MobileScanner), findsOneWidget);
        scanner.scan('mediavore://together?v=2&name=');
        await pumpUntilSettled(tester);
        expect(find.byType(MobileScanner), findsNothing);
        expect(appMessageController.current?.text, l10n.listsInvalidLink);
        expect(session.participants, isEmpty);

        // First friend: one QR code.
        final friendA = _friendQr([..._common, 105]);
        expect(friendA, hasLength(1));
        await _scan(tester, scanner, friendA.single);
        // Scanning it again by mistake adds nobody.
        await _scan(tester, scanner, friendA.single);

        // Second friend: two QR codes, the same (empty) name as the first.
        final friendB = _friendQr([..._common, ..._extras]);
        expect(friendB, hasLength(2));
        await _scan(tester, scanner, friendB[0]);
        expect(
          appMessageController.current?.text,
          l10n.togetherScanNextPart(2, 2),
        );
        final friend2 = '${l10n.togetherFriendName} 2';
        expect(session.participants.last.name, friend2);
        expect(session.participants.last.isComplete, isFalse);
        await _scan(tester, scanner, friendB[1]);

        expect(
          [
            for (final p in session.participants)
              (p.name, p.entries.length, p.isComplete),
          ],
          [
            (l10n.togetherFriendName, 4, true),
            (friend2, _common.length + _extras.length, true),
          ],
        );
        expect(
          find.byKey(Key('together_participant_$friend2')),
          findsOneWidget,
        );

        // 4. The session survives a change of tab.
        await goToTab(tester, AppTab.library);
        await goToTab(tester, AppTab.together);
        expect(session.participants, hasLength(2));
        expect(
          find.byKey(Key('together_participant_${l10n.togetherFriendName}')),
          findsOneWidget,
        );

        // 3. Common titles, then the vote.
        await _tapKey(tester, 'together_see_common_button');
        expect(find.byType(TogetherResultsPage), findsOneWidget);
        expect(find.text(l10n.togetherCommonCount(3)), findsOneWidget);
        expect(find.text(l10n.togetherAlmostSection(2, 3)), findsOneWidget);

        await _tapKey(tester, 'together_swipe_vote_button');
        expect(find.byType(TogetherVotePage), findsOneWidget);
        expect(session.isVoting, isTrue);
        expect(find.byType(AppTabBar, skipOffstage: false), findsNothing);

        // Approvals: 101 by all three, 102 by two, 103 by the host only.
        final yes = <String, Set<int>>{
          l10n.togetherYouHost: {101, 102, 103},
          l10n.togetherFriendName: {101, 102},
          friend2: {101},
        };
        for (final MapEntry(key: voter, value: approved) in yes.entries) {
          await _tapKey(tester, 'together_start_turn_button');
          for (var i = 0; i < _common.length; i++) {
            expect(find.widgetWithText(Chip, voter), findsOneWidget);
            final id = _votedTitle(tester);
            await _tapKey(
              tester,
              approved.contains(id) ? 'together_vote_yes' : 'together_vote_no',
            );
          }
        }

        expect(find.text(l10n.togetherTonightChoice), findsOneWidget);
        expect(find.text(l10n.togetherUnanimousVote), findsOneWidget);
        // Ranked tiles under the winner: "#rank" and "approvals / voters".
        for (final (id, rank, approvals) in [(102, 2, 2), (103, 3, 1)]) {
          final tile = find.ancestor(
            of: find.text('Movie $id'),
            matching: find.byType(ListTile),
          );
          expect(
            find.descendant(of: tile, matching: find.text('#$rank')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: tile, matching: find.text('$approvals / 3')),
            findsOneWidget,
          );
        }
        final prefs = await tester.runAsync(SharedPreferences.getInstance);
        expect(prefs!.getInt(StorageKeys.togetherChoicesKey), 1);
        // The first choice made together unlocks an achievement: let its
        // banner close by itself (4 s) before leaving.
        await tester.pump(const Duration(seconds: 5));
        await pumpUntilSettled(tester);

        // Back to the list, then a new session.
        await _tapKey(tester, 'together_review_list_button');
        expect(find.byType(TogetherResultsPage), findsOneWidget);
        expect(session.isVoting, isFalse);
        await _tapKey(tester, 'together_results_reset_button');
        await _tapKey(tester, 'together_reset_confirm_button');

        expect(find.byType(TogetherResultsPage), findsNothing);
        expect(session.hasSession, isFalse);
        expect(find.byKey(const Key('together_reset_button')), findsNothing);
        expect(find.byType(AppTabBar), findsOneWidget);
      },
      seed: AppSeed(
        lists: {
          'watchlist': [
            for (final id in [..._common, 104, ..._extras]) _movie(id),
          ],
        },
      ),
    );
  });
}

/// A phone screen: the Together page and the vote need its height.
Future<void> _phoneView(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await pumpUntilSettled(tester);
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpUntilSettled(tester);
}

Future<void> _openScanner(WidgetTester tester) async {
  await _tapKey(tester, 'together_scan_button');
  expect(find.byType(MobileScanner), findsOneWidget);
}

/// Opens the scanner and shows it [code].
Future<void> _scan(
  WidgetTester tester,
  FakeMobileScanner scanner,
  String code,
) async {
  await _openScanner(tester);
  scanner.scan(code);
  await pumpUntilSettled(tester);
  expect(find.byType(MobileScanner), findsNothing);
}

/// Id of the title on the vote card (`Movie <id>`, see FakeTmdb).
int _votedTitle(WidgetTester tester) {
  final title = tester.widget<Text>(
    find.descendant(
      of: find.byType(TogetherVotePage),
      matching: find.byWidgetPredicate(
        (w) => w is Text && (w.data?.startsWith('Movie ') ?? false),
      ),
    ),
  );
  return int.parse(title.data!.substring('Movie '.length));
}
