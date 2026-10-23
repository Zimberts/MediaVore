import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/genres.dart';

void main() {
  group('GenreUtils', () {
    test('should resolve English, French and TMDB genre names', () {
      expect(GenreUtils.getGenreIdByName('Horror'), 27);
      expect(GenreUtils.getGenreIdByName('Horreur'), 27);
      expect(GenreUtils.getGenreIdByName('aventure'), 12);
      expect(GenreUtils.getGenreIdByName('Science Fiction'), 878);
      expect(GenreUtils.getGenreIdByName('Science-Fiction'), 878);
      expect(
        GenreUtils.getGenreIdByName('Science-Fiction & Fantastique'),
        10765,
      );
      expect(GenreUtils.getGenreIdByName('Not a genre'), isNull);
    });

    test('should have a localized name for every known genre', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      final en = lookupAppLocalizations(const Locale('en'));
      for (final id in GenreUtils.getAllGenres().keys) {
        expect(GenreUtils.localizedName(fr, id), isNotEmpty);
        expect(GenreUtils.localizedName(en, id), GenreUtils.getAllGenres()[id]);
      }
      expect(GenreUtils.localizedName(fr, 35), 'Comédie');
    });
  });

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
