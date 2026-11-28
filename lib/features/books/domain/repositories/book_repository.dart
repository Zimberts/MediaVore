import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';

/// Repository for fetching book metadata from remote book sources.
abstract class BookRepository {
  /// Fetches book metadata by its ISBN-10 or ISBN-13.
  ///
  /// Returns `null` when no book matches [isbn].
  /// Throws an [AppException] on network, server, or parsing failures.
  Future<Book?> fetchBookByIsbn(String isbn);

  /// Fetches book metadata by its Open Library work key (e.g. `/works/OL45804W`).
  ///
  /// Returns `null` when the work does not exist.
  /// Throws an [AppException] on network, server, or parsing failures.
  Future<Book?> fetchBookByWorkKey(String workKey);

  /// Searches books remotely by title, author, ISBN, or free-text query.
  ///
  /// Throws an [AppException] on network, server, or parsing failures.
  Future<List<Book>> searchBooks(String query, {int page = 1, int limit = 20});
}
