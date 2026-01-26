import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
  });

  setUp(() {
    repo = MockMediaRepository();
    registerFallbackValue(FakeMediaItem());

    // Basic stubs used by SearchProvider._init
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
      () => repo.discoverMedia(
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
    'importList calls repository.createList and addToList for entries',
    () async {
      final provider = SearchProvider(repo);

      // Prepare repository to accept createList and addToList
      when(() => repo.createList('MyList')).thenAnswer((_) async {});
      when(() => repo.addToList(any(), 'MyList')).thenAnswer((_) async {});

      await provider.importList('MyList', ['123:movie', '456:tv']);

      verify(() => repo.createList('MyList')).called(1);
      verify(() => repo.addToList(any(), 'MyList')).called(2);
    },
  );
}
