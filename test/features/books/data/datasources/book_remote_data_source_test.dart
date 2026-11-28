import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/features/books/data/datasources/book_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late BookRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = BookRemoteDataSource(mockDio);
  });

  Response<dynamic> okResponse(Object? data, {int statusCode = 200}) =>
      Response<dynamic>(
        requestOptions: RequestOptions(),
        data: data,
        statusCode: statusCode,
      );

  DioException httpError(int statusCode) => DioException(
    requestOptions: RequestOptions(),
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: RequestOptions(),
      statusCode: statusCode,
    ),
  );

  group('helpers', () {
    test('should normalize ISBN by stripping hyphens and whitespace', () {
      expect(
        BookRemoteDataSource.normalizeIsbn(' 978-0-14-032872-1 '),
        '9780140328721',
      );
    });

    test('should extract four-digit year from date strings', () {
      expect(BookRemoteDataSource.parseYear('October 1988'), 1988);
      expect(BookRemoteDataSource.parseYear('2023-05-01'), 2023);
      expect(BookRemoteDataSource.parseYear('unknown'), isNull);
      expect(BookRemoteDataSource.parseYear(null), isNull);
    });

    test('should parse description from string or Open Library map', () {
      expect(BookRemoteDataSource.parseDescription('Plain text'), 'Plain text');
      expect(
        BookRemoteDataSource.parseDescription({'value': 'Map description'}),
        'Map description',
      );
      expect(BookRemoteDataSource.parseDescription(123), isNull);
    });
  });

  group('fetchBookByIsbn', () {
    const isbn = '978-0-14-032872-1';
    const normalized = '9780140328721';

    test(
      'should return null without network call when ISBN is empty',
      () async {
        final result = await dataSource.fetchBookByIsbn('  --- ');
        expect(result, isNull);
        verifyNever(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        );
      },
    );

    test(
      'should parse book from primary /api/books.json and enrich description from work',
      () async {
        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/api/books.json',
            queryParameters: {
              'bibkeys': 'ISBN:$normalized',
              'format': 'json',
              'jscmd': 'data',
            },
          ),
        ).thenAnswer(
          (_) async => okResponse({
            'ISBN:$normalized': {
              'url': 'https://openlibrary.org/books/OL123M/Fantastic_Mr_Fox',
              'title': 'Fantastic Mr. Fox',
              'authors': [
                {
                  'name': 'Roald Dahl',
                  'url': 'https://openlibrary.org/authors/OL34184A/Roald_Dahl',
                },
              ],
              'cover': {
                'small': 'https://covers.openlibrary.org/b/id/1-S.jpg',
                'large': 'https://covers.openlibrary.org/b/id/1-L.jpg',
              },
              'publishers': [
                {'name': 'Puffin Books'},
              ],
              'publish_date': '1988',
              'number_of_pages': 96,
              'subjects': [
                {'name': 'Foxes'},
                {'name': 'Juvenile Fiction'},
              ],
            },
          }),
        );

        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/isbn/$normalized.json',
          ),
        ).thenAnswer(
          (_) async => okResponse({
            'works': [
              {'key': '/works/OL45804W'},
            ],
          }),
        );

        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/works/OL45804W.json',
          ),
        ).thenAnswer(
          (_) async => okResponse({
            'description': {'value': 'Three mean farmers hunt a clever fox.'},
          }),
        );

        final book = await dataSource.fetchBookByIsbn(isbn);

        expect(book, isNotNull);
        expect(book!.isbn, normalized);
        expect(book.openLibraryKey, '/works/OL45804W');
        expect(book.title, 'Fantastic Mr. Fox');
        expect(book.authors, ['Roald Dahl']);
        expect(book.authorKeys, ['/authors/OL34184A']);
        expect(book.coverUrl, 'https://covers.openlibrary.org/b/id/1-L.jpg');
        expect(book.publisher, 'Puffin Books');
        expect(book.publishYear, 1988);
        expect(book.pageCount, 96);
        expect(book.description, 'Three mean farmers hunt a clever fox.');
        expect(book.subjects, ['Foxes', 'Juvenile Fiction']);
      },
    );

    test(
      'should fall back to /isbn/<isbn>.json when primary response omits ISBN',
      () async {
        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/api/books.json',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => okResponse(<String, dynamic>{}));

        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/isbn/$normalized.json',
          ),
        ).thenAnswer(
          (_) async => okResponse({
            'title': 'Dune',
            'authors': [
              {'key': '/authors/OL79034A'},
            ],
            'covers': [42],
            'publishers': ['Chilton Books'],
            'publish_date': 'August 1965',
            'number_of_pages': 412,
            'description': 'Arrakis, the desert planet.',
            'works': [
              {'key': '/works/OL893415W'},
            ],
          }),
        );

        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/authors/OL79034A.json',
          ),
        ).thenAnswer((_) async => okResponse({'name': 'Frank Herbert'}));

        final book = await dataSource.fetchBookByIsbn(normalized);

        expect(book, isNotNull);
        expect(book!.title, 'Dune');
        expect(book.authors, ['Frank Herbert']);
        expect(book.authorKeys, ['/authors/OL79034A']);
        expect(book.coverUrl, 'https://covers.openlibrary.org/b/id/42-L.jpg');
        expect(book.publisher, 'Chilton Books');
        expect(book.publishYear, 1965);
        expect(book.pageCount, 412);
        expect(book.description, 'Arrakis, the desert planet.');
        expect(book.openLibraryKey, '/works/OL893415W');
      },
    );

    test(
      'should return null when primary omits ISBN and editions returns 404',
      () async {
        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/api/books.json',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => okResponse(<String, dynamic>{}));

        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/isbn/$normalized.json',
          ),
        ).thenThrow(httpError(404));

        final book = await dataSource.fetchBookByIsbn(normalized);
        expect(book, isNull);
      },
    );

    test('should throw NetworkException on connection timeout', () async {
      when(
        () => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await expectLater(
        dataSource.fetchBookByIsbn(normalized),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw ServerException on 500 response', () async {
      when(
        () => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(httpError(500));

      await expectLater(
        dataSource.fetchBookByIsbn(normalized),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test(
      'should throw ParsingException when response payload is not a JSON object',
      () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => okResponse('not a map'));

        await expectLater(
          dataSource.fetchBookByIsbn(normalized),
          throwsA(isA<ParsingException>()),
        );
      },
    );
  });

  group('fetchBookByWorkKey', () {
    test('should return null when work key is blank or 404', () async {
      expect(await dataSource.fetchBookByWorkKey('   '), isNull);

      when(
        () => mockDio.get<dynamic>('https://openlibrary.org/works/OL999W.json'),
      ).thenThrow(httpError(404));

      expect(await dataSource.fetchBookByWorkKey('works/OL999W'), isNull);
    });

    test('should parse work details and resolve author names', () async {
      when(
        () =>
            mockDio.get<dynamic>('https://openlibrary.org/works/OL45804W.json'),
      ).thenAnswer(
        (_) async => okResponse({
          'title': 'Fantastic Mr. Fox',
          'description': 'A clever fox story.',
          'first_publish_date': '1970',
          'covers': [-1, 555],
          'subjects': ['Foxes', 'Children'],
          'authors': [
            {
              'author': {'key': '/authors/OL34184A'},
            },
          ],
        }),
      );

      when(
        () => mockDio.get<dynamic>(
          'https://openlibrary.org/authors/OL34184A.json',
        ),
      ).thenAnswer((_) async => okResponse({'name': 'Roald Dahl'}));

      final book = await dataSource.fetchBookByWorkKey('/works/OL45804W');

      expect(book, isNotNull);
      expect(book!.openLibraryKey, '/works/OL45804W');
      expect(book.title, 'Fantastic Mr. Fox');
      expect(book.authors, ['Roald Dahl']);
      expect(book.authorKeys, ['/authors/OL34184A']);
      expect(book.coverUrl, 'https://covers.openlibrary.org/b/id/555-L.jpg');
      expect(book.publishYear, 1970);
      expect(book.description, 'A clever fox story.');
      expect(book.subjects, ['Foxes', 'Children']);
    });
  });

  group('searchBooks', () {
    test(
      'should return empty list without network call for blank query',
      () async {
        final result = await dataSource.searchBooks('   ');
        expect(result, isEmpty);
        verifyNever(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        );
      },
    );

    test(
      'should parse search docs, prefer ISBN-13, and fall back to ISBN cover',
      () async {
        when(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/search.json',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => okResponse({
            'docs': [
              {
                'key': '/works/OL893415W',
                'title': 'Dune',
                'author_name': ['Frank Herbert'],
                'author_key': ['OL79034A'],
                'isbn': ['0441172717', '9780441172719'],
                'cover_i': 12345,
                'publisher': ['Ace Books'],
                'first_publish_year': 1965,
                'number_of_pages_median': 535,
                'subject': ['Science Fiction'],
                'language': ['eng'],
              },
              {
                'key': '/works/OL111W',
                'title': 'No Cover Id Book',
                'author_name': ['Jane Doe'],
                'isbn': ['1234567890'],
              },
              {
                // Missing both isbn and key -> skipped
                'title': 'Orphan Book',
              },
            ],
          }),
        );

        final results = await dataSource.searchBooks(
          'Dune',
          page: 2,
          limit: 10,
        );

        verify(
          () => mockDio.get<dynamic>(
            'https://openlibrary.org/search.json',
            queryParameters: {
              'q': 'Dune',
              'page': 2,
              'limit': 10,
              'fields':
                  'key,title,author_name,author_key,isbn,cover_i,publisher,'
                  'first_publish_year,number_of_pages_median,subject,language',
            },
          ),
        ).called(1);

        expect(results, hasLength(2));
        expect(results[0].isbn, '9780441172719');
        expect(results[0].openLibraryKey, '/works/OL893415W');
        expect(results[0].authors, ['Frank Herbert']);
        expect(results[0].authorKeys, ['/authors/OL79034A']);
        expect(
          results[0].coverUrl,
          'https://covers.openlibrary.org/b/id/12345-L.jpg',
        );
        expect(results[0].publisher, 'Ace Books');
        expect(results[0].publishYear, 1965);
        expect(results[0].pageCount, 535);
        expect(results[0].subjects, ['Science Fiction']);
        expect(results[0].language, 'eng');

        expect(results[1].isbn, '1234567890');
        expect(
          results[1].coverUrl,
          'https://covers.openlibrary.org/b/isbn/1234567890-L.jpg',
        );
      },
    );

    test('should throw NetworkException when search fails offline', () async {
      when(
        () => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        dataSource.searchBooks('Dune'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
