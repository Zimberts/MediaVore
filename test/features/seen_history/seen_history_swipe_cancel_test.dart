import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
  });

  testWidgets('Swiping a seen entry and cancelling does not delete', (
    tester,
  ) async {
    final seen = [
      SeenItem(
        id: 1,
        tmdbId: 10,
        type: MediaType.movie,
        title: 'X',
        seenDate: DateTime.now(),
      ),
    ];

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
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => seen);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    var deleted = false;
    when(() => mockRepository.deleteSeenEntry(any())).thenAnswer((_) async {
      deleted = true;
    });

    final mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
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

    final tile = find.text('X');
    expect(tile, findsOneWidget);

    // Swipe left to trigger confirm dialog
    await tester.drag(
      find.byKey(const Key('seen_1')),
      const Offset(-500.0, 0.0),
    );
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Remove log?'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // deleteSeenEntry should NOT have been called
    expect(deleted, isFalse);
  });
}
