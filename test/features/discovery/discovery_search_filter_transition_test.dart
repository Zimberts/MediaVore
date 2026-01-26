import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

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
    when(
      () => repo.searchMedia(
        any(),
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <MediaItem>[]);
  });

  test('searchMedia uses active filters when performing search', () async {
    final provider = SearchProvider(repo);

    provider.setFilters(
      genreIds: [12, 34],
      releaseYear: 1999,
      minRating: 7.5,
      type: null,
    );

    await provider.searchMedia('matrix');

    // Should call searchMedia on repository (non-discover mode because query non-empty)
    verify(
      () => repo.searchMedia(
        'matrix',
        page: 1,
        genreIds: [12, 34],
        releaseYear: 1999,
        minRating: 7.5,
        language: null,
        type: null,
      ),
    ).called(1);
  });
}
