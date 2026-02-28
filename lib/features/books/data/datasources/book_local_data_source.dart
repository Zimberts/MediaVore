import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/books/data/models/book_model.dart';
import 'package:mediavore/features/books/data/models/book_list_model.dart';
import 'package:mediavore/features/books/data/models/book_list_item_model.dart';

@lazySingleton
class BookLocalDataSource {
  final Isar _isar;

  BookLocalDataSource(this._isar);

  // ── Books ──

  Future<void> saveBook(BookModel book) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.bookModels
          .filter()
          .isbnEqualTo(book.isbn)
          .findFirst();
      if (existing != null) {
        book.isarId = existing.isarId;
      }
      await _isar.bookModels.put(book);
    });
  }

  Future<List<BookModel>> getAllBooks() async {
    return await _isar.bookModels.where().sortByDateAddedDesc().findAll();
  }

  Future<BookModel?> getBookByIsbn(String isbn) async {
    return await _isar.bookModels.filter().isbnEqualTo(isbn).findFirst();
  }

  Future<void> deleteBook(String isbn) async {
    await _isar.writeTxn(() async {
      // Remove from all lists first
      await _isar.bookListItemModels.filter().isbnEqualTo(isbn).deleteAll();
      // Remove the book itself
      await _isar.bookModels.filter().isbnEqualTo(isbn).deleteAll();
    });
  }

  Future<void> updateReadStatus(String isbn, int readStatus, DateTime? readDate) async {
    await _isar.writeTxn(() async {
      final book = await _isar.bookModels.filter().isbnEqualTo(isbn).findFirst();
      if (book != null) {
        book.readStatus = readStatus;
        // We need to create a new BookModel with updated readDate since it's final
        final updated = BookModel(
          isbn: book.isbn,
          title: book.title,
          authors: book.authors,
          coverUrl: book.coverUrl,
          publisher: book.publisher,
          publishYear: book.publishYear,
          pageCount: book.pageCount,
          description: book.description,
          dateAdded: book.dateAdded,
          readStatus: readStatus,
          readDate: readDate,
        );
        updated.isarId = book.isarId;
        await _isar.bookModels.put(updated);
      }
    });
  }

  Future<List<BookModel>> getBooksByReadStatus(int readStatus) async {
    return await _isar.bookModels
        .filter()
        .readStatusEqualTo(readStatus)
        .sortByDateAddedDesc()
        .findAll();
  }

  Future<List<BookModel>> searchBooks(String query) async {
    final lowerQuery = query.toLowerCase();
    final allBooks = await _isar.bookModels.where().findAll();
    return allBooks.where((book) {
      return book.title.toLowerCase().contains(lowerQuery) ||
          book.authors.any((a) => a.toLowerCase().contains(lowerQuery)) ||
          book.isbn.contains(lowerQuery);
    }).toList();
  }

  // ── Book Lists ──

  Future<void> createList(String name) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.bookListModels
          .filter()
          .nameEqualTo(name)
          .findFirst();
      if (existing == null) {
        await _isar.bookListModels.put(
          BookListModel(name: name, dateCreated: DateTime.now()),
        );
      }
    });
  }

  Future<void> deleteList(String name) async {
    await _isar.writeTxn(() async {
      await _isar.bookListItemModels.filter().listNameEqualTo(name).deleteAll();
      await _isar.bookListModels.filter().nameEqualTo(name).deleteAll();
    });
  }

  Future<List<BookListModel>> getAllLists() async {
    return await _isar.bookListModels.where().sortByDateCreated().findAll();
  }

  Future<void> addBookToList(String isbn, String listName) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.bookListItemModels
          .filter()
          .isbnEqualTo(isbn)
          .listNameEqualTo(listName)
          .findFirst();
      if (existing == null) {
        final count = await _isar.bookListItemModels
            .filter()
            .listNameEqualTo(listName)
            .count();
        await _isar.bookListItemModels.put(
          BookListItemModel(isbn: isbn, listName: listName, position: count),
        );
      }
    });
  }

  Future<void> removeBookFromList(String isbn, String listName) async {
    await _isar.writeTxn(() async {
      await _isar.bookListItemModels
          .filter()
          .isbnEqualTo(isbn)
          .listNameEqualTo(listName)
          .deleteAll();
    });
  }

  Future<List<String>> getListBookIsbns(String listName) async {
    final items = await _isar.bookListItemModels
        .filter()
        .listNameEqualTo(listName)
        .sortByPosition()
        .findAll();
    return items.map((item) => item.isbn).toList();
  }

  Future<List<BookModel>> getListBooks(String listName) async {
    final isbns = await getListBookIsbns(listName);
    final books = <BookModel>[];
    for (final isbn in isbns) {
      final book = await getBookByIsbn(isbn);
      if (book != null) books.add(book);
    }
    return books;
  }

  Future<bool> isBookInList(String isbn, String listName) async {
    final item = await _isar.bookListItemModels
        .filter()
        .isbnEqualTo(isbn)
        .listNameEqualTo(listName)
        .findFirst();
    return item != null;
  }

  Future<List<String>> getListsForBook(String isbn) async {
    final items = await _isar.bookListItemModels
        .filter()
        .isbnEqualTo(isbn)
        .findAll();
    return items.map((item) => item.listName).toList();
  }

  Future<void> updateListOrder(String listName, List<String> orderedIsbns) async {
    await _isar.writeTxn(() async {
      for (int i = 0; i < orderedIsbns.length; i++) {
        final item = await _isar.bookListItemModels
            .filter()
            .isbnEqualTo(orderedIsbns[i])
            .listNameEqualTo(listName)
            .findFirst();
        if (item != null) {
          item.position = i;
          await _isar.bookListItemModels.put(item);
        }
      }
    });
  }

  Future<int> getBookCount() async {
    return await _isar.bookModels.count();
  }

  Future<int> getListItemCount(String listName) async {
    return await _isar.bookListItemModels
        .filter()
        .listNameEqualTo(listName)
        .count();
  }
}
