import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

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

  test('future and unaired episodes are skipped in quick add population', () async {
    final tmdbId = 300;

    final now = DateTime.now();
    // Watch up to episode 16
    final seenItems = List.generate(
      16,
      (i) => SeenItemModel(
        tmdbId: tmdbId,
        type: 'tv',
        title: 'T',
        seenDate: now.subtract(Duration(days: 16 - i)),
        seasonNumber: 1,
        episodeNumber: i + 1,
      ),
    );

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
        TVSeason(id: 1, seasonNumber: 1, episodeCount: 18),
      ],
    );

    when(() => cache.getItem(tmdbId, MediaType.tv)).thenReturn(null);
    when(() => remote.getMediaItem(tmdbId, type: MediaType.tv)).thenAnswer((_) async => media);

    when(() => cache.cacheItem(any())).thenAnswer((_) async {});
    when(() => cache.isSeasonCached(any(), any())).thenReturn(false);
    when(() => cache.cacheSeason(any(), any(), any())).thenAnswer((_) async {});
    when(() => cache.getSeason(any(), any())).thenReturn(null);

    // Provide episode info logic
    when(() => remote.getSeasonDetails(tmdbId, 1)).thenAnswer((_) async => {
          'episodes': List.generate(18, (i) {
            final epNum = i + 1;
            String? airDate;

            if (epNum <= 16) {
              // Past episodes
              airDate = now.subtract(Duration(days: 30 - i)).toIso8601String().substring(0, 10);
            } else if (epNum == 17) {
              // Future episode
              airDate = now.add(Duration(days: 7)).toIso8601String().substring(0, 10);
            } else if (epNum == 18) {
              // Unaired (null)
              airDate = null;
            }

            return {
              'episode_number': epNum,
              'air_date': airDate,
            };
          }),
        });

    final added = <QuickAddItemModel>[];
    when(() => local.addQuickAddItem(any())).thenAnswer((inv) async {
      final arg = inv.positionalArguments[0] as QuickAddItemModel;
      added.add(arg);
    });

    await repository.populateQuickAddFromSeenHistory();

    // Since episode 17 is in the future, and 18 has no air date, 
    // the system should NOT add any to quick add since the next available episode hasn't aired yet.
    expect(added.isEmpty, isTrue, reason: "Expected 0 quick-adds because ep 17 is future and ep 18 is unaired");
  });

  test('markAsSeen also skips future and unaired episodes when computing next quick add', () async {
    final tmdbId = 300;
    final now = DateTime.now();
    
    // Simulate marking episode 16 as seen
    final item = SeenItem(
      id: 1,
      tmdbId: tmdbId,
      type: MediaType.tv,
      title: 'T',
      seenDate: now,
      seasonNumber: 1,
      episodeNumber: 16,
    );

    // We need to return MediaItem for the series so the repository can inspect it
    final detailsItem = MediaItem(
      id: tmdbId,
      title: 'T',
      overview: '',
      releaseDate: '2020-01-01',
      mediaType: MediaType.tv,
      seasons: [
        TVSeason(id: 1, seasonNumber: 1, episodeCount: 18),
      ],
    );
    when(() => remote.getMediaItem(tmdbId, type: MediaType.tv)).thenAnswer((_) async => detailsItem);

    when(() => local.getAllSeenItems()).thenAnswer((_) async => [
      SeenItemModel(
        tmdbId: tmdbId,
        type: 'tv',
        title: 'T',
        seenDate: now,
        seasonNumber: 1,
        episodeNumber: 16,
      )
    ]);
    when(() => local.markAsSeen(any())).thenAnswer((_) async {});
    when(() => local.removeQuickAddItemByTmdbSeasonEpisode(any(), seasonNumber: any(named: 'seasonNumber'), episodeNumber: any(named: 'episodeNumber'))).thenAnswer((_) async {});
    when(() => local.isOptedOut(any(), seasonNumber: any(named: 'seasonNumber'), episodeNumber: any(named: 'episodeNumber'))).thenAnswer((_) async => false);
    when(() => local.getQuickAddItems()).thenAnswer((_) async => <QuickAddItemModel>[]);
    when(() => local.getSeenStatus(tmdbId, 'tv')).thenAnswer((_) async => <SeenItemModel>[
      SeenItemModel(
        tmdbId: tmdbId,
        type: 'tv',
        title: 'T',
        seenDate: now,
        seasonNumber: 1,
        episodeNumber: 16,
      )
    ]);

    when(() => cache.cacheItem(any())).thenAnswer((_) async {});
    when(() => cache.isSeasonCached(any(), any())).thenReturn(false);
    when(() => cache.cacheSeason(any(), any(), any())).thenAnswer((_) async {});
    when(() => cache.getSeason(any(), any())).thenReturn(null);

    when(() => remote.getSeasonDetails(tmdbId, 1)).thenAnswer((_) async => {
          'episodes': List.generate(18, (i) {
            final epNum = i + 1;
            String? airDate;
            if (epNum <= 16) {
              airDate = now.subtract(Duration(days: 30 - i)).toIso8601String().substring(0, 10);
            } else if (epNum == 17) {
              airDate = now.add(Duration(days: 7)).toIso8601String().substring(0, 10); // future
            } else {
              airDate = null; // unaired
            }
            return {
              'episode_number': epNum,
              'air_date': airDate,
            };
          }),
        });

    final addedQuickAdds = <QuickAddItemModel>[];
    when(() => local.addQuickAddItem(any())).thenAnswer((inv) async {
      addedQuickAdds.add(inv.positionalArguments[0] as QuickAddItemModel);
    });

    await repository.markAsSeen(item);

    // Assuming we remove it from watchlist since markAsSeen tries to do that
    verifyNever(() => local.addQuickAddItem(any()));
    expect(addedQuickAdds.isEmpty, isTrue, reason: "When marking episode 16 as seen, we shouldn't get 17 or 18 as quick add because they are unaired/future");
  });
}