import 'package:injectable/injectable.dart';
import 'package:mediavore/features/books/data/datasources/book_remote_data_source.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/domain/repositories/book_repository.dart';

/// Remote-backed implementation of [BookRepository].
@LazySingleton(as: BookRepository)
class BookRepositoryImpl implements BookRepository {
  final BookRemoteDataSource remoteDataSource;

  BookRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Book?> fetchBookByIsbn(String isbn) =>
      remoteDataSource.fetchBookByIsbn(isbn);

  @override
  Future<Book?> fetchBookByWorkKey(String workKey) =>
      remoteDataSource.fetchBookByWorkKey(workKey);

  @override
  Future<List<Book>> searchBooks(
    String query, {
    int page = 1,
    int limit = 20,
  }) => remoteDataSource.searchBooks(query, page: page, limit: limit);
}
