import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
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
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    provider = SearchProvider(mockRepository);
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
    test('should load all seen items into the cache map', () async {
      final seenItems = [
        SeenItem(tmdbId: 1, type: MediaType.movie, title: 'M', seenDate: DateTime(2023)),
        SeenItem(tmdbId: 2, type: MediaType.tv, title: 'T', seenDate: DateTime(2023), seasonNumber: 1, episodeNumber: 1),
        SeenItem(tmdbId: 2, type: MediaType.tv, title: 'T', seenDate: DateTime(2023), seasonNumber: 1, episodeNumber: 2),
      ];

      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => seenItems);

      await provider.loadAllSeenStatus();

      const movieItem = MediaItem(id: 1, title: 'M', overview: '', releaseDate: '', mediaType: MediaType.movie);
      const tvItem = MediaItem(id: 2, title: 'T', overview: '', releaseDate: '', mediaType: MediaType.tv);

      expect(provider.getSeenCount(movieItem), 1);
      expect(provider.getSeenCount(tvItem), 2);
    });

    test('markAsSeen should call repository and reload cache', () async {
      final item = SeenItem(tmdbId: 1, type: MediaType.movie, title: 'M', seenDate: DateTime(2023));
      
      when(() => mockRepository.markAsSeen(any())).thenAnswer((_) async {});
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => [item]);

      await provider.markAsSeen(item);

      verify(() => mockRepository.markAsSeen(item)).called(1);
      expect(provider.getSeenCount(const MediaItem(id: 1, title: 'M', overview: '', releaseDate: '')), 1);
    });
  });
}
