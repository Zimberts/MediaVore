import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/error/exceptions.dart';

/// Handles data fetching from the TMDB API.
@lazySingleton
class MediaRemoteDataSource {
  final Dio dio;
  final String apiToken;

  /// Creates a new instance of [MediaRemoteDataSource].
  ///
  /// Requires a [Dio] to make network requests and an [apiToken] for TMDB API.
  /// If [apiToken] is not provided, it will be read from the environment variable 'TMDB_API_TOKEN'.
  @factoryMethod
  factory MediaRemoteDataSource({required Dio dio, String? apiToken}) {
    return MediaRemoteDataSource._internal(
      dio: dio,
      apiToken: apiToken ?? dotenv.env['TMDB_API_TOKEN'] ?? '',
    );
  }

  MediaRemoteDataSource._internal({required this.dio, required this.apiToken});

  /// Searches for movies and series on the TMDB API, supporting optional filters.
  Future<List<MediaItem>> searchMedia(String query, {
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
      if (genreIds != null && genreIds.isNotEmpty) params['with_genres'] = genreIds.join(',');
      if (releaseYear != null) {
        if (type == MediaType.movie) {
          params['primary_release_year'] = releaseYear;
        } else {
          params['first_air_date_year'] = releaseYear;
        }
      }
      if (minRating != null) params['vote_average.gte'] = minRating;
      if (language != null) params['language'] = language;

      final response = await dio.get(
        'https://api.themoviedb.org/3/search/$path',
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );

      final List results = response.data['results'];
      final mediaItems = results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();

      // Enrich items with full details to get number of seasons or runtime
      final enrichedItems = await Future.wait(mediaItems.map((item) async {
        try {
          return await getMediaItem(item.id, type: item.mediaType);
        } catch (_) {
          return item;
        }
      }));

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
      throw ParsingException('Failed to parse search response', e);
    }
  }

  /// Fetches the details for a single media item from the TMDB API.
  Future<MediaItem> getMediaItem(int id, {MediaType type = MediaType.movie}) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/$path/$id',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
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
      throw ParsingException('Failed to parse response', e);
    }
  }

  /// Fetches the details for a TV season from the TMDB API.
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) async {
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/tv/$tvId/season/$seasonNumber',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      return response.data;
    } on DioException catch (e) {
       throw ServerException('Failed to load season details', e.response?.statusCode, e);
    } catch (e) {
      throw ParsingException('Failed to parse season details', e);
    }
  }

  /// Fetches the credits for a single media item from the TMDB API.
  Future<Map<String, dynamic>> getMediaCredits(int id, {MediaType type = MediaType.movie}) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/$path/$id/credits',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
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
      throw ParsingException('Failed to parse credits response', e);
    }
  }

  /// Fetches the details for an actor from the TMDB API.
  Future<ActorDetails> getActorDetails(int actorId) async {
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/person/$actorId',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      return ActorDetails.fromJson(response.data);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while fetching actor details', e);
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

      final response = await dio.get(
        'https://api.themoviedb.org/3/discover/$path',
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );

      final List results = response.data['results'];
      final mediaItems = results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).where((m) => m.mediaType == MediaType.movie || m.mediaType == MediaType.tv).toList();

      // Try to enrich items similarly to searchMedia
      final enriched = await Future.wait(mediaItems.map((item) async {
        try {
          return await getMediaItem(item.id, type: item.mediaType);
        } catch (_) {
          return item;
        }
      }));

      return enriched;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while discovering', e);
        case DioExceptionType.badResponse:
          throw ServerException('Server error while discovering', e.response?.statusCode, e);
        default:
          throw ServerException('Failed to discover', null, e);
      }
    } catch (e) {
      throw ParsingException('Failed to parse discover response', e);
    }
  }

  /// Fetches the movies an actor has been in.
  Future<List<MediaItem>> getActorMediaCredits(int actorId) async {
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/person/$actorId/combined_credits',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      final List results = response.data['cast'];
      return results.map((m) => MediaItem.fromJson(m)).toList();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while fetching actor movie credits', e);
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
      withGenres: genreIds != null && genreIds.isNotEmpty ? genreIds.join(',') : null,
      minRating: minRating,
      language: language,
    );
  }

  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/$path/$id/similar',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      final List results = response.data['results'];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();
    } catch (e) {
      throw ParsingException('Failed to fetch similar media', e);
    }
  }

  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/$path/$id/recommendations',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      final List results = response.data['results'];
      return results.map((m) {
        final data = Map<String, dynamic>.from(m);
        if (data['media_type'] == null) data['media_type'] = path;
        return MediaItem.fromJson(data);
      }).toList();
    } catch (e) {
      throw ParsingException('Failed to fetch recommendations', e);
    }
  }

  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/$path/$id/watch/providers',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      return response.data['results'] as Map<String, dynamic>;
    } catch (e) {
      throw ParsingException('Failed to fetch watch providers', e);
    }
  }

  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) async {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/$path/$id/videos',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      final List results = response.data['results'];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ParsingException('Failed to fetch videos', e);
    }
  }
}
