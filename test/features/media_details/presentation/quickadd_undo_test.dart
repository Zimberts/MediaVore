import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

import '../../../helpers/mocks.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  late MockMediaRepository repo;
  late SearchProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeQuickAddItem());
  });

  setUp(() async {
    repo = MockMediaRepository();

    // Basic stubs for initialization calls
    when(() => repo.getAllListNames()).thenAnswer((_) async => <String>[]);
    when(() => repo.getListEntries(any())).thenAnswer((_) async => <String>[]);
    when(
      () => repo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => repo.getWatchlistEntries()).thenAnswer((_) async => <String>[]);
    when(() => repo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => repo.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    final qa = QuickAddItem(
      isarId: 1,
      tmdbId: 100,
      type: MediaType.tv,
      seasonNumber: 1,
      episodeNumber: 2,
      insertedAt: DateTime.now(),
      title: 'Test Show',
      posterPath: null,
    );

    when(() => repo.getQuickAddItems()).thenAnswer((_) async => [qa]);
    when(
      () => repo.optOutSeries(
        any(),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer((inv) async {
      // After opting out, repo should return no quick-adds for this test
      when(
        () => repo.getQuickAddItems(),
      ).thenAnswer((_) async => <QuickAddItem>[]);
    });

    when(
      () => repo.clearOptOutSeries(
        any(),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer((inv) async {
      // Do nothing here; the UI now calls populateQuickAddFromSeenHistory()
      return Future.value();
    });

    when(
      () => repo.addQuickAddItem(any()),
    ).thenAnswer((inv) async {
      // Simulate repopulation by restoring the quick-add item
      when(() => repo.getQuickAddItems()).thenAnswer((_) async => [qa]);
    });

    provider = SearchProvider(repo);
    await provider.loadQuickAddItems();
  });

  testWidgets('swipe opt-out shows undo and undo calls clearOptOutSeries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SearchProvider>.value(
          value: provider,
          child: const NotificationCenterPage(),
        ),
      ),
    );

    // let init finish
    await tester.pumpAndSettle();

    // Switch to Quick Add tab
    await tester.tap(find.text('Quick Add'));
    await tester.pumpAndSettle();

    // Ensure quick-add item is present
    expect(find.text('Test Show'), findsOneWidget);

    // Swipe left to dismiss (opt-out)
    await tester.drag(find.text('Test Show'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // SnackBar with Undo should appear
    expect(find.text('Streak opted out of Quick Add'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    // Verify clearOptOutSeries and populateQuickAddFromSeenHistory were called
    verify(
      () => repo.clearOptOutSeries(100, seasonNumber: 1, episodeNumber: 2),
    ).called(1);
    verify(
      () => repo.addQuickAddItem(any()),
    ).called(1);
  });
}
