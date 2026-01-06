import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
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
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);

    provider = SearchProvider(mockRepository);
    
    // The SearchProvider calls several async methods in its constructor (_init).
    await untilCalled(() => mockRepository.getWatchlistEntries());
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
      // 1. Arrange offline state
      provider.notifyNetworkError();
      expect(provider.isOffline, isTrue);

      // 2. Mock success
      when(() => mockRepository.searchMedia(any(), page: any(named: 'page')))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);

      // 3. Act
      await provider.searchMedia('Dune');

      // 4. Assert
      expect(provider.isOffline, isFalse);
    });
  });

  group('SearchProvider - Seen Status', () {
    test('should load all seen items and deduplicate episodes for TV counts', () async {
      final seenItems = [
        SeenItem(tmdbId: 1, type: MediaType.movie, title: 'M', seenDate: DateTime(2023, 1, 1)),
        SeenItem(tmdbId: 1, type: MediaType.movie, title: 'M', seenDate: DateTime(2023, 1, 2)), // Same movie, twice
        SeenItem(tmdbId: 2, type: MediaType.tv, title: 'T', seenDate: DateTime(2023), seasonNumber: 1, episodeNumber: 1),
        SeenItem(tmdbId: 2, type: MediaType.tv, title: 'T', seenDate: DateTime(2023), seasonNumber: 1, episodeNumber: 1), // Same episode, twice
      ];

      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => seenItems);

      await provider.loadAllSeenStatus();

      const movieItem = MediaItem(id: 1, title: 'M', overview: '', releaseDate: '', mediaType: MediaType.movie);
      const tvItem = MediaItem(id: 2, title: 'T', overview: '', releaseDate: '', mediaType: MediaType.tv);

      // Movie should count total viewings (2)
      expect(provider.getSeenCount(movieItem), 2);
      // TV should count unique episodes only (1)
      expect(provider.getSeenCount(tvItem), 1);
    });

    test('markAsSeen should call repository and reload cache', () async {
      final item = SeenItem(tmdbId: 1, type: MediaType.movie, title: 'M', seenDate: DateTime(2023));
      
      when(() => mockRepository.markAsSeen(any())).thenAnswer((_) async {});
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => [item]);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 10);

      await provider.markAsSeen(item);

      verify(() => mockRepository.markAsSeen(item)).called(1);
      expect(provider.getSeenCount(const MediaItem(id: 1, title: 'M', overview: '', releaseDate: '')), 1);
    });
  });

  group('SearchProvider - Import/Export', () {
    test('exportSeenData should call repository with filters', () async {
      final start = DateTime(2023);
      final end = DateTime(2024);
      when(() => mockRepository.exportSeenData(
        start: any(named: 'start'),
        end: any(named: 'end'),
        tmdbId: any(named: 'tmdbId'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => []);

      await provider.exportSeenData(start: start, end: end);

      verify(() => mockRepository.exportSeenData(start: start, end: end)).called(1);
    });

    test('importSeenData should call repository and refresh state', () async {
      final data = <Map<String, dynamic>>[];
      when(() => mockRepository.importSeenData(any(), mode: any(named: 'mode')))
          .thenAnswer((_) async {});
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
      when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 100);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 200);

      await provider.importSeenData(data, mode: ImportMode.replace);

      verify(() => mockRepository.importSeenData(data, mode: ImportMode.replace)).called(1);
      verify(() => mockRepository.getSeenItems()).called(1);
      verify(() => mockRepository.getCacheSize()).called(1);
      verify(() => mockRepository.getSeenDbSize()).called(1);
    });
  });

  group('SearchProvider - Database Isolation', () {
    test('seenDbSize should only update when seen history changes', () async {
      // 1. Initial state
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 100);
      await provider.updateSeenDbSize();
      expect(provider.seenDbSize, 100);

      // 2. Seen History Change -> Should update size
      when(() => mockRepository.markAsSeen(any())).thenAnswer((_) async {});
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 150); // Increased
      
      final item = SeenItem(tmdbId: 1, type: MediaType.movie, title: 'T', seenDate: DateTime.now());
      await provider.markAsSeen(item);
      expect(provider.seenDbSize, 150);

      // 3. List Database Change -> Should NOT trigger seenDbSize update
      when(() => mockRepository.addToList(any(), any())).thenAnswer((_) async {});
      when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => ['1:movie']);
      
      const mediaItem = MediaItem(id: 1, title: 'T', overview: '', releaseDate: '');
      await provider.toggleInList(mediaItem, 'watchlist');
      
      // We check that the count hasn't increased since the markAsSeen call
      // (1 initial + 1 markAsSeen = 2)
      verify(() => mockRepository.getSeenDbSize()).called(2);
    });
  });
}
