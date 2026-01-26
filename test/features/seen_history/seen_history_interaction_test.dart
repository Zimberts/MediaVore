import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
  });

  testWidgets(
    'Swiping a seen entry opens confirmation and deletes on confirm',
    (tester) async {
      final seen = SeenItem(
        id: 555,
        tmdbId: 999,
        title: 'SwipeDelete',
        type: MediaType.movie,
        seenDate: DateTime.now(),
      );

      // initial seen list contains the item
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => [seen]);

      // delete should update repository to return empty list afterwards
      when(() => mockRepository.deleteSeenEntry(any())).thenAnswer((inv) async {
        when(
          () => mockRepository.getSeenItems(),
        ).thenAnswer((_) async => <SeenItem>[]);
      });

      final mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getInt(any())).thenReturn(0);
      when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
      when(() => mockPrefs.getBool(any())).thenReturn(false);
      when(
        () => mockPrefs.setDouble(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      final settings = SettingsProvider(mockPrefs);
      final provider = SearchProvider(mockRepository);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
          ],
          child: MaterialApp(
            theme: DefaultLightPalette().toThemeData(),
            home: const SeenHistoryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure the seen item is present
      expect(find.text('SwipeDelete'), findsOneWidget);

      // Dismiss by dragging left on the list tile
      final dismissible = find.byKey(const Key('seen_555'));
      expect(dismissible, findsOneWidget);
      await tester.drag(dismissible, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Remove log?'), findsOneWidget);
      // Tap Remove
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Now the item should be removed
      expect(find.text('SwipeDelete'), findsNothing);
    },
  );
}
