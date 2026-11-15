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

    test('should parse origin_country when non-empty', () {
      final item = MediaItem.fromJson({
        'id': 5,
        'title': 'Test Movie',
        'media_type': 'movie',
        'origin_country': ['US', 'CA'],
      });

      expect(item.originCountries, ['US', 'CA']);
    });

    test(
      'should fallback to production_countries when origin_country is empty',
      () {
        final item = MediaItem.fromJson({
          'id': 6,
          'title': 'French Movie',
          'media_type': 'movie',
          'origin_country': <dynamic>[],
          'production_countries': [
            {'iso_3166_1': 'FR', 'name': 'France'},
            {'iso_3166_1': 'BE', 'name': 'Belgium'},
          ],
        });

        expect(item.originCountries, ['FR', 'BE']);
      },
    );

    test(
      'should return empty list when both origin_country and production_countries are empty',
      () {
        final item = MediaItem.fromJson({
          'id': 7,
          'title': 'No Country Movie',
          'media_type': 'movie',
          'origin_country': <dynamic>[],
          'production_countries': <dynamic>[],
        });

        expect(item.originCountries, isEmpty);
        expect(item.originCountries, isNotNull);
      },
    );

    test('should return null when country fields are absent (pre-v1.3.0)', () {
      final item = MediaItem.fromJson({
        'id': 8,
        'title': 'Old Cached Movie',
        'media_type': 'movie',
      });

      expect(item.originCountries, isNull);
    });
  });

  group('MediaItem.isComplete', () {
    test('should return true when all metadata fields are present', () {
      const completeItem = MediaItem(
        id: 1,
        title: 'Complete',
        overview: '',
        releaseDate: '2023-01-01',
        originCountries: ['FR'],
        voteCount: 42,
        originalLanguage: 'fr',
      );

      expect(completeItem.isComplete, isTrue);
    });

    test(
      'should return true when originCountries is empty list and voteCount is 0',
      () {
        const completeItem = MediaItem(
          id: 1,
          title: 'Complete with zero/empty',
          overview: '',
          releaseDate: '2023-01-01',
          originCountries: [],
          voteCount: 0,
          originalLanguage: 'xx',
        );

        expect(completeItem.isComplete, isTrue);
      },
    );

    test('should return false if originCountries is null', () {
      const item = MediaItem(
        id: 1,
        title: 'Missing origin',
        overview: '',
        releaseDate: '2023-01-01',
        voteCount: 10,
        originalLanguage: 'en',
      );

      expect(item.isComplete, isFalse);
    });

    test('should return false if voteCount is null', () {
      const item = MediaItem(
        id: 1,
        title: 'Missing votes',
        overview: '',
        releaseDate: '2023-01-01',
        originCountries: ['US'],
        originalLanguage: 'en',
      );

      expect(item.isComplete, isFalse);
    });

    test('should return false if originalLanguage is null', () {
      const item = MediaItem(
        id: 1,
        title: 'Missing language',
        overview: '',
        releaseDate: '2023-01-01',
        originCountries: ['US'],
        voteCount: 10,
      );

      expect(item.isComplete, isFalse);
    });
  });

  group('originalTitle', () {
    test('should read original_title for a movie', () {
      final item = MediaItem.fromJson({
        'id': 1,
        'title': 'Spirited Away',
        'original_title': '千と千尋の神隠し',
        'media_type': 'movie',
      });

      expect(item.originalTitle, '千と千尋の神隠し');
    });

    test('should read original_name for a series', () {
      final item = MediaItem.fromJson({
        'id': 2,
        'name': 'Money Heist',
        'original_name': 'La casa de papel',
        'media_type': 'tv',
      });

      expect(item.originalTitle, 'La casa de papel');
    });

    test('should survive a toJson / fromJson round trip', () {
      const item = MediaItem(
        id: 3,
        title: 'Dark',
        originalTitle: 'Dunkel',
        overview: '',
        releaseDate: '2017-12-01',
        mediaType: MediaType.tv,
      );

      final restored = MediaItem.fromJson(item.toJson());

      expect(restored.originalTitle, 'Dunkel');
      expect(restored, item);
    });

    test('should stay null when TMDB does not report it', () {
      final item = MediaItem.fromJson({'id': 4, 'title': 'Untitled'});

      expect(item.originalTitle, isNull);
      expect(MediaItem.fromJson(item.toJson()).originalTitle, isNull);
    });
  });
}
