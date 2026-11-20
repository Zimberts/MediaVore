import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';

void main() {
  group('TmdbImageSize', () {
    test('fromString returns matching enum for valid sizes', () {
      expect(TmdbImageSize.fromString('w92'), TmdbImageSize.w92);
      expect(TmdbImageSize.fromString('w154'), TmdbImageSize.w154);
      expect(TmdbImageSize.fromString('w185'), TmdbImageSize.w185);
      expect(TmdbImageSize.fromString('w342'), TmdbImageSize.w342);
      expect(TmdbImageSize.fromString('w500'), TmdbImageSize.w500);
      expect(TmdbImageSize.fromString('w780'), TmdbImageSize.w780);
      expect(TmdbImageSize.fromString('original'), TmdbImageSize.original);
    });

    test('fromString returns fallback for null, empty, or unknown strings', () {
      expect(TmdbImageSize.fromString(null), TmdbImageSize.w185);
      expect(TmdbImageSize.fromString(''), TmdbImageSize.w185);
      expect(TmdbImageSize.fromString('w9999'), TmdbImageSize.w185);
      expect(
        TmdbImageSize.fromString('invalid', fallback: TmdbImageSize.w342),
        TmdbImageSize.w342,
      );
    });
  });

  group('TmdbImageUtils.buildUrl', () {
    test('returns null when path is null or whitespace', () {
      expect(TmdbImageUtils.buildUrl(null), isNull);
      expect(TmdbImageUtils.buildUrl(''), isNull);
      expect(TmdbImageUtils.buildUrl('   '), isNull);
    });

    test('preserves full http/https URLs directly', () {
      expect(
        TmdbImageUtils.buildUrl('https://example.com/poster.jpg'),
        'https://example.com/poster.jpg',
      );
      expect(
        TmdbImageUtils.buildUrl('http://example.com/poster.jpg'),
        'http://example.com/poster.jpg',
      );
    });

    test('prepends leading slash if missing', () {
      expect(
        TmdbImageUtils.buildUrl('poster.jpg'),
        'https://image.tmdb.org/t/p/w185/poster.jpg',
      );
    });

    test('preserves leading slash if present', () {
      expect(
        TmdbImageUtils.buildUrl('/poster.jpg'),
        'https://image.tmdb.org/t/p/w185/poster.jpg',
      );
    });

    test('formats URL with requested size', () {
      expect(
        TmdbImageUtils.buildUrl('/pic.jpg', size: TmdbImageSize.w92),
        'https://image.tmdb.org/t/p/w92/pic.jpg',
      );
      expect(
        TmdbImageUtils.buildUrl('/pic.jpg', size: TmdbImageSize.w780),
        'https://image.tmdb.org/t/p/w780/pic.jpg',
      );
      expect(
        TmdbImageUtils.buildUrl('/pic.jpg', size: TmdbImageSize.original),
        'https://image.tmdb.org/t/p/original/pic.jpg',
      );
    });

    test('buildUrlWithSizeString handles string sizes gracefully', () {
      expect(
        TmdbImageUtils.buildUrlWithSizeString('/pic.jpg', size: 'w500'),
        'https://image.tmdb.org/t/p/w500/pic.jpg',
      );
      expect(
        TmdbImageUtils.buildUrlWithSizeString(
          '/pic.jpg',
          size: 'unknown',
          fallback: TmdbImageSize.w342,
        ),
        'https://image.tmdb.org/t/p/w342/pic.jpg',
      );
    });
  });

  group('TmdbImagePathX extension', () {
    test('calls buildUrl correctly', () {
      const String? nullPath = null;
      expect(nullPath.tmdbImageUrl(), isNull);
      expect('   '.tmdbImageUrl(), isNull);
      expect(
        '/poster.png'.tmdbImageUrl(TmdbImageSize.w342),
        'https://image.tmdb.org/t/p/w342/poster.png',
      );
      expect('poster.png'.tmdbImageUrl(), 'https://image.tmdb.org/t/p/w185/poster.png');
    });
  });
}
