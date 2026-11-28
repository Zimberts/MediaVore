import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';
import 'package:mediavore/features/media_details/presentation/pages/manual_media_form_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockMediaRepository mockRepo;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(ManualMediaKind.movie);
    registerFallbackValue(
      ManualMedia(
        localId: -1,
        kind: ManualMediaKind.movie,
        title: 'Fallback',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
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
    when(() => mockRepo.getListPreviews(any())).thenAnswer((_) async => []);
    when(
      () => mockRepo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    searchProvider = SearchProvider(mockRepo);
  });

  Widget buildPage({ManualMedia? initialMedia, String? initialTitle}) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: testApp(
        ManualMediaFormPage(
          initialMedia: initialMedia,
          initialTitle: initialTitle,
        ),
        scaffold: false,
      ),
    );
  }

  group('ManualMediaFormPage', () {
    testWidgets('should require a title before saving', (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.ensureVisible(find.byKey(ManualMediaFormPage.saveButtonKey));
      await tester.tap(find.byKey(ManualMediaFormPage.saveButtonKey));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
      verifyNever(
        () => mockRepo.createManualMedia(
          kind: any(named: 'kind'),
          title: any(named: 'title'),
        ),
      );
    });

    testWidgets(
      'should create a manual series with seasons and episodes when kind is tv',
      (tester) async {
        final created = ManualMedia(
          localId: -1,
          kind: ManualMediaKind.tv,
          title: 'My Web Series',
          seasons: const [10, 12],
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        when(
          () => mockRepo.createManualMedia(
            kind: ManualMediaKind.tv,
            title: 'My Web Series',
            originalTitle: any(named: 'originalTitle'),
            overview: any(named: 'overview'),
            releaseDate: any(named: 'releaseDate'),
            runtime: any(named: 'runtime'),
            seasons: any(named: 'seasons'),
            posterPath: any(named: 'posterPath'),
            genres: any(named: 'genres'),
            originCountries: any(named: 'originCountries'),
            sourceUrl: any(named: 'sourceUrl'),
            sourceProvider: any(named: 'sourceProvider'),
          ),
        ).thenAnswer((_) async => created);

        await tester.pumpWidget(buildPage());

        await tester.tap(find.byKey(const Key('manual_media_kind_tv')));
        await tester.pump();

        await tester.enterText(
          find.byKey(ManualMediaFormPage.titleFieldKey),
          'My Web Series',
        );

        await tester.ensureVisible(
          find.byKey(ManualMediaFormPage.addSeasonButtonKey),
        );
        await tester.tap(find.byKey(ManualMediaFormPage.addSeasonButtonKey));
        await tester.pump();

        await tester.ensureVisible(
          find.byKey(const Key('manual_media_season_2_episodes')),
        );
        await tester.enterText(
          find.byKey(const Key('manual_media_season_2_episodes')),
          '12',
        );

        await tester.ensureVisible(
          find.byKey(ManualMediaFormPage.saveButtonKey),
        );
        await tester.tap(find.byKey(ManualMediaFormPage.saveButtonKey));
        await tester.pumpAndSettle();

        verify(
          () => mockRepo.createManualMedia(
            kind: ManualMediaKind.tv,
            title: 'My Web Series',
            seasons: const [10, 12],
          ),
        ).called(1);
      },
    );

    testWidgets('should update existing manual media when editing', (
      tester,
    ) async {
      final existing = ManualMedia(
        localId: -2,
        kind: ManualMediaKind.video,
        title: 'Old Title',
        runtime: 15,
        sourceUrl: 'https://example.com/v',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      when(
        () => mockRepo.updateManualMedia(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ManualMedia);

      await tester.pumpWidget(buildPage(initialMedia: existing));

      await tester.enterText(
        find.byKey(ManualMediaFormPage.titleFieldKey),
        'New Title',
      );
      await tester.ensureVisible(find.byKey(ManualMediaFormPage.saveButtonKey));
      await tester.tap(find.byKey(ManualMediaFormPage.saveButtonKey));
      await tester.pumpAndSettle();

      final captured =
          verify(() => mockRepo.updateManualMedia(captureAny())).captured.single
              as ManualMedia;
      expect(captured.localId, -2);
      expect(captured.title, 'New Title');
      expect(captured.kind, ManualMediaKind.video);
    });
  });
}
