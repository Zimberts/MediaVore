import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaListLocalDataSource local;
  late MockMediaRemoteDataSource remote;
  late MockMediaCache cache;
  late MediaRepositoryImpl repository;

  const tmdbId = 500;

  setUpAll(() {
    registerFallbackValue(
      SeenItemModel(
        tmdbId: 1,
        type: 'tv',
        title: 'f',
        seenDate: DateTime.now(),
      ),
    );
    registerFallbackValue(
      QuickAddItemModel(tmdbId: 1, type: 'tv', insertedAt: DateTime.now()),
    );
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    local = MockMediaListLocalDataSource();
    remote = MockMediaRemoteDataSource();
    cache = MockMediaCache();

    repository = MediaRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      cache: cache,
      autoInit: false,
    );
  });

  SeenItemModel seenFirstEpisode() => SeenItemModel(
    tmdbId: tmdbId,
    type: 'tv',
    title: 'Show',
    seenDate: DateTime.now().subtract(const Duration(days: 7)),
    seasonNumber: 1,
    episodeNumber: 1,
  );

  MediaItem showItem() => MediaItem(
    id: tmdbId,
    title: 'Show',
    overview: '',
    releaseDate: '2020-01-01',
    seasons: [TVSeason(id: 1, seasonNumber: 1, episodeCount: 3)],
  );

  Map<String, dynamic> seasonWith(List<Map<String, dynamic>> episodes) => {
    'episodes': episodes,
  };

  void stubSingleSeenEpisode() {
    final seen = [seenFirstEpisode()];
    when(() => local.getAllSeenItems()).thenAnswer((_) async => seen);
    when(() => local.getSeenStatus(tmdbId, 'tv')).thenAnswer((_) async => seen);
  }

  void stubEpisodesE1AiredE2Aired() {
    when(() => cache.getSeason(tmdbId, 1)).thenAnswer((_) async => 
      seasonWith([
        {'episode_number': 1, 'air_date': '2020-01-01'},
        {'episode_number': 2, 'air_date': '2020-01-08'},
      ]),
    );
  }

  test('should report opted out when the streak was dismissed', () async {
    stubSingleSeenEpisode();
    when(() => local.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => showItem());
    stubEpisodesE1AiredE2Aired();
    when(
      () => local.isOptedOut(
        any(),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer((_) async => true);

    final omissions = await repository.getQuickAddOmissions();

    expect(omissions, hasLength(1));
    expect(omissions.single.reason, QuickAddOmissionReason.optedOut);
    expect(omissions.single.seasonNumber, 1);
    expect(omissions.single.episodeNumber, 2);
  });

  test('should report notPopulated when an aired episode is missing', () async {
    stubSingleSeenEpisode();
    when(() => local.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => showItem());
    stubEpisodesE1AiredE2Aired();
    when(
      () => local.isOptedOut(
        any(),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer((_) async => false);

    final omissions = await repository.getQuickAddOmissions();

    expect(omissions, hasLength(1));
    expect(omissions.single.reason, QuickAddOmissionReason.notPopulated);
    expect(omissions.single.episodeNumber, 2);
  });

  test(
    'should report nothing when the episode is already in quick add',
    () async {
      stubSingleSeenEpisode();
      when(() => local.getQuickAddItems()).thenAnswer(
        (_) async => [
          QuickAddItemModel(
            tmdbId: tmdbId,
            type: 'tv',
            seasonNumber: 1,
            episodeNumber: 2,
            insertedAt: DateTime.now(),
          ),
        ],
      );
      when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => showItem());
      stubEpisodesE1AiredE2Aired();

      final omissions = await repository.getQuickAddOmissions();

      expect(omissions, isEmpty);
    },
  );

  test(
    'should report notReleased when the next episode has not aired',
    () async {
      stubSingleSeenEpisode();
      when(() => local.getQuickAddItems()).thenAnswer((_) async => []);
      when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => showItem());
      final futureStr = DateTime.now()
          .add(const Duration(days: 10))
          .toIso8601String()
          .substring(0, 10);
      when(() => cache.getSeason(tmdbId, 1)).thenAnswer((_) async => 
        seasonWith([
          {'episode_number': 1, 'air_date': '2020-01-01'},
          {'episode_number': 2, 'air_date': futureStr},
        ]),
      );

      final omissions = await repository.getQuickAddOmissions();

      expect(omissions, hasLength(1));
      expect(omissions.single.reason, QuickAddOmissionReason.notReleased);
      expect(omissions.single.episodeNumber, 2);
      expect(omissions.single.airDate, isNotNull);
    },
  );

  test('should report noCacheData when show metadata is not cached', () async {
    stubSingleSeenEpisode();
    when(() => local.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => null);

    final omissions = await repository.getQuickAddOmissions();

    expect(omissions, hasLength(1));
    expect(omissions.single.reason, QuickAddOmissionReason.noCacheData);
    verifyNever(() => remote.getMediaItem(tmdbId, type: MediaType.tv));
  });

  test('should fetch when allowFetch is true', () async {
    stubSingleSeenEpisode();
    when(() => local.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => null);
    when(
      () => remote.getMediaItem(tmdbId, type: MediaType.tv),
    ).thenAnswer((_) async => showItem());
    when(() => cache.cacheItem(any())).thenAnswer((_) async {});
    stubEpisodesE1AiredE2Aired();
    when(
      () => local.isOptedOut(
        any(),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
      ),
    ).thenAnswer((_) async => true);

    final omissions = await repository.getQuickAddOmissions(allowFetch: true);

    expect(omissions.single.reason, QuickAddOmissionReason.optedOut);
    verify(() => remote.getMediaItem(tmdbId, type: MediaType.tv)).called(1);
  });

  test('should ignore an announced next season with no air dates', () async {
    // A fully-watched show whose only "next" is an announced but unscheduled
    // season must not surface as a "no air date" omission.
    final now = DateTime.now();
    final seen = [
      SeenItemModel(
        tmdbId: tmdbId,
        type: 'tv',
        title: 'Show',
        seenDate: now.subtract(const Duration(days: 2)),
        seasonNumber: 1,
        episodeNumber: 1,
      ),
      SeenItemModel(
        tmdbId: tmdbId,
        type: 'tv',
        title: 'Show',
        seenDate: now.subtract(const Duration(days: 1)),
        seasonNumber: 1,
        episodeNumber: 2,
      ),
    ];
    when(() => local.getAllSeenItems()).thenAnswer((_) async => seen);
    when(() => local.getSeenStatus(tmdbId, 'tv')).thenAnswer((_) async => seen);
    when(() => local.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => 
      MediaItem(
        id: tmdbId,
        title: 'Show',
        overview: '',
        releaseDate: '2020-01-01',
        seasons: [
          TVSeason(id: 1, seasonNumber: 1, episodeCount: 2),
          TVSeason(id: 2, seasonNumber: 2, episodeCount: 3),
        ],
      ),
    );
    when(() => cache.getSeason(tmdbId, 1)).thenAnswer((_) async => 
      seasonWith([
        {'episode_number': 1, 'air_date': '2020-01-01'},
        {'episode_number': 2, 'air_date': '2020-01-08'},
      ]),
    );
    when(() => cache.getSeason(tmdbId, 2)).thenAnswer((_) async => 
      seasonWith([
        {'episode_number': 1, 'air_date': null},
        {'episode_number': 2, 'air_date': null},
        {'episode_number': 3, 'air_date': null},
      ]),
    );

    final omissions = await repository.getQuickAddOmissions();

    expect(omissions, isEmpty);
  });

  test(
    'should match the opt-out to the found episode, not the streak tail',
    () async {
      stubSingleSeenEpisode(); // tail = S1E1
      when(() => local.getQuickAddItems()).thenAnswer((_) async => []);
      when(() => cache.getItem(tmdbId, MediaType.tv)).thenAnswer((_) async => showItem());
      stubEpisodesE1AiredE2Aired(); // found = S1E2
      when(
        () => local.isOptedOut(
          any(),
          seasonNumber: any(named: 'seasonNumber'),
          episodeNumber: any(named: 'episodeNumber'),
        ),
      ).thenAnswer(
        (inv) async =>
            inv.namedArguments[#seasonNumber] == 1 &&
            inv.namedArguments[#episodeNumber] == 2,
      );

      final omissions = await repository.getQuickAddOmissions();

      expect(omissions.single.reason, QuickAddOmissionReason.optedOut);
      expect(omissions.single.seasonNumber, 1);
      expect(omissions.single.episodeNumber, 2);
    },
  );
}
