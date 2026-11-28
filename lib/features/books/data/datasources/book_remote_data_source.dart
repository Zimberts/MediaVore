import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/network/dio_error_mapper.dart';
import 'package:mediavore/core/utils/json_maps.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';

/// Fetches book metadata from the Open Library API.
@lazySingleton
class BookRemoteDataSource {
  static const String _baseUrl = 'https://openlibrary.org';
  static const String _coversBaseUrl = 'https://covers.openlibrary.org';

  final Dio dio;

  BookRemoteDataSource(this.dio);

  /// Strips hyphens and whitespace from [raw] ISBN strings.
  static String normalizeIsbn(String raw) =>
      raw.replaceAll(RegExp(r'[-\s]'), '').trim();

  /// Builds a cover image URL from an ISBN.
  static String coverUrlFromIsbn(String isbn) =>
      '$_coversBaseUrl/b/isbn/$isbn-L.jpg';

  /// Builds a cover image URL from an Open Library cover ID.
  static String coverUrlFromId(int coverId) =>
      '$_coversBaseUrl/b/id/$coverId-L.jpg';

  /// Extracts the first four-digit year from a date string, if any.
  @visibleForTesting
  static int? parseYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final match = RegExp(r'\d{4}').firstMatch(dateStr);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  /// Extracts a description string from either a raw [String] or an
  /// Open Library `{"value": "..."}` object.
  @visibleForTesting
  static String? parseDescription(Object? raw) {
    if (raw is String) return raw;
    final map = jsonObject(raw);
    final value = map?['value'];
    return value is String ? value : null;
  }

  /// Looks up a book by its ISBN (10 or 13 digit) using Open Library.
  ///
  /// Tries `/api/books.json` first and falls back to `/isbn/<isbn>.json` when
  /// the primary endpoint has no entry for [isbn]. Returns `null` when [isbn]
  /// is empty or Open Library reports no matching book.
  ///
  /// Throws an [AppException] on network, server (except 404), or parsing
  /// failures.
  Future<Book?> fetchBookByIsbn(String isbn) async {
    final normalized = normalizeIsbn(isbn);
    if (normalized.isEmpty) return null;

    return guardDioRequest('fetching book by ISBN', () async {
      final response = await dio.get<dynamic>(
        '$_baseUrl/api/books.json',
        queryParameters: {
          'bibkeys': 'ISBN:$normalized',
          'format': 'json',
          'jscmd': 'data',
        },
      );

      final data = jsonObject(response.data);
      if (data == null) {
        throw const ParsingException(
          'Expected JSON object from Open Library books API',
        );
      }

      final key = 'ISBN:$normalized';
      final bookData = jsonObject(data[key]);
      if (bookData == null) {
        return _fetchFromEditionsApi(normalized);
      }

      final authors = <String>[];
      final authorKeys = <String>[];
      for (final author in jsonObjectList(bookData['authors'])) {
        final name = author['name'];
        if (name is String && name.isNotEmpty) {
          authors.add(name);
        }
        final url = author['url'];
        if (url is String) {
          final extracted = _extractKeyFromUrl(url, 'authors');
          if (extracted != null) authorKeys.add(extracted);
        }
      }

      String? coverUrl;
      final cover = jsonObject(bookData['cover']);
      if (cover != null) {
        final candidate = cover['large'] ?? cover['medium'] ?? cover['small'];
        if (candidate is String && candidate.isNotEmpty) {
          coverUrl = candidate;
        }
      }
      coverUrl ??= coverUrlFromIsbn(normalized);

      String? publisher;
      final publishers = jsonObjectList(bookData['publishers']);
      if (publishers.isNotEmpty) {
        final name = publishers.first['name'];
        if (name is String && name.isNotEmpty) {
          publisher = name;
        }
      }

      final subjects = <String>[];
      for (final subject in jsonObjectList(bookData['subjects'])) {
        final name = subject['name'];
        if (name is String && name.isNotEmpty) {
          subjects.add(name);
        }
      }

      final editionDetails = await _fetchEditionDetails(normalized);

      return Book(
        isbn: normalized,
        openLibraryKey:
            editionDetails.workKey ??
            _extractKeyFromUrl(bookData['url'] as String?, 'books'),
        title: (bookData['title'] as String?) ?? '',
        authors: authors,
        authorKeys: authorKeys,
        coverUrl: coverUrl,
        publisher: publisher,
        publishYear: parseYear(bookData['publish_date'] as String?),
        pageCount: (bookData['number_of_pages'] as num?)?.toInt(),
        description: editionDetails.description,
        subjects: subjects,
      );
    });
  }

