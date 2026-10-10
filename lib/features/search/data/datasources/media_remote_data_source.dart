import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';

/// Handles data fetching from the TMDB API.
@lazySingleton
class MediaRemoteDataSource {
  final Dio dio;
  final TmdbCredentialStore credentials;

  String get _apiCredential {
    final raw = credentials.credential.trim();
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
  /// Requires a [Dio] to make network requests and a [TmdbCredentialStore]
  /// holding the TMDB credential.
  @factoryMethod
  factory MediaRemoteDataSource({
    required Dio dio,
    required TmdbCredentialStore credentials,
  }) {
    return MediaRemoteDataSource._internal(dio: dio, credentials: credentials);
  }

  MediaRemoteDataSource._internal({
    required this.dio,
    required this.credentials,
  });

  /// Maps a [DioException] to the matching [AppException].
  ///
  /// Timeouts and connection failures become [NetworkException]; HTTP error
  /// responses become [ServerException] with the status code; anything else
  /// (cancel, bad certificate, unknown) becomes [ServerException] without one.
  @visibleForTesting
  static AppException mapDioException(DioException e, String action) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException('Network error while $action', e);
      case DioExceptionType.badResponse:
        return ServerException(
          'Server error while $action',
          e.response?.statusCode,
          e,
        );
      default:
        return ServerException('Request failed while $action', null, e);
    }
  }

  /// Runs [request] and normalizes failures into [AppException]s.
  ///
  /// [DioException]s go through [mapDioException]; [AppException]s are
  /// rethrown unchanged; any other error is a [ParsingException].
  Future<T> _guard<T>(String action, Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw mapDioException(e, action);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParsingException('Failed to parse response while $action', e);
    }
  }

  /// Searches for movies and series on the TMDB API, supporting optional filters.
  Future<List<MediaItem>> searchMedia(
    String query, {
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType? type,
  }) {
    final path = (type == MediaType.tv) ? 'tv' : 'movie';
    return _guard('searching', () async {
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
      // Not enriched here: MediaRepositoryImpl enriches cache-first with
      // bounded concurrency.
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();
    });
  }

  /// Fetches the details for a single media item from the TMDB API.
  Future<MediaItem> getMediaItem(int id, {MediaType type = MediaType.movie}) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching details', () async {
      final response = await _tmdbGet('https://api.themoviedb.org/3/$path/$id');
      final data = Map<String, dynamic>.from(response.data);
      data['media_type'] = path;
      return MediaItem.fromJson(data);
    });
  }

  /// Fetches the details for a TV season from the TMDB API.
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) {
    return _guard('fetching season details', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/tv/$tvId/season/$seasonNumber',
      );
      return response.data as Map<String, dynamic>;
    });
  }

  /// Fetches the credits for a single media item from the TMDB API.
  Future<Map<String, dynamic>> getMediaCredits(
    int id, {
    MediaType type = MediaType.movie,
  }) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching credits', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/credits',
      );
      return response.data as Map<String, dynamic>;
    });
  }

  /// Fetches the details for an actor from the TMDB API.
  Future<ActorDetails> getActorDetails(int actorId) {
    return _guard('fetching actor details', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/person/$actorId',
      );
      return ActorDetails.fromJson(response.data);
    });
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
  }) {
    final path = mediaType == 'tv' ? 'tv' : 'movie';
    return _guard('discovering', () async {
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
      // Not enriched here: MediaRepositoryImpl enriches cache-first with
      // bounded concurrency.
      return results
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
    });
  }

  /// Fetches the movies an actor has been in.
  Future<List<MediaItem>> getActorMediaCredits(int actorId) {
    return _guard('fetching actor movie credits', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/person/$actorId/combined_credits',
      );
      final List results = response.data['cast'];
      return results.map((m) => MediaItem.fromJson(m)).toList();
    });
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

  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching similar media', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/similar',
      );
      final List results = response.data['results'];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();
    });
  }

  /// Fetches the parts of a collection (saga) by collection id.
  Future<List<MediaItem>> getCollectionParts(int collectionId) {
    return _guard('fetching collection parts', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/collection/$collectionId',
      );
      final List results = response.data['parts'] ?? [];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = 'movie';
        return MediaItem.fromJson(data);
      }).toList();
    });
  }

  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching recommendations', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/recommendations',
      );
      final List results = response.data['results'];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();
    });
  }

  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching watch providers', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/watch/providers',
      );
      return response.data['results'] as Map<String, dynamic>;
    });
  }

  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching videos', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/videos',
      );
      final List results = response.data['results'];
      return results.cast<Map<String, dynamic>>();
    });
  }
}
