import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/services/search_relevance.dart';

void main() {
  group('titleSimilarityScore', () {
    test('returns 0 for empty query', () {
      expect(titleSimilarityScore('', 'Inception'), equals(0));
      expect(titleSimilarityScore('   ', 'Inception'), equals(0));
    });

    test('returns 4 for exact match ignoring case', () {
      expect(titleSimilarityScore('inception', 'Inception'), equals(4));
    });

    test('returns 3 for prefix match', () {
      expect(titleSimilarityScore('incep', 'Inception'), equals(3));
    });

    test('returns 2 for substring match', () {
      expect(titleSimilarityScore('cept', 'Inception'), equals(2));
    });

    test('returns 1 for shared word', () {
      expect(titleSimilarityScore('dark knight', 'The Dark World'), equals(1));
    });

    test('returns 0 when no match', () {
      expect(titleSimilarityScore('avatar', 'Inception'), equals(0));
    });
  });

  group('sortMediaByRelevance', () {
    test('sorts by relevance score then by rating', () {
      const itemExact = MediaItem(
        id: 1,
        title: 'Batman',
        overview: '',
        releaseDate: '2000-01-01',
        mediaType: MediaType.movie,
        voteAverage: 7.0,
      );
      const itemPrefix = MediaItem(
        id: 2,
        title: 'Batman Begins',
        overview: '',
        releaseDate: '2005-01-01',
        mediaType: MediaType.movie,
        voteAverage: 8.5,
      );
      const itemSubstring = MediaItem(
        id: 3,
        title: 'The Batman',
        overview: '',
        releaseDate: '2022-01-01',
        mediaType: MediaType.movie,
        voteAverage: 9.0,
      );
      const itemNoMatch = MediaItem(
        id: 4,
        title: 'Superman',
        overview: '',
        releaseDate: '1998-01-01',
        mediaType: MediaType.movie,
        voteAverage: 8.0,
      );

      final list = [itemNoMatch, itemSubstring, itemPrefix, itemExact];
      sortMediaByRelevance(list, 'Batman');

      expect(list.first.id, equals(1)); // Exact match
      expect(list[1].id, equals(2)); // Prefix match
      expect(list[2].id, equals(3)); // Substring match
      expect(list.last.id, equals(4)); // No match
    });
  });
}
