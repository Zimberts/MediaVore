import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/library/presentation/utils/list_entry.dart';

void main() {
  MediaItem movie(
    int id,
    String title, {
    String releaseDate = '2000-01-01',
    int? collectionId,
    String? collectionName,
  }) {
    return MediaItem(
      id: id,
      title: title,
      overview: '',
      releaseDate: releaseDate,
      collectionId: collectionId,
      collectionName: collectionName,
    );
  }

  MediaItem tv(int id, String title, {int? collectionId}) {
    return MediaItem(
      id: id,
      title: title,
      overview: '',
      releaseDate: '2020-01-01',
      mediaType: MediaType.tv,
      collectionId: collectionId,
      collectionName: collectionId != null ? 'Should Ignore' : null,
    );
  }

  group('groupMoviesBySaga', () {
    test('should keep all items as SingleListEntry when disabled', () {
      final items = [
        movie(1, 'LOTR 1', collectionId: 119, collectionName: 'LOTR'),
        movie(2, 'LOTR 2', collectionId: 119, collectionName: 'LOTR'),
      ];

      final entries = groupMoviesBySaga(items, enabled: false);

      expect(entries, hasLength(2));
      expect(entries.every((e) => e is SingleListEntry), isTrue);
    });

    test(
      'should group >= 2 movies with same collectionId at first member position and sort chronologically',
      () {
        final m1 = movie(
          1,
          'Return of the King',
          releaseDate: '2003-12-17',
          collectionId: 119,
          collectionName: 'The Lord of the Rings Collection',
        );
        final m2 = movie(
          2,
          'Fellowship of the Ring',
          releaseDate: '2001-12-19',
          collectionId: 119,
          collectionName: 'The Lord of the Rings Collection',
        );
        final standalone = movie(3, 'Inception', releaseDate: '2010-07-16');

        // m1 (2003) appears at index 1 before m2 (2001) at index 2.
        final entries = groupMoviesBySaga([standalone, m1, m2], enabled: true);

        expect(entries, hasLength(2));
        expect(entries[0], isA<SingleListEntry>());
        expect((entries[0] as SingleListEntry).item, standalone);

        final saga = entries[1] as SagaListEntry;
        expect(saga.collectionId, 119);
        expect(saga.name, 'The Lord of the Rings Collection');
        // Sorted chronologically: 2001 then 2003.
        expect(saga.movies, [m2, m1]);
      },
    );

    test('should keep single-movie saga as SingleListEntry', () {
      final singleSagaMovie = movie(
        10,
        'Matrix',
        releaseDate: '1999-03-31',
        collectionId: 2344,
        collectionName: 'The Matrix Collection',
      );

      final entries = groupMoviesBySaga([singleSagaMovie], enabled: true);

      expect(entries, hasLength(1));
      expect(entries.first, isA<SingleListEntry>());
      expect((entries.first as SingleListEntry).item, singleSagaMovie);
    });

    test(
      'should keep TV series and movies without collectionId as SingleListEntry',
      () {
        final tv1 = tv(100, 'Series A', collectionId: 500);
        final tv2 = tv(101, 'Series B', collectionId: 500);
        final offlineMovie = movie(200, 'Offline Movie');

        final entries = groupMoviesBySaga([
          tv1,
          tv2,
          offlineMovie,
        ], enabled: true);

        expect(entries, hasLength(3));
        expect(entries.every((e) => e is SingleListEntry), isTrue);
      },
    );
  });

  group('SagaListEntry.representativeMovie', () {
    test('should return first unseen movie in chronological order', () {
      final m1 = movie(1, 'Part 1', releaseDate: '2001-01-01');
      final m2 = movie(2, 'Part 2', releaseDate: '2002-01-01');
      final m3 = movie(3, 'Part 3', releaseDate: '2003-01-01');
      final entry = SagaListEntry(
        collectionId: 1,
        name: 'Trilogy',
        movies: [m1, m2, m3],
      );

      final rep = entry.representativeMovie((m) => m.id == 1);
      expect(rep, m2);
    });

    test('should return first movie when all movies are seen', () {
      final m1 = movie(1, 'Part 1', releaseDate: '2001-01-01');
      final m2 = movie(2, 'Part 2', releaseDate: '2002-01-01');
      final entry = SagaListEntry(
        collectionId: 1,
        name: 'Trilogy',
        movies: [m1, m2],
      );

      final rep = entry.representativeMovie((_) => true);
      expect(rep, m1);
    });
  });

  group('reorderCurrentItemsByEntry', () {
    test(
      'should move all movies of a saga entry together while preserving filtered-out items',
      () {
        final a = movie(1, 'A');
        final filteredTv = tv(99, 'TV');
        final b1 = movie(
          2,
          'B1',
          releaseDate: '2001-01-01',
          collectionId: 10,
          collectionName: 'B',
        );
        final b2 = movie(
          3,
          'B2',
          releaseDate: '2002-01-01',
          collectionId: 10,
          collectionName: 'B',
        );
        final c = movie(4, 'C');

        final allItems = [a, filteredTv, b1, c, b2];
        final visibleEntries = groupMoviesBySaga([a, b1, c, b2], enabled: true);

        // Move Saga(B) from index 1 to index 2 (after Single(C)).
        final reordered = reorderCurrentItemsByEntry(
          allItems: allItems,
          visibleEntries: visibleEntries,
          oldIndex: 1,
          newIndex: 2,
        );

        expect(reordered, [a, filteredTv, c, b1, b2]);
      },
    );
  });
}
