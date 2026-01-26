import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
  });

  setUp(() {
    repo = MockMediaRepository();
    registerFallbackValue(FakeMediaItem());

    when(() => repo.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => repo.getListEntries(any())).thenAnswer((_) async => <String>[]);
    when(
      () => repo.getListPreviews(any()),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => repo.getWatchlistEntries()).thenAnswer((_) async => <String>[]);
    when(() => repo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => repo.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    // Simulate discover pages
    when(
      () => repo.discoverMedia(
        page: 1,
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) async => [
        const MediaItem(
          id: 1,
          title: 'A',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.movie,
        ),
        const MediaItem(
          id: 2,
          title: 'B',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.movie,
        ),
      ],
    );
    when(
      () => repo.discoverMedia(
        page: 2,
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) async => [
        const MediaItem(
          id: 3,
          title: 'C',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.movie,
        ),
      ],
    );
  });

  test('pagination via fetchNextPage appends results', () async {
    final provider = SearchProvider(repo);

    // Start in discover mode (empty query)
    await provider.searchMedia('');
    final firstCount = provider.items.length;

    await provider.fetchNextPage();
    final secondCount = provider.items.length;

    expect(secondCount, greaterThanOrEqualTo(firstCount));
    expect(provider.hasMore, isTrue);
  });
}
