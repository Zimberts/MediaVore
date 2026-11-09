// Benchmark of a full cache reload (Wipe, then warm-up) against a fake TMDB
// server with simulated latency (#212).
//
// The fake answers at the HTTP level (Dio adapter), so the measured request
// count does not depend on how the data source splits its calls. The cache is
// the real Isar-backed `MediaCache`.
//
// N = 50 always runs and guards the request budget. N = 200 and 500 run only
// with MEDIAVORE_BENCHMARK=1:
//   MEDIAVORE_BENCHMARK=1 flutter test test/benchmark/
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/services/cache_warmup_service.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

/// Simulated round-trip time of one TMDB request.
const Duration latency = Duration(milliseconds: 10);

/// Seasons per show in the synthetic library.
const int seasonsPerShow = 6;

final bool fullBenchmark = Platform.environment['MEDIAVORE_BENCHMARK'] == '1';

/// Library of [n] titles: every third title is a show, every fourth movie
/// belongs to a collection.
List<MediaListItem> library(int n) => List.generate(n, (i) {
  final isTv = i % 3 == 2;
  return MediaListItem(
    id: 1000 + i,
    type: isTv ? 'tv' : 'movie',
    title: 'T$i',
    position: i,
  );
});

/// Fake TMDB server: counts requests (per endpoint kind) and the peak number
/// of requests in flight, and answers after [latency].
class FakeTmdbAdapter implements HttpClientAdapter {
  int requests = 0;
  int inFlight = 0;
  int maxInFlight = 0;
  final Map<String, int> byKind = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      await Future<void>.delayed(latency);
      final segments = options.uri.pathSegments.skip(1).toList(); // drop "3"
      final append = (options.uri.queryParameters['append_to_response'] ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      final kind = _kind(segments, append);
      byKind[kind] = (byKind[kind] ?? 0) + 1;
      return ResponseBody.fromString(
        jsonEncode(_body(segments, append)),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    } finally {
      inFlight--;
    }
  }

  static String _kind(List<String> s, List<String> append) {
    final base = s.length <= 2 ? s[0] : '${s[0]}/${s.skip(2).join('/')}';
    if (append.isEmpty) return base;
    final seasons = append.where((a) => a.startsWith('season/')).length;
    final others = append.length - seasons;
    return '$base+append(${others > 0 ? '$others parts' : ''}'
        '${others > 0 && seasons > 0 ? ', ' : ''}'
        '${seasons > 0 ? '$seasons seasons' : ''})';
  }

  static Map<String, dynamic> _body(List<String> s, List<String> append) {
    final root = s[0];
    if (root == 'collection') {
      final id = int.parse(s[1]);
      return {
        'id': id,
        'parts': [
          for (var k = 0; k < 3; k++)
            {'id': id * 10 + k, 'title': 'Part $k', 'overview': 'o'},
        ],
      };
    }
    final id = int.parse(s[1]);
    final isTv = root == 'tv';
    if (s.length == 2) {
      return {
        ..._item(id, isTv),
        for (final part in append)
          part: part.startsWith('season/')
              ? _season(id, int.parse(part.split('/')[1]))
              : _part(part),
      };
    }
    final sub = s.skip(2).join('/');
    if (sub.startsWith('season/')) return _season(id, int.parse(s[3]));
    return _part(sub);
  }

  static Map<String, dynamic> _item(int id, bool isTv) => isTv
      ? {
          'id': id,
          'name': 'Show $id',
          'overview': 'o',
          'first_air_date': '2010-01-01',
          'status': 'Ended',
          'genres': [
            {'id': 18, 'name': 'Drama'},
          ],
          'episode_run_time': [45],
          'number_of_seasons': seasonsPerShow,
          'seasons': [
            for (var n = 1; n <= seasonsPerShow; n++)
              {'id': id * 100 + n, 'season_number': n, 'episode_count': 10},
          ],
        }
      : {
          'id': id,
          'title': 'Movie $id',
          'overview': 'o',
          'release_date': '2010-01-01',
          'runtime': 120,
          'genres': [
            {'id': 28, 'name': 'Action'},
          ],
          if (id % 4 == 0)
            'belongs_to_collection': {'id': id + 900000, 'name': 'Saga'},
        };

  static Map<String, dynamic> _season(int tvId, int n) => {
    'id': tvId * 100 + n,
    'season_number': n,
    'episodes': [
      for (var e = 1; e <= 10; e++)
        {
          'episode_number': e,
          'season_number': n,
          'name': 'E$e',
          'air_date': '2010-01-0${e % 9 + 1}',
          'runtime': 45,
        },
    ],
  };

