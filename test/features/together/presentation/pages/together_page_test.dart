import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/together/presentation/pages/together_page.dart';
import 'package:mediavore/features/together/presentation/pages/together_results_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;
  late SearchProvider searchProvider;
  late TogetherSessionProvider sessionProvider;

  setUp(() async {
    repo = MockMediaRepository();
    when(() => repo.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(
      () => repo.getWatchlistEntries(),
    ).thenAnswer((_) async => ['101:movie', '201:tv']);
    when(
      () => repo.getListEntries('watchlist'),
    ).thenAnswer((_) async => ['101:movie', '201:tv']);
    when(
      () => repo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenItems()).thenAnswer((_) async => []);
    when(() => repo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repo.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => repo.getQuickAddItems()).thenAnswer((_) async => []);
    when(
      () => repo.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());

    searchProvider = SearchProvider(repo);
    await searchProvider.loadLists();

    sessionProvider = TogetherSessionProvider();
  });

  Widget buildSubject({
    Widget Function(BuildContext, ValueChanged<String>)? scannerBuilder,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: searchProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
      ],
      child: MaterialApp(
        theme: AppPalette.ink.toThemeData(),
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: AppMessageHost(
          child: TogetherPage(scannerBuilder: scannerBuilder),
        ),
      ),
    );
  }

  group('TogetherPage', () {
    testWidgets(
      'renders setup elements and disables see common button when empty',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Type selector
        expect(
          find.byKey(const Key('together_type_segmented_button')),
          findsOneWidget,
        );

        // List dropdown
        expect(find.byKey(const Key('together_list_dropdown')), findsOneWidget);

        // QR Image
        expect(find.byKey(const Key('together_qr_image')), findsOneWidget);

        // Warning notice
        expect(
          find.textContaining('Le QR contient votre liste'),
          findsOneWidget,
        );

        // Host participant in list
        expect(
          find.byKey(const Key('together_participant_host')),
          findsOneWidget,
        );

        // Prompt to scan
        expect(
          find.textContaining('Scannez au moins un ami pour continuer'),
          findsOneWidget,
        );

        // "Voir les titres en commun" button exists but is disabled
        final seeCommonButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('together_see_common_button')),
        );
        expect(seeCommonButton.onPressed, isNull);
      },
    );

    testWidgets(
      'scans friend QR, adds participant, and enables see common button',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final friendQrUrl = ListShareCodec.createShareUrl(
          listName: 'Alice',
          entries: const [
            SharedMediaEntry(101, MediaType.movie),
            SharedMediaEntry(301, MediaType.movie),
          ],
          customScheme: true,
        );

        await tester.pumpWidget(
          buildSubject(
            scannerBuilder: (context, onCode) {
              return Center(
                child: ElevatedButton(
                  key: const Key('mock_scan_trigger'),
                  onPressed: () => onCode(friendQrUrl),
                  child: const Text('Simulate Scan'),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap scan button
        await tester.tap(find.byKey(const Key('together_scan_button')));
        await tester.pumpAndSettle();

        // Trigger simulated scan
        expect(find.byKey(const Key('mock_scan_trigger')), findsOneWidget);
        await tester.tap(find.byKey(const Key('mock_scan_trigger')));
        await tester.pumpAndSettle();

        // Participant Alice should be in the list
        expect(find.text('Alice'), findsOneWidget);
        expect(sessionProvider.participants, hasLength(1));
        expect(sessionProvider.participants.first.name, 'Alice');

        // "Voir les titres en commun" button should now be enabled
        final seeCommonButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('together_see_common_button')),
        );
        expect(seeCommonButton.onPressed, isNotNull);

        // Tapping it pushes TogetherResultsPage
        await tester.tap(find.byKey(const Key('together_see_common_button')));
        await tester.pumpAndSettle();

        expect(find.byType(TogetherResultsPage), findsOneWidget);
      },
    );

    testWidgets('allows removing a scanned participant', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      sessionProvider.addParticipant(
        const TogetherParticipant(
          name: 'Bob',
          entries: [SharedMediaEntry(101, MediaType.movie)],
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);

      // Remove Bob
      final removeButton = find.descendant(
        of: find.byKey(const Key('together_participant_Bob')),
        matching: find.byIcon(Icons.remove_circle_outline),
      );
      expect(removeButton, findsOneWidget);
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(sessionProvider.participants, isEmpty);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets('resets session when clicking reset action and confirming', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      sessionProvider.addParticipant(
        const TogetherParticipant(
          name: 'Charlie',
          entries: [SharedMediaEntry(101, MediaType.movie)],
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('together_reset_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('together_reset_button')));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.textContaining('Réinitialiser'), findsWidgets);
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(sessionProvider.participants, isEmpty);
      expect(sessionProvider.hasSession, isFalse);
    });
  });
}
