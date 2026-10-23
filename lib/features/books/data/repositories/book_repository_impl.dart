import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/books/data/datasources/book_local_data_source.dart';
import 'package:mediavore/features/books/data/datasources/book_remote_data_source.dart';
import 'package:mediavore/features/books/data/models/book_model.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/domain/repositories/book_repository.dart';

@LazySingleton(as: BookRepository)
class BookRepositoryImpl implements BookRepository {
  final BookLocalDataSource localDataSource;
  final BookRemoteDataSource remoteDataSource;

  BookRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  // ── Mapping helpers ──

  Book _modelToEntity(BookModel model) {
    return Book(
      isbn: model.isbn,
      title: model.title,
      authors: model.authors,
      coverUrl: model.coverUrl,
      publisher: model.publisher,
      publishYear: model.publishYear,
      pageCount: model.pageCount,
      description: model.description,
      dateAdded: model.dateAdded,
      readStatus: ReadStatus.fromIndex(model.readStatus),
      readDate: model.readDate,
    );
  }

  BookModel _entityToModel(Book book) {
    return BookModel(
      isbn: book.isbn,
      title: book.title,
      authors: book.authors,
      coverUrl: book.coverUrl,
      publisher: book.publisher,
      publishYear: book.publishYear,
      pageCount: book.pageCount,
      description: book.description,
      dateAdded: book.dateAdded,
      readStatus: book.readStatus.index,
      readDate: book.readDate,
    );
  }

  // ── Books ──

  @override
  Future<List<Book>> getAllBooks() async {
    final models = await localDataSource.getAllBooks();
    return models.map(_modelToEntity).toList();
  }

  @override
  Future<Book?> getBookByIsbn(String isbn) async {
    final model = await localDataSource.getBookByIsbn(isbn);
    return model != null ? _modelToEntity(model) : null;
  }

  @override
  Future<void> addBook(Book book) async {
    await localDataSource.saveBook(_entityToModel(book));
  }

  @override
  Future<void> deleteBook(String isbn) async {
    await localDataSource.deleteBook(isbn);
  }

  @override
  Future<void> updateReadStatus(String isbn, ReadStatus status) async {
    final readDate = status == ReadStatus.read ? DateTime.now() : null;
    await localDataSource.updateReadStatus(isbn, status.index, readDate);
  }

  @override
  Future<List<Book>> getBooksByReadStatus(ReadStatus status) async {
    final models = await localDataSource.getBooksByReadStatus(status.index);
    return models.map(_modelToEntity).toList();
  }

  @override
  Future<List<Book>> searchLocalBooks(String query) async {
    final models = await localDataSource.searchBooks(query);
    return models.map(_modelToEntity).toList();
  }

  @override
  Future<Book?> fetchBookByIsbn(String isbn) async {
    try {
      final model = await remoteDataSource.fetchBookByIsbn(isbn);
      return model != null ? _modelToEntity(model) : null;
    } catch (e) {
      debugPrint('[BookRepo] Error fetching book by ISBN: $e');
      return null;
    }
  }

  @override
  Future<List<Book>> searchRemoteBooks(String query) async {
    try {
      final models = await remoteDataSource.searchBooks(query);
      return models.map(_modelToEntity).toList();
    } catch (e) {
      debugPrint('[BookRepo] Error searching remote books: $e');
      return [];
    }
  }

  // ── Book Lists ──

  @override
  Future<void> createList(String name) async {
    await localDataSource.createList(name);
  }

  @override
  Future<void> deleteList(String name) async {
    await localDataSource.deleteList(name);
  }

  @override
  Future<List<BookList>> getAllLists() async {
    final models = await localDataSource.getAllLists();
    final lists = <BookList>[];
    for (final model in models) {
      final count = await localDataSource.getListItemCount(model.name);
      lists.add(BookList(
        name: model.name,
        dateCreated: model.dateCreated,
        itemCount: count,
      ));
    }
    return lists;
  }

  @override
  Future<void> addBookToList(String isbn, String listName) async {
    await localDataSource.addBookToList(isbn, listName);
  }

  @override
  Future<void> removeBookFromList(String isbn, String listName) async {
    await localDataSource.removeBookFromList(isbn, listName);
  }

  @override
  Future<List<Book>> getListBooks(String listName) async {
    final models = await localDataSource.getListBooks(listName);
    return models.map(_modelToEntity).toList();
  }

  @override
  Future<bool> isBookInList(String isbn, String listName) async {
    return await localDataSource.isBookInList(isbn, listName);
  }

  @override
  Future<List<String>> getListsForBook(String isbn) async {
    return await localDataSource.getListsForBook(isbn);
  }

  @override
  Future<int> getBookCount() async {
    return await localDataSource.getBookCount();
  }

  @override
  Future<int> getListItemCount(String listName) async {
    return await localDataSource.getListItemCount(listName);
  }
}
