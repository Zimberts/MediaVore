import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MediaRepositoryImpl repository;
  late MockMediaRemoteDataSource mockRemoteDataSource;
  late MockWatchlistLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRemoteDataSource = MockMediaRemoteDataSource();
    mockLocalDataSource = MockWatchlistLocalDataSource();
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
    const CastMember(name: 'Leonardo DiCaprio', character: 'Cobb', profilePath: '/leo.jpg'),
  ];

  const tDirector = CrewMember(name: 'Christopher Nolan', job: 'Director');

  group('searchMedia', () {
    const tQuery = 'Inception';
    final tMediaItems = [tMediaItem];

    test('should return list of media items from remote data source', () async {
      // arrange
      when(() => mockRemoteDataSource.searchMedia(tQuery))
          .thenAnswer((_) async => tMediaItems);

      // act
      final result = await repository.searchMedia(tQuery);

      // assert
      expect(result, equals(tMediaItems));
      verify(() => mockRemoteDataSource.searchMedia(tQuery)).called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });

  group('getMediaDetails', () {
    const tId = 1;

    test('should return media details with cast and director', () async {
      // arrange
      when(() => mockRemoteDataSource.getMediaItem(tId, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaItem);
      when(() => mockRemoteDataSource.getMediaCredits(tId, type: any(named: 'type')))
          .thenAnswer((_) async => {
            'cast': [
              {'name': 'Leonardo DiCaprio', 'character': 'Cobb', 'profile_path': '/leo.jpg'}
            ],
            'crew': [
              {'name': 'Christopher Nolan', 'job': 'Director'}
            ]
          });

      // act
      final result = await repository.getMediaDetails(tId);

      // assert
      expect(result.item, equals(tMediaItem));
      expect(result.cast, equals(tCast));
      expect(result.director, equals(tDirector));
    });
  });

  group('addToWatchlist', () {
    const tId = 1;
    const tType = MediaType.movie;

    test('should call local data source to add item', () async {
      // arrange
      when(() => mockLocalDataSource.addToWatchlist(tId, tType.name))
          .thenAnswer((_) async => Future.value());

      // act
      await repository.addToWatchlist(tId, tType);

      // assert
      verify(() => mockLocalDataSource.addToWatchlist(tId, tType.name)).called(1);
    });
  });

  group('removeFromWatchlist', () {
    const tId = 1;
    const tType = MediaType.movie;

    test('should call local data source to remove item', () async {
      // arrange
      when(() => mockLocalDataSource.removeFromWatchlist(tId, tType.name))
          .thenAnswer((_) async => Future.value());

      // act
      await repository.removeFromWatchlist(tId, tType);

      // assert
      verify(() => mockLocalDataSource.removeFromWatchlist(tId, tType.name)).called(1);
    });
  });

  group('getWatchlistEntries', () {
    final tEntries = ['1:movie', '2:tv'];

    test('should return list of entries from local data source', () async {
      // arrange
      when(() => mockLocalDataSource.getWatchlistEntries())
          .thenAnswer((_) async => tEntries);

      // act
      final result = await repository.getWatchlistEntries();

      // assert
      expect(result, equals(tEntries));
      verify(() => mockLocalDataSource.getWatchlistEntries()).called(1);
    });
  });

  group('isInWatchlist', () {
    const tId = 1;
    const tType = MediaType.movie;

    test('should return true when item is in watchlist', () async {
      // arrange
      when(() => mockLocalDataSource.getWatchlistEntries())
          .thenAnswer((_) async => ['1:movie', '2:tv']);

      // act
      final result = await repository.isInWatchlist(tId, tType);

      // assert
      expect(result, true);
    });

    test('should return false when item is not in watchlist', () async {
      // arrange
      when(() => mockLocalDataSource.getWatchlistEntries())
          .thenAnswer((_) async => ['2:tv']);

      // act
      final result = await repository.isInWatchlist(tId, tType);

      // assert
      expect(result, false);
    });
  });
}
