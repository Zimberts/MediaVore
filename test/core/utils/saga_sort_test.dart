import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/saga_sort.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  test('sortSagaByDate sorts movies by releaseDate and TV by lastEpisodeAirDate', () {
    final m1 = MediaItem(id: 1, title: 'M1', overview: '', releaseDate: '2000-01-01');
    final m2 = MediaItem(id: 2, title: 'M2', overview: '', releaseDate: '2005-01-01');
    final tv3 = MediaItem(
      id: 3,
      title: 'TV3',
      overview: '',
      releaseDate: '2008-01-01',
      mediaType: MediaType.tv,
      lastEpisodeAirDate: '2010-06-01',
    );

    final list = [m2, tv3, m1];
    final sorted = sortSagaByDate(list);
    expect(sorted.map((i) => i.id).toList(), [1, 2, 3]);
  });

  test('rotateSagaElements rotates around current id and omits current', () {
    final items = List.generate(
      5,
      (i) => MediaItem(id: i + 1, title: 'T${i + 1}', overview: '', releaseDate: '200${i + 1}-01-01'),
    );

    final rotated = rotateSagaElements(items, 3);
    expect(rotated.map((i) => i.id).toList(), [4, 5, 1, 2]);
  });

  test('items with null/empty dates go last', () {
    final withDate = MediaItem(id: 1, title: 'D', overview: '', releaseDate: '2020-01-01');
    final noDate = MediaItem(id: 2, title: 'ND', overview: '', releaseDate: '');
    final sorted = sortSagaByDate([noDate, withDate]);
    expect(sorted.map((i) => i.id).toList(), [1, 2]);
  });
}
