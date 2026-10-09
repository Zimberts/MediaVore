import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/genres.dart';

void main() {
  group('GenreUtils.getGenreIdByName', () {
    test('should resolve display names case-insensitively', () {
      expect(GenreUtils.getGenreIdByName('Horror'), 27);
      expect(GenreUtils.getGenreIdByName('sci-fi'), 878);
    });

    test(
      'should resolve English TMDB names that differ from display names',
      () {
        expect(GenreUtils.getGenreIdByName('Science Fiction'), 878);
        expect(GenreUtils.getGenreIdByName('TV Movie'), 10770);
      },
    );

    test('should resolve French TMDB names', () {
      expect(GenreUtils.getGenreIdByName('Horreur'), 27);
      expect(GenreUtils.getGenreIdByName('Comédie'), 35);
      expect(GenreUtils.getGenreIdByName('Science-Fiction'), 878);
      expect(GenreUtils.getGenreIdByName('Drame'), 18);
    });

    test('should return null for unknown names', () {
      expect(GenreUtils.getGenreIdByName('Not a genre'), isNull);
    });
  });
}
