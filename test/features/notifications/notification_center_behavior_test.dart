import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
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
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
    when(
      () => mockRepository.refreshNotifiedItems(),
    ).thenAnswer((_) async => {});
    when(
      () => mockRepository.toggleNotification(
        any(),
        autoNotify: any(named: 'autoNotify'),
      ),
    ).thenAnswer((_) async => {});
    when(() => mockRepository.markAsSeen(any())).thenAnswer((_) async => {});
    when(
      () => mockRepository.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer(
      (_) async => MediaDetails(
        item: MediaItem(id: 1, title: 'T', overview: '', releaseDate: ''),
        cast: [],
      ),
    );
  });

  testWidgets('Mark as seen and toggle notification trigger repository calls', (
    tester,
  ) async {
    final seenDate = DateTime.now().subtract(const Duration(days: 1));
    final notified = NotifiedItem(
      tmdbId: 3,
      type: MediaType.movie,
      title: 'Notify Movie',
      releaseDate: seenDate,
    );

    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => [notified]);

    final provider = SearchProvider(mockRepository);

    await tester.pumpWidget(
      ChangeNotifierProvider<SearchProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const NotificationCenterPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the 'Mark as seen' icon/button for the released item
    final markSeenFinder = find.byTooltip('Mark as seen');
    expect(markSeenFinder, findsWidgets);

    await tester.tap(markSeenFinder.first);
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.markAsSeen(any()),
    ).called(greaterThanOrEqualTo(1));

    // Toggle notifications via the notifications_off icon (present as an IconButton)
    final notifyToggle = find.byIcon(Icons.notifications_off_outlined);
    expect(notifyToggle, findsWidgets);
    await tester.tap(notifyToggle.first);
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.toggleNotification(any()),
    ).called(greaterThanOrEqualTo(1));
  });
}
