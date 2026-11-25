import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'fixture_reader.dart';

/// Error a [FakeTmdb] can be switched to (see [FakeTmdb.fail]).
enum FakeTmdbFailure {
  /// HTTP 401: invalid or missing credential.
  unauthorized,

  /// HTTP 429: rate limit exceeded.
  rateLimited,

  /// HTTP 500.
  serverError,

  /// Connection timeout (`DioExceptionType.connectionTimeout`).
  timeout,

  /// No network (`DioExceptionType.connectionError` caused by a
  /// `SocketException`).
  offline,
}

/// Host of every TMDB API request.
const String tmdbApiHost = 'api.themoviedb.org';

/// Fake TMDB server at the HTTP level: the adapter of the app's TMDB [Dio],
/// so the real interceptors (rate limit, retry) and the real data source run.
///
/// Answers come from the JSON templates in `test/fixtures/tmdb/` (and
/// `test/fixtures/trending_all_week.json`), specialised with the requested id.
/// A request no route covers, or to another host than [tmdbApiHost], is
/// recorded in [unhandled] and fails: assert `unhandled` is empty in tests.
///
/// Records every request ([requests], [byKind], [maxInFlight]); errors can be
/// switched on and off with [fail] and [recover].
class FakeTmdb implements HttpClientAdapter {
  FakeTmdb({
    this.latency = Duration.zero,
    this.seasonsPerShow = 2,
    this.episodesPerSeason = 10,
    this.collectionOf,
    this.releaseDateOf,
  });

  /// Simulated round-trip time of one request.
  final Duration latency;

  /// Seasons of every show (`tv/{id}`).
  final int seasonsPerShow;

  /// Episodes of every season (`tv/{id}/season/{n}`).
  final int episodesPerSeason;

  /// Collection (saga) of a movie, by movie id; none when null or when it
  /// returns null.
  final int? Function(int movieId)? collectionOf;

  /// Release date (`yyyy-MM-dd`) of a movie, by movie id; the fixture's when
  /// null or when it returns null.
  final String? Function(int movieId)? releaseDateOf;

  /// Every request received, in order (including failed ones).
  final List<Uri> requests = [];

  /// Requests no route covers. Must stay empty.
  final List<Uri> unhandled = [];

  /// Number of requests per endpoint kind, e.g. `movie`, `tv/season`,
  /// `movie+5` (5 appended resources).
  final Map<String, int> byKind = {};

  /// Requests being answered right now.
  int inFlight = 0;

  /// Peak of [inFlight].
  int maxInFlight = 0;

  final Map<String, Object> _overrides = {};
  FakeTmdbFailure? _failure;
  String? _failurePrefix;
  int? _failuresLeft;

  /// Number of requests received.
  int get requestCount => requests.length;

  /// Number of requests whose path (after `/3/`) starts with [prefix].
  int countFor(String prefix) =>
      requests.where((uri) => _path(uri).startsWith(prefix)).length;

  /// Answers [json] to the requests whose path (after `/3/`) is exactly
  /// [path], e.g. `movie/550`, instead of the fixture.
  void respond(String path, Object json) => _overrides[path] = json;

  /// Makes every request fail with [failure], or only those whose path
  /// (after `/3/`) starts with [pathPrefix]; only the next [times] of them
  /// when given, then [recover]s.
  void fail(FakeTmdbFailure failure, {String? pathPrefix, int? times}) {
    assert(times == null || times > 0);
    _failure = failure;
    _failurePrefix = pathPrefix;
    _failuresLeft = times;
  }

