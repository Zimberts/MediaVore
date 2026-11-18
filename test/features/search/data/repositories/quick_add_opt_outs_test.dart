import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaListLocalDataSource local;
  late MockMediaRemoteDataSource remote;
  late MockMediaCache cache;
  late MediaRepositoryImpl repository;

  setUp(() {
    local = MockMediaListLocalDataSource();
    remote = MockMediaRemoteDataSource();
    cache = MockMediaCache();

    repository = MediaRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      cache: cache,
      autoInit: false,
    );
  });

  QuickAddOptOutModel optOut(int tmdbId, int episode, DateTime at) =>
      QuickAddOptOutModel(
        tmdbId: tmdbId,
        seasonNumber: 1,
        episodeNumber: episode,
        optedOutAt: at,
      );

  MediaItem show(int id, String title) => MediaItem(
    id: id,
    title: title,
    overview: '',
    releaseDate: '2020-01-01',
    posterPath: '/$id.jpg',
    mediaType: MediaType.tv,
  );

  group('MediaRepositoryImpl.getQuickAddOptOuts', () {
    test('should be empty without any opt-out', () async {
      when(() => local.getOptOuts()).thenAnswer((_) async => []);

      expect(await repository.getQuickAddOptOuts(), isEmpty);
      verifyNever(() => cache.getItems(any()));
    });

    test(
      'should list the opt-outs most recent first with the cached title',
      () async {
        when(() => local.getOptOuts()).thenAnswer(
          (_) async => [
            optOut(10, 4, DateTime(2026, 11, 1)),
            optOut(20, 2, DateTime(2026, 11, 10)),
          ],
        );
        when(() => cache.getItems(any())).thenAnswer(
          (_) async => [show(10, 'Chernobyl'), show(20, 'Severance')],
        );

        final optOuts = await repository.getQuickAddOptOuts();

        expect([for (final o in optOuts) o.tmdbId], [20, 10]);
        expect(optOuts.first.title, 'Severance');
        expect(optOuts.first.posterPath, '/20.jpg');
        expect(optOuts.first.seasonNumber, 1);
        expect(optOuts.first.episodeNumber, 2);
        expect(optOuts.first.optedOutAt, DateTime(2026, 11, 10));
        expect(optOuts.last.title, 'Chernobyl');
        verify(
          () => cache.getItems([(10, MediaType.tv), (20, MediaType.tv)]),
        ).called(1);
      },
    );

    test(
      'should fall back to the title of a viewing when nothing is cached',
      () async {
        when(
          () => local.getOptOuts(),
        ).thenAnswer((_) async => [optOut(10, 4, DateTime(2026, 11, 1))]);
        when(() => cache.getItems(any())).thenAnswer((_) async => [null]);
        when(() => local.getSeenStatus(10, 'tv')).thenAnswer(
          (_) async => [
            SeenItemModel(
              tmdbId: 10,
              type: 'tv',
              title: 'Chernobyl',
              posterPath: '/seen.jpg',
              seenDate: DateTime(2026, 10, 1),
              seasonNumber: 1,
              episodeNumber: 3,
            ),
          ],
        );

        final optOuts = await repository.getQuickAddOptOuts();

        expect(optOuts.single.title, 'Chernobyl');
        expect(optOuts.single.posterPath, '/seen.jpg');
      },
    );

    test('should leave the title empty when the series is unknown', () async {
      when(
        () => local.getOptOuts(),
      ).thenAnswer((_) async => [optOut(10, 4, DateTime(2026, 11, 1))]);
      when(() => cache.getItems(any())).thenAnswer((_) async => [null]);
      when(() => local.getSeenStatus(10, 'tv')).thenAnswer((_) async => []);

      final optOuts = await repository.getQuickAddOptOuts();

      expect(optOuts.single.title, isNull);
      verifyZeroInteractions(remote);
    });
  });
}
