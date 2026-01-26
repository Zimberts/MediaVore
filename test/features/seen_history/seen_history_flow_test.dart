import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => <NotifiedItem>[]);
    when(() => mockRepository.refreshNotifiedItems()).thenAnswer((_) async => {});
  });

  testWidgets('SeenManager: mark as seen via text entry and add multiple viewings', (tester) async {
    final seenItems = <SeenItem>[];

    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => seenItems);

    when(() => mockRepository.markAsSeen(any())).thenAnswer((inv) async {
      final arg = inv.positionalArguments[0] as SeenItem;
      final newEntry = SeenItem(
        id: 1,
        tmdbId: arg.tmdbId,
        type: arg.type,
        title: arg.title,
        posterPath: arg.posterPath,
        seenDate: arg.seenDate,
        seasonNumber: arg.seasonNumber,
        episodeNumber: arg.episodeNumber,
        runtime: arg.runtime,
      );
      seenItems.add(newEntry);
    });

    when(() => mockRepository.deleteSeenEntry(any())).thenAnswer((_) async {});
    when(() => mockRepository.removeFromSeen(any(), any())).thenAnswer((_) async {});

    final provider = SearchProvider(mockRepository);

    final testItem = MediaItem(id: 99, title: 'Test Movie', overview: '', releaseDate: '2024', mediaType: MediaType.movie);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<SearchProvider>.value(value: provider)],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: Scaffold(body: Center(child: SeenManager(item: testItem, compact: true))),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially, not seen -> icon should be outline
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    // Tap icon to open mark-as-seen dialog
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();

    // Switch to text entry mode (keyboard icon)
    expect(find.byIcon(Icons.keyboard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard));
    await tester.pumpAndSettle();

    // Enter a date in DD/MM/YYYY format
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, '01/01/2020');
    await tester.pumpAndSettle();

    // Tap LOG VIEWING
    await tester.tap(find.text('LOG VIEWING'));
    await tester.pumpAndSettle();

    // Verify repository.markAsSeen was called
    verify(() => mockRepository.markAsSeen(any(that: predicate((SeenItem s) => s.tmdbId == 99))))
        .called(1);

    // After markAsSeen, provider should have seenItems updated via getSeenItems -> widget rebuilds to show filled icon
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // Open history sheet by tapping the filled icon
    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();

    // 'Add New Viewing' option should be present
    expect(find.text('Add New Viewing'), findsOneWidget);

    // Tap 'Add New Viewing' to open the dialog again
    await tester.tap(find.text('Add New Viewing'));
    await tester.pumpAndSettle();

    // Use text entry and add second viewing
    await tester.tap(find.byIcon(Icons.keyboard));
    await tester.pumpAndSettle();
    await tester.enterText(textField, '02/02/2021');
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOG VIEWING'));
    await tester.pumpAndSettle();

    // After adding the second viewing, the mock-backed seenItems should contain two entries
    expect(seenItems.length, equals(2));
  });
}
