import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MediaRepositoryImpl repository;
  late MockMediaRemoteDataSource mockRemoteDataSource;
  late MockMediaListLocalDataSource mockLocalDataSource;
  late MockMediaCache mockCache;
  late MockMediaListLocalDataSource mockLocalDataSource;
  late MockMediaCache mockCache;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(SeenItemModel(
      tmdbId: 1,
      type: 'movie',
      title: 'T',
      seenDate: DateTime(2000)
    ));
    registerFallbackValue(const MediaItem(
      id: 0,
      title: '',
      overview: '',
      releaseDate: ''
    ));
    registerFallbackValue(MediaDetails(
      item: const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
      cast: const [],
    ));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(ImportMode.append);
  });

  setUp(() async {
  setUp(() async {
    mockRemoteDataSource = MockMediaRemoteDataSource();
    mockLocalDataSource = MockMediaListLocalDataSource();
    mockCache = MockMediaCache();

    // Mock cache and data source setup
    when(() => mockCache.init()).thenAnswer((_) async {});
    when(() => mockCache.cleanup(keepKeys: any(named: 'keepKeys'), olderThan: any(named: 'olderThan')))
        .thenAnswer((_) async {});
    when(() => mockCache.cacheItem(any())).thenAnswer((_) async {});
    when(() => mockCache.cacheDetails(any())).thenAnswer((_) async {});
    when(() => mockCache.cacheActorProfile(any(), any())).thenAnswer((_) async {});
    when(() => mockCache.clearAll()).thenAnswer((_) async {});
    when(() => mockCache.getCacheSize()).thenAnswer((_) async => 1024);
    when(() => mockCache.isItemCached(any(), any())).thenReturn(false);
    when(() => mockCache.areDetailsCached(any(), any())).thenReturn(false);
    when(() => mockCache.isSeasonCached(any(), any())).thenReturn(false);
    when(() => mockCache.cacheSeason(any(), any(), any())).thenAnswer((_) async {});

    when(() => mockLocalDataSource.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockLocalDataSource.getListItems(any())).thenAnswer((_) async => []);
    when(() => mockLocalDataSource.getAllSeenItems()).thenAnswer((_) async => []);
    when(() => mockLocalDataSource.getLikedItems()).thenAnswer((_) async => []);
    when(() => mockLocalDataSource.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockLocalDataSource.isNotified(any(), any())).thenAnswer((_) async => false);
    when(() => mockLocalDataSource.toggleNotification(
      tmdbId: any(named: 'tmdbId'),
      type: any(named: 'type'),
      title: any(named: 'title'),
      posterPath: any(named: 'posterPath'),
      releaseDate: any(named: 'releaseDate'),
      seasonNumber: any(named: 'seasonNumber'),
      episodeNumber: any(named: 'episodeNumber'),
      autoNotify: any(named: 'autoNotify'),
    )).thenAnswer((_) async => Future.value());

    repository = MediaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      cache: mockCache,
    );

    // Wait for the background initialization to complete by calling a method
    // that ensures initialization.
    await repository.getAllListNames();

    // Clear interactions that happened during repository initialization (_initCache)
    // so tests can verify exact call counts for their specific operations.
    clearInteractions(mockRemoteDataSource);
    clearInteractions(mockLocalDataSource);
    clearInteractions(mockCache);
      cache: mockCache,
    );

    // Wait for the background initialization to complete by calling a method
    // that ensures initialization.
    await repository.getAllListNames();

    // Clear interactions that happened during repository initialization (_initCache)
    // so tests can verify exact call counts for their specific operations.
    clearInteractions(mockRemoteDataSource);
    clearInteractions(mockLocalDataSource);
    clearInteractions(mockCache);
  });

  const tMediaItem = MediaItem(
    id: 1,
    title: 'Inception',
    posterPath: '/path.jpg',
    overview: 'Overview...',
    releaseDate: '2010-07-16',
    mediaType: MediaType.movie,
  );

  final tCast = [
    const CastMember(id: 1, name: 'Leonardo DiCaprio', character: 'Cobb', profilePath: '/leo.jpg'),
  ];

  const tDirector = CrewMember(name: 'Christopher Nolan', job: 'Director');

  group('searchMedia', () {
    const tQuery = 'Inception';
    final tMediaItems = [tMediaItem];

    test('should return list of media items from remote data source and cache them', () async {
    test('should return list of media items from remote data source and cache them', () async {
      when(() => mockRemoteDataSource.searchMedia(tQuery))
          .thenAnswer((_) async => tMediaItems);

      final result = await repository.searchMedia(tQuery);

      expect(result, equals(tMediaItems));
      verify(() => mockRemoteDataSource.searchMedia(tQuery)).called(1);
      verify(() => mockCache.cacheItem(tMediaItem)).called(1);
    });

    test('should return empty list when remote call throws an exception (resilience test)', () async {
      when(() => mockRemoteDataSource.searchMedia(any()))
          .thenThrow(Exception('Network error'));

      final result = await repository.searchMedia(tQuery);

      expect(result, isEmpty);
    });
   group('getMediaDetails', () {
    const tId = 1;

    test('should return media details from cache if available', () async {
      final tDetails = MediaDetails(item: tMediaItem, cast: [], director: tDirector);
      when(() => mockCache.areDetailsCached(tId, MediaType.movie)).thenReturn(true);
      when(() => mockCache.getDetails(tId, MediaType.movie)).thenReturn(tDetails);

      final result = await repository.getMediaDetails(tId);

      expect(result, equals(tDetails));
      verifyNever(() => mockRemoteDataSource.getMediaItem(any(), type: any(named: 'type')));
    });

    test('should fetch and cache media details if not in cache', () async {
      when(() => mockCache.areDetailsCached(tId, MediaType.movie)).thenReturn(false);
    test('should return media details from cache if available', () async {
      final tDetails = MediaDetails(item: tMediaItem, cast: [], director: tDirector);
      when(() => mockCache.areDetailsCached(tId, MediaType.movie)).thenReturn(true);
      when(() => mockCache.getDetails(tId, MediaType.movie)).thenReturn(tDetails);

      final result = await repository.getMediaDetails(tId);

      expect(result, equals(tDetails));
      verifyNever(() => mockRemoteDataSource.getMediaItem(any(), type: any(named: 'type')));
    });

    test('should fetch and cache media details if not in cache', () async {
      when(() => mockCache.areDetailsCached(tId, MediaType.movie)).thenReturn(false);
      when(() => mockRemoteDataSource.getMediaItem(tId, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaItem);
      when(() => mockRemoteDataSource.getMediaCredits(tId, type: any(named: 'type')))
          .thenAnswer((_) async => {
            'cast': [
              {'id':1,'name': 'Leonardo DiCaprio', 'character': 'Cobb', 'profile_path': '/leo.jpg'}
            ],
            'crew': [
              {'name': 'Christopher Nolan', 'job': 'Director'}
            ]
          });

      final result = await repository.getMediaDetails(tId);

      expect(result.item, equals(tMediaItem));
      expect(result.cast, equals(tCast));
      expect(result.director, equals(tDirector));
      verify(() => mockCache.cacheDetails(any())).called(1);
    });
  });

  group('Seen Items', () {
    test('markAsSeen should call local data source and check notifications', () async {
      when(() => mockLocalDataSource.markAsSeen(any())).thenAnswer((_) async {});
      when(() => mockLocalDataSource.isNotified(any(), any())).thenAnswer((_) async => false);

      final tSeenItem = SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'Dune',
        seenDate: DateTime(2023, 10, 1),
      );

      // Ensure cache returns the item so the background notification refresher
      // uses the cached item path and calls `localDataSource.isNotified`.
      when(() => mockCache.getItem(1, MediaType.movie)).thenReturn(tMediaItem);

      await repository.markAsSeen(tSeenItem);

      verify(() => mockLocalDataSource.markAsSeen(any())).called(1);
      // isNotified is called inside unawaited _refreshNotificationDateByTmdbId
      await untilCalled(() => mockLocalDataSource.isNotified(any(), any()));
      verify(() => mockLocalDataSource.isNotified(1, 'movie')).called(1);
    });
  });

  group('Notifications', () {
    test('toggleNotification should call local data source', () async {
      when(() => mockLocalDataSource.isNotified(any(), any())).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.toggleNotification(
        tmdbId: any(named: 'tmdbId'),
        type: any(named: 'type'),
        title: any(named: 'title'),
        posterPath: any(named: 'posterPath'),
        releaseDate: any(named: 'releaseDate'),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
        autoNotify: any(named: 'autoNotify'),
      )).thenAnswer((_) async => Future.value());

      await repository.toggleNotification(tMediaItem);

      verify(() => mockLocalDataSource.toggleNotification(
        tmdbId: tMediaItem.id,
        type: tMediaItem.mediaType.name,
        title: tMediaItem.title,
        posterPath: any(named: 'posterPath'),
        autoNotify: any(named: 'autoNotify'),
      )).called(1);
    });
  });
}
