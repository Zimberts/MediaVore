import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/books/data/datasources/book_remote_data_source.dart';
import 'package:mediavore/features/books/data/repositories/book_repository_impl.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mocktail/mocktail.dart';

class _MockBookRemoteDataSource extends Mock implements BookRemoteDataSource {}

void main() {
  late BookRepositoryImpl repository;
  late _MockBookRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = _MockBookRemoteDataSource();
    repository = BookRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const tBook = Book(
    isbn: '9780441172719',
    openLibraryKey: '/works/OL893415W',
    title: 'Dune',
    authors: ['Frank Herbert'],
  );

  group('BookRepositoryImpl', () {
    test('should delegate fetchBookByIsbn to remote data source', () async {
      when(
        () => mockRemoteDataSource.fetchBookByIsbn('9780441172719'),
      ).thenAnswer((_) async => tBook);

      final result = await repository.fetchBookByIsbn('9780441172719');

      expect(result, tBook);
      verify(
        () => mockRemoteDataSource.fetchBookByIsbn('9780441172719'),
      ).called(1);
    });

    test('should delegate fetchBookByWorkKey to remote data source', () async {
      when(
        () => mockRemoteDataSource.fetchBookByWorkKey('/works/OL893415W'),
      ).thenAnswer((_) async => tBook);

      final result = await repository.fetchBookByWorkKey('/works/OL893415W');

      expect(result, tBook);
      verify(
        () => mockRemoteDataSource.fetchBookByWorkKey('/works/OL893415W'),
      ).called(1);
    });

    test('should delegate searchBooks to remote data source', () async {
      when(
        () => mockRemoteDataSource.searchBooks('Dune', page: 2, limit: 15),
      ).thenAnswer((_) async => [tBook]);

      final result = await repository.searchBooks('Dune', page: 2, limit: 15);

      expect(result, [tBook]);
      verify(
        () => mockRemoteDataSource.searchBooks('Dune', page: 2, limit: 15),
      ).called(1);
    });
  });
}
