// Benchmark of a full cache reload (Wipe, then warm-up) against a fake TMDB
// server with simulated latency (#212).
//
// The fake (`FakeTmdb`) answers at the HTTP level (adapter of the app's TMDB
// Dio, with its rate limiter and retry), so the measured request count does
// not depend on how the data source splits its calls. The cache is the real Isar-backed
// `MediaCache`. Half of the library is also in the recent seen history (one
// row per movie, ten episodes per show) and one title in five is liked, so
// the same titles come from several sources.
//
// N = 50 always runs and guards the request budget. N = 200 and 500 run only
// with MEDIAVORE_BENCHMARK=1:
//   MEDIAVORE_BENCHMARK=1 flutter test test/benchmark/
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/network/tmdb_dio.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/services/cache_warmup_service.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_tmdb.dart';
import '../helpers/mocks.dart';

/// Simulated round-trip time of one TMDB request; 10 ms unless set with
/// MEDIAVORE_BENCHMARK_LATENCY_MS.
final Duration latency = Duration(
  milliseconds:
      int.tryParse(
        Platform.environment['MEDIAVORE_BENCHMARK_LATENCY_MS'] ?? '',
      ) ??
      10,
);

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

/// Recent seen rows for the first half of [items]: one per movie, ten
/// episodes of season 1 per show.
List<SeenItemModel> seenHistory(List<MediaListItem> items) {
  final seenDate = DateTime.now().subtract(const Duration(days: 1));
  return [
    for (final item in items.take(items.length ~/ 2))
      if (item.type == 'movie')
        SeenItemModel(
          tmdbId: item.id,
          type: 'movie',
          title: item.title,
          posterPath: '/p.jpg',
          seenDate: seenDate,
        )
      else
        for (var e = 1; e <= 10; e++)
          SeenItemModel(
            tmdbId: item.id,
            type: 'tv',
            title: item.title,
            posterPath: '/p.jpg',
            seenDate: seenDate,
            seasonNumber: 1,
            episodeNumber: e,
          ),
  ];
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
    return 'N=$n latency=${latency.inMilliseconds}ms  cold: ${cold.inMilliseconds} ms, $coldRequests requests '
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
    final adapter = FakeTmdb(
      latency: latency,
      seasonsPerShow: seasonsPerShow,
      // Every 4th movie is part of a 3-movie saga.
      collectionOf: (id) => id % 4 == 0 ? 9000 + id % 10 : null,
    );
    final dio = createTmdbDio()..httpClientAdapter = adapter;
    final remote = MediaRemoteDataSource(
      dio: dio,
      credentials: FakeTmdbCredentialStore('0123456789abcdef0123456789abcdef'),
      locale: FakeLocaleService(),
    );
    final local = MockMediaListLocalDataSource();
    final items = library(n);
    when(local.getAllListNames).thenAnswer((_) async => ['watchlist']);
    when(() => local.getListItems('watchlist')).thenAnswer((_) async => items);
    when(local.getAllSeenItems).thenAnswer((_) async => seenHistory(items));
    when(local.getLikedItems).thenAnswer(
      (_) async => [
        for (final item in items.where((i) => i.position % 5 == 0))
          LikedItem(tmdbId: item.id, type: item.type, title: item.title),
      ],
    );
    when(local.getNotifiedItems).thenAnswer((_) async => []);

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
    final coldRequests = adapter.requestCount;
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
      adapter.requestCount - coldRequests,
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
