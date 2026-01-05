import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MediaRepositoryImpl repository;
  late MockMediaRemoteDataSource mockRemoteDataSource;
  late MockMediaListLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(SeenItemModel(
      tmdbId: 1, 
      type: 'movie', 
      title: 'T', 
      seenDate: DateTime(2000)
    ));
  });

  setUp(() {
    mockRemoteDataSource = MockMediaRemoteDataSource();
    mockLocalDataSource = MockMediaListLocalDataSource();
    repository = MediaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
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

    test('should return list of media items from remote data source', () async {
      when(() => mockRemoteDataSource.searchMedia(tQuery))
          .thenAnswer((_) async => tMediaItems);

      final result = await repository.searchMedia(tQuery);

      expect(result, equals(tMediaItems));
      verify(() => mockRemoteDataSource.searchMedia(tQuery)).called(1);
    });
   group('getMediaDetails', () {
    const tId = 1;

    test('should return media details with cast and director', () async {
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
    });

    test('should return movie details with N/A director when no director found', () async {
      when(() => mockRemoteDataSource.getMediaItem(tId, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaItem);
      when(() => mockRemoteDataSource.getMediaCredits(tId, type: any(named: 'type')))
          .thenAnswer((_) async => {
        'cast': [],
        'crew': [{'name': 'Someone', 'job': 'Writer'}]
      });

      final result = await repository.getMediaDetails(tId);

      expect(result.director, CrewMember(name: 'N/A', job: 'Director'));
    });
  });

  group('getSeasonDetails', () {
    test('should call remote data source for season details', () async {
      final tData = {'episodes': []};
      when(() => mockRemoteDataSource.getSeasonDetails(any(), any()))
          .thenAnswer((_) async => tData);

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

    test('should return actor details with their movies', () async {
      when(() => mockRemoteDataSource.getActorDetails(tActorId)).thenAnswer((_) async => tActorDetails);
      when(() => mockRemoteDataSource.getActorMediaCredits(tActorId)).thenAnswer((_) async => [tMediaItem]);

      final result = await repository.getActorDetails(tActorId);

      expect(result.id, equals(tActorId));
      expect(result.items, contains(tMediaItem));
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
  });

  group('Watchlist & Lists', () {
    test('addToWatchlist should call local data source', () async {
      when(() => mockLocalDataSource.addToList(
        id: any(named: 'id'),
        type: any(named: 'type'),
        listName: any(named: 'listName'),
        title: any(named: 'title'),
        posterPath: any(named: 'posterPath'),
      )).thenAnswer((_) async {});

      await repository.addToWatchlist(tMediaItem);

      verify(() => mockLocalDataSource.addToList(
        id: 1,
        type: 'movie',
        listName: 'watchlist',
        title: 'Inception',
        posterPath: '/path.jpg',
      )).called(1);
    });

    test('isInWatchlist should check local entries', () async {
      when(() => mockLocalDataSource.getListEntries('watchlist'))
          .thenAnswer((_) async => ['1:movie']);

      final result = await repository.isInWatchlist(1, MediaType.movie);
      expect(result, isTrue);
    });
  });
});
}
