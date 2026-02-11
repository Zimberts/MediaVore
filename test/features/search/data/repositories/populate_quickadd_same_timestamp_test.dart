import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaListLocalDataSource local;
  late MockMediaRemoteDataSource remote;
  late MockMediaCache cache;
  late MediaRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(SeenItemModel(
      tmdbId: 1,
      type: 'tv',
      title: 'f',
      seenDate: DateTime.now(),
    ));
    registerFallbackValue(QuickAddItemModel(
      tmdbId: 1,
      type: 'tv',
      insertedAt: DateTime.now(),
    ));
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

  test('equal timestamps are grouped into a single tail', () async {
    final tmdbId = 200;

    final now = DateTime.now();
    // episodes 1 and 2 seen earlier, episodes 3 and 4 seen at the exact same time
    final seenItems = [
      SeenItemModel(tmdbId: tmdbId, type: 'tv', title: 'T', seenDate: now.subtract(Duration(days: 3)), seasonNumber: 1, episodeNumber: 1),
      SeenItemModel(tmdbId: tmdbId, type: 'tv', title: 'T', seenDate: now.subtract(Duration(days: 2)), seasonNumber: 1, episodeNumber: 2),
      SeenItemModel(tmdbId: tmdbId, type: 'tv', title: 'T', seenDate: now, seasonNumber: 1, episodeNumber: 3),
      SeenItemModel(tmdbId: tmdbId, type: 'tv', title: 'T', seenDate: now, seasonNumber: 1, episodeNumber: 4),
    ];

    when(() => local.getAllSeenItems()).thenAnswer((_) async => seenItems);
    when(() => local.getQuickAddItems()).thenAnswer((_) async => <QuickAddItemModel>[]);
    when(() => local.isOptedOut(any(), seasonNumber: any(named: 'seasonNumber'), episodeNumber: any(named: 'episodeNumber')))
        .thenAnswer((_) async => false);
    when(() => local.getSeenStatus(tmdbId, 'tv')).thenAnswer((_) async => seenItems);

    final media = MediaItem(
      id: tmdbId,
      title: 'T',
      overview: '',
      releaseDate: '2020-01-01',
      seasons: [
        TVSeason(id: 1, seasonNumber: 1, episodeCount: 10),
      ],
    );

    when(() => cache.getItem(tmdbId, MediaType.tv)).thenReturn(null);
    when(() => remote.getMediaItem(tmdbId, type: MediaType.tv)).thenAnswer((_) async => media);

    when(() => cache.cacheItem(any())).thenAnswer((_) async {});
    when(() => cache.isSeasonCached(any(), any())).thenReturn(false);
    when(() => cache.cacheSeason(any(), any(), any())).thenAnswer((_) async {});
    when(() => cache.getSeason(any(), any())).thenReturn(null);

    List<Map<String, dynamic>> makeEpisodes(int count) => List.generate(count, (i) => {
          'episode_number': i + 1,
          'air_date': '2020-01-0${(i % 9) + 1}',
        });

    when(() => remote.getSeasonDetails(tmdbId, 1)).thenAnswer((_) async => {'episodes': makeEpisodes(10)});

    final added = <QuickAddItemModel>[];
    when(() => local.addQuickAddItem(any())).thenAnswer((inv) async {
      final arg = inv.positionalArguments[0] as QuickAddItemModel;
      added.add(arg);
    });

    await repository.populateQuickAddFromSeenHistory();

    // Because episodes 3 and 4 share the exact same timestamp, they should be
    // considered the same tail and only produce one quick-add (for episode 5).
    expect(added.length, 1);
    final a = added.first;
    expect(a.seasonNumber, 1);
    expect(a.episodeNumber, 5);
  });
}
