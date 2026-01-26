import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
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
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    // Default: page 1 returns 2 items, page 2 returns empty
    when(
      () => mockRepository.discoverMedia(
        page: 1,
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) async => [
        MediaItem(
          id: 1,
          title: 'One',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.movie,
        ),
        MediaItem(
          id: 2,
          title: 'Two',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.movie,
        ),
      ],
    );

    when(
      () => mockRepository.discoverMedia(
        page: 2,
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <MediaItem>[]);
  });

  test('fetchNextPage sets hasMore=false when next page empty', () async {
    final provider = SearchProvider(mockRepository);

    // Start discovery mode by searching empty query
    await provider.searchMedia('');
    // Discovery mode returns both movies and tv items (two lists combined)
    expect(provider.items.length, equals(4));

    // Fetch next page (page 2 is empty)
    await provider.fetchNextPage();

    expect(provider.hasMore, isFalse);
    expect(provider.items.length, equals(4));
  });
}
