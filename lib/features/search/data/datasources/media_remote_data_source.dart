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

  /// Searches for movies and series on the TMDB API.
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async {
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/search/multi',
        queryParameters: {
          'query': query,
          'page': page,
        },
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      final List results = response.data['results'];
      final mediaItems = results
          .map((m) => MediaItem.fromJson(m))
          .where((m) => m.mediaType == MediaType.movie || m.mediaType == MediaType.tv)
          .toList();

      // Enrich items with full details to get number of seasons or runtime
      final enrichedItems = await Future.wait(mediaItems.map((item) async {
        try {
          // We fetch the full details for each item to get extra info (runtime, seasons).
          return await getMediaItem(item.id, type: item.mediaType);
        } catch (e) {
          // If enrichment fails, we return the basic item from search.
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
}
