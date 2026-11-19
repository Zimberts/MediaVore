import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/discovery/presentation/widgets/because_you_row.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockMediaRepository repository;
  late SearchProvider searchProvider;

  setUp(() {
    repository = MockMediaRepository();
    when(() => repository.getAllListNames()).thenAnswer((_) async => []);
    when(() => repository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => repository.getListPreviews(any())).thenAnswer((_) async => []);
    when(() => repository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenItems()).thenAnswer((_) async => []);
    when(() => repository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => repository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => repository.getLikedItems()).thenAnswer((_) async => []);
    when(
      () => repository.getTrendingMedia(page: any(named: 'page')),
    ).thenAnswer((_) async => []);

    searchProvider = SearchProvider(repository);
  });

  Widget wrapWithProvider(Widget child) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: testApp(child),
    );
  }

  group('BecauseYouRow', () {
    testWidgets('renders nothing when recommendations count < 3', (
      tester,
    ) async {
      const data = BecauseYouData(
        sourceId: 1,
        sourceType: MediaType.movie,
        sourceTitle: 'Dune',
        reason: BecauseYouReason.liked,
        items: [
          MediaItem(id: 10, title: 'Item 1', overview: '', releaseDate: ''),
          MediaItem(id: 20, title: 'Item 2', overview: '', releaseDate: ''),
        ],
      );

      await tester.pumpWidget(
        wrapWithProvider(const BecauseYouRow(data: data)),
      );

      expect(find.byType(BecauseYouRow), findsOneWidget);
      expect(
        find.byKey(const Key('discovery_because_you_section')),
        findsNothing,
      );
    });

    testWidgets(
      'renders "Because you liked X" and cards when reason is liked',
      (tester) async {
        const data = BecauseYouData(
          sourceId: 1,
          sourceType: MediaType.movie,
          sourceTitle: 'Dune',
          reason: BecauseYouReason.liked,
          items: [
            MediaItem(
              id: 10,
              title: 'Blade Runner 2049',
              overview: '',
              releaseDate: '',
            ),
            MediaItem(id: 20, title: 'Arrival', overview: '', releaseDate: ''),
            MediaItem(id: 30, title: 'Sicario', overview: '', releaseDate: ''),
          ],
        );

        await tester.pumpWidget(
          wrapWithProvider(const BecauseYouRow(data: data)),
        );

        expect(
          find.byKey(const Key('discovery_because_you_section')),
          findsOneWidget,
        );
        expect(find.text('Because you liked Dune'), findsOneWidget);
        expect(find.text('Blade Runner 2049'), findsOneWidget);
        expect(find.text('Arrival'), findsOneWidget);
        expect(find.text('Sicario'), findsOneWidget);
      },
    );

    testWidgets('renders "Because you watched X" when reason is watched', (
      tester,
    ) async {
      const data = BecauseYouData(
        sourceId: 2,
        sourceType: MediaType.tv,
        sourceTitle: 'Severance',
        reason: BecauseYouReason.watched,
        items: [
          MediaItem(id: 101, title: 'Dark', overview: '', releaseDate: ''),
          MediaItem(id: 102, title: 'Devs', overview: '', releaseDate: ''),
          MediaItem(
            id: 103,
            title: 'Black Mirror',
            overview: '',
            releaseDate: '',
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithProvider(const BecauseYouRow(data: data)),
      );

      expect(find.text('Because you watched Severance'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Devs'), findsOneWidget);
      expect(find.text('Black Mirror'), findsOneWidget);
    });
  });
}
