import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  group('MediaItem.fromJson', () {
    test('should parse runtime from episode_run_time for TV series', () {
      final item = MediaItem.fromJson({
        'id': 1,
        'name': 'Breaking Bad',
        'media_type': 'tv',
        'overview': '',
        'first_air_date': '2008-01-20',
        'episode_run_time': [47, 50],
      });

      expect(item.mediaType, MediaType.tv);
      expect(item.runtime, 47);
    });

    test('should prefer movie runtime over episode_run_time', () {
      final item = MediaItem.fromJson({
        'id': 2,
        'title': 'Inception',
        'media_type': 'movie',
        'overview': '',
        'release_date': '2010-07-16',
        'runtime': 148,
        'episode_run_time': [60],
      });

      expect(item.runtime, 148);
    });

    test('should leave runtime null when neither field is present', () {
      final item = MediaItem.fromJson({
        'id': 3,
        'title': 'Some Movie',
        'media_type': 'movie',
        'overview': '',
        'release_date': '2010-07-16',
      });

      expect(item.runtime, isNull);
    });

    test('should leave runtime null for an empty episode_run_time list', () {
      final item = MediaItem.fromJson({
        'id': 4,
        'name': 'Some Show',
        'media_type': 'tv',
        'overview': '',
        'first_air_date': '2010-07-16',
        'episode_run_time': <int>[],
      });

      expect(item.runtime, isNull);
    });
  });
}
