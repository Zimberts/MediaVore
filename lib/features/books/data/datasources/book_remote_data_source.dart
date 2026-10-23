import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/books/data/models/book_model.dart';

/// Fetches book data from the Open Library API using ISBN.
@lazySingleton
class BookRemoteDataSource {
  final Dio _dio;

  BookRemoteDataSource(this._dio);

  /// Looks up a book by its ISBN (10 or 13 digit) using Open Library.
  Future<BookModel?> fetchBookByIsbn(String isbn) async {
    try {
      final response = await _dio.get(
        'https://openlibrary.org/api/books.json',
        queryParameters: {
          'bibkeys': 'ISBN:$isbn',
          'format': 'json',
          'jscmd': 'data',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final key = 'ISBN:$isbn';

      if (!data.containsKey(key)) return null;

      final bookData = data[key] as Map<String, dynamic>;

      final title = bookData['title'] as String? ?? 'Unknown';

      final authors = <String>[];
      if (bookData['authors'] != null) {
        for (final author in bookData['authors'] as List) {
          if (author is Map && author['name'] != null) {
            authors.add(author['name'] as String);
          }
        }
      }

      String? coverUrl;
      if (bookData['cover'] != null) {
        final cover = bookData['cover'] as Map<String, dynamic>;
        coverUrl = (cover['large'] ?? cover['medium'] ?? cover['small']) as String?;
      }
      // Fallback: generate cover URL from ISBN directly
      coverUrl ??= 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';

      final publishers = bookData['publishers'] as List?;
      String? publisher;
      if (publishers != null && publishers.isNotEmpty) {
        final pub = publishers.first;
        if (pub is Map && pub['name'] != null) {
          publisher = pub['name'] as String;
        }
      }

      int? publishYear;
      if (bookData['publish_date'] != null) {
        final dateStr = bookData['publish_date'] as String;
        final yearMatch = RegExp(r'\d{4}').firstMatch(dateStr);
        if (yearMatch != null) {
          publishYear = int.tryParse(yearMatch.group(0)!);
        }
      }

      int? pageCount;
      if (bookData['number_of_pages'] != null) {
        pageCount = bookData['number_of_pages'] as int?;
      }

      // Fetch additional details (description) from the works endpoint
      String? description;
      if (bookData['identifiers'] != null || bookData['key'] != null) {
        description = await _fetchDescription(isbn);
      }

      return BookModel(
        isbn: isbn,
        title: title,
        authors: authors.isEmpty ? ['Auteur inconnu'] : authors,
        coverUrl: coverUrl,
        publisher: publisher,
        publishYear: publishYear,
        pageCount: pageCount,
        description: description,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      // Try the editions API as fallback
      return _fetchFromEditionsApi(isbn);
    }
  }

  Future<String?> _fetchDescription(String isbn) async {
    try {
      final response = await _dio.get(
        'https://openlibrary.org/isbn/$isbn.json',
      );
      final data = response.data as Map<String, dynamic>;

      // Check for description in the edition
      if (data['description'] != null) {
        if (data['description'] is String) {
          return data['description'] as String;
        } else if (data['description'] is Map) {
          return (data['description'] as Map)['value'] as String?;
        }
      }

      // Try to get description from the work
      if (data['works'] != null && (data['works'] as List).isNotEmpty) {
        final workKey = (data['works'] as List).first['key'] as String;
        final workResponse = await _dio.get(
          'https://openlibrary.org$workKey.json',
        );
        final workData = workResponse.data as Map<String, dynamic>;

        if (workData['description'] != null) {
          if (workData['description'] is String) {
            return workData['description'] as String;
          } else if (workData['description'] is Map) {
            return (workData['description'] as Map)['value'] as String?;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<BookModel?> _fetchFromEditionsApi(String isbn) async {
    try {
      final response = await _dio.get(
        'https://openlibrary.org/isbn/$isbn.json',
      );
      final data = response.data as Map<String, dynamic>;

      final title = data['title'] as String? ?? 'Unknown';

      final authors = <String>[];
      if (data['authors'] != null) {
        for (final authorRef in data['authors'] as List) {
          if (authorRef is Map && authorRef['key'] != null) {
            try {
              final authorResponse = await _dio.get(
                'https://openlibrary.org${authorRef['key']}.json',
              );
              final authorData = authorResponse.data as Map<String, dynamic>;
              if (authorData['name'] != null) {
                authors.add(authorData['name'] as String);
              }
            } catch (_) {}
          }
        }
      }

      int? pageCount;
      if (data['number_of_pages'] != null) {
        pageCount = data['number_of_pages'] as int?;
      }

      String? coverUrl;
      if (data['covers'] != null && (data['covers'] as List).isNotEmpty) {
        coverUrl = 'https://covers.openlibrary.org/b/id/${(data['covers'] as List).first}-L.jpg';
      }
      // Fallback: generate cover URL from ISBN directly
      coverUrl ??= 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';

      String? publisher;
      if (data['publishers'] != null && (data['publishers'] as List).isNotEmpty) {
        publisher = (data['publishers'] as List).first as String;
      }

      int? publishYear;
      if (data['publish_date'] != null) {
        final dateStr = data['publish_date'] as String;
        final yearMatch = RegExp(r'\d{4}').firstMatch(dateStr);
        if (yearMatch != null) {
          publishYear = int.tryParse(yearMatch.group(0)!);
        }
      }

      String? description;
      if (data['description'] != null) {
        if (data['description'] is String) {
          description = data['description'] as String;
        } else if (data['description'] is Map) {
          description = (data['description'] as Map)['value'] as String?;
        }
      }

      return BookModel(
        isbn: isbn,
        title: title,
        authors: authors.isEmpty ? ['Auteur inconnu'] : authors,
        coverUrl: coverUrl,
        publisher: publisher,
        publishYear: publishYear,
        pageCount: pageCount,
        description: description,
        dateAdded: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Search books by title/author query using Open Library search API.
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      final response = await _dio.get(
        'https://openlibrary.org/search.json',
        queryParameters: {
          'q': query,
          'limit': 20,
          'fields': 'title,author_name,isbn,cover_i,publisher,first_publish_year,number_of_pages_median,key',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final docs = data['docs'] as List? ?? [];

      final books = <BookModel>[];
      for (final doc in docs) {
        final d = doc as Map<String, dynamic>;
        final isbns = d['isbn'] as List?;
        if (isbns == null || isbns.isEmpty) continue;

        // Pick the first ISBN-13 if available, otherwise first ISBN
        String isbn = isbns.first.toString();
        for (final i in isbns) {
          if (i.toString().length == 13) {
            isbn = i.toString();
            break;
          }
        }

        final authors = <String>[];
        if (d['author_name'] != null) {
          for (final a in d['author_name'] as List) {
            authors.add(a.toString());
          }
        }

        String? coverUrl;
        if (d['cover_i'] != null) {
          coverUrl = 'https://covers.openlibrary.org/b/id/${d['cover_i']}-L.jpg';
        }
        // Fallback: generate cover URL from ISBN directly
        coverUrl ??= 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';

        String? publisher;
        if (d['publisher'] != null && (d['publisher'] as List).isNotEmpty) {
          publisher = (d['publisher'] as List).first.toString();
        }

        books.add(BookModel(
          isbn: isbn,
          title: d['title'] as String? ?? 'Unknown',
          authors: authors.isEmpty ? ['Auteur inconnu'] : authors,
          coverUrl: coverUrl,
          publisher: publisher,
          publishYear: d['first_publish_year'] as int?,
          pageCount: d['number_of_pages_median'] as int?,
          dateAdded: DateTime.now(),
        ));
      }

      return books;
    } catch (_) {
      return [];
    }
  }
}
