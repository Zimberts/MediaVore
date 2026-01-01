import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/core/error/exceptions.dart';

/// Handles data fetching from the TMDB API.
@lazySingleton
class MovieRemoteDataSource {
  final Dio dio;
  final String apiToken;

  /// Creates a new instance of [MovieRemoteDataSource].
  ///
  /// Requires a [Dio] to make network requests and an [apiToken] for TMDB API.
  /// If [apiToken] is not provided, it will be read from the environment variable 'TMDB_API_TOKEN'.
  @factoryMethod
  factory MovieRemoteDataSource({required Dio dio, String? apiToken}) {
    return MovieRemoteDataSource._internal(
      dio: dio,
      apiToken: apiToken ?? dotenv.env['TMDB_API_TOKEN'] ?? '',
    );
  }

  MovieRemoteDataSource._internal({required this.dio, required this.apiToken});

  /// Searches for movies on the TMDB API.
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/search/movie',
        queryParameters: {'query': query},
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      final List results = response.data['results'];
      return results.map((m) => Movie.fromJson(m)).toList();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while searching movies', e);
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while searching movies',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load movies', null, e);
      }
    } catch (e) {
      throw ParsingException('Failed to parse movie search response', e);
    }
  }

  /// Fetches the details for a single movie from the TMDB API.
  Future<Movie> getMovie(int movieId) async {
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/movie/$movieId',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      return Movie.fromJson(response.data);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while fetching movie', e);
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while fetching movie',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load movie', null, e);
      }
    } catch (e) {
      throw ParsingException('Failed to parse movie response', e);
    }
  }

  /// Fetches the credits for a single movie from the TMDB API.
  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    try {
      final response = await dio.get(
        'https://api.themoviedb.org/3/movie/$movieId/credits',
        options: Options(headers: {'Authorization': 'Bearer $apiToken'}),
      );
      return response.data;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          throw NetworkException('Network error while fetching movie credits', e);
        case DioExceptionType.badResponse:
          throw ServerException(
            'Server error while fetching movie credits',
            e.response?.statusCode,
            e,
          );
        default:
          throw ServerException('Failed to load movie credits', null, e);
      }
    } catch (e) {
      throw ParsingException('Failed to parse movie credits response', e);
    }
  }
}
