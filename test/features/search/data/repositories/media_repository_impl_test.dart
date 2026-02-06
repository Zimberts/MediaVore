import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
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

  setUp(() {
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

    repository = MediaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      cache: mockCache,
    );
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
      when(() => mockRemoteDataSource.searchMedia(tQuery))
          .thenAnswer((_) async => tMediaItems);

      final result = await repository.searchMedia(tQuery);

      expect(result, equals(tMediaItems));
      verify(() => mockRemoteDataSource.searchMedia(tQuery)).called(1);
      verify(() => mockCache.cacheItem(tMediaItem)).called(1);
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

    test('should return movie details with N/A director when no director found', () async {
      when(() => mockCache.areDetailsCached(tId, MediaType.movie)).thenReturn(false);
      when(() => mockRemoteDataSource.getMediaItem(tId, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaItem);
      when(() => mockRemoteDataSource.getMediaCredits(tId, type: any(named: 'type')))
          .thenAnswer((_) async => {
        'cast': [],
        'crew': [{'name': 'Someone', 'job': 'Writer'}]
      });

      final result = await repository.getMediaDetails(tId);

      expect(result.director, const CrewMember(name: 'N/A', job: 'Director'));
    });
  });

  group('getSeasonDetails', () {
    test('should call remote data source for season details', () async {
      final tData = {'episodes': []};
      when(() => mockRemoteDataSource.getSeasonDetails(any(), any()))
          .thenAnswer((_) async => tData);
      when(() => mockCache.isSeasonCached(any(), any())).thenReturn(false);
      when(() => mockCache.cacheSeason(any(), any(), any())).thenAnswer((_) async {});

      final result = await repository.getSeasonDetails(1, 1);

      expect(result, tData);
      verify(() => mockRemoteDataSource.getSeasonDetails(1, 1)).called(1);
    });
  });

  group('getActorDetails', () {
    const tActorId = 1;
    const tActorDetails = ActorDetails(
      id: 1,
      name: 'Leonardo DiCaprio',
      biography: 'Bio...',
      birthday: '1974-11-11',
      placeOfBirth: 'LA',
      profilePath: '/leo.jpg',
    );

    test('should return actor details with their movies and cache profile path', () async {
      when(() => mockRemoteDataSource.getActorDetails(tActorId)).thenAnswer((_) async => tActorDetails);
      when(() => mockRemoteDataSource.getActorMediaCredits(tActorId)).thenAnswer((_) async => [tMediaItem]);

      final result = await repository.getActorDetails(tActorId);

      expect(result.id, equals(tActorId));
      expect(result.items, contains(tMediaItem));
      verify(() => mockCache.cacheActorProfile(tActorId, '/leo.jpg')).called(1);
    });
  });

  group('Seen Items', () {
    final tSeenItem = SeenItem(
      tmdbId: 1,
      type: MediaType.movie,
      title: 'Dune',
      seenDate: DateTime(2023, 10, 1),
    );

    test('markAsSeen should call local data source', () async {
      when(() => mockLocalDataSource.markAsSeen(any())).thenAnswer((_) async {});
      await repository.markAsSeen(tSeenItem);
      verify(() => mockLocalDataSource.markAsSeen(any())).called(1);
    });

    test('removeFromSeen should call local data source', () async {
      when(() => mockLocalDataSource.removeFromSeen(any(), any(), 
          seasonNumber: any(named: 'seasonNumber'), 
          episodeNumber: any(named: 'episodeNumber')))
          .thenAnswer((_) async {});

      await repository.removeFromSeen(1, MediaType.movie);
      verify(() => mockLocalDataSource.removeFromSeen(1, 'movie')).called(1);
    });

    test('exportSeenData should call local data source with filters', () async {
      final tModel = SeenItemModel(
        tmdbId: 1,
        type: 'movie',
        title: 'Dune',
        seenDate: DateTime(2023, 10, 1),
      );
      when(() => mockLocalDataSource.getExportData(
        start: any(named: 'start'),
        end: any(named: 'end'),
        tmdbId: any(named: 'tmdbId'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => [tModel]);

      final result = await repository.exportSeenData(tmdbId: 1);

      expect(result.first['tmdbId'], 1);
      verify(() => mockLocalDataSource.getExportData(tmdbId: 1)).called(1);
    });

    test('importSeenData should call local data source with items and mode', () async {
      final tData = [
        {
          'tmdbId': 1,
          'type': 'movie',
          'title': 'Dune',
          'seenDate': '2023-10-01T00:00:00.000',
          'seasonNumber': null,
          'episodeNumber': null,
        }
      ];
      when(() => mockLocalDataSource.importSeenItems(any(), mode: any(named: 'mode')))
          .thenAnswer((_) async {});

      await repository.importSeenData(tData, mode: ImportMode.merge);

      verify(() => mockLocalDataSource.importSeenItems(any(), mode: ImportMode.merge)).called(1);
    });
  });

  group('Watchlist & Lists', () {
    test('addToWatchlist should call local data source and cache full details', () async {
      when(() => mockLocalDataSource.addToList(
        id: any(named: 'id'),
        type: any(named: 'type'),
        listName: any(named: 'listName'),
        title: any(named: 'title'),
      )).thenAnswer((_) async {});
      
      when(() => mockCache.areDetailsCached(any(), any())).thenReturn(true);
      when(() => mockCache.getDetails(any(), any())).thenReturn(
        MediaDetails(item: tMediaItem, cast: [], director: tDirector)
      );

      await repository.addToWatchlist(tMediaItem);

      verify(() => mockLocalDataSource.addToList(
        id: 1,
        type: 'movie',
        listName: 'watchlist',
        title: 'Inception',
      )).called(1);
      verify(() => mockCache.cacheItem(tMediaItem)).called(1);
    });

    test('isInWatchlist should check local entries', () async {
      when(() => mockLocalDataSource.getListEntries('watchlist'))
          .thenAnswer((_) async => ['1:movie']);

      final result = await repository.isInWatchlist(1, MediaType.movie);
      expect(result, isTrue);
    });
  });

  group('Cache Management', () {
    test('getCacheSize should return size from cache', () async {
      when(() => mockCache.getCacheSize()).thenAnswer((_) async => 2048);
      final size = await repository.getCacheSize();
      expect(size, 2048);
    });

    test('clearCache with complete true should call cache.clearAll', () async {
      await repository.clearCache(complete: true);
      verify(() => mockCache.clearAll()).called(1);
    });

    test('clearCache with complete false should trigger maintenance', () async {
      await repository.clearCache(complete: false);
      // Maintenance involves getting list names, items, etc.
      // Called once in _init during repository creation and once in clearCache
      verify(() => mockLocalDataSource.getAllListNames()).called(2);
    });

    test('fillCache should trigger maintenance', () async {
      await repository.fillCache();
      // Called once in _init during repository creation and once in fillCache
      verify(() => mockLocalDataSource.getAllListNames()).called(2);
    });
  });
});
}
