import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_header.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockMediaRepository mockRepo;
  late SearchProvider searchProvider;

  final manual = ManualMedia(
    localId: -1,
    kind: ManualMediaKind.video,
    title: 'Short Film',
    overview: 'An indie short film.',
    releaseDate: '2025-02-01',
    runtime: 18,
    sourceUrl: 'https://example.com/short',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  setUpAll(() {
    registerFallbackValue(manual.toMediaItem());
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepo = MockMediaRepository();
    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepo.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepo.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepo.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepo.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => mockRepo.getInProgressItems()).thenAnswer((_) async => []);
    when(
      () => mockRepo.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockRepo.getListPreviews(any())).thenAnswer((_) async => []);
    when(
      () => mockRepo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepo.getMediaDetails(-1, type: MediaType.movie),
    ).thenAnswer((_) async => manual.toMediaDetails());
    when(() => mockRepo.getManualMedia(-1)).thenAnswer((_) async => manual);
    when(() => mockRepo.deleteManualMedia(-1)).thenAnswer((_) async {});
    searchProvider = SearchProvider(mockRepo);
  });

  group('MediaDetailPage for manual media', () {
    testWidgets(
      'should show manual badge and open link button without TMDB blocks',
      (tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<SearchProvider>.value(
            value: searchProvider,
            child: testApp(
              MediaDetailPage(item: manual.toMediaItem()),
              scaffold: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('media_detail_manual_badge')),
          findsOneWidget,
        );
        expect(find.text('Added manually'), findsOneWidget);
        expect(find.byKey(const Key('media_detail_open_link')), findsOneWidget);
        expect(find.byKey(const Key('detail_notify')), findsNothing);
        expect(find.text('Cast'), findsNothing);
        expect(find.text('Where to watch'), findsNothing);
      },
    );

    testWidgets('should delete manual media from more menu after confirm', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SearchProvider>.value(
          value: searchProvider,
          child: testApp(
            MediaDetailPage(item: manual.toMediaItem()),
            scaffold: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(MediaDetailHeader.moreKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteManualMedia(-1)).called(1);
    });
  });
}