  /// Fetches book metadata for an Open Library work key (e.g. `/works/OL45804W`).
  ///
  /// Returns `null` when [workKey] is empty or the work returns HTTP 404.
  /// Throws an [AppException] on network, server, or parsing failures.
  Future<Book?> fetchBookByWorkKey(String workKey) async {
    final normalizedKey = _normalizeWorkKey(workKey);
    if (normalizedKey == null) return null;

    return guardDioRequest('fetching book work details', () async {
      final data = await _getJsonOrNullOn404('$_baseUrl$normalizedKey.json');
      if (data == null) return null;

      final authors = <String>[];
      final authorKeys = <String>[];
      for (final entry in jsonObjectList(data['authors'])) {
        final authorRef = jsonObject(entry['author']);
        final authorKey = authorRef?['key'];
        if (authorKey is String && authorKey.isNotEmpty) {
          authorKeys.add(authorKey);
          final name = await _fetchAuthorName(authorKey);
          if (name != null) authors.add(name);
        }
      }

      String? coverUrl;
      final covers = data['covers'];
      if (covers is List) {
        for (final id in covers) {
          if (id is int && id > 0) {
            coverUrl = coverUrlFromId(id);
            break;
          }
        }
      }

      final subjects = _extractStringList(data['subjects']);

      return Book(
        openLibraryKey: normalizedKey,
        title: (data['title'] as String?) ?? '',
        authors: authors,
        authorKeys: authorKeys,
        coverUrl: coverUrl,
        publishYear: parseYear(data['first_publish_date'] as String?),
        description: parseDescription(data['description']),
        subjects: subjects,
      );
    });
  }

  /// Searches books by title, author, or general query on Open Library.
  ///
  /// Returns an empty list immediately when [query] is blank.
  /// Throws an [AppException] on network, server, or parsing failures.
  Future<List<Book>> searchBooks(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    return guardDioRequest('searching books', () async {
      final response = await dio.get<dynamic>(
        '$_baseUrl/search.json',
        queryParameters: {
          'q': trimmed,
          'page': page,
          'limit': limit,
          'fields':
              'key,title,author_name,author_key,isbn,cover_i,publisher,'
              'first_publish_year,number_of_pages_median,subject,language',
        },
      );

      final data = jsonObject(response.data);
      if (data == null) {
        throw const ParsingException(
          'Expected JSON object from Open Library search API',
        );
      }

      final docs = jsonObjectList(data['docs']);
      final books = <Book>[];

      for (final doc in docs) {
        final title = doc['title'];
        if (title is! String || title.isEmpty) continue;

        final isbn = _pickPreferredIsbn(doc['isbn']);
        final openLibraryKey = doc['key'] as String?;
        if (isbn == null && openLibraryKey == null) continue;

        final authors = _extractStringList(doc['author_name']);
        final authorKeys = [
          for (final key in _extractStringList(doc['author_key']))
            key.startsWith('/authors/') ? key : '/authors/$key',
        ];

        final coverId = (doc['cover_i'] as num?)?.toInt();
        String? coverUrl;
        if (coverId != null && coverId > 0) {
          coverUrl = coverUrlFromId(coverId);
        } else if (isbn != null) {
          coverUrl = coverUrlFromIsbn(isbn);
        }

        final publishers = _extractStringList(doc['publisher']);
        final languages = _extractStringList(doc['language']);

        books.add(
          Book(
            isbn: isbn,
            openLibraryKey: openLibraryKey,
            title: title,
            authors: authors,
            authorKeys: authorKeys,
            coverUrl: coverUrl,
            publisher: publishers.isNotEmpty ? publishers.first : null,
            publishYear: (doc['first_publish_year'] as num?)?.toInt(),
            pageCount: (doc['number_of_pages_median'] as num?)?.toInt(),
            subjects: _extractStringList(doc['subject']),
            language: languages.isNotEmpty ? languages.first : null,
          ),
        );
      }

      return books;
    });
  }

