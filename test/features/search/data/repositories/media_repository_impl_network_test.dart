import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/cache/cache_warmup_policy.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/mocks.dart';

class MockCacheWarmupPolicy extends Mock implements CacheWarmupPolicy {}

MediaItem _item(int id, {int? runtime}) => MediaItem(
  id: id,
  title: 'T$id',
  overview: '',
  releaseDate: '',
  runtime: runtime,
);

void main() {
  late MockMediaRemoteDataSource remote;
  late MockMediaListLocalDataSource local;
  late MockMediaCache cache;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(_item(0));
    registerFallbackValue(<SeenItemModel>[]);
    registerFallbackValue(ImportMode.append);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    remote = MockMediaRemoteDataSource();
    local = MockMediaListLocalDataSource();
    cache = MockMediaCache();

    when(() => cache.init()).thenAnswer((_) async {});
    when(() => cache.cacheItem(any())).thenAnswer((_) async {});
    when(() => cache.getDetails(any(), any())).thenReturn(null);
    when(() => cache.areDetailsCached(any(), any())).thenReturn(false);
    when(() => cache.isSeasonCached(any(), any())).thenReturn(false);
    when(
      () => cache.cleanup(
        keepKeys: any(named: 'keepKeys'),
        olderThan: any(named: 'olderThan'),
      ),
    ).thenAnswer((_) async {});
    when(() => cache.clearAll()).thenAnswer((_) async {});
    when(() => local.getAllListNames()).thenAnswer((_) async => []);
    when(() => local.getAllSeenItems()).thenAnswer((_) async => []);
    when(() => local.getLikedItems()).thenAnswer((_) async => []);
    when(() => local.getNotifiedItems()).thenAnswer((_) async => []);
  });

  MediaRepositoryImpl build({
    CacheWarmupPolicy? policy,
    bool autoInit = true,
  }) => MediaRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    cache: cache,
    warmupPolicy: policy,
    autoInit: autoInit,
  );

  group('search/discover enrichment', () {
    test('should use cached details and bound concurrent fetches', () async {
      final repo = build(autoInit: false);
      final raw = List.generate(10, (i) => _item(i));
      when(
        () => remote.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => raw);
      // Item 0 is already cached with full details.
      when(
        () => cache.getDetails(0, MediaType.movie),
      ).thenReturn(MediaDetails(item: _item(0, runtime: 99), cast: const []));

      var inFlight = 0;
      var maxInFlight = 0;
      when(
        () => remote.getMediaItem(any(), type: any(named: 'type')),
      ).thenAnswer((inv) async {
        final id = inv.positionalArguments.first as int;
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        inFlight--;
        if (id == 5) throw Exception('boom');
        return _item(id, runtime: id + 100);
      });

      final result = await repo.searchMedia('q');

      expect(result.map((m) => m.id), List.generate(10, (i) => i));
      expect(result[0].runtime, 99); // from cache
      expect(result[5].runtime, isNull); // fetch failed: raw row kept
      expect(result[9].runtime, 109);
      expect(maxInFlight, MediaRepositoryImpl.enrichmentConcurrency);
      verifyNever(() => remote.getMediaItem(0, type: any(named: 'type')));
      verify(
        () => remote.getMediaItem(any(), type: any(named: 'type')),
      ).called(9);
    });
  });

  group('cache warm-up', () {
    test('should skip the automatic warm-up when the policy says so', () async {
      final policy = MockCacheWarmupPolicy();
      when(() => policy.shouldRunAutomatically()).thenReturn(false);

      build(policy: policy);
      await pumpEventQueue();

      verifyNever(() => local.getAllListNames());
      verifyNever(() => policy.markCompleted());
    });

    test('should run and record completion when allowed', () async {
      final policy = MockCacheWarmupPolicy();
      when(() => policy.shouldRunAutomatically()).thenReturn(true);
      when(() => policy.markCompleted()).thenAnswer((_) async {});

      build(policy: policy);
      await pumpEventQueue();

      verify(() => local.getAllListNames()).called(1);
      verify(() => policy.markCompleted()).called(1);
    });

    test('should stop and not record completion when cleared', () async {
      final policy = MockCacheWarmupPolicy();
      when(() => policy.shouldRunAutomatically()).thenReturn(true);
      when(() => policy.markCompleted()).thenAnswer((_) async {});
      final names = Completer<List<String>>();
      when(() => local.getAllListNames()).thenAnswer((_) => names.future);
      when(() => local.getListItems(any())).thenAnswer(
        (_) async => [MediaListItem(id: 1, type: 'movie', title: 'T1')],
      );

      final repo = build(policy: policy);
      await pumpEventQueue();
      await repo.clearCache(complete: true);
      names.complete(['watchlist']);
      await pumpEventQueue();

      verifyNever(() => remote.getMediaItem(any(), type: any(named: 'type')));
      verifyNever(() => policy.markCompleted());
    });

    test(
      'should share a single run between concurrent fillCache calls',
      () async {
        final names = Completer<List<String>>();
        when(() => local.getAllListNames()).thenAnswer((_) => names.future);
        final repo = build(autoInit: false);

        final a = repo.fillCache();
        final b = repo.fillCache();
        names.complete([]);
        await Future.wait([a, b]);

        verify(() => local.getAllListNames()).called(1);
      },
    );
  });

  group('import enrichment', () {
    SeenItemModel row(int id, String type, {int? s, int? e}) => SeenItemModel(
      tmdbId: id,
      type: type,
      title: 'T$id',
      seenDate: DateTime(2024),
      seasonNumber: s,
      episodeNumber: e,
    );

    test('should look up each show once, even when the lookup fails', () async {
      final repo = build(autoInit: false);
      when(
        () => local.importAll(
          mode: any(named: 'mode'),
          seen: any(named: 'seen'),
          likes: any(named: 'likes'),
          notifications: any(named: 'notifications'),
          quickAdd: any(named: 'quickAdd'),
          lists: any(named: 'lists'),
        ),
      ).thenAnswer((_) async {});
      // Synchronous throw: the enrichment lookup fails before other calls.
      when(
        () => remote.getMediaItem(any(), type: any(named: 'type')),
      ).thenThrow(Exception('offline'));

      final zip = ExportEnvelope(
        version: 1,
        exportedAt: DateTime(2024),
        seen: [
          row(7, 'movie'),
          row(7, 'movie'),
          row(8, 'tv', s: 1, e: 1),
          row(8, 'tv', s: 1, e: 2),
          row(8, 'tv', s: 1, e: 3),
        ],
      ).toZipBytes();

      await repo.importAllData(zip);

      verify(() => remote.getMediaItem(7, type: MediaType.movie)).called(1);
      verify(() => remote.getMediaItem(8, type: MediaType.tv)).called(1);
      verifyNever(() => remote.getSeasonDetails(any(), any()));
      final saved =
          verify(
                () => local.importAll(
                  mode: any(named: 'mode'),
                  seen: captureAny(named: 'seen'),
                  likes: any(named: 'likes'),
                  notifications: any(named: 'notifications'),
                  quickAdd: any(named: 'quickAdd'),
                  lists: any(named: 'lists'),
                ),
              ).captured.single
              as List<SeenItemModel>;
      expect(saved, hasLength(5));
    });
  });

  group('app language', () {
    late LocaleService localeService;

    MediaRepositoryImpl buildWithLocale() => MediaRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      cache: cache,
      localeService: localeService,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localeService = LocaleService.withDeviceLocales(
        prefs,
        () => const [Locale('fr')],
      );
    });

    test('should clear a cache filled in another language on init', () async {
      final repo = buildWithLocale();
      await repo.applyLanguageChange();

      verify(() => cache.clearAll()).called(1);
      expect(localeService.isCacheLanguageStale, isFalse);
    });

    test('should keep a cache filled in the current language', () async {
      await localeService.markCacheLanguage();

      final repo = buildWithLocale();
      await repo.applyLanguageChange();

      verifyNever(() => cache.clearAll());
    });

    test('should clear the cache when the language changes', () async {
      await localeService.markCacheLanguage();
      final repo = buildWithLocale();
      await repo.applyLanguageChange();

      await localeService.setOverride(englishLanguage);
      await repo.applyLanguageChange();

      verify(() => cache.clearAll()).called(1);
      expect(localeService.isCacheLanguageStale, isFalse);
    });

    test('should prefer the cached title for saved items', () async {
      final repo = build(autoInit: false);
      when(() => local.getListItems(any())).thenAnswer(
        (_) async => [
          MediaListItem(id: 1, type: 'movie', title: 'Stored'),
          MediaListItem(id: 2, type: 'movie', title: 'Stored 2'),
        ],
      );
      when(() => cache.getItem(1, MediaType.movie)).thenReturn(
        MediaItem(id: 1, title: 'Titre', overview: '', releaseDate: ''),
      );
      when(() => cache.getItem(2, MediaType.movie)).thenReturn(null);

      final previews = await repo.getListPreviews('watchlist');

      expect(previews.map((p) => p.title), ['Titre', 'Stored 2']);
    });
  });
}
