import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/features/search/presentation/pages/list_intersection_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/incoming_list_sheet.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;
  late SearchProvider provider;

  setUp(() {
    repo = MockMediaRepository();
    when(() => repo.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => repo.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => repo.getListEntries(any())).thenAnswer((_) async => []);
    when(
      () => repo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenItems()).thenAnswer((_) async => []);
    when(() => repo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repo.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => repo.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    provider = SearchProvider(repo);
  });

  Widget buildTestWidget(ListSharePayload payload) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: provider),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showIncomingListOptionsSheet(
                    context: context,
                    payload: payload,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('showIncomingListOptionsSheet displays choice buttons', (
    tester,
  ) async {
    const payload = ListSharePayload(
      name: 'Alice List',
      entries: [
        SharedMediaEntry(1, MediaType.movie),
        SharedMediaEntry(2, MediaType.tv),
      ],
    );

    await tester.pumpWidget(buildTestWidget(payload));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Alice List'), findsOneWidget);
    expect(
      find.byKey(const Key('incoming_list_compare_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('incoming_list_import_button')),
      findsOneWidget,
    );
  });

  testWidgets('tapping compare navigates to ListIntersectionPage', (
    tester,
  ) async {
    const payload = ListSharePayload(
      name: 'Alice List',
      entries: [SharedMediaEntry(1, MediaType.movie)],
    );

    await tester.pumpWidget(buildTestWidget(payload));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('incoming_list_compare_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ListIntersectionPage), findsOneWidget);
  });
}
