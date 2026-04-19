import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/error/exceptions.dart';

/// Handles data fetching from the TMDB API.
@lazySingleton
class MediaRemoteDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  String get _apiCredential {
    final raw = (prefs.getString('tmdbApiKey') ?? '').trim();
    if (raw.toLowerCase().startsWith('bearer ')) {
      return raw.substring(7).trim();
    }
    return raw;
  }

  bool _isV3ApiKey(String credential) =>
      RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(credential);

  Future<Response<dynamic>> _tmdbGet(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) {
    final credential = _apiCredential;
    if (credential.isEmpty) {
      throw const ConfigurationException(
        'TMDB API credential is missing. Add a v3 API key or v4 read token in Settings.',
      );
    }

    final params = <String, dynamic>{...?queryParameters};
    final useV3ApiKey = _isV3ApiKey(credential);

    if (useV3ApiKey) {
      params['api_key'] = credential;
    }

    final options = useV3ApiKey
        ? null
        : Options(headers: {'Authorization': 'Bearer $credential'});

    return dio.get(
      url,
      queryParameters: params.isEmpty ? null : params,
      options: options,
    );
  }

  /// Creates a new instance of [MediaRemoteDataSource].
  ///
  /// Requires a [Dio] to make network requests and [SharedPreferences]
  /// that stores the TMDB credential under 'tmdbApiKey'.
  @factoryMethod
  factory MediaRemoteDataSource({required Dio dio, required SharedPreferences prefs}) {
    return MediaRemoteDataSource._internal(
      dio: dio,
      prefs: prefs,
    );
  }

  MediaRemoteDataSource._internal({required this.dio, required this.prefs});

  /// Searches for movies and series on the TMDB API, supporting optional filters.
  Future<List<MediaItem>> searchMedia(
    String query, {
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType? type,
  }) async {
    final path = (type == MediaType.tv) ? 'tv' : 'movie';
    try {
      final params = <String, dynamic>{'query': query, 'page': page};
      if (genreIds != null && genreIds.isNotEmpty) {
        params['with_genres'] = genreIds.join(',');
      }
      if (releaseYear != null) {
        if (type == MediaType.movie) {
          params['primary_release_year'] = releaseYear;
        } else {
          params['first_air_date_year'] = releaseYear;
        }
      }
      if (minRating != null) params['vote_average.gte'] = minRating;
      if (language != null) params['language'] = language;

      debugPrint('[Remote] searchMedia -> /search/$path params=$params');
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/search/$path',
        queryParameters: params,
      );

      final List results = response.data['results'];
      final mediaItems = results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();

      // Enrich items with full details to get number of seasons or runtime
      final enrichedItems = await Future.wait(
        mediaItems.map((item) async {
          try {
            return await getMediaItem(item.id, type: item.mediaType);
          } catch (_) {
            return item;
          }
        }),
      );

      return enrichedItems;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while searching', e);
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while searching',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load results', null, e);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to parse search response', e);
    }
  }

  /// Fetches the details for a single media item from the TMDB API.
  Future<MediaItem> getMediaItem(
    int id, {
    MediaType type = MediaType.movie,
  }) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await _tmdbGet('https://api.themoviedb.org/3/$path/$id');
      final data = Map<String, dynamic>.from(response.data);
      data['media_type'] = path;
      return MediaItem.fromJson(data);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while fetching details', e);
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while fetching details',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load details', null, e);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to parse response', e);
    }
  }

  /// Fetches the details for a TV season from the TMDB API.
  Future<Map<String, dynamic>> getSeasonDetails(
    int tvId,
    int seasonNumber,
  ) async {
    try {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/tv/$tvId/season/$seasonNumber',
      );
      return response.data;
    } on DioException catch (e) {
      throw ServerException(
        'Failed to load season details',
        e.response?.statusCode,
        e,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to parse season details', e);
    }
  }

  /// Fetches the credits for a single media item from the TMDB API.
  Future<Map<String, dynamic>> getMediaCredits(
    int id, {
    MediaType type = MediaType.movie,
  }) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/credits',
      );
      return response.data;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while fetching credits', e);
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while fetching credits',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load credits', null, e);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to parse credits response', e);
    }
  }

  /// Fetches the details for an actor from the TMDB API.
  Future<ActorDetails> getActorDetails(int actorId) async {
    try {
      final response = await _tmdbGet('https://api.themoviedb.org/3/person/$actorId');
      return ActorDetails.fromJson(response.data);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException(
            'Network error while fetching actor details',
            e,
          );
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while fetching actor details',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load actor details', null, e);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to parse actor details response', e);
    }
  }

  /// Discover movies or TV using TMDb discover endpoint.
  /// [mediaType] should be 'movie' or 'tv'.
  Future<List<MediaItem>> discover({
    required String mediaType,
    String? sortBy,
    int page = 1,
    int? year,
    String? withGenres,
    double? minRating,
    String? language,
  }) async {
    final path = mediaType == 'tv' ? 'tv' : 'movie';
    try {
      final params = <String, dynamic>{'page': page};
      if (sortBy != null) params['sort_by'] = sortBy;
      if (year != null) {
        if (mediaType == 'movie') {
          params['primary_release_year'] = year;
        } else {
          params['first_air_date_year'] = year;
        }
      }
      if (withGenres != null) params['with_genres'] = withGenres;
      if (minRating != null) params['vote_average.gte'] = minRating;
      if (language != null) params['language'] = language;

      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/discover/$path',
        queryParameters: params,
      );

      final List results = response.data['results'];
      final mediaItems = results
          .map((m) {
            final data = Map<String, dynamic>.from(m);
            if (data['media_type'] == null) data['media_type'] = path;
            return MediaItem.fromJson(data);
          })
          .where(
            (m) =>
                m.mediaType == MediaType.movie || m.mediaType == MediaType.tv,
          )
          .toList();

      // Try to enrich items similarly to searchMedia
      final enriched = await Future.wait(
        mediaItems.map((item) async {
          try {
            return await getMediaItem(item.id, type: item.mediaType);
          } catch (_) {
            return item;
          }
        }),
      );

      return enriched;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while discovering', e);
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while discovering',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to discover', null, e);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to parse discover response', e);
    }
  }

  /// Fetches the movies an actor has been in.
  Future<List<MediaItem>> getActorMediaCredits(int actorId) async {
    try {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/person/$actorId/combined_credits',
      );
      final List results = response.data['cast'];
      return results.map((m) => MediaItem.fromJson(m)).toList();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException(
            'Network error while fetching actor movie credits',
            e,
          );
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while fetching actor movie credits',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load actor movie credits', null, e);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to parse actor movie credits response', e);
    }
  }

  /// Backwards-compatible wrapper for discover with filter naming used elsewhere.
  Future<List<MediaItem>> discoverMedia({
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType type = MediaType.movie,
    String sortBy = 'popularity.desc',
  }) async {
    final mediaType = type == MediaType.tv ? 'tv' : 'movie';
    return await discover(
      mediaType: mediaType,
      sortBy: sortBy,
      page: page,
      year: releaseYear,
      withGenres: genreIds != null && genreIds.isNotEmpty
          ? genreIds.join(',')
          : null,
      minRating: minRating,
      language: language,
    );
  }

  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await _tmdbGet('https://api.themoviedb.org/3/$path/$id/similar');
      final List results = response.data['results'];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to fetch similar media', e);
    }
  }

  /// Fetches the parts of a collection (saga) by collection id.
  Future<List<MediaItem>> getCollectionParts(int collectionId) async {
    try {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/collection/$collectionId',
      );
      final List results = response.data['parts'] ?? [];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = 'movie';
        return MediaItem.fromJson(data);
      }).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to fetch collection parts', e);
    }
  }

  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/recommendations',
      );
      final List results = response.data['results'];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to fetch recommendations', e);
    }
  }

  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/watch/providers',
      );
      return response.data['results'] as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to fetch watch providers', e);
    }
  }

  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await _tmdbGet('https://api.themoviedb.org/3/$path/$id/videos');
      final List results = response.data['results'];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParsingException('Failed to fetch videos', e);
    }
  }
}