  Future<Book?> _fetchFromEditionsApi(String isbn) async {
    final data = await _getJsonOrNullOn404('$_baseUrl/isbn/$isbn.json');
    if (data == null) return null;

    final authors = <String>[];
    final authorKeys = <String>[];
    for (final authorRef in jsonObjectList(data['authors'])) {
      final key = authorRef['key'];
      if (key is String && key.isNotEmpty) {
        authorKeys.add(key);
        final name = await _fetchAuthorName(key);
        if (name != null) authors.add(name);
      }
    }

    String? coverUrl;
    final covers = data['covers'];
    if (covers is List) {
      for (final id in covers) {
        if (id is int && id > 0) {
          coverUrl = coverUrlFromId(id);
          break;
        }
      }
    }
    coverUrl ??= coverUrlFromIsbn(isbn);

    final publishers = _extractStringList(data['publishers']);
    final works = jsonObjectList(data['works']);
    final workKey = works.isNotEmpty ? works.first['key'] as String? : null;

    var description = parseDescription(data['description']);
    if (description == null && workKey != null) {
      description = await _fetchWorkDescription(workKey);
    }

    return Book(
      isbn: isbn,
      openLibraryKey: workKey ?? (data['key'] as String?),
      title: (data['title'] as String?) ?? '',
      authors: authors,
      authorKeys: authorKeys,
      coverUrl: coverUrl,
      publisher: publishers.isNotEmpty ? publishers.first : null,
      publishYear: parseYear(data['publish_date'] as String?),
      pageCount: (data['number_of_pages'] as num?)?.toInt(),
      description: description,
      subjects: _extractStringList(data['subjects']),
    );
  }

  Future<({String? description, String? workKey})> _fetchEditionDetails(
    String isbn,
  ) async {
    try {
      final data = await _getJsonOrNullOn404('$_baseUrl/isbn/$isbn.json');
      if (data == null) return (description: null, workKey: null);

      final works = jsonObjectList(data['works']);
      final workKey = works.isNotEmpty ? works.first['key'] as String? : null;

      var description = parseDescription(data['description']);
      if (description == null && workKey != null) {
        description = await _fetchWorkDescription(workKey);
      }
      return (description: description, workKey: workKey);
    } on DioException {
      // Description enrichment is best-effort after a successful primary fetch.
      return (description: null, workKey: null);
    } on AppException {
      return (description: null, workKey: null);
    }
  }

  Future<String?> _fetchWorkDescription(String workKey) async {
    try {
      final workData = await _getJsonOrNullOn404('$_baseUrl$workKey.json');
      return parseDescription(workData?['description']);
    } on DioException {
      return null;
    } on AppException {
      return null;
    }
  }

  Future<String?> _fetchAuthorName(String authorKey) async {
    try {
      final data = await _getJsonOrNullOn404('$_baseUrl$authorKey.json');
      final name = data?['name'];
      return name is String && name.isNotEmpty ? name : null;
    } on DioException {
      return null;
    } on AppException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getJsonOrNullOn404(String url) async {
    try {
      final response = await dio.get<dynamic>(url);
      final data = jsonObject(response.data);
      if (data == null) {
        throw ParsingException('Expected JSON object from $url');
      }
      return data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  static String? _pickPreferredIsbn(Object? rawIsbns) {
    if (rawIsbns is! List || rawIsbns.isEmpty) return null;
    String? fallback;
    for (final entry in rawIsbns) {
      final value = entry?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      fallback ??= value;
      if (value.length == 13) return value;
    }
    return fallback;
  }

  static List<String> _extractStringList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.isNotEmpty) item,
    ];
  }

  static String? _normalizeWorkKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static String? _extractKeyFromUrl(String? url, String segment) {
    if (url == null || url.isEmpty) return null;
    final match = RegExp('/$segment/([^/]+)').firstMatch(url);
    if (match == null) return null;
    return '/$segment/${match.group(1)}';
  }
}