  /// Stops the failure set by [fail].
  void recover() {
    _failure = null;
    _failurePrefix = null;
    _failuresLeft = null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      if (latency > Duration.zero) await Future<void>.delayed(latency);
      if (uri.host != tmdbApiHost || uri.pathSegments.firstOrNull != '3') {
        return _unhandled(uri);
      }
      final path = _path(uri);
      final failure = _failure;
      if (failure != null &&
          (_failurePrefix == null || path.startsWith(_failurePrefix!))) {
        final left = _failuresLeft;
        if (left != null && left <= 1) recover();
        if (left != null && left > 1) _failuresLeft = left - 1;
        return _failWith(failure, options);
      }
      final segments = uri.pathSegments.skip(1).toList();
      final append = (uri.queryParameters['append_to_response'] ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      final kind = _kind(segments, append);
      byKind[kind] = (byKind[kind] ?? 0) + 1;

      final body =
          _overrides[path] ??
          _route(
            segments,
            append,
            page: int.tryParse(uri.queryParameters['page'] ?? '') ?? 1,
          );
      if (body == null) return _unhandled(uri);
      return _json(body, 200);
    } finally {
      inFlight--;
    }
  }

  @override
  void close({bool force = false}) {}

  static String _path(Uri uri) => uri.pathSegments.skip(1).join('/');

  ResponseBody _unhandled(Uri uri) {
    unhandled.add(uri);
    throw StateError('FakeTmdb: no route for $uri');
  }

  static ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  static ResponseBody _failWith(
    FakeTmdbFailure failure,
    RequestOptions options,
  ) => switch (failure) {
    FakeTmdbFailure.unauthorized => _json({
      'success': false,
      'status_code': 7,
      'status_message': 'Invalid API key: You must be granted a valid key.',
    }, 401),
    FakeTmdbFailure.rateLimited => _json({
      'success': false,
      'status_code': 25,
      'status_message': 'Your request count is over the allowed limit.',
    }, 429),
    FakeTmdbFailure.serverError => _json({
      'success': false,
      'status_code': 11,
      'status_message': 'Internal error.',
    }, 500),
    FakeTmdbFailure.timeout => throw DioException.connectionTimeout(
      timeout: options.connectTimeout ?? Duration.zero,
      requestOptions: options,
    ),
    // As the IO adapter reports a failed DNS lookup.
    FakeTmdbFailure.offline => throw DioException.connectionError(
      requestOptions: options,
      reason: 'Failed host lookup: $tmdbApiHost',
      error: const SocketException('Failed host lookup: $tmdbApiHost'),
    ),
  };

  static String _kind(List<String> s, List<String> append) {
    final base = s.length <= 2 ? s[0] : '${s[0]}/${s.skip(2).join('/')}';
    return append.isEmpty ? base : '$base+${append.length}';
  }

  /// Body of the request, or null when no route covers it.
  Object? _route(List<String> s, List<String> append, {required int page}) {
    final id = s.length > 1 ? int.tryParse(s[1]) : null;
    return switch (s) {
      ['authentication'] => _fixture('authentication.json'),
      ['search', 'person'] => _fixture('search_person.json'),
      ['search', 'movie' || 'tv' || 'multi'] => _page(s[1], page),
      ['discover', 'movie' || 'tv'] => _page(s[1], page),
      ['trending', ...] => _trending(page),
      ['movie', _] when id != null => _movie(id, append),
      ['tv', _] when id != null => _show(id, append),
      ['tv', _, 'season', final n] when id != null && int.tryParse(n) != null =>
        _season(id, int.parse(n)),
      ['movie' || 'tv', _, final part] when id != null => _appended(
        part,
        s[0],
        id,
      ),
      ['movie' || 'tv', _, 'watch', 'providers'] when id != null => _appended(
        'watch/providers',
        s[0],
        id,
      ),
      ['collection', _] when id != null => _collection(id),
      ['person', _] when id != null => _person(id),
      ['person', _, 'combined_credits'] => _fixture(
        'person_combined_credits.json',
      ),
      _ => null,
    };
  }

  static final Map<String, Map<String, dynamic>> _cache = {};

