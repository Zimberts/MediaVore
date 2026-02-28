import 'package:mediavore/features/books/domain/entities/book.dart';

/// Abstract repository for book library operations.
abstract class BookRepository {
  // ── Books ──

  /// Get all books in the library.
  Future<List<Book>> getAllBooks();

  /// Get a book by its ISBN.
  Future<Book?> getBookByIsbn(String isbn);

  /// Add a book to the library.
  Future<void> addBook(Book book);

  /// Delete a book from the library.
  Future<void> deleteBook(String isbn);

  /// Update the read status of a book.
  Future<void> updateReadStatus(String isbn, ReadStatus status);

  /// Get books filtered by read status.
  Future<List<Book>> getBooksByReadStatus(ReadStatus status);

  /// Search books in local library.
  Future<List<Book>> searchLocalBooks(String query);

  /// Fetch book info from remote API by ISBN (for barcode scanning).
  Future<Book?> fetchBookByIsbn(String isbn);

  /// Search books remotely by title/author.
  Future<List<Book>> searchRemoteBooks(String query);

  // ── Book Lists ──

  /// Create a new book list.
  Future<void> createList(String name);

  /// Delete a book list.
  Future<void> deleteList(String name);

  /// Get all book lists.
  Future<List<BookList>> getAllLists();

  /// Add a book to a list.
  Future<void> addBookToList(String isbn, String listName);

  /// Remove a book from a list.
  Future<void> removeBookFromList(String isbn, String listName);

  /// Get all books in a specific list.
  Future<List<Book>> getListBooks(String listName);

  /// Check if a book is in a specific list.
  Future<bool> isBookInList(String isbn, String listName);

  /// Get all lists a book belongs to.
  Future<List<String>> getListsForBook(String isbn);

  /// Get total book count in the library.
  Future<int> getBookCount();

  /// Get item count in a specific list.
  Future<int> getListItemCount(String listName);
}

/// Represents a named book list.
class BookList {
  final String name;
  final DateTime dateCreated;
  final int itemCount;

  const BookList({
    required this.name,
    required this.dateCreated,
    this.itemCount = 0,
  });
}
