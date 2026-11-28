import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';

void main() {
  group('Book', () {
    const tBook = Book(
      isbn: '9780140328721',
      openLibraryKey: '/works/OL45804W',
      title: 'Fantastic Mr. Fox',
      authors: ['Roald Dahl', 'Quentin Blake'],
      authorKeys: ['/authors/OL34184A'],
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9780140328721-L.jpg',
      publisher: 'Puffin Books',
      publishYear: 1970,
      pageCount: 96,
      description: 'A clever fox outsmarts three farmers.',
      subjects: ['Foxes', 'Fiction'],
      language: 'eng',
    );

    test('should join authors with a comma in authorsDisplay', () {
      expect(tBook.authorsDisplay, 'Roald Dahl, Quentin Blake');
      expect(const Book(title: 'Unknown').authorsDisplay, '');
    });

    test('should support value equality via Equatable', () {
      const duplicate = Book(
        isbn: '9780140328721',
        openLibraryKey: '/works/OL45804W',
        title: 'Fantastic Mr. Fox',
        authors: ['Roald Dahl', 'Quentin Blake'],
        authorKeys: ['/authors/OL34184A'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9780140328721-L.jpg',
        publisher: 'Puffin Books',
        publishYear: 1970,
        pageCount: 96,
        description: 'A clever fox outsmarts three farmers.',
        subjects: ['Foxes', 'Fiction'],
        language: 'eng',
      );
      expect(tBook, equals(duplicate));
    });

    test('should copyWith updated fields while preserving others', () {
      final updated = tBook.copyWith(title: 'Updated Title', pageCount: 120);
      expect(updated.title, 'Updated Title');
      expect(updated.pageCount, 120);
      expect(updated.isbn, tBook.isbn);
      expect(updated.authors, tBook.authors);
    });
  });
}
