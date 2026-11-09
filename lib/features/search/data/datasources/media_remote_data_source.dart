import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';

/// Handles data fetching from the TMDB API.
@lazySingleton
class MediaRemoteDataSource {
  final Dio dio;
  final TmdbCredentialStore credentials;

  /// Supplies the `language` sent with every TMDB request.
  final LocaleService locale;

  /// Strips an optional `Bearer ` prefix from a pasted credential.
  static String _normalizeCredential(String raw) {
    final trimmed = raw.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  bool _isV3ApiKey(String credential) =>
      RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(credential);

  /// GETs [url] authenticated with the stored credential, or with
  /// [credential] when given (used to check a key before saving it).
  Future<Response<dynamic>> _tmdbGet(
    String url, {
    Map<String, dynamic>? queryParameters,
    String? credential,
  }) {
    final apiCredential = _normalizeCredential(
      credential ?? credentials.credential,
    );
    if (apiCredential.isEmpty) {
      throw const ConfigurationException(
        'TMDB API credential is missing. Add a v3 API key or v4 read token in Settings.',
      );
    }

    final params = <String, dynamic>{
      'language': locale.tmdbLanguage,
      ...?queryParameters,
    };
    final useV3ApiKey = _isV3ApiKey(apiCredential);

    if (useV3ApiKey) {
      params['api_key'] = apiCredential;
    }

    final options = useV3ApiKey
        ? null
        : Options(headers: {'Authorization': 'Bearer $apiCredential'});

    return dio.get(
      url,
      queryParameters: params.isEmpty ? null : params,
      options: options,
    );
  }

  /// Creates a new instance of [MediaRemoteDataSource].
  ///
  /// Requires a [Dio] to make network requests, a [TmdbCredentialStore]
  /// holding the TMDB credential and a [LocaleService] for the response
  /// language.
  @factoryMethod
  factory MediaRemoteDataSource({
    required Dio dio,
    required TmdbCredentialStore credentials,
    required LocaleService locale,
  }) {
    return MediaRemoteDataSource._internal(
      dio: dio,
      credentials: credentials,
      locale: locale,
    );
  }

  MediaRemoteDataSource._internal({
    required this.dio,
    required this.credentials,
    required this.locale,
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

  /// Checks [credential] (v3 API key or v4 read token) against TMDB's
  /// `/authentication` endpoint without storing it.
  ///
  /// Completes when TMDB accepts it. Throws [ConfigurationException] when it
  /// is empty, [ServerException] with status 401 when TMDB rejects it, and
  /// [NetworkException] when TMDB can't be reached.
  Future<void> validateCredential(String credential) {
    return _guard('validating the TMDB credential', () async {
      await _tmdbGet(
        'https://api.themoviedb.org/3/authentication',
        credential: credential,
      );
    });
  }

  /// Searches for movies and series on the TMDB API, supporting optional filters.
  Future<List<MediaItem>> searchMedia(
    String query, {
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? originalLanguage,
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

      debugPrint('[Remote] searchMedia -> /search/$path params=$params');
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/search/$path',
        queryParameters: params,
      );

      final List results = response.data['results'];
      // Not enriched here: MediaRepositoryImpl enriches cache-first with
      // bounded concurrency.
      return results
          .map((m) => Map<String, dynamic>.from(m))
          // /search has no `with_original_language`; filter client-side.
          .where(
            (data) =>
                originalLanguage == null ||
                data['original_language'] == originalLanguage,
          )
          .map((data) {
            if (data['media_type'] == null) data['media_type'] = path;
            return MediaItem.fromJson(data);
          })
          .toList();
    });
  }

  /// Fetches the details for a single media item from the TMDB API.
  Future<MediaItem> getMediaItem(int id, {MediaType type = MediaType.movie}) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching details', () async {
      final url = 'https://api.themoviedb.org/3/$path/$id';
      final response = await _tmdbGet(url);
      final data = Map<String, dynamic>.from(response.data);
      data['media_type'] = path;
      await _fillMissingOverview(url, data);
      return MediaItem.fromJson(data);
    });
  }

  /// Sub-resources fetched with the item by [getMediaDetailsBundle], through
  /// TMDB's `append_to_response` (one request instead of six).
  static const List<String> detailsAppendedResources = [
    'credits',
    'similar',
    'recommendations',
    'watch/providers',
    'videos',
  ];

  /// TMDB accepts at most 20 `append_to_response` entries per request.
  static const int maxAppendedResponses = 20;

  /// Fetches a media item with its credits, similar titles,
  /// recommendations, watch providers and videos in one request
  /// (`append_to_response`).
  ///
  /// Only the item is required: a missing or malformed appended part falls
  /// back to an empty value, as the separate optional requests did.
  Future<MediaDetailsBundle> getMediaDetailsBundle(
    int id, {
    MediaType type = MediaType.movie,
  }) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching details', () async {
      final url = 'https://api.themoviedb.org/3/$path/$id';
      final response = await _tmdbGet(
        url,
        queryParameters: {
          'append_to_response': detailsAppendedResources.join(','),
        },
      );
      final data = Map<String, dynamic>.from(response.data);
      final appended = {
        for (final key in detailsAppendedResources) key: data.remove(key),
      };
      data['media_type'] = path;
      await _fillMissingOverview(url, data);

      T part<T>(String key, T Function(dynamic raw) parse, T fallback) {
        final raw = appended[key];
        if (raw == null) return fallback;
        try {
          return parse(raw);
        } catch (e) {
          debugPrint('[Remote] Appended $key unreadable for $url: $e');
          return fallback;
        }
      }

      return MediaDetailsBundle(
        item: MediaItem.fromJson(data),
        credits: part(
          'credits',
          (raw) => Map<String, dynamic>.from(raw as Map),
          {'cast': [], 'crew': []},
        ),
        similar: part(
          'similar',
          (raw) => _parseResults(raw['results'] as List, path),
          [],
        ),
        recommendations: part(
          'recommendations',
          (raw) => _parseResults(raw['results'] as List, path),
          [],
        ),
        watchProviders: part(
          'watch/providers',
          (raw) => Map<String, dynamic>.from(raw['results'] as Map),
          {},
        ),
        videos: part(
          'videos',
          (raw) => (raw['results'] as List)
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList(),
          [],
        ),
      );
    });
  }

  /// Fetches several seasons of a show with `append_to_response`, at most
  /// [maxAppendedResponses] seasons per request. Seasons TMDB does not return
  /// are absent from the result.
  Future<Map<int, Map<String, dynamic>>> getSeasonsDetails(
    int tvId,
    List<int> seasonNumbers,
  ) {
    return _guard('fetching season details', () async {
      final seasons = <int, Map<String, dynamic>>{};
      for (var i = 0; i < seasonNumbers.length; i += maxAppendedResponses) {
        final batch = seasonNumbers.skip(i).take(maxAppendedResponses);
        final response = await _tmdbGet(
          'https://api.themoviedb.org/3/tv/$tvId',
          queryParameters: {
            'append_to_response': batch.map((n) => 'season/$n').join(','),
          },
        );
        final data = response.data as Map;
        for (final n in batch) {
          final season = data['season/$n'];
          if (season is Map) seasons[n] = Map<String, dynamic>.from(season);
        }
      }
      return seasons;
    });
  }

  /// Parses a TMDB result list, defaulting `media_type` to [path].
  static List<MediaItem> _parseResults(List results, String path) {
    return results.map((m) {
      final data = Map<String, dynamic>.from(m as Map);
      if (data['media_type'] == null) data['media_type'] = path;
      return MediaItem.fromJson(data);
    }).toList();
  }

  /// TMDB returns an empty overview when it has no translation; fall back to
  /// the English one so the details page isn't blank.
  Future<void> _fillMissingOverview(
    String url,
    Map<String, dynamic> data,
  ) async {
    final overview = data['overview'] as String?;
    if (overview != null && overview.trim().isNotEmpty) return;
    if (locale.tmdbLanguage == fallbackAppLanguage.tmdbTag) return;
    try {
      final fallback = await _tmdbGet(
        url,
        queryParameters: {'language': fallbackAppLanguage.tmdbTag},
      );
      final fallbackOverview = fallback.data['overview'] as String?;
      if (fallbackOverview != null && fallbackOverview.isNotEmpty) {
        data['overview'] = fallbackOverview;
      }
    } catch (e) {
      debugPrint('[Remote] Overview fallback failed for $url: $e');
    }
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
    String? originalLanguage,
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
      if (originalLanguage != null) {
        params['with_original_language'] = originalLanguage;
      }

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
    String? originalLanguage,
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
      originalLanguage: originalLanguage,
    );
  }

  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) {
    final path = type == MediaType.tv ? 'tv' : 'movie';
    return _guard('fetching similar media', () async {
      final response = await _tmdbGet(
        'https://api.themoviedb.org/3/$path/$id/similar',
      );
      return _parseResults(response.data['results'] as List, path);
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
      return _parseResults(response.data['results'] as List, path);
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

/// A media item and the sub-resources fetched with it by
/// [MediaRemoteDataSource.getMediaDetailsBundle].
class MediaDetailsBundle {
  final MediaItem item;

  /// Raw `/credits` payload (`cast`, `crew`).
  final Map<String, dynamic> credits;
  final List<MediaItem> similar;
  final List<MediaItem> recommendations;

  /// `/watch/providers` results, keyed by country.
  final Map<String, dynamic> watchProviders;
  final List<Map<String, dynamic>> videos;

  const MediaDetailsBundle({
    required this.item,
    required this.credits,
    required this.similar,
    required this.recommendations,
    required this.watchProviders,
    required this.videos,
  });
}
