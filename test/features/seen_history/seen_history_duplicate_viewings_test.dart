import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    // Make getSeenItems return dynamic list controlled by test
  });

  test(
    'markAsSeen increments movie seen count and groups tv episodes correctly',
    () async {
      final seenList = <SeenItem>[];

      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => seenList);

      when(() => mockRepository.markAsSeen(any())).thenAnswer((inv) async {
        final item = inv.positionalArguments[0] as SeenItem;
        seenList.add(item);
      });

      when(
        () => mockRepository.getMediaDetails(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => throw UnimplementedError());

      final provider = SearchProvider(mockRepository);

      // Initially no seen
      expect(
        provider.getSeenCount(
          MediaItem(
            id: 100,
            title: 'X',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.movie,
          ),
        ),
        equals(0),
      );

      // Mark movie seen twice
      final movieSeen = SeenItem(
        tmdbId: 100,
        type: MediaType.movie,
        title: 'X',
        seenDate: DateTime.now(),
      );
      await provider.markAsSeen(movieSeen);
      await provider.markAsSeen(movieSeen);

      expect(
        provider.getSeenCount(
          MediaItem(
            id: 100,
            title: 'X',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.movie,
          ),
        ),
        equals(2),
      );

      // TV episodes: mark two different episodes
      final ep1 = SeenItem(
        tmdbId: 200,
        type: MediaType.tv,
        title: 'Show',
        seenDate: DateTime.now(),
        seasonNumber: 1,
        episodeNumber: 1,
      );
      final ep2 = SeenItem(
        tmdbId: 200,
        type: MediaType.tv,
        title: 'Show',
        seenDate: DateTime.now(),
        seasonNumber: 1,
        episodeNumber: 2,
      );

      await provider.markAsSeen(ep1);
      await provider.markAsSeen(ep2);

      // For TV, seen count should reflect unique season:episode pairs
      expect(
        provider.getSeenCount(
          MediaItem(
            id: 200,
            title: 'Show',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.tv,
          ),
        ),
        equals(2),
      );
    },
  );
}
