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

  group('SearchProvider - Discovery & Search Filters', () {
    test('searchMedia with empty query should call discoverMedia for both Movie and TV when filterType is null', () async {
      when(() => mockRepository.discoverMedia(
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            language: any(named: 'language'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => []);

      await provider.searchMedia('');

      verify(() => mockRepository.discoverMedia(
            page: 1,
            type: MediaType.movie,
          )).called(1);
      verify(() => mockRepository.discoverMedia(
            page: 1,
            type: MediaType.tv,
          )).called(1);
      expect(provider.isDiscoverMode, isTrue);
    });

    test('searchMedia with query should call searchMedia on repository', () async {
       when(() => mockRepository.searchMedia(
            any(),
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            language: any(named: 'language'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => []);

      await provider.searchMedia('Inception');

      verify(() => mockRepository.searchMedia(
            'Inception',
            page: 1,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            type: any(named: 'type'),
          )).called(1);
      expect(provider.isDiscoverMode, isFalse);
    });

    test('should pass filters to repository calls', () async {
      provider.setFilters(
        genreIds: [28],
        releaseYear: 2022,
        minRating: 7.0,
        type: MediaType.movie,
      );

      when(() => mockRepository.searchMedia(
            any(),
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            language: any(named: 'language'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => []);

      await provider.searchMedia('Batman');

      verify(() => mockRepository.searchMedia(
            'Batman',
            page: 1,
            genreIds: [28],
            releaseYear: 2022,
            minRating: 7.0,
            type: MediaType.movie,
          )).called(1);
    });
  });

  group('SearchProvider - Media Details Enrichment', () {
    test('getMediaDetails should fetch extra data (similar, recommended, providers, videos)', () async {
      final tItem = const MediaItem(id: 1, title: 'T', overview: 'O', releaseDate: '2023');
      final tDetails = MediaDetails(
        item: tItem,
        cast: [],
        similar: [],
        recommendations: [],
        watchProviders: {},
        videos: [],
      );

      when(() => mockRepository.getMediaDetails(any(), type: any(named: 'type')))
          .thenAnswer((_) async => tDetails);

      final result = await provider.getMediaDetails(1, MediaType.movie);

      expect(result.similar, isNotNull);
      expect(result.recommendations, isNotNull);
      expect(result.watchProviders, isNotNull);
      expect(result.videos, isNotNull);
    });
  });

  group('SearchProvider - Offline Status', () {
    test('initial state should be online', () {
      expect(provider.isOffline, isFalse);
    });

    test('should set offline to true when network call fails', () async {
      when(() => mockRepository.discoverMedia(page: any(named: 'page')))
          .thenThrow(Exception('SocketException: Connection failed'));

      try {
        await provider.searchMedia('');
      } catch (_) {}

      expect(provider.isOffline, isTrue);
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
}