  static dynamic _part(String part) => switch (part) {
    'credits' => {
      'cast': [
        {'id': 1, 'name': 'Actor', 'character': 'Role'},
      ],
      'crew': [
        {'id': 2, 'name': 'Director', 'job': 'Director'},
      ],
    },
    'similar' || 'recommendations' => {
      'results': [
        {'id': 7, 'title': 'Other', 'overview': 'o'},
      ],
    },
    'watch/providers' => {'results': <String, dynamic>{}},
    'videos' => {'results': <Map<String, dynamic>>[]},
    _ => <String, dynamic>{},
  };

  @override
  void close({bool force = false}) {}
}

class BenchmarkResult {
  final int n;
  final Duration cold;
  final int coldRequests;
  final int maxInFlight;
  final Map<String, int> byKind;
  final Duration warm;
  final int warmRequests;

  BenchmarkResult(
    this.n,
    this.cold,
    this.coldRequests,
    this.maxInFlight,
    this.byKind,
    this.warm,
    this.warmRequests,
  );

  @override
  String toString() {
    final kinds =
        (byKind.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
    return 'N=$n  cold: ${cold.inMilliseconds} ms, $coldRequests requests '
        '(${(coldRequests / n).toStringAsFixed(2)}/title, '
        'max in flight $maxInFlight)  warm: ${warm.inMilliseconds} ms, '
        '$warmRequests requests\n  cold by endpoint: $kinds';
  }
}

void main() {
  late Isar isar;
  late String tempPath;

  setUpAll(() async {
    registerFallbackValue(Duration.zero);
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempPath =
        '${Directory.current.path}/test/tmp_cache_benchmark_'
        '${DateTime.now().microsecondsSinceEpoch}';
    Directory(tempPath).createSync(recursive: true);
    isar = await Isar.open(
      [CachedMediaSchema, CachedSeasonSchema, CachedActorProfileSchema],
      directory: tempPath,
      name: 'cache_benchmark',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (Directory(tempPath).existsSync()) {
      Directory(tempPath).deleteSync(recursive: true);
    }
  });

  Future<BenchmarkResult> runBenchmark(int n) async {
    final adapter = FakeTmdbAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final remote = MediaRemoteDataSource(
      dio: dio,
      credentials: FakeTmdbCredentialStore('0123456789abcdef0123456789abcdef'),
      locale: FakeLocaleService(),
    );
    final local = MockMediaListLocalDataSource();
    final items = library(n);
    when(() => local.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => local.getListItems('watchlist')).thenAnswer((_) async => items);
    when(() => local.getAllSeenItems()).thenAnswer((_) async => []);
    when(() => local.getLikedItems()).thenAnswer((_) async => []);
    when(() => local.getNotifiedItems()).thenAnswer((_) async => []);

    final cache = MediaCache(isar);
    final details = MediaDetailsService(remoteDataSource: remote, cache: cache);
    final scanner = NextEpisodeScanner(details);
    final warmup = CacheWarmupService(
      localDataSource: local,
      cache: cache,
      details: details,
      notifications: NotificationRefreshService(
        remoteDataSource: remote,
        localDataSource: local,
        cache: cache,
        details: details,
        scanner: scanner,
        quickAdd: QuickAddService(
          remoteDataSource: remote,
          localDataSource: local,
          cache: cache,
          details: details,
          scanner: scanner,
        ),
      ),
    );

    await cache.clearAll(); // "Wipe"
    final cold = Stopwatch()..start();
    expect(await warmup.run(), isTrue);
    cold.stop();
    final coldRequests = adapter.requests;
    final byKind = Map.of(adapter.byKind);
    final maxInFlight = adapter.maxInFlight;

    final warm = Stopwatch()..start();
    expect(await warmup.run(), isTrue);
    warm.stop();

    final result = BenchmarkResult(
      n,
      cold.elapsed,
      coldRequests,
      maxInFlight,
      byKind,
      warm.elapsed,
      adapter.requests - coldRequests,
    );
    // ignore: avoid_print
    print(result);
    return result;
  }

  test('cache reload, N = 50', () async {
    final r = await runBenchmark(50);
    // Request budget (#212): one request per title, one more per show for
    // its seasons (up to 20 per request) and per saga. 8.1/title before.
    expect(r.coldRequests, lessThanOrEqualTo(75));
    // A warm cache needs no request (ended shows, details all cached).
    expect(r.warmRequests, 0);
  });

  test(
    'cache reload, N = 200',
    () => runBenchmark(200),
    skip: fullBenchmark ? false : 'set MEDIAVORE_BENCHMARK=1',
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'cache reload, N = 500',
    () => runBenchmark(500),
    skip: fullBenchmark ? false : 'set MEDIAVORE_BENCHMARK=1',
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