  /// A fresh copy of the fixture `test/fixtures/tmdb/[name]`, or of
  /// `test/fixtures/[name]` when [shared].
  static Map<String, dynamic> _fixture(String name, {bool shared = false}) {
    final path = shared ? name : 'tmdb/$name';
    final template = _cache.putIfAbsent(
      path,
      () => jsonDecode(fixture(path)) as Map<String, dynamic>,
    );
    return jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> _results(Map<String, dynamic> page) =>
      (page['results'] as List).cast<Map<String, dynamic>>();

  /// Page [page] of a paginated list. Ids are shifted by 1000 per page so
  /// pages never repeat; TV results carry TV field names.
  static Map<String, dynamic> _page(String type, int page) {
    final body = _fixture('media_page.json')..['page'] = page;
    for (final item in _results(body)) {
      item['id'] = (item['id'] as int) + (page - 1) * 1000;
      if (type == 'tv') {
        item
          ..['name'] = (item.remove('title') as String).replaceAll(
            'Movie',
            'Show',
          )
          ..['original_name'] = item.remove('original_title')
          ..['first_air_date'] = item.remove('release_date')
          ..['origin_country'] = ['US'];
      }
      if (type != 'movie' && type != 'tv') {
        item['media_type'] = 'movie';
      }
    }
    return body;
  }

  static Map<String, dynamic> _trending(int page) {
    final body = _fixture('trending_all_week.json', shared: true)
      ..['page'] = page;
    for (final item in _results(body)) {
      item['id'] = (item['id'] as int) + (page - 1) * 1000000;
    }
    return body;
  }

  Map<String, dynamic> _movie(int id, List<String> append) {
    final collectionId = collectionOf?.call(id);
    return _fixture('movie.json')
      ..['id'] = id
      ..['title'] = 'Movie $id'
      ..['original_title'] = 'Movie $id'
      ..['poster_path'] = '/p$id.jpg'
      ..['belongs_to_collection'] = collectionId == null
          ? null
          : {'id': collectionId, 'name': 'Saga $collectionId'}
      ..addAll({for (final a in append) a: _appended(a, 'movie', id)})
      ..addAll({
        if (releaseDateOf?.call(id) case final date?) 'release_date': date,
      });
  }

  Map<String, dynamic> _show(int id, List<String> append) => _fixture('tv.json')
    ..['id'] = id
    ..['name'] = 'Show $id'
    ..['original_name'] = 'Show $id'
    ..['poster_path'] = '/p$id.jpg'
    ..['number_of_seasons'] = seasonsPerShow
    ..['number_of_episodes'] = seasonsPerShow * episodesPerSeason
    ..['seasons'] = [
      for (var n = 1; n <= seasonsPerShow; n++)
        {
          'id': id * 10 + n,
          'season_number': n,
          'name': 'Season $n',
          'episode_count': episodesPerSeason,
          'air_date': '2020-01-01',
        },
    ]
    ..addAll({for (final a in append) a: _appended(a, 'tv', id)});

  Map<String, dynamic> _season(int tvId, int seasonNumber) {
    final body = _fixture('tv_season.json');
    final template = (body['episodes'] as List).first as Map<String, dynamic>;
    return body
      ..['id'] = tvId * 10 + seasonNumber
      ..['name'] = 'Season $seasonNumber'
      ..['season_number'] = seasonNumber
      ..['episodes'] = [
        for (var e = 1; e <= episodesPerSeason; e++)
          {
            ...template,
            'id': tvId * 100 + seasonNumber * 10 + e,
            'episode_number': e,
            'season_number': seasonNumber,
            'name': 'S${seasonNumber}E$e',
          },
      ];
  }

  Object? _appended(String resource, String type, int id) => switch (resource) {
    _ when resource.startsWith('season/') => _season(
      id,
      int.parse(resource.split('/')[1]),
    ),
    'credits' => _fixture('credits.json'),
    'similar' || 'recommendations' => _page(type, 1),
    'watch/providers' => _fixture('watch_providers.json')..['id'] = id,
    'videos' => _fixture('videos.json')..['id'] = id,
    _ => null,
  };

  static Map<String, dynamic> _collection(int id) {
    final body = _fixture('collection.json');
    final template = (body['parts'] as List).first as Map<String, dynamic>;
    return body
      ..['id'] = id
      ..['name'] = 'Collection $id'
      ..['parts'] = [
        for (var i = 0; i < 3; i++)
          {...template, 'id': id * 10 + i, 'title': 'Part $i'},
      ];
  }

  static Map<String, dynamic> _person(int id) => _fixture('person.json')
    ..['id'] = id
    ..['name'] = 'Person $id';
}
