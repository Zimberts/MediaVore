import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late SearchProvider provider;
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(MediaType.tv);
    registerFallbackValue(SeenItem(
      tmdbId: 1,
      type: MediaType.movie,
      title: 'T',
      seenDate: DateTime(2000),
    ));
    registerFallbackValue(ImportMode.append);
    registerFallbackValue(const MediaItem(
      id: 0,
      title: '',
      overview: '',
      releaseDate: '',
    ));
  });

  setUp(() async {
    mockRepository = MockMediaRepository();

    // Default mocks for SearchProvider init
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.toggleNotification(any(), autoNotify: any(named: 'autoNotify')))
        .thenAnswer((_) async => Future.value());

    provider = SearchProvider(mockRepository);

    await untilCalled(() => mockRepository.getNotifiedItems());
    clearInteractions(mockRepository);
  });

  group('SearchProvider - Offline Status', () {
    test('initial state should be online', () {
      expect(provider.isOffline, isFalse);
    });

    test('should set offline to true when network call fails', () async {
      when(() => mockRepository.searchMedia(any(), page: any(named: 'page')))
          .thenThrow(Exception('SocketException: Connection failed'));

      try {
        await provider.searchMedia('Dune');
      } catch (_) {}

      expect(provider.isOffline, isTrue);
    });

    test('should set offline to false when network call succeeds', () async {
      provider.notifyNetworkError();
      expect(provider.isOffline, isTrue);

      when(() => mockRepository.searchMedia(any(), page: any(named: 'page')))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);

      await provider.searchMedia('Dune');

      expect(provider.isOffline, isFalse);
    });
  });

  group('SearchProvider - Seen Status', () {
    test('should load all seen items and deduplicate episodes for TV counts', () async {
      final seenItems = [
        SeenItem(tmdbId: 1, type: MediaType.movie, title: 'M', seenDate: DateTime(2023, 1, 1)),
        SeenItem(tmdbId: 1, type: MediaType.movie, title: 'M', seenDate: DateTime(2023, 1, 2)),
        SeenItem(tmdbId: 2, type: MediaType.tv, title: 'T', seenDate: DateTime(2023), seasonNumber: 1, episodeNumber: 1),
        SeenItem(tmdbId: 2, type: MediaType.tv, title: 'T', seenDate: DateTime(2023), seasonNumber: 1, episodeNumber: 1),
      ];

      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => seenItems);

      await provider.loadAllSeenStatus();

      const movieItem = MediaItem(id: 1, title: 'M', overview: '', releaseDate: '', mediaType: MediaType.movie);
      const tvItem = MediaItem(id: 2, title: 'T', overview: '', releaseDate: '', mediaType: MediaType.tv);

      expect(provider.getSeenCount(movieItem), 2);
      expect(provider.getSeenCount(tvItem), 1);
    });
  });

  group('SearchProvider - getNextEpisode (Watch Next)', () {
    const tTvId = 100; // Use unique ID for these tests
    final tSeasons = [
      const TVSeason(id: 1, seasonNumber: 1, episodeCount: 2, name: 'S1'),
      const TVSeason(id: 2, seasonNumber: 2, episodeCount: 1, name: 'S2'),
    ];
    final tTvItem = MediaItem(id: tTvId, title: 'Show', overview: '', releaseDate: '', mediaType: MediaType.tv, seasons: tSeasons);
    final tDetails = MediaDetails(item: tTvItem, cast: []);

    test('should return S1 E1 if nothing has been seen', () async {
      when(() => mockRepository.getSeenStatus(tTvId, MediaType.tv)).thenAnswer((_) async => []);
      when(() => mockRepository.getSeasonDetails(tTvId, 1)).thenAnswer((_) async => {
        'episodes': [{'episode_number': 1, 'air_date': '2020-01-01'}]
      });

      final result = await provider.getNextEpisode(tTvId);

      expect(result, isNotNull);
      expect(result?.seasonNumber, 1);
      expect(result?.episodeNumber, 1);
    });

    test('should return S1 E2 if S1 E1 is seen', () async {
      final seen = [
        SeenItem(tmdbId: tTvId, type: MediaType.tv, title: 'Show', seenDate: DateTime.now(), seasonNumber: 1, episodeNumber: 1),
      ];
      when(() => mockRepository.getSeenStatus(tTvId, MediaType.tv)).thenAnswer((_) async => seen);
      when(() => mockRepository.getMediaDetails(tTvId, type: MediaType.tv)).thenAnswer((_) async => tDetails);
      when(() => mockRepository.getSeasonDetails(tTvId, 1)).thenAnswer((_) async => {
        'episodes': [
          {'episode_number': 1, 'air_date': '2020-01-01'},
          {'episode_number': 2, 'air_date': '2020-01-01'},
        ]
      });

      final result = await provider.getNextEpisode(tTvId);

      expect(result, isNotNull);
      expect(result?.seasonNumber, 1);
      expect(result?.episodeNumber, 2);
    });

    test('should move to S2 E1 if last episode of S1 is seen', () async {
      final seen = [
        SeenItem(tmdbId: tTvId, type: MediaType.tv, title: 'Show', seenDate: DateTime.now(), seasonNumber: 1, episodeNumber: 2),
      ];
      when(() => mockRepository.getSeenStatus(tTvId, MediaType.tv)).thenAnswer((_) async => seen);
      when(() => mockRepository.getMediaDetails(tTvId, type: MediaType.tv)).thenAnswer((_) async => tDetails);
      when(() => mockRepository.getSeasonDetails(tTvId, 2)).thenAnswer((_) async => {
        'episodes': [{'episode_number': 1, 'air_date': '2020-01-01'}]
      });

      final result = await provider.getNextEpisode(tTvId);

      expect(result, isNotNull);
      expect(result?.seasonNumber, 2);
      expect(result?.episodeNumber, 1);
    });

    test('should return null if the next episode air date is in the future', () async {
      when(() => mockRepository.getSeenStatus(tTvId, MediaType.tv)).thenAnswer((_) async => []);
      when(() => mockRepository.getSeasonDetails(tTvId, 1)).thenAnswer((_) async => {
        'episodes': [{'episode_number': 1, 'air_date': '2099-01-01'}]
      });

      final result = await provider.getNextEpisode(tTvId);

      expect(result, isNull);
    });

    test('should return null if all episodes are seen', () async {
      final seen = [
        SeenItem(tmdbId: tTvId, type: MediaType.tv, title: 'Show', seenDate: DateTime.now(), seasonNumber: 2, episodeNumber: 1),
      ];
      when(() => mockRepository.getSeenStatus(tTvId, MediaType.tv)).thenAnswer((_) async => seen);
      when(() => mockRepository.getMediaDetails(tTvId, type: MediaType.tv)).thenAnswer((_) async => tDetails);

      final result = await provider.getNextEpisode(tTvId);

      expect(result, isNull);
    });
  });
}
