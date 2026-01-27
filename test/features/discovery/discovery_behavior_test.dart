import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepo = MockMediaRepository();
    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepo.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getListPreviews(any()),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepo.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    when(
      () => mockRepo.discoverMedia(
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <MediaItem>[]);
    when(
      () => mockRepo.searchMedia(
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

  test(
    'SearchProvider discover/search flows produce empty results safely',
    () async {
      final provider = SearchProvider(mockRepo);
      await Future.delayed(Duration.zero);

      expect(provider.items, isEmpty);

      await provider.searchMedia('');
      expect(provider.items, isEmpty);

      await provider.searchMedia('query');
      expect(provider.items, isEmpty);
    },
  );
}
